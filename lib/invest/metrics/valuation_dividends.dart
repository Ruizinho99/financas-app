/// Secção 9 (avaliação) e secção 10 (dividendos e retorno aos acionistas) da especificação
/// (docs/metricas-fundamentais.md, Parte 2.4). Funções puras: sem rede, sem Flutter, sem estado.
///
/// Os dados de mercado (`MarketSnapshot`) já estão na moeda de reporte: aqui não se converte moeda.
/// O período "atual" é `f.latest` (TTM se existir, senão o último anual), salvo indicação em contrário.
library;

import 'dart:math' as math;

import 'financials.dart';

/// Divisão que exige denominador positivo: nulo se faltar um valor ou se o denominador for ≤ 0.
/// Usa-se nos múltiplos (EPS, VPA, FCF, EBIT, EBITDA, receita ≤ 0 dão `null`).
double? _dividirPositivo(double? a, double? b) {
  if (a == null || b == null || !a.isFinite || !b.isFinite || b <= 0)
    return null;
  return a / b;
}

/// EBIT para as fórmulas: resultado operacional e, se faltar, o `ebit` da fonte (Parte 2.0).
double? _ebit(FinPeriod p) => p.operatingIncome ?? p.ebit;

/// EPS diluído: `dilutedEps ?? netIncome / dilutedShares` (Parte 2.3).
double? _eps(FinPeriod p) =>
    p.dilutedEps ?? _dividirPositivo(p.netIncome, p.dilutedShares);

/// FCF = operatingCashFlow − |capex|; se faltar um dos dois, o `freeCashFlow` da fonte (Parte 2.0).
double? _fcf(FinPeriod p) {
  if (p.operatingCashFlow != null && p.capex != null) {
    return p.operatingCashFlow! - p.capexSpent!;
  }
  return p.freeCashFlow;
}

/// Taxa de imposto efetiva com o fallback de 21 % (Parte 2.0).
double _taxa(FinPeriod p) {
  final imposto = p.taxProvision, antes = p.pretaxIncome;
  if (imposto == null || antes == null || antes <= 0) return 0.21;
  final r = imposto / antes;
  return (r >= 0 && r <= 0.5) ? r : 0.21;
}

/// Capitalização bolsista: `marketCap` da fonte ou preço × ações (Parte 2.4).
double? _capitalizacao(MarketSnapshot m) {
  if (m.marketCap != null) return m.marketCap;
  final p = m.price, n = m.sharesOutstanding;
  return (p == null || n == null) ? null : p * n;
}

/// EV = capitalização + dívida total − caixa + minoritários + preferenciais (minoritários e preferenciais nulos → 0).
/// Dívida ou caixa nulos → `null`. Não se usa `MarketSnapshot.enterpriseValue` (mistura moedas e definições).
double? _ev(FinPeriod c, double? mcap) {
  if (mcap == null || c.totalDebt == null || c.cash == null) return null;
  return mcap +
      c.totalDebt! -
      c.cash! +
      (c.minorityInterest ?? 0) +
      (c.preferredStock ?? 0);
}

/// Capital investido de um período: capitais próprios + dívida total − caixa (Parte 2.2).
double? _capitalInvestido(FinPeriod p) {
  if (p.equity == null || p.totalDebt == null || p.cash == null) return null;
  return p.equity! + p.totalDebt! - p.cash!;
}

/// Período anterior para as médias (Parte 2.0). Para os anuais é o anual anterior. Para o TTM é o trimestre
/// (ou o anual, se não houver trimestrais) cujo fecho está entre 320 e 410 dias antes; escolhe o mais próximo de 365 dias.
FinPeriod? _anterior(Financials f, FinPeriod c) {
  if (!identical(c, f.ttm)) {
    final i = f.annual.indexOf(c);
    return i > 0 ? f.annual[i - 1] : null;
  }
  final lista = f.quarterly.isNotEmpty ? f.quarterly : f.annual;
  FinPeriod? melhor;
  int? distancia;
  for (final p in lista) {
    final dias = c.end.difference(p.end).inDays;
    if (dias < 320 || dias > 410) continue;
    final d = (dias - 365).abs();
    if (distancia == null || d < distancia) {
      melhor = p;
      distancia = d;
    }
  }
  return melhor;
}

/// ROIC = NOPAT / capital investido médio, NOPAT = EBIT × (1 − t). Média ≤ 0 → `null` (Parte 2.2).
double? _roic(Financials f, FinPeriod? c) {
  if (c == null) return null;
  final ebit = _ebit(c);
  final ic = _capitalInvestido(c);
  if (ebit == null || ic == null) return null;
  final ant = _anterior(f, c);
  final media = avgOf(ic, ant == null ? null : _capitalInvestido(ant));
  return _dividirPositivo(ebit * (1 - _taxa(c)), media);
}

/// Greenblatt: ROC = EBIT / (max(fundo de maneio líquido, 0) + imobilizado líquido). Não é o ROIC.
/// Fundo de maneio líquido = (AC − caixa) − (PC − dívida corrente), com a dívida corrente `null` → 0.
double? _rocGreenblatt(FinPeriod c) {
  final ebit = _ebit(c);
  final ac = c.currentAssets,
      pc = c.currentLiabilities,
      caixa = c.cash,
      ppe = c.netPpe;
  if (ebit == null || ac == null || pc == null || caixa == null || ppe == null)
    return null;
  final fundoManeio = (ac - caixa) - (pc - (c.currentDebt ?? 0));
  return _dividirPositivo(ebit, math.max(fundoManeio, 0.0) + ppe);
}

/// Crescimento anual composto do EPS diluído: 3 anos (4 anuais) ou 2 anos (se só houver 3 anuais). Nulo se EPS ≤ 0 ou g ≤ 0.
double? _cagrEps(List<FinPeriod> anuais) {
  final n = anuais.length;
  if (n < 3) return null;
  final anos = n >= 4 ? 3 : 2;
  final fim = _eps(anuais[n - 1]), ini = _eps(anuais[n - 1 - anos]);
  if (fim == null || ini == null || fim <= 0 || ini <= 0) return null;
  return math.pow(fim / ini, 1 / anos).toDouble() - 1;
}

/// Avaliação (secção 9 da especificação). Devolve uma métrica por chave, mesmo quando o valor é `null`.
List<Metric> valuationMetrics(Financials f, MarketSnapshot m) {
  final c = f.latest;
  final ultimo = f.lastAnnual;
  final preco = m.price;
  final mcap = _capitalizacao(m);
  final ev = c == null ? null : _ev(c, mcap);
  final ebit = c == null ? null : _ebit(c);
  final fcf = c == null ? null : _fcf(c);

  // P/E: preço / EPS (EPS ≤ 0 → null). Trailing = último anual; TTM = período atual.
  final epsTtm = c == null ? null : _eps(c);
  final peTtm = _dividirPositivo(preco, epsTtm);
  final peTrailing = _dividirPositivo(
    preco,
    ultimo == null ? null : _eps(ultimo),
  );
  // P/E esperado: melhor esforço, a partir do EPS esperado da fonte (`forwardEps`).
  final peForward = _dividirPositivo(preco, m.forwardEps);
  // PEG = P/E TTM / (g × 100), g = CAGR do EPS.
  final g = _cagrEps(f.annual);
  final peg = (peTtm == null || g == null || g <= 0) ? null : peTtm / (g * 100);

  // Valores por ação: VPA = capitais próprios / ações; VPTA = capital tangível / ações.
  final vpa = c == null
      ? null
      : _dividirPositivo(c.equity, c.sharesOutstanding);
  final vpta = c == null
      ? null
      : _dividirPositivo(c.tangibleBookValue, c.sharesOutstanding);

  return [
    Metric('market_cap', mcap, MetricKind.money),
    Metric('ev', ev, MetricKind.money),
    Metric('pe_ttm', peTtm, MetricKind.ratio),
    Metric('pe_trailing', peTrailing, MetricKind.ratio),
    Metric('pe_forward', peForward, MetricKind.ratio),
    // CAPE exige 10 anos de lucros reais (Shiller): não se calcula com os dados gratuitos.
    const Metric('cape', null, MetricKind.ratio),
    // Rendimento dos lucros = EPS / preço (o inverso do P/E).
    // (o EPS pode ser negativo: só o preço tem de ser positivo)
    Metric(
      'earnings_yield',
      _dividirPositivo(epsTtm, preco),
      MetricKind.percent,
    ),
    Metric('peg', peg, MetricKind.ratio),
    Metric('pb', _dividirPositivo(preco, vpa), MetricKind.ratio),
    Metric('p_tbv', _dividirPositivo(preco, vpta), MetricKind.ratio),
    Metric('ps', _dividirPositivo(mcap, c?.revenue), MetricKind.ratio),
    Metric('p_fcf', _dividirPositivo(mcap, fcf), MetricKind.ratio),
    Metric('fcf_yield', _dividirPositivo(fcf, mcap), MetricKind.percent),
    Metric('ev_ebit', _dividirPositivo(ev, ebit), MetricKind.ratio),
    Metric('ev_ebitda', _dividirPositivo(ev, c?.ebitda), MetricKind.ratio),
    Metric('ev_revenue', _dividirPositivo(ev, c?.revenue), MetricKind.ratio),
    Metric('ev_fcf', _dividirPositivo(ev, fcf), MetricKind.ratio),
    // Fórmula mágica (Greenblatt): a revisão da spec usa o ROC de Greenblatt; a lista do utilizador pede o ROIC
    // (o ranking combina o rendimento EV/EBIT com o ROIC). Devolve-se cada componente.
    Metric(
      'magic_formula_roc',
      c == null ? null : _rocGreenblatt(c),
      MetricKind.percent,
    ),
    Metric('magic_formula_roic', _roic(f, c), MetricKind.percent),
    Metric('earnings_yield_ev', _dividirPositivo(ebit, ev), MetricKind.percent),
  ];
}

/// Agrupa o histórico de dividendos por ano civil (soma dos eventos de cada ano).
Map<int, double> _dpsPorAno(Map<DateTime, double> historico) {
  final r = <int, double>{};
  historico.forEach((data, valor) {
    r[data.year] = (r[data.year] ?? 0) + valor;
  });
  return r;
}

/// Crescimento do dividendo do último ano completo face ao anterior. Nulo sem dados suficientes ou se o anterior for 0.
double? _crescimentoDividendo(Map<int, double> dps, int ultimo, int primeiro) {
  if (ultimo - 1 < primeiro) return null;
  final anterior = dps[ultimo - 1] ?? 0;
  if (anterior <= 0) return null;
  return (dps[ultimo] ?? 0) / anterior - 1;
}

/// Anos consecutivos de aumento do dividendo, a contar para trás a partir do último ano completo.
double? _anosConsecutivosAumento(
  Map<int, double> dps,
  int ultimo,
  int primeiro,
) {
  if (ultimo - 1 < primeiro) return null;
  var anos = 0;
  for (var y = ultimo; y - 1 >= primeiro; y--) {
    if ((dps[y] ?? 0) > (dps[y - 1] ?? 0)) {
      anos++;
    } else {
      break;
    }
  }
  return anos.toDouble();
}

/// Dividendos e retorno aos acionistas (secção 10 da especificação).
///
/// [dividendHistory]: eventos de dividendo por data (pedido ao Yahoo com `range=max`, `events=div`), por ação, na moeda de reporte.
/// Só anos civis completos entram no crescimento e nos anos consecutivos (o ano corrente fica de fora).
/// [agora] existe para tornar os testes determinísticos; por omissão é a data atual.
List<Metric> dividendMetrics(
  Financials f,
  MarketSnapshot m, {
  Map<DateTime, double> dividendHistory = const {},
  DateTime? agora,
}) {
  final c = f.latest;
  final preco = m.price;
  final mcap = _capitalizacao(m);
  final fcf = c == null ? null : _fcf(c);
  // Valores em positivo: dividendos pagos e recompras líquidas (Parte 2.1).
  final divPago = c?.dividendsPaidPositive;
  final recompras = c?.netBuybacks;

  // Histórico por ano civil completo.
  double? crescimento;
  double? anos;
  if (dividendHistory.isNotEmpty) {
    final dps = _dpsPorAno(dividendHistory);
    final ultimo = (agora ?? DateTime.now()).year - 1;
    final primeiro = dps.keys.reduce(math.min);
    crescimento = _crescimentoDividendo(dps, ultimo, primeiro);
    anos = _anosConsecutivosAumento(dps, ultimo, primeiro);
  }

  return [
    Metric(
      'dividend_yield',
      _dividirPositivo(m.dividendPerShare, preco),
      MetricKind.percent,
    ),
    Metric(
      'payout_ratio',
      _dividirPositivo(divPago, c?.netIncome),
      MetricKind.percent,
    ),
    Metric('payout_fcf', _dividirPositivo(divPago, fcf), MetricKind.percent),
    Metric('dividend_growth', crescimento, MetricKind.percent),
    Metric('dividend_consecutive_years', anos, MetricKind.years),
    // Recompras líquidas / capitalização.
    Metric(
      'buyback_yield',
      _dividirPositivo(recompras, mcap),
      MetricKind.percent,
    ),
    // Shareholder yield = (dividendos + recompras líquidas) / capitalização; pode ser negativo.
    Metric(
      'shareholder_yield',
      recompras == null
          ? null
          : _dividirPositivo((divPago ?? 0) + recompras, mcap),
      MetricKind.percent,
    ),
  ];
}
