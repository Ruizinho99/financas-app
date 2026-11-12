/// Secções 1 a 4 da lista do utilizador (docs/metricas-fundamentais.md, Parte 2.0 e 2.2):
/// rentabilidade (margens), crescimento, retorno sobre o capital (ROE, ROA, ROIC, ROTE, DuPont)
/// e eficiência (rotação do ativo, prazos de caixa, rotação de inventários).
/// Funções PURAS: sem rede, sem Flutter, sem estado. Valor `null` quando falta um dado ou há divisão por zero.
library;

import 'dart:math' as math;

import 'financials.dart';

// ---------------------------------------------------------------------------
// Auxiliares (convenções da Parte 2.0 e 2.1)
// ---------------------------------------------------------------------------

/// EBIT para as fórmulas: resultado operacional e, se faltar, o campo `ebit`.
/// Não se usa `FinPeriod.ebitOrOperating` (tem a prioridade inversa, ver Parte 2.0).
double? _ebit(FinPeriod p) => p.operatingIncome ?? p.ebit;

double? _receita(FinPeriod p) => p.revenue;
double? _custo(FinPeriod p) => p.costOfRevenue;
double? _lucro(FinPeriod p) => p.netIncome;
double? _ebitda(FinPeriod p) => p.ebitda;
double? _patrimonio(FinPeriod p) => p.equity;
double? _ativo(FinPeriod p) => p.totalAssets;
double? _tangivel(FinPeriod p) => p.tangibleBookValue;
double? _inventario(FinPeriod p) => p.inventory;
double? _recebiveis(FinPeriod p) => p.receivables;
double? _pagaveis(FinPeriod p) => p.payables;

/// Resultado bruto: o `grossProfit` da fonte ou, se faltar, (receita − custo das vendas).
double? _resultadoBruto(FinPeriod p) {
  if (p.grossProfit != null) return p.grossProfit;
  if (p.revenue == null || p.costOfRevenue == null) return null;
  return p.revenue! - p.costOfRevenue!;
}

/// FCF = CFO − |capex|; se faltar um dos dois, o `freeCashFlow` da fonte.
double? _fcf(FinPeriod p) {
  if (p.operatingCashFlow != null && p.capexSpent != null) {
    return p.operatingCashFlow! - p.capexSpent!;
  }
  return p.freeCashFlow;
}

/// Capital investido de um período: capitais próprios + dívida financeira − caixa e equivalentes.
/// (Não se usa o `investedCapital` do Yahoo, que não deduz a caixa.)
double? _capitalInvestido(FinPeriod p) {
  if (p.equity == null || p.totalDebt == null || p.cash == null) return null;
  return p.equity! + p.totalDebt! - p.cash!;
}

/// Taxa de imposto efetiva `t` (Parte 2.0): `taxProvision / pretaxIncome` se estiver em [0; 0,5] e o
/// resultado antes de impostos for positivo; senão 21 %. É um fallback, não um clamp.
double taxRateOf(FinPeriod p) {
  final pt = p.pretaxIncome;
  final tx = p.taxProvision;
  if (pt == null || tx == null || pt <= 0) return 0.21;
  final r = tx / pt;
  return (r >= 0 && r <= 0.5) ? r : 0.21;
}

/// Período anterior de `cur` para as médias de balanço (Parte 2.0).
/// Exercício anual: o exercício anual imediatamente anterior. TTM ou trimestre: o período cujo fecho
/// está entre 320 e 410 dias antes de `cur.end`, primeiro nos trimestrais e depois nos anuais; `null` se não houver.
FinPeriod? periodoAnterior(Financials f, FinPeriod cur) {
  final i = f.annual.indexWhere((p) => identical(p, cur));
  if (i >= 0) return i > 0 ? f.annual[i - 1] : null;
  bool naJanela(FinPeriod p) {
    final dias = cur.end.difference(p.end).inDays;
    return dias >= 320 && dias <= 410;
  }

  for (final p in f.quarterly.reversed) {
    if (naJanela(p)) return p;
  }
  for (final p in f.annual.reversed) {
    if (naJanela(p)) return p;
  }
  return null;
}

/// Campo de um período, ou `null` se o período não existir.
double? _de(FinPeriod? p, double? Function(FinPeriod) campo) =>
    p == null ? null : campo(p);

/// Média de um saldo de balanço entre `cur` e `prev` (se faltar `prev`, só `cur`).
double? _mediaDe(
  FinPeriod? cur,
  FinPeriod? prev,
  double? Function(FinPeriod) campo,
) => cur == null ? null : avgOf(campo(cur), _de(prev, campo));

/// Quociente por um saldo médio: nulo se o saldo médio for ≤ 0 (ou em falta). Usado em ROE, ROA, ROIC, ROTE,
/// rotações e alavancagem, onde um denominador negativo não tem leitura económica.
double? _porMedia(double? numerador, double? saldoMedio) {
  if (saldoMedio == null || saldoMedio <= 0) return null;
  return safeDiv(numerador, saldoMedio);
}

/// Dias: saldo / base × 365 (nulo se faltar o saldo ou a base for 0).
double? _dias(double? saldo, double? base) {
  final r = safeDiv(saldo, base);
  return r == null ? null : r * 365;
}

/// Variação anual `atual / anterior − 1`, só se o período anterior for > 0 (Parte 2.2).
double? _yoy(double? atual, double? anterior) {
  if (atual == null || anterior == null || anterior <= 0) return null;
  return atual / anterior - 1;
}

/// CAGR `(atual / inicial)^(1/anos) − 1`, só se ambos forem > 0.
double? _cagr(double? atual, double? inicial, int anos) {
  if (atual == null || inicial == null || atual <= 0 || inicial <= 0) {
    return null;
  }
  return math.pow(atual / inicial, 1 / anos).toDouble() - 1;
}

/// ROE de um período (resultado / capitais próprios médios).
double? _roe(FinPeriod? cur, FinPeriod? prev) =>
    _porMedia(_de(cur, _lucro), _mediaDe(cur, prev, _patrimonio));

// ---------------------------------------------------------------------------
// Secção 1: rentabilidade (margens)
// ---------------------------------------------------------------------------

/// Secção 1: margens sobre a receita do período `cur` (por omissão, o `fin.latest`: TTM se existir).
List<Metric> profitabilityMetrics(Financials f, {FinPeriod? cur}) {
  final c = cur ?? f.latest;
  final receita = _de(c, _receita);
  return [
    // margem bruta = (receita − custo das vendas) / receita
    Metric(
      'gross_margin',
      safeDiv(_de(c, _resultadoBruto), receita),
      MetricKind.percent,
    ),
    // margem EBITDA = EBITDA / receita
    Metric(
      'ebitda_margin',
      safeDiv(_de(c, _ebitda), receita),
      MetricKind.percent,
    ),
    // margem operacional = EBIT / receita
    Metric(
      'operating_margin',
      safeDiv(_de(c, _ebit), receita),
      MetricKind.percent,
    ),
    // margem líquida = resultado líquido / receita
    Metric('net_margin', safeDiv(_de(c, _lucro), receita), MetricKind.percent),
    // margem de FCF = FCF / receita
    Metric('fcf_margin', safeDiv(_de(c, _fcf), receita), MetricKind.percent),
  ];
}

// ---------------------------------------------------------------------------
// Secção 2: crescimento (sempre anual: t = annual.last, t-1 = annual[len-2], t-3 = annual[len-4])
// ---------------------------------------------------------------------------

/// Secção 2: crescimento. Usa só os exercícios anuais.
List<Metric> growthMetrics(Financials f) {
  final a = f.annual;
  final t = a.isEmpty ? null : a.last;
  final t1 = a.length < 2 ? null : a[a.length - 2];
  final t3 = a.length < 4 ? null : a[a.length - 4];

  // crescimento sustentável = ROE × (1 − payout); payout = |dividendos| / resultado (dividendos em falta → 0)
  double? sustentavel;
  final roeAnual = _roe(t, t1);
  final lucroAnual = _de(t, _lucro);
  if (roeAnual != null && lucroAnual != null && lucroAnual > 0) {
    final payout = (t!.dividendsPaid?.abs() ?? 0) / lucroAnual;
    sustentavel = roeAnual * (1 - payout);
  }

  // alavancagem operacional = (variação % do EBIT) / (variação % da receita)
  final alavancagem = safeDiv(
    _yoy(_de(t, _ebit), _de(t1, _ebit)),
    _yoy(_de(t, _receita), _de(t1, _receita)),
  );

  return [
    // crescimento anual = x_t / x_{t-1} − 1
    Metric(
      'revenue_growth',
      _yoy(_de(t, _receita), _de(t1, _receita)),
      MetricKind.percent,
    ),
    Metric(
      'net_income_growth',
      _yoy(_de(t, _lucro), _de(t1, _lucro)),
      MetricKind.percent,
    ),
    Metric('fcf_growth', _yoy(_de(t, _fcf), _de(t1, _fcf)), MetricKind.percent),
    // CAGR a 3 anos = (x_t / x_{t-3})^(1/3) − 1 (exige 4 exercícios anuais)
    Metric(
      'revenue_cagr_3y',
      _cagr(_de(t, _receita), _de(t3, _receita), 3),
      MetricKind.percent,
    ),
    // CAGR a 5 e 10 anos e crescimento orgânico: não disponíveis com dados gratuitos
    const Metric('revenue_cagr_5y', null, MetricKind.percent),
    const Metric('revenue_cagr_10y', null, MetricKind.percent),
    const Metric('organic_growth', null, MetricKind.percent),
    Metric('sustainable_growth', sustentavel, MetricKind.percent),
    Metric('operating_leverage', alavancagem, MetricKind.ratio),
  ];
}

// ---------------------------------------------------------------------------
// Secção 3: retorno sobre o capital (ROE, ROA, ROIC, ROTE, DuPont)
// ---------------------------------------------------------------------------

/// Secção 3: retornos. `wacc` (fração) é opcional: sem ele não há spread ROIC − WACC.
/// `cur`/`prev` por omissão: `fin.latest` e o período anterior (ver [periodoAnterior]).
List<Metric> returnMetrics(
  Financials f, {
  double? wacc,
  FinPeriod? cur,
  FinPeriod? prev,
}) {
  final c = cur ?? f.latest;
  final p = prev ?? (c == null ? null : periodoAnterior(f, c));

  final lucro = _de(c, _lucro);
  final receita = _de(c, _receita);
  final ativoMedio = _mediaDe(c, p, _ativo);
  final patrimonioMedio = _mediaDe(c, p, _patrimonio);

  // ROE = resultado / capitais próprios médios
  final roe = _porMedia(lucro, patrimonioMedio);
  // ROA = resultado / ativo total médio
  final roa = _porMedia(lucro, ativoMedio);

  // ROIC = NOPAT / capital investido médio; NOPAT = EBIT × (1 − t)
  final ebit = _de(c, _ebit);
  final t = c == null ? null : taxRateOf(c);
  final nopat = (ebit == null || t == null) ? null : ebit * (1 - t);
  final roic = _porMedia(nopat, _mediaDe(c, p, _capitalInvestido));

  // ROTE = resultado / capitais próprios tangíveis médios
  final rote = _porMedia(lucro, _mediaDe(c, p, _tangivel));

  // DuPont: ROE = margem líquida × rotação do ativo × alavancagem financeira
  final margemLiquida = safeDiv(lucro, receita);
  final rotacaoAtivo = _porMedia(receita, ativoMedio);
  final alavancagem = _porMedia(ativoMedio, patrimonioMedio);
  final dupontRoe =
      (margemLiquida == null || rotacaoAtivo == null || alavancagem == null)
      ? null
      : margemLiquida * rotacaoAtivo * alavancagem;

  return [
    Metric('roe', roe, MetricKind.percent),
    Metric('roa', roa, MetricKind.percent),
    Metric('roic', roic, MetricKind.percent),
    // spread só se houver WACC: ROIC − WACC
    if (wacc != null)
      Metric(
        'roic_wacc_spread',
        roic == null ? null : roic - wacc,
        MetricKind.percent,
      ),
    Metric('rote', rote, MetricKind.percent),
    // taxa de imposto efetiva (a usada no NOPAT)
    Metric('tax_rate', t, MetricKind.percent),
    Metric('dupont_net_margin', margemLiquida, MetricKind.percent),
    Metric('dupont_asset_turnover', rotacaoAtivo, MetricKind.ratio),
    Metric('dupont_financial_leverage', alavancagem, MetricKind.ratio),
    Metric('dupont_roe', dupontRoe, MetricKind.percent),
  ];
}

// ---------------------------------------------------------------------------
// Secção 4: eficiência e ciclo de caixa
// ---------------------------------------------------------------------------

/// Secção 4: eficiência. Rotações com saldos médios; prazos (DSO, DIO, DPO) com o saldo de fecho de `cur`.
List<Metric> efficiencyMetrics(
  Financials f, {
  FinPeriod? cur,
  FinPeriod? prev,
}) {
  final c = cur ?? f.latest;
  final p = prev ?? (c == null ? null : periodoAnterior(f, c));

  final receita = _de(c, _receita);
  final custo = _de(c, _custo);

  // rotação do ativo = receita / ativo total médio
  final rotacaoAtivo = _porMedia(receita, _mediaDe(c, p, _ativo));
  // DSO = contas a receber / receita × 365
  final dso = _dias(_de(c, _recebiveis), receita);
  // DIO = inventários / custo das vendas × 365 (null se não houver inventários)
  final dio = _dias(_de(c, _inventario), custo);
  // DPO = contas a pagar / custo das vendas × 365
  final dpo = _dias(_de(c, _pagaveis), custo);
  // ciclo de conversão de caixa = DSO + DIO − DPO
  final ciclo = (dso == null || dio == null || dpo == null)
      ? null
      : dso + dio - dpo;
  // rotação de inventários = custo das vendas / inventário médio
  final rotacaoInventarios = _porMedia(custo, _mediaDe(c, p, _inventario));

  return [
    Metric('asset_turnover', rotacaoAtivo, MetricKind.ratio),
    Metric('dso', dso, MetricKind.days),
    Metric('dio', dio, MetricKind.days),
    Metric('dpo', dpo, MetricKind.days),
    Metric('cash_conversion_cycle', ciclo, MetricKind.days),
    Metric('inventory_turnover', rotacaoInventarios, MetricKind.ratio),
  ];
}
