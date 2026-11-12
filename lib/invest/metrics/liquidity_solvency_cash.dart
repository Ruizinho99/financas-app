/// Métricas de liquidez, solvência, fluxo de caixa e por ação (lista do utilizador, secções 5 a 8;
/// especificação Parte 2, secção 2.3).
///
/// Funções PURAS: recebem `Financials` e devolvem `List<Metric>`. Sem rede, sem Flutter, sem estado.
/// Base temporal: o período corrente é `fin.latest` (TTM se existir, senão o último anual); o período anterior
/// só serve para médias ("médio" = média do saldo corrente e do anterior). Diluição usa sempre anuais.
/// Dado em falta ou divisão por zero dá `null`. Valores monetários na moeda de reporte.
library;

import 'dart:math' show min;

import 'financials.dart';

/// Período vazio para quando não há demonstrações: todos os campos são `null`, logo todas as métricas dão `null`.
final FinPeriod _vazio = FinPeriod(end: DateTime(1970), annual: true);

/// Período corrente: `fin.latest` (TTM se existir, senão o último anual).
FinPeriod _cur(Financials f) => f.latest ?? _vazio;

/// Período anterior para as médias ("médio").
/// - Sem TTM (o corrente é o último anual): o anual anterior.
/// - Com TTM: o período (trimestral, ou anual se não houver trimestral) cujo `end` está entre 320 e 410 dias
///   antes de `cur.end`; se não houver nenhum, `null` (a média usa só o saldo corrente).
FinPeriod? _anterior(Financials f) {
  if (f.ttm == null) return f.prevAnnual;
  final fim = _cur(f).end;
  final candidatos = f.quarterly.isNotEmpty ? f.quarterly : f.annual;
  FinPeriod? melhor;
  int? melhorDif;
  for (final p in candidatos) {
    final dias = fim.difference(p.end).inDays;
    if (dias < 320 || dias > 410) continue;
    final dif = (dias - 365).abs();
    if (melhor == null || dif < melhorDif!) {
      melhor = p;
      melhorDif = dif;
    }
  }
  return melhor;
}

/// Soma que dá `null` se faltar uma parcela (não se inventa um zero).
double? _soma(double? a, double? b) => a == null || b == null ? null : a + b;

/// EBIT = resultado operacional e, se faltar, o campo `ebit` (Parte 2.0: NÃO o `ebitOrOperating` do contrato).
double? _ebit(FinPeriod p) => p.operatingIncome ?? p.ebit;

/// Juros para a cobertura: `interestExpense ?? interestPaid`; `null` ou 0 dão `null`.
double? _juros(FinPeriod p) {
  final j = p.interestExpense ?? p.interestPaid;
  return j == null || j == 0 ? null : j;
}

/// FCF = CFO − |capex|; se faltar um dos dois, o `freeCashFlow` da fonte.
double? _fcf(FinPeriod p) {
  final cfo = p.operatingCashFlow;
  final capex = p.capexSpent;
  if (cfo != null && capex != null) return cfo - capex;
  return p.freeCashFlow;
}

// ---------------------------------------------------------------- 5. Liquidez

/// Liquidez (saldos do fecho do período corrente).
List<Metric> liquidityMetrics(Financials f) {
  final c = _cur(f);
  final ac = c.currentAssets, pc = c.currentLiabilities;
  return [
    // Rácio corrente = ativo corrente / passivo corrente
    Metric('current_ratio', safeDiv(ac, pc), MetricKind.ratio),
    // Rácio rápido = (caixa + investimentos de curto prazo + contas a receber) / passivo corrente
    Metric(
      'quick_ratio',
      safeDiv(_soma(c.cashAndShortTermInvestments, c.receivables), pc),
      MetricKind.ratio,
    ),
    // Rácio de caixa = caixa / passivo corrente
    Metric('cash_ratio', safeDiv(c.cash, pc), MetricKind.ratio),
    // Fundo de maneio = ativo corrente − passivo corrente
    Metric(
      'working_capital',
      ac == null || pc == null ? null : ac - pc,
      MetricKind.money,
    ),
  ];
}

// ---------------------------------------------------------------- 6. Solvência e dívida

/// Solvência e dívida. Locações (IFRS 16): usa `totalDebt` tal como vem e NUNCA lhe soma `leaseLiabilities`
/// (a fonte não é consistente; ver Parte 3). Maturidades e dívida a taxa variável não estão nos dados gratuitos.
List<Metric> solvencyMetrics(Financials f) {
  final c = _cur(f);
  final divida = c.totalDebt;
  final caixa = c.cash;
  final dl = divida == null || caixa == null ? null : divida - caixa;
  final ebitda = c.ebitda;
  final pl = c.equity;
  final juros = _juros(c);
  final ebit = _ebit(c);
  final fcf = _fcf(c);
  return [
    // Dívida líquida = dívida financeira − caixa e equivalentes (negativa = caixa líquida)
    Metric('net_debt', dl, MetricKind.money),
    // Dívida líquida / EBITDA (EBITDA ≤ 0 → null)
    Metric(
      'net_debt_to_ebitda',
      ebitda == null || ebitda <= 0 ? null : safeDiv(dl, ebitda),
      MetricKind.ratio,
    ),
    // Dívida / capitais próprios (capitais próprios ≤ 0 → null)
    Metric(
      'debt_to_equity',
      pl == null || pl <= 0 ? null : safeDiv(divida, pl),
      MetricKind.ratio,
    ),
    // Cobertura de juros = EBIT / juros
    Metric(
      'interest_coverage',
      juros == null || ebit == null ? null : safeDiv(ebit, juros),
      MetricKind.ratio,
    ),
    // Dívida líquida / FCF = anos de FCF para pagar a dívida (FCF ≤ 0 → null)
    Metric(
      'net_debt_to_fcf',
      fcf == null || fcf <= 0 ? null : safeDiv(dl, fcf),
      MetricKind.years,
    ),
    // Maturidades da dívida: não disponível com dados gratuitos (só nas notas do relatório)
    const Metric('debt_maturities', null, MetricKind.money),
    // Dívida de taxa variável: não disponível com dados gratuitos
    const Metric('variable_rate_debt', null, MetricKind.percent),
  ];
}

// ---------------------------------------------------------------- 7. Fluxo de caixa e qualidade dos lucros

/// Fluxo de caixa e qualidade dos lucros. Capex em valor positivo (o que se gastou).
List<Metric> cashFlowMetrics(Financials f) {
  final c = _cur(f);
  final ant = _anterior(f);
  final cfo = c.operatingCashFlow;
  final capex = c.capexSpent; // |capex|
  final da = c.depreciationAmortization;
  final ni = c.netIncome;
  final cwc = c.changeInWorkingCapital;
  final sbc = c.stockBasedComp;
  final fcf = _fcf(c);
  // Capex de manutenção ≈ min(|capex|, D&A); capex de crescimento = |capex| − manutenção (aproximação)
  final manut = capex == null || da == null ? null : min(capex, da);
  final crescimento = capex == null || manut == null ? null : capex - manut;
  // Owner earnings (Buffett, aproximação) = resultado + D&A − capex de manutenção + variação do fundo de maneio
  // (a variação entra com o sinal da fonte: negativo = consumiu caixa)
  final ownerEarnings = ni == null || da == null || manut == null || cwc == null
      ? null
      : ni + da - manut + cwc;
  // Accruals de Sloan (versão por fluxos) = (resultado − CFO) / ativo total médio
  final ativoMedio = avgOf(c.totalAssets, ant?.totalAssets);
  final sloan = ni == null || cfo == null
      ? null
      : safeDiv(ni - cfo, ativoMedio);
  return [
    Metric('cfo', cfo, MetricKind.money),
    Metric('capex', capex, MetricKind.money),
    // FCF = CFO − capex
    Metric('fcf', fcf, MetricKind.money),
    // FCF tal como a fonte o reporta (freeCashFlow), para comparação
    Metric('fcf_reported', c.freeCashFlow, MetricKind.money),
    // FCF ajustado de SBC = FCF − remuneração em ações
    Metric(
      'fcf_after_sbc',
      fcf == null || sbc == null ? null : fcf - sbc,
      MetricKind.money,
    ),
    Metric('owner_earnings', ownerEarnings, MetricKind.money),
    Metric('maintenance_capex', manut, MetricKind.money),
    Metric('growth_capex', crescimento, MetricKind.money),
    // Conversão de caixa = CFO / resultado (resultado ≤ 0 → null)
    Metric(
      'cash_conversion',
      cfo == null || ni == null || ni <= 0 ? null : safeDiv(cfo, ni),
      MetricKind.percent,
    ),
    Metric('sloan_accruals', sloan, MetricKind.percent),
    // Capex / receita
    Metric('capex_to_revenue', safeDiv(capex, c.revenue), MetricKind.percent),
    // Capex / amortizações e depreciações
    Metric('capex_to_da', safeDiv(capex, da), MetricKind.ratio),
  ];
}

// ---------------------------------------------------------------- 8. Métricas por ação

/// Métricas por ação. Saldos e resultados vêm de `fin.latest`; a diluição usa sempre anuais.
/// O DPS vem do `MarketSnapshot` (dividendo dos últimos 12 meses, na moeda de reporte); sem snapshot, `null`.
List<Metric> perShareMetrics(Financials f, {MarketSnapshot? market}) {
  final c = _cur(f);
  final acoes = c.dilutedShares;
  final fcf = _fcf(c);
  // EPS = resultado líquido / ações diluídas (o `dilutedEps` da fonte tem prioridade)
  final eps = c.dilutedEps ?? safeDiv(c.netIncome, acoes);
  // Diluição = ações em fim de ano / ações do ano anterior − 1 (negativa = recompras)
  final relacao = safeDiv(
    f.lastAnnual?.sharesOutstanding,
    f.prevAnnual?.sharesOutstanding,
  );
  return [
    Metric('eps', eps, MetricKind.perShare),
    Metric('fcf_per_share', safeDiv(fcf, acoes), MetricKind.perShare),
    // BVPS = capitais próprios / ações
    Metric('bvps', safeDiv(c.equity, c.sharesOutstanding), MetricKind.perShare),
    // Valor contabilístico tangível por ação
    Metric(
      'tbvps',
      safeDiv(c.tangibleBookValue, c.sharesOutstanding),
      MetricKind.perShare,
    ),
    Metric('dps', market?.dividendPerShare, MetricKind.perShare),
    Metric(
      'share_dilution',
      relacao == null ? null : relacao - 1,
      MetricKind.percent,
    ),
  ];
}
