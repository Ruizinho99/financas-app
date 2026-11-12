/// DCF (secção 12 da lista; especificação em `docs/metricas-fundamentais.md`, 2.8 e a Revisão).
/// Funções PURAS: sem rede, sem Flutter, sem estado. Valores em moeda de reporte; taxas em fração.
library;

import 'dart:math' as math;

import 'financials.dart';

/// Premissas editáveis pelo utilizador. Os valores por omissão são os da especificação.
class DcfAssumptions {
  /// Taxa sem risco (rf) do CAPM.
  final double riskFreeRate;

  /// Prémio de risco de mercado (MRP) do CAPM.
  final double marketRiskPremium;

  /// Anos de projeção explícita (N).
  final int years;

  /// Crescimento explícito anual (gr). Se `null`: CAGR de 3 anos da receita limitado a [0; 0,15]
  /// (fallback 5 % se não houver CAGR), ver [defaultExplicitGrowth].
  final double? explicitGrowth;

  /// Crescimento terminal na perpetuidade (g).
  final double terminalGrowth;

  /// Beta do utilizador. Se `null`: beta do snapshot de mercado, senão 1,0.
  final double? beta;

  /// Taxa de imposto do utilizador. Se `null`: taxa efetiva do período ([effectiveTaxRate]).
  final double? taxRate;

  const DcfAssumptions({
    this.riskFreeRate = 0.04,
    this.marketRiskPremium = 0.055,
    this.years = 5,
    this.explicitGrowth,
    this.terminalGrowth = 0.025,
    this.beta,
    this.taxRate,
  });
}

/// Valores de fallback fixados pela especificação (2.0 e 2.8).
const double taxFallback = 0.21;
const double betaFallback = 1.0;
const double kdFallback = 0.05;
const double explicitGrowthFallback = 0.05;

/// Resultado do DCF para um conjunto de premissas.
class DcfResult {
  final double fcff0; // base FCFF₀
  final double growth; // crescimento explícito gr
  final double terminalGrowth; // g
  final double wacc;
  final int years;
  final double sumPv; // soma dos fluxos descontados
  final double terminalValue; // TV em t = N
  final double pvTerminal; // TV descontado
  final double? equityValue; // null se faltar a dívida líquida
  final double? valuePerShare; // null se faltar dívida líquida ou ações

  const DcfResult({
    required this.fcff0,
    required this.growth,
    required this.terminalGrowth,
    required this.wacc,
    required this.years,
    required this.sumPv,
    required this.terminalValue,
    required this.pvTerminal,
    required this.equityValue,
    required this.valuePerShare,
  });
}

/// Taxa de imposto efetiva `t` (2.0): `impostos / resultado antes de impostos`; se o resultado for <= 0 ou faltar
/// um dos dois, ou se a taxa cair fora de [0; 0,5], usa 21 % (é um fallback, não um clamp: 0,7 dá 0,21).
double effectiveTaxRate(FinPeriod p) {
  final pretax = p.pretaxIncome;
  final tax = p.taxProvision;
  if (pretax == null || tax == null || pretax <= 0) return taxFallback;
  final r = tax / pretax;
  return (r >= 0 && r <= 0.5) ? r : taxFallback;
}

/// Ke pelo CAPM: `Ke = rf + β × prémio de risco`.
double capmKe({
  required double rf,
  required double beta,
  required double mrp,
}) => rf + beta * mrp;

/// WACC = `E/(D+E) · Ke + D/(D+E) · Kd · (1 − t)`. E = capitalização bolsista; D = dívida total contabilística
/// (`null` → 0). Devolve `null` se faltar E ou se E + D não for positivo.
double? waccOf({
  required double? marketCap,
  required double? totalDebt,
  required double ke,
  required double kd,
  required double t,
}) {
  final e = marketCap;
  if (e == null || !e.isFinite) return null;
  final d = totalDebt ?? 0;
  final v = e + d;
  final we = safeDiv(e, v);
  if (we == null) return null;
  final wd = d / v;
  return we * ke + wd * kd * (1 - t);
}

/// Kd = juros / dívida média. Juros = `interestExpense ?? interestPaid` (em valor absoluto); dívida média = `avgOf` da
/// dívida total de `cur` e `prev`. Sem juros ou sem dívida, ou se o resultado estiver fora de [0; 0,20], devolve 5 %.
double costOfDebt(FinPeriod cur, FinPeriod? prev) {
  final interest = (cur.interestExpense ?? cur.interestPaid)?.abs();
  final debt = avgOf(cur.totalDebt, prev?.totalDebt);
  final kd = interest == null ? null : safeDiv(interest, debt);
  if (kd == null || kd < 0 || kd > 0.20) return kdFallback;
  return kd;
}

/// FCFF₀ = EBIT × (1 − t) + D&A − |capex| + variação do fundo de maneio (com o sinal de caixa reportado).
/// EBIT = `operatingIncome ?? ebit` (ver 2.0). Qualquer termo em falta dá `null`.
double? fcff({required FinPeriod cur, required double taxRate}) {
  final ebit = cur.operatingIncome ?? cur.ebit;
  final da = cur.depreciationAmortization;
  final capex = cur.capexSpent;
  final cwc = cur.changeInWorkingCapital;
  if (ebit == null || da == null || capex == null || cwc == null) return null;
  return ebit * (1 - taxRate) + da - capex + cwc;
}

/// Crescimento explícito por omissão: CAGR de 3 anos da receita (anual.last vs anual[len-4]) limitado a [0; 0,15].
/// Se não houver CAGR calculável, 5 %.
double defaultExplicitGrowth(Financials f) {
  final a = f.annual;
  double? cagr;
  if (a.length >= 4) {
    final end = a.last.revenue;
    final start = a[a.length - 4].revenue;
    if (end != null && start != null && start > 0 && end > 0) {
      cagr = math.pow(end / start, 1 / 3).toDouble() - 1;
    }
  }
  if (cagr == null || !cagr.isFinite) return explicitGrowthFallback;
  return math.min(math.max(cagr, 0), 0.15);
}

/// DCF de N anos com valor terminal de Gordon (desconto de fim de ano).
/// `FCF_i = fcff0 (1+gr)^i`; `PV = Σ FCF_i/(1+WACC)^i`; `TV = FCF_N (1+g)/(WACC−g)`; `equity = PV + TV/(1+WACC)^N − dívida líquida − minoritários − preferenciais`.
/// Devolve `null` se FCFF₀ <= 0, N < 1 ou WACC <= g (o valor terminal não existe).
DcfResult? computeDcf({
  required double fcff0,
  required double growth,
  required double terminalGrowth,
  required double wacc,
  required int years,
  required double? netDebt,
  double minority = 0,
  double preferred = 0,
  required double? shares,
}) {
  if (!fcff0.isFinite ||
      !growth.isFinite ||
      !terminalGrowth.isFinite ||
      !wacc.isFinite) {
    return null;
  }
  if (fcff0 <= 0 || years < 1 || wacc <= terminalGrowth) return null;
  var sumPv = 0.0;
  var fcfN = fcff0;
  for (var i = 1; i <= years; i++) {
    final fcfI = fcff0 * math.pow(1 + growth, i).toDouble();
    sumPv += fcfI / math.pow(1 + wacc, i).toDouble();
    if (i == years) fcfN = fcfI;
  }
  final tv = fcfN * (1 + terminalGrowth) / (wacc - terminalGrowth);
  final pvTv = tv / math.pow(1 + wacc, years).toDouble();
  final equity = netDebt == null
      ? null
      : sumPv + pvTv - netDebt - minority - preferred;
  final perShare = (equity == null || shares == null || shares <= 0)
      ? null
      : equity / shares;
  return DcfResult(
    fcff0: fcff0,
    growth: growth,
    terminalGrowth: terminalGrowth,
    wacc: wacc,
    years: years,
    sumPv: sumPv,
    terminalValue: tv,
    pvTerminal: pvTv,
    equityValue: equity,
    valuePerShare: perShare,
  );
}

/// Margem de segurança = `1 − preço / valor intrínseco`. Nulo se faltar algum valor ou se o valor intrínseco não for positivo.
double? safetyMargin(double? intrinsic, double? price) {
  if (intrinsic == null || price == null || intrinsic <= 0) return null;
  final ratio = safeDiv(price, intrinsic);
  return ratio == null ? null : 1 - ratio;
}

/// DCF inverso: o crescimento explícito `gr` que faz o valor por ação igualar o preço. Bisseção em [−0,5; 1,0]
/// (100 iterações ou intervalo < 1e-7). Nulo se não houver mudança de sinal no intervalo.
double? impliedGrowth({
  required double fcff0,
  required double terminalGrowth,
  required double wacc,
  required int years,
  required double? netDebt,
  double minority = 0,
  double preferred = 0,
  required double? shares,
  required double price,
}) {
  double? valueAt(double gr) => computeDcf(
    fcff0: fcff0,
    growth: gr,
    terminalGrowth: terminalGrowth,
    wacc: wacc,
    years: years,
    netDebt: netDebt,
    minority: minority,
    preferred: preferred,
    shares: shares,
  )?.valuePerShare;

  var lo = -0.5;
  var hi = 1.0;
  final vLo = valueAt(lo);
  final vHi = valueAt(hi);
  if (vLo == null || vHi == null) return null;
  var fLo = vLo - price;
  final fHi = vHi - price;
  if (fLo * fHi > 0) return null;
  var mid = lo;
  for (var i = 0; i < 100; i++) {
    mid = (lo + hi) / 2;
    final vm = valueAt(mid);
    if (vm == null) return null;
    final fm = vm - price;
    if ((hi - lo).abs() < 1e-7) break;
    if (fLo * fm > 0) {
      lo = mid;
      fLo = fm;
    } else {
      hi = mid;
    }
  }
  return mid;
}

/// Matriz 5 × 5 de valor por ação: linhas WACC + {−2; −1; 0; +1; +2} pontos base; colunas g + {−1; −0,5; 0; +0,5; +1} pontos base.
/// Célula com WACC <= g é `null`.
List<List<double?>> sensitivityMatrix({
  required double fcff0,
  required double growth,
  required double wacc,
  required double terminalGrowth,
  required int years,
  required double? netDebt,
  double minority = 0,
  double preferred = 0,
  required double? shares,
}) {
  const dWacc = [-0.02, -0.01, 0.0, 0.01, 0.02];
  const dG = [-0.01, -0.005, 0.0, 0.005, 0.01];
  return [
    for (final dw in dWacc)
      [
        for (final dg in dG)
          computeDcf(
            fcff0: fcff0,
            growth: growth,
            terminalGrowth: terminalGrowth + dg,
            wacc: wacc + dw,
            years: years,
            netDebt: netDebt,
            minority: minority,
            preferred: preferred,
            shares: shares,
          )?.valuePerShare,
      ],
  ];
}

/// Cenários de crescimento explícito (mesmos WACC e g): `pessimistic` gr × 0,5, `base` gr, `optimistic` gr × 1,5.
Map<String, double?> scenarios({
  required double fcff0,
  required double growth,
  required double terminalGrowth,
  required double wacc,
  required int years,
  required double? netDebt,
  double minority = 0,
  double preferred = 0,
  required double? shares,
}) {
  double? valueWith(double gr) => computeDcf(
    fcff0: fcff0,
    growth: gr,
    terminalGrowth: terminalGrowth,
    wacc: wacc,
    years: years,
    netDebt: netDebt,
    minority: minority,
    preferred: preferred,
    shares: shares,
  )?.valuePerShare;
  return {
    'pessimistic': valueWith(growth * 0.5),
    'base': valueWith(growth),
    'optimistic': valueWith(growth * 1.5),
  };
}

/// Período anterior (um ano antes) para as médias de `cur` (2.0). Se `cur` é o TTM, procura um trimestre (ou, se
/// não houver, um anual) cujo fecho esteja entre 320 e 410 dias antes de `cur.end`; senão `null`.
FinPeriod? prevPeriodFor(Financials f, FinPeriod cur) {
  if (identical(cur, f.ttm)) {
    bool inWindow(FinPeriod p) {
      final d = cur.end.difference(p.end).inDays;
      return d >= 320 && d <= 410;
    }

    var pool = f.quarterly.where(inWindow).toList();
    if (pool.isEmpty) pool = f.annual.where(inWindow).toList();
    if (pool.isEmpty) return null;
    pool.sort(
      (a, b) => (cur.end.difference(a.end).inDays - 365).abs().compareTo(
        (cur.end.difference(b.end).inDays - 365).abs(),
      ),
    );
    return pool.first;
  }
  if (cur.annual) {
    final i = f.annual.indexWhere((p) => p.end == cur.end);
    return i > 0 ? f.annual[i - 1] : null;
  }
  return null;
}

/// Métricas do DCF de uma empresa com as premissas dadas (ou as por omissão). Base `f.latest` (TTM se existir), 2.0 e 2.8.
/// Cada chave devolvida tem uma ficha em `dcfInfo` (ver dcf_info.dart).
List<Metric> dcfMetrics(
  Financials f,
  MarketSnapshot m, {
  DcfAssumptions? assumptions,
}) {
  final a = assumptions ?? const DcfAssumptions();
  final cur = f.latest;
  final prev = cur == null ? null : prevPeriodFor(f, cur);

  final t = a.taxRate ?? (cur == null ? taxFallback : effectiveTaxRate(cur));
  final base = cur == null ? null : fcff(cur: cur, taxRate: t);
  final beta = a.beta ?? m.beta ?? betaFallback;
  final ke = capmKe(rf: a.riskFreeRate, beta: beta, mrp: a.marketRiskPremium);
  final kd = cur == null ? kdFallback : costOfDebt(cur, prev);
  final wacc = waccOf(
    marketCap: m.marketCap,
    totalDebt: cur?.totalDebt,
    ke: ke,
    kd: kd,
    t: t,
  );

  // Dívida líquida = dívida total − caixa (se faltar algum, fica null: sem valor por ação).
  final debt = cur?.totalDebt;
  final cash = cur?.cash;
  final netDebt = (debt == null || cash == null) ? null : debt - cash;
  final minority = cur?.minorityInterest ?? 0;
  final preferred = cur?.preferredStock ?? 0;
  final shares = m.sharesOutstanding ?? cur?.sharesOutstanding;
  final gr = a.explicitGrowth ?? defaultExplicitGrowth(f);
  final g = a.terminalGrowth;

  final dcf = (base == null || wacc == null)
      ? null
      : computeDcf(
          fcff0: base,
          growth: gr,
          terminalGrowth: g,
          wacc: wacc,
          years: a.years,
          netDebt: netDebt,
          minority: minority,
          preferred: preferred,
          shares: shares,
        );
  final perShare = dcf?.valuePerShare;
  final price = m.price;

  final implied = (base == null || wacc == null || price == null)
      ? null
      : impliedGrowth(
          fcff0: base,
          terminalGrowth: g,
          wacc: wacc,
          years: a.years,
          netDebt: netDebt,
          minority: minority,
          preferred: preferred,
          shares: shares,
          price: price,
        );

  final sc = (base == null || wacc == null)
      ? const <String, double?>{}
      : scenarios(
          fcff0: base,
          growth: gr,
          terminalGrowth: g,
          wacc: wacc,
          years: a.years,
          netDebt: netDebt,
          minority: minority,
          preferred: preferred,
          shares: shares,
        );

  return [
    Metric('fcff', base, MetricKind.money),
    Metric('ke', ke, MetricKind.percent),
    Metric('wacc', wacc, MetricKind.percent),
    Metric('dcf_value_per_share', perShare, MetricKind.perShare),
    Metric(
      'dcf_margin_of_safety',
      safetyMargin(perShare, price),
      MetricKind.percent,
    ),
    Metric('dcf_implied_growth', implied, MetricKind.percent),
    Metric('dcf_scenario_pessimistic', sc['pessimistic'], MetricKind.perShare),
    Metric('dcf_scenario_base', sc['base'], MetricKind.perShare),
    Metric('dcf_scenario_optimistic', sc['optimistic'], MetricKind.perShare),
  ];
}
