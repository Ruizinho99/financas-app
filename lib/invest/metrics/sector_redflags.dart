/// Qualidade do negócio e governo (secções 14 e 15 da Parte 1), métricas específicas por setor (secção 16)
/// e alertas de red flags (secção 17) de docs/metricas-fundamentais.md.
///
/// Funções puras (sem rede, sem Flutter). Todas as chaves têm prefixo (`quality_`, `gov_`, `bank_`, `insurer_`,
/// `reit_`, `utility_`, `commodity_`, `saas_`, `pharma_`, `retail_`, `holding_`, `nolp_`, `flag_`) para não
/// colidirem com as chaves dos outros módulos. As fichas estão em `sector_redflags_info.dart`.
///
/// Regras de base (Parte 2.0): `cur` = `fin.latest` (TTM se existir) para margens, retornos e saldos;
/// as taxas de crescimento e as séries usam sempre os exercícios anuais. EBIT = `operatingIncome ?? ebit`.
library;

import 'dart:math' as math;

import 'financials.dart';

/// Grupo setorial (secção 16), decidido pela indústria do Yahoo (ou pelo setor, quando a indústria falta).
enum SectorGroup {
  banks,
  insurers,
  reits,
  utilities,
  commodities,
  software,
  retail,
  pharma,
  holdings,
  generic,
}

/// Classifica o título num grupo da secção 16. Ordem de prioridade: a primeira regra que bater ganha.
/// Sem correspondência (industriais, consumo, comunicação...) é `generic`: sem métricas setoriais.
SectorGroup sectorGroupOf(MarketSnapshot m) {
  final ind = m.industry.toLowerCase();
  final sec = m.sector.toLowerCase();
  final name = m.name.toLowerCase();
  if (ind.contains('bank')) return SectorGroup.banks;
  if (ind.contains('insurance')) return SectorGroup.insurers;
  if (ind.contains('reit')) return SectorGroup.reits;
  if (sec.contains('utilities')) return SectorGroup.utilities;
  if (sec.contains('energy') || sec.contains('basic materials')) {
    return SectorGroup.commodities;
  }
  if (ind.contains('software')) return SectorGroup.software;
  if (ind.contains('retail')) return SectorGroup.retail;
  if (ind.contains('drug') || ind.contains('biotech'))
    return SectorGroup.pharma;
  if (ind.contains('conglomerate') ||
      ind.contains('holding') ||
      name.contains('holding')) {
    return SectorGroup.holdings;
  }
  return SectorGroup.generic;
}

// ---------------------------------------------------------------------------------------------------------------
// Auxiliares privados (cópias locais das regras da Parte 2; este módulo não depende de outros módulos).
// ---------------------------------------------------------------------------------------------------------------

/// EBIT das fórmulas: resultado operacional e, se faltar, o `ebit` da fonte (Parte 2.0).
double? _ebit(FinPeriod p) => p.operatingIncome ?? p.ebit;

/// Taxa de imposto efetiva (Parte 2.0): fallback de 21 % quando não é calculável ou está fora de [0; 0,5].
double _taxRate(FinPeriod p) {
  final pt = p.pretaxIncome;
  final tp = p.taxProvision;
  if (pt == null || tp == null || pt <= 0) return 0.21;
  final r = tp / pt;
  return (r >= 0 && r <= 0.5) ? r : 0.21;
}

/// FCF = CFO − |capex|; se faltar um dos dois, o `freeCashFlow` da fonte (Parte 2.0).
double? _fcf(FinPeriod p) {
  final o = p.operatingCashFlow;
  final c = p.capex;
  if (o != null && c != null) return o - c.abs();
  return p.freeCashFlow;
}

/// Margem bruta: `grossProfit / receita`, ou `(receita − custo) / receita` se faltar o lucro bruto.
double? _grossMargin(FinPeriod p) {
  if (p.grossProfit != null) return safeDiv(p.grossProfit, p.revenue);
  if (p.revenue == null || p.costOfRevenue == null) return null;
  return safeDiv(p.revenue! - p.costOfRevenue!, p.revenue);
}

/// Capital investido bruto de caixa: capitais próprios + dívida − caixa (Parte 2.2, ROIC).
double? _investedCapital(FinPeriod p) {
  if (p.equity == null || p.totalDebt == null || p.cash == null) return null;
  return p.equity! + p.totalDebt! - p.cash!;
}

/// Período anterior para as médias ("médio", Parte 2.0): o anual anterior; no TTM, o período (trimestral,
/// ou anual se não houver trimestral) cujo fecho está 320 a 410 dias antes, o mais próximo de 365 dias.
FinPeriod? _prevPeriod(Financials f, FinPeriod cur) {
  if (!identical(cur, f.ttm)) {
    final earlier = f.annual.where((p) => p.end.isBefore(cur.end)).toList();
    return earlier.isEmpty ? null : earlier.last;
  }
  for (final lista in [f.quarterly, f.annual]) {
    FinPeriod? best;
    var bestDist = 1 << 30;
    for (final p in lista) {
      final d = cur.end.difference(p.end).inDays;
      if (d < 320 || d > 410) continue;
      final dist = (d - 365).abs();
      if (dist < bestDist) {
        best = p;
        bestDist = dist;
      }
    }
    if (best != null) return best;
  }
  return null;
}

/// Variação percentual `x / x_anterior − 1`, só se o anterior for > 0 (Parte 2.2).
double? _yoy(double? x, double? xPrev) {
  if (x == null || xPrev == null || xPrev <= 0) return null;
  return x / xPrev - 1;
}

/// Últimos `n` exercícios anuais (ou todos, se houver menos).
List<FinPeriod> _ultimosAnuais(Financials f, int n) =>
    f.annual.length <= n ? f.annual : f.annual.sublist(f.annual.length - n);

/// Média aritmética; nula se a lista estiver vazia.
double? _mean(List<double> xs) =>
    xs.isEmpty ? null : xs.reduce((a, b) => a + b) / xs.length;

/// Desvio-padrão amostral (n − 1). Exige pelo menos 3 valores: com menos, o desvio não diz nada e devolve nulo.
double? _stdev(List<double> xs) {
  if (xs.length < 3) return null;
  final mu = _mean(xs)!;
  var soma = 0.0;
  for (final x in xs) {
    soma += (x - mu) * (x - mu);
  }
  return math.sqrt(soma / (xs.length - 1));
}

/// Variação do primeiro para o último valor (ordem cronológica). Exige pelo menos 2 valores.
double? _change(List<double> xs) => xs.length < 2 ? null : xs.last - xs.first;

/// Métricas que a fonte gratuita não permite calcular (Parte 3): `null`, com a ficha a explicar porquê.
List<Metric> _na(List<(String, MetricKind)> items) => [
  for (final (key, kind) in items) Metric(key, null, kind),
];

// ---------------------------------------------------------------------------------------------------------------
// Secções 14 e 15: qualidade do negócio e governo.
// ---------------------------------------------------------------------------------------------------------------

/// Secções 14 e 15 da Parte 1. Calcula só a estabilidade do ROIC e das margens ao longo dos exercícios anuais
/// (desvio-padrão amostral e variação do primeiro para o último ano; o desvio exige 3 anos e a variação 2) e a
/// percentagem de ações detidas por administradores (`m.insidersPercentHeld`, quando a fonte a dá). O ROIC de
/// cada ano = NOPAT / capital investido médio (ano atual e anterior); anos sem média positiva ficam de fora.
/// O resto das duas secções devolve `null` (não disponível com dados gratuitos).
///
/// `m` é opcional: sem snapshot, a percentagem de insiders fica nula.
List<Metric> qualityMetrics(Financials f, {MarketSnapshot? m}) {
  final a = f.annual;

  // ROIC anual: NOPAT_t / média(capital investido_t, capital investido_{t−1}); exige o ano anterior.
  final roics = <double>[];
  for (var i = 1; i < a.length; i++) {
    final icPrev = _investedCapital(a[i - 1]);
    final icNow = _investedCapital(a[i]);
    final ebit = _ebit(a[i]);
    if (icPrev == null || icNow == null || ebit == null) continue;
    final avgIc = (icPrev + icNow) / 2;
    if (avgIc <= 0) continue;
    roics.add(ebit * (1 - _taxRate(a[i])) / avgIc);
  }

  final gross = <double>[];
  final oper = <double>[];
  final net = <double>[];
  for (final p in a) {
    final g = _grossMargin(p);
    if (g != null) gross.add(g);
    final o = safeDiv(_ebit(p), p.revenue);
    if (o != null) oper.add(o);
    final n = safeDiv(p.netIncome, p.revenue);
    if (n != null) net.add(n);
  }

  return [
    Metric('quality_roic_mean', _mean(roics), MetricKind.percent),
    Metric('quality_roic_stdev', _stdev(roics), MetricKind.percent),
    Metric('quality_roic_change', _change(roics), MetricKind.percent),
    Metric('quality_gross_margin_stdev', _stdev(gross), MetricKind.percent),
    Metric('quality_gross_margin_change', _change(gross), MetricKind.percent),
    Metric('quality_operating_margin_stdev', _stdev(oper), MetricKind.percent),
    Metric(
      'quality_operating_margin_change',
      _change(oper),
      MetricKind.percent,
    ),
    Metric('quality_net_margin_stdev', _stdev(net), MetricKind.percent),
    Metric('quality_net_margin_change', _change(net), MetricKind.percent),
    Metric('gov_insider_ownership', m?.insidersPercentHeld, MetricKind.percent),
    ..._na(const [
      ('quality_roic_10y', MetricKind.percent),
      ('quality_market_share', MetricKind.percent),
      ('quality_recurring_revenue', MetricKind.percent),
      ('quality_customer_concentration', MetricKind.percent),
      ('quality_supplier_concentration', MetricKind.percent),
      ('quality_moat_sources', MetricKind.score),
      ('gov_capital_allocation', MetricKind.score),
      ('gov_buyback_price_discipline', MetricKind.score),
      ('gov_pay_linked_to_roic_fcf', MetricKind.score),
      ('gov_board_independence', MetricKind.score),
      ('gov_share_classes', MetricKind.score),
      ('gov_auditor_risk', MetricKind.score),
    ]),
  ];
}

// ---------------------------------------------------------------------------------------------------------------
// Secção 16: métricas específicas por setor.
// ---------------------------------------------------------------------------------------------------------------

/// Secção 16 da Parte 1: métricas do grupo do título (`sectorGroupOf`), mais as de "sem lucros" quando o
/// título não tem lucro (ver `_semLucros`). Para as métricas que a Parte 3 diz não estarem disponíveis, devolve
/// `null` com a ficha a explicar porquê. Um grupo `generic` sem lucros negativos não devolve nada.
List<Metric> sectorMetrics(Financials f, MarketSnapshot m) {
  final g = sectorGroupOf(m);
  final out = <Metric>[];
  switch (g) {
    case SectorGroup.banks:
      out.addAll(_banks(f, m));
    case SectorGroup.insurers:
      out.addAll(_insurers());
    case SectorGroup.reits:
      out.addAll(_reits());
    case SectorGroup.utilities:
      out.addAll(_utilities());
    case SectorGroup.commodities:
      out.addAll(_commodities());
    case SectorGroup.software:
      out.addAll(_software(f));
    case SectorGroup.retail:
      out.addAll(_retail());
    case SectorGroup.pharma:
      out.addAll(_pharma(f));
    case SectorGroup.holdings:
      out.addAll(_holdings());
    case SectorGroup.generic:
      break;
  }
  if (_semLucrosAplicavel(f, g)) out.addAll(_semLucros(f));
  return out;
}

/// "Empresas sem lucros" é decidido pelas demonstrações (lucro líquido do período atual ≤ 0), não pelo setor.
/// Aplica-se por cima do grupo setorial, mas não a bancos, seguradoras, REITs nem utilities: nesses, a
/// queima de caixa e a diluição não têm o mesmo significado (e a secção 16 não as pede).
bool _semLucrosAplicavel(Financials f, SectorGroup g) {
  const grupos = {
    SectorGroup.generic,
    SectorGroup.software,
    SectorGroup.pharma,
    SectorGroup.retail,
    SectorGroup.commodities,
    SectorGroup.holdings,
  };
  if (!grupos.contains(g)) return false;
  final ni = f.latest?.netIncome;
  return ni != null && ni <= 0;
}

List<Metric> _banks(Financials f, MarketSnapshot m) {
  final cur = f.latest;
  // P/TBV = preço / (valor contabilístico tangível / ações), com o saldo do fecho de cur (Parte 2.3 e 2.4).
  final tbvps = safeDiv(cur?.tangibleBookValue, cur?.sharesOutstanding);
  final price = m.price;
  final ptbv = (tbvps != null && tbvps > 0 && price != null)
      ? price / tbvps
      : null;
  return [
    Metric('bank_nii', cur?.netInterestIncome, MetricKind.money),
    Metric(
      'bank_nii_growth',
      _yoy(f.lastAnnual?.netInterestIncome, f.prevAnnual?.netInterestIncome),
      MetricKind.percent,
    ),
    Metric('bank_rote', _rote(f), MetricKind.percent),
    Metric('bank_p_tbv', ptbv, MetricKind.ratio),
    ..._na(const [
      ('bank_nim', MetricKind.percent),
      ('bank_cost_to_income', MetricKind.percent),
      ('bank_cost_of_risk', MetricKind.percent),
      ('bank_cet1', MetricKind.percent),
      ('bank_npl', MetricKind.percent),
      ('bank_npl_coverage', MetricKind.percent),
      ('bank_lcr', MetricKind.percent),
    ]),
  ];
}

/// ROTE = resultado / média dos capitais próprios tangíveis (Parte 2.2); média ≤ 0 → nulo.
double? _rote(Financials f) {
  final cur = f.latest;
  if (cur == null) return null;
  final prev = _prevPeriod(f, cur);
  final avgTbv = avgOf(cur.tangibleBookValue, prev?.tangibleBookValue);
  final ni = cur.netIncome;
  if (ni == null || avgTbv == null || avgTbv <= 0) return null;
  return ni / avgTbv;
}

List<Metric> _insurers() => _na(const [
  ('insurer_combined_ratio', MetricKind.percent),
  ('insurer_float', MetricKind.money),
  ('insurer_reserves', MetricKind.money),
]);

List<Metric> _reits() => _na(const [
  ('reit_ffo', MetricKind.money),
  ('reit_affo', MetricKind.money),
  ('reit_nav', MetricKind.perShare),
  ('reit_cap_rate', MetricKind.percent),
  ('reit_ltv', MetricKind.percent),
  ('reit_occupancy', MetricKind.percent),
]);

List<Metric> _utilities() => _na(const [
  ('utility_rab', MetricKind.money),
  ('utility_allowed_return', MetricKind.percent),
]);

List<Metric> _commodities() => _na(const [
  ('commodity_breakeven', MetricKind.perShare),
  ('commodity_reserves', MetricKind.score),
  ('commodity_cost_per_unit', MetricKind.perShare),
  ('commodity_fcf_cycle', MetricKind.money),
  ('commodity_normalized_earnings', MetricKind.money),
]);

/// Software e SaaS: regra dos 40 = crescimento YoY da receita (anual) + margem de FCF (`cur`), em fração
/// (0,40 = 40 pontos percentuais); SBC / receita; margem bruta. ARR, NRR e CAC payback não se calculam.
List<Metric> _software(Financials f) {
  final cur = f.latest;
  final growth = _yoy(f.lastAnnual?.revenue, f.prevAnnual?.revenue);
  final fcfMargin = cur == null ? null : safeDiv(_fcf(cur), cur.revenue);
  final rule40 = (growth != null && fcfMargin != null)
      ? growth + fcfMargin
      : null;
  return [
    Metric('saas_revenue_growth', growth, MetricKind.percent),
    Metric('saas_fcf_margin', fcfMargin, MetricKind.percent),
    Metric('saas_rule_of_40', rule40, MetricKind.percent),
    Metric(
      'saas_sbc_to_revenue',
      cur == null ? null : safeDiv(cur.stockBasedComp, cur.revenue),
      MetricKind.percent,
    ),
    Metric(
      'saas_gross_margin',
      cur == null ? null : _grossMargin(cur),
      MetricKind.percent,
    ),
    ..._na(const [
      ('saas_arr', MetricKind.money),
      ('saas_nrr', MetricKind.percent),
      ('saas_cac_payback', MetricKind.years),
    ]),
  ];
}

/// Farma e biotecnologia: I&D / receita (`cur`). Pipeline, patent cliff e rNPV não se calculam.
List<Metric> _pharma(Financials f) {
  final cur = f.latest;
  return [
    Metric(
      'pharma_rd_to_revenue',
      cur == null ? null : safeDiv(cur.researchDevelopment, cur.revenue),
      MetricKind.percent,
    ),
    ..._na(const [
      ('pharma_pipeline', MetricKind.score),
      ('pharma_patent_cliff', MetricKind.score),
      ('pharma_rnpv', MetricKind.money),
    ]),
  ];
}

List<Metric> _retail() => _na(const [
  ('retail_like_for_like', MetricKind.percent),
  ('retail_sales_per_sqm', MetricKind.money),
  ('retail_store_margin', MetricKind.percent),
]);

List<Metric> _holdings() => _na(const [
  ('holding_sotp', MetricKind.perShare),
  ('holding_discount', MetricKind.percent),
]);

/// Empresas sem lucros: receita, margem bruta, cash runway e diluição (Parte 3, secção 16).
/// Cash runway (meses) = caixa e investimentos de curto prazo / queima mensal de FCF, só com FCF TTM < 0.
/// Diluição = ações do fecho de t / ações do fecho de t−1 − 1 (Parte 2.3).
List<Metric> _semLucros(Financials f) {
  final cur = f.latest;
  final fcf = cur == null ? null : _fcf(cur);
  final cash = cur?.cashAndShortTermInvestments;
  final runway = (fcf != null && fcf < 0 && cash != null)
      ? cash / (-fcf / 12)
      : null;
  return [
    Metric('nolp_revenue', cur?.revenue, MetricKind.money),
    Metric(
      'nolp_gross_margin',
      cur == null ? null : _grossMargin(cur),
      MetricKind.percent,
    ),
    Metric('nolp_cash_runway_months', runway, MetricKind.years),
    Metric(
      'nolp_dilution',
      _yoy(f.lastAnnual?.sharesOutstanding, f.prevAnnual?.sharesOutstanding),
      MetricKind.percent,
    ),
  ];
}

// ---------------------------------------------------------------------------------------------------------------
// Secção 17: red flags. Cada alerta é uma Metric com chave `flag_*`: 1.0 (alerta ativo), 0.0 (sem alerta) ou
// null (sem dados para decidir). Limiares simples, documentados na ficha de cada alerta.
// ---------------------------------------------------------------------------------------------------------------

/// Limiares dos alertas (iguais aos das fichas em `sector_redflags_info.dart`).
const double _limiteCrescimentoWc =
    0.05; // DSO / DIO a subir mais de 5 % num ano
const double _limiteItensEspeciais = 0.01; // |itens especiais| ≥ 1 % da receita
const double _limiteGoodwill = 0.30; // goodwill > 30 % do ativo total
const double _limiteImparidade = 0.01; // imparidade ≥ 1 % do ativo total
const double _limiteCaixa = 0.20; // caixa ≥ 20 % do ativo total
const double _limiteDivida = 0.25; // dívida ≥ 25 % do ativo total
const double _limiteImpostoPago =
    0.50; // imposto pago < 50 % do imposto reportado

/// Red flags (secção 17 da Parte 1). `m` está na assinatura para as regras futuras que precisem de mercado;
/// as regras atuais usam só as demonstrações. Os alertas sem fonte de dados (ajustados vs GAAP, mudanças de
/// políticas contabilísticas, capitalização de custos) devolvem sempre `null`.
List<Metric> redFlags(Financials f, MarketSnapshot m) {
  final t = f.lastAnnual;
  final p = f.prevAnnual;
  return [
    Metric(
      'flag_earnings_up_cfo_down',
      _earningsUpCfoDown(t, p),
      MetricKind.score,
    ),
    Metric(
      'flag_dso_rising',
      _risingAbove(t, p, _dso, _limiteCrescimentoWc),
      MetricKind.score,
    ),
    Metric(
      'flag_dio_rising',
      _risingAbove(t, p, _dio, _limiteCrescimentoWc),
      MetricKind.score,
    ),
    const Metric('flag_adjusted_vs_gaap', null, MetricKind.score),
    Metric(
      'flag_special_items_recurring',
      _todosOsAnos(f.annual, _itensEspeciaisAcima),
      MetricKind.score,
    ),
    Metric('flag_goodwill_high', _goodwillAlto(f), MetricKind.score),
    Metric('flag_impairments', _imparidades(f), MetricKind.score),
    Metric('flag_debt_and_cash_high', _dividaECaixa(f), MetricKind.score),
    Metric('flag_tax_paid_low', _impostoPagoBaixo(f), MetricKind.score),
    Metric(
      'flag_serial_acquisitions',
      _todosOsAnos(f.annual, _aquisicoes),
      MetricKind.score,
    ),
    const Metric('flag_accounting_policy_changes', null, MetricKind.score),
    const Metric('flag_capitalized_costs', null, MetricKind.score),
  ];
}

/// 1 se o lucro líquido subiu e o CFO desceu no último ano anual face ao anterior.
double? _earningsUpCfoDown(FinPeriod? t, FinPeriod? p) {
  if (t == null || p == null) return null;
  final ni1 = t.netIncome, ni0 = p.netIncome;
  final cfo1 = t.operatingCashFlow, cfo0 = p.operatingCashFlow;
  if (ni1 == null || ni0 == null || cfo1 == null || cfo0 == null) return null;
  return (ni1 > ni0 && cfo1 < cfo0) ? 1 : 0;
}

/// DSO = contas a receber / receita × 365 (saldo de fecho).
double? _dso(FinPeriod p) {
  final r = safeDiv(p.receivables, p.revenue);
  return r == null ? null : r * 365;
}

/// DIO = inventário / custo das vendas × 365 (saldo de fecho).
double? _dio(FinPeriod p) {
  final r = safeDiv(p.inventory, p.costOfRevenue);
  return r == null ? null : r * 365;
}

/// 1 se a métrica subiu mais de [limite] (em %) face ao ano anterior; 0 se não subiu tanto; nulo sem dados.
double? _risingAbove(
  FinPeriod? t,
  FinPeriod? p,
  double? Function(FinPeriod) metric,
  double limite,
) {
  if (t == null || p == null) return null;
  final now = metric(t);
  final before = metric(p);
  if (now == null || before == null || before <= 0) return null;
  return (now / before - 1) > limite ? 1 : 0;
}

/// Itens especiais: 1 se |itens| ≥ 1 % da receita; 0 se não (incluindo o zero explícito).
bool? _itensEspeciaisAcima(FinPeriod p) {
  final s = p.specialItems;
  if (s == null) return null;
  if (s == 0) return false;
  final r = p.revenue;
  if (r == null || r == 0) return null;
  return s.abs() / r.abs() >= _limiteItensEspeciais;
}

/// Aquisições: `acquisitions` negativo (saída de caixa) neste ano.
bool? _aquisicoes(FinPeriod p) {
  final q = p.acquisitions;
  if (q == null) return null;
  return q < 0;
}

/// Regra "todos os anos": exige pelo menos 3 exercícios anuais. Um ano que quebra o padrão (`false`) dá 0 de
/// imediato; um ano em falta (`null`) sem quebra dá nulo; só com todos os anos a cumprir dá 1.
double? _todosOsAnos(List<FinPeriod> a, bool? Function(FinPeriod) teste) {
  if (a.length < 3) return null;
  var emFalta = false;
  for (final p in a) {
    final r = teste(p);
    if (r == false) return 0;
    if (r == null) emFalta = true;
  }
  return emFalta ? null : 1;
}

/// Goodwill > 30 % do ativo total (saldo de `cur`).
double? _goodwillAlto(Financials f) {
  final cur = f.latest;
  if (cur == null) return null;
  final r = safeDiv(cur.goodwill, cur.totalAssets);
  if (r == null) return null;
  return r > _limiteGoodwill ? 1 : 0;
}

/// Imparidades: 1 se algum dos últimos 3 anos tem imparidade ≥ 1 % do ativo. Campo ausente conta como sem
/// imparidade (a fonte omite os zeros); nulo só se nenhum ano tiver ativo total.
double? _imparidades(Financials f) {
  var sabe = false;
  for (final p in _ultimosAnuais(f, 3)) {
    final ta = p.totalAssets;
    if (ta == null || ta <= 0) continue;
    sabe = true;
    if ((p.impairment ?? 0) / ta >= _limiteImparidade) return 1;
  }
  return sabe ? 0 : null;
}

/// Dívida e caixa elevados ao mesmo tempo: caixa ≥ 20 % do ativo e dívida ≥ 25 % do ativo (saldos de `cur`).
double? _dividaECaixa(Financials f) {
  final cur = f.latest;
  if (cur == null) return null;
  final cashRatio = safeDiv(cur.cash, cur.totalAssets);
  final debtRatio = safeDiv(cur.totalDebt, cur.totalAssets);
  if (cashRatio == null || debtRatio == null) return null;
  return (cashRatio >= _limiteCaixa && debtRatio >= _limiteDivida) ? 1 : 0;
}

/// Imposto pago abaixo de 50 % do reportado, somando os últimos 3 anos em que há os dois valores e o imposto
/// reportado é positivo (`incomeTaxPaid` vs `taxProvision`). Sem anos utilizáveis, nulo.
double? _impostoPagoBaixo(Financials f) {
  var pago = 0.0, reportado = 0.0;
  var n = 0;
  for (final p in _ultimosAnuais(f, 3)) {
    final prov = p.taxProvision, paid = p.incomeTaxPaid;
    if (prov == null || paid == null || prov <= 0) continue;
    reportado += prov;
    pago += paid;
    n++;
  }
  if (n == 0) return null;
  return (pago / reportado) < _limiteImpostoPago ? 1 : 0;
}
