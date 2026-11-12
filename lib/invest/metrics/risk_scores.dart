/// Scores de risco e qualidade: Altman Z (original e Z″), Piotroski F-Score e Beneish M-Score.
/// Funções puras (sem rede, sem Flutter). Especificação: docs/metricas-fundamentais.md, secções 2.0, 2.5, 2.6 e 2.7.
library;

import 'financials.dart';

/// Modelo de Altman que a interface destaca para um setor.
enum AltmanModel { original, doublePrime, notApplicable }

/// Zona de risco de Altman.
enum AltmanZone { safe, grey, distress, notApplicable }

/// Setores em que o Altman não se aplica (financeiras e imobiliário).
const _altmanNaoAplicavel = {'Financial Services', 'Real Estate'};

/// Setores em que se destaca o Z original (industriais e não financeiros cíclicos/defensivos).
const _altmanOriginal = {
  'Industrials',
  'Basic Materials',
  'Energy',
  'Consumer Cyclical',
  'Consumer Defensive',
};

/// Mapeamento setor → modelo (setor do Yahoo). Qualquer outro setor, incluindo vazio, usa o Z″.
AltmanModel altmanModelForSector(String sector) {
  if (_altmanNaoAplicavel.contains(sector)) return AltmanModel.notApplicable;
  if (_altmanOriginal.contains(sector)) return AltmanModel.original;
  return AltmanModel.doublePrime;
}

/// Zona de um valor de Altman. Original: > 2,99 segura; 1,81 a 2,99 cinzenta; < 1,81 risco.
/// Z″ (sem constante): > 2,6 segura; 1,1 a 2,6 cinzenta; < 1,1 risco. Nulo ou "não aplicável" → `notApplicable`.
AltmanZone altmanZone(double? z, AltmanModel model) {
  if (z == null || model == AltmanModel.notApplicable) {
    return AltmanZone.notApplicable;
  }
  final (seg, cin) = model == AltmanModel.original ? (2.99, 1.81) : (2.6, 1.1);
  if (z > seg) return AltmanZone.safe;
  if (z >= cin) return AltmanZone.grey;
  return AltmanZone.distress;
}

// ---------------------------------------------------------------------------
// Auxiliares

/// Soma ponderada; nulo se algum termo for nulo (nada de `?? 0`).
double? _comb(List<(double?, double)> termos) {
  var s = 0.0;
  for (final (x, w) in termos) {
    if (x == null) return null;
    s += w * x;
  }
  return s;
}

double? _add(double? a, double? b) => a == null || b == null ? null : a + b;
double? _sub(double? a, double? b) => a == null || b == null ? null : a - b;
double? _avg2(double? a, double? b) =>
    a == null || b == null ? null : (a + b) / 2;
double? _umMenos(double? x) => x == null ? null : 1 - x;

/// Período anual `k` anos antes do último (0 = o último), ou nulo.
FinPeriod? _anual(Financials f, int k) {
  final a = f.annual;
  return a.length > k ? a[a.length - 1 - k] : null;
}

bool? _gt(double? a, double? b) => a == null || b == null ? null : a > b;
bool? _lt(double? a, double? b) => a == null || b == null ? null : a < b;
bool? _le(double? a, double? b) => a == null || b == null ? null : a <= b;

/// Teste booleano como métrica 0/1 (nulo se o teste não foi avaliado).
double? _bit(bool? b) => b == null ? null : (b ? 1.0 : 0.0);

// ---------------------------------------------------------------------------
// Altman

/// Altman Z original e Z″ (SEM constante), com as capitalizações de `m.marketCap` (moeda de reporte).
///
/// `cur` é o período de balanço e de fluxos; por omissão `f.latest` (TTM se existir, senão o último anual).
/// Setores financeiros e imobiliário devolvem ambos `null` (Altman não se aplica).
///
/// Z  = 1,2·X1 + 1,4·X2 + 3,3·X3 + 0,6·X4 + 1,0·X5, com X4 = capitalização / passivo total.
/// Z″ = 6,56·X1 + 3,26·X2 + 6,72·X3 + 1,05·X4b, com X4b = capitais próprios contabilísticos / passivo total.
/// Em ambos: X1 = fundo de maneio / ativo; X2 = resultados retidos / ativo; X3 = EBIT / ativo; X5 = receita / ativo.
List<Metric> altmanMetrics(Financials f, MarketSnapshot m, {FinPeriod? cur}) {
  final p = cur ?? f.latest;
  if (p == null ||
      altmanModelForSector(m.sector) == AltmanModel.notApplicable) {
    return const [
      Metric('altman_z', null, MetricKind.score),
      Metric('altman_z2', null, MetricKind.score),
    ];
  }
  final ta = p.totalAssets;
  final tl = p.totalLiabilities;
  final x1 = safeDiv(_sub(p.currentAssets, p.currentLiabilities), ta);
  final x2 = safeDiv(p.retainedEarnings, ta);
  // EBIT = operatingIncome ?? ebit (getter do contrato: ebitOrOperating).
  final x3 = safeDiv(p.ebitOrOperating, ta);
  final x4 = safeDiv(m.marketCap, tl);
  final x4b = safeDiv(p.equity, tl);
  final x5 = safeDiv(p.revenue, ta);

  final z = _comb([(x1, 1.2), (x2, 1.4), (x3, 3.3), (x4, 0.6), (x5, 1.0)]);
  final z2 = _comb([(x1, 6.56), (x2, 3.26), (x3, 6.72), (x4b, 1.05)]);
  return [
    Metric('altman_z', z, MetricKind.score),
    Metric('altman_z2', z2, MetricKind.score),
  ];
}

// ---------------------------------------------------------------------------
// Piotroski

/// Piotroski F-Score (Piotroski 2000) com os 9 testes como métricas 0/1 (nulo se não avaliado).
///
/// Usa sempre os anuais: t = último, t-1 e t-2. ROA, CFO, accruals e rotação usam o ativo do INÍCIO do ano
/// (ativo de t-1 para o ano t). A alavancagem usa a dívida de LP sobre o ativo MÉDIO.
/// Um teste com dado em falta não é avaliado: não conta nem penaliza. `piotroski_f` = nº de testes a 1;
/// `piotroski_n_avaliados` = nº de testes avaliados (é "f de n" na interface).
List<Metric> piotroskiMetrics(Financials f) {
  final t = _anual(f, 0);
  final t1 = _anual(f, 1);
  final t2 = _anual(f, 2);

  // ROA(x) = resultado líquido(x) / ativo(x−1)
  double? roa(FinPeriod? x, FinPeriod? antes) => x == null || antes == null
      ? null
      : safeDiv(x.netIncome, antes.totalAssets);
  // LEV(x) = dívida LP(x) / ativo médio(x, x−1)
  double? lev(FinPeriod? x, FinPeriod? antes) => x == null || antes == null
      ? null
      : safeDiv(x.longTermDebt, _avg2(x.totalAssets, antes.totalAssets));
  // CR(x) = ativo corrente / passivo corrente
  double? cr(FinPeriod? x) =>
      x == null ? null : safeDiv(x.currentAssets, x.currentLiabilities);
  // GM(x) = resultado bruto / receita
  double? gm(FinPeriod? x) =>
      x == null ? null : safeDiv(x.grossProfit, x.revenue);
  // TURN(x) = receita(x) / ativo(x−1)
  double? turn(FinPeriod? x, FinPeriod? antes) =>
      x == null || antes == null ? null : safeDiv(x.revenue, antes.totalAssets);

  final testes = <bool?>[
    _gt(roa(t, t1), 0), // 1 ROA > 0
    _gt(t?.operatingCashFlow, 0), // 2 CFO > 0
    _gt(roa(t, t1), roa(t1, t2)), // 3 ROA(t) > ROA(t−1)
    _gt(
      t?.operatingCashFlow,
      t?.netIncome,
    ), // 4 CFO > resultado líquido (accruals negativos)
    _lt(lev(t, t1), lev(t1, t2)), // 5 alavancagem desce
    _gt(cr(t), cr(t1)), // 6 liquidez sobe
    _le(
      t?.sharesOutstanding,
      t1?.sharesOutstanding,
    ), // 7 sem diluição (aproximação)
    _gt(gm(t), gm(t1)), // 8 margem bruta sobe
    _gt(turn(t, t1), turn(t1, t2)), // 9 rotação do ativo sobe
  ];

  final avaliados = testes.where((x) => x != null).toList();
  final n = avaliados.length;
  final f0 = n == 0 ? null : avaliados.where((x) => x!).length.toDouble();

  const chaves = [
    'piotroski_roa',
    'piotroski_cfo',
    'piotroski_d_roa',
    'piotroski_accruals',
    'piotroski_d_leverage',
    'piotroski_d_current',
    'piotroski_no_dilution',
    'piotroski_d_margin',
    'piotroski_d_turnover',
  ];
  return [
    for (var i = 0; i < 9; i++)
      Metric(chaves[i], _bit(testes[i]), MetricKind.score),
    Metric('piotroski_f', f0, MetricKind.score),
    Metric('piotroski_n_avaliados', n.toDouble(), MetricKind.score),
  ];
}

// ---------------------------------------------------------------------------
// Beneish

/// Limiar de alerta do M-Score (Parte 1; Beneish, Lee e Nichols 2013).
const beneishLimiarAlerta = -1.78;

/// Beneish M-Score (modelo de 8 variáveis) com os 8 índices, o M e o sinal de alerta (1 se M > −1,78).
///
/// Usa os anuais t e t−1 com saldos de fecho. Se faltar qualquer índice, `M` e o alerta são `null`
/// (o modelo precisa dos 8; não há `?? 0`). Aproximações: DEPI com D&A (e não depreciação) e TATA
/// pela versão de fluxos de caixa (Beneish, Lee e Nichols 2013).
List<Metric> beneishMetrics(Financials f) {
  final t = _anual(f, 0);
  final p = _anual(f, 1);

  double? gm(FinPeriod x) => safeDiv(x.grossProfit, x.revenue);
  // AQI: 1 − (ativo corrente + imobilizado líquido) / ativo total
  double? naoAmortizavel(FinPeriod x) =>
      _umMenos(safeDiv(_add(x.currentAssets, x.netPpe), x.totalAssets));
  // DEPI: depreciação / (depreciação + imobilizado líquido)
  double? taxaDep(FinPeriod x) => safeDiv(
    x.depreciationAmortization,
    _add(x.depreciationAmortization, x.netPpe),
  );
  // LVGI: (passivo corrente + dívida LP) / ativo total
  double? alavanca(FinPeriod x) =>
      safeDiv(_add(x.currentLiabilities, x.longTermDebt), x.totalAssets);

  double? dsri, gmi, aqi, sgi, depi, sgai, lvgi, tata;
  if (t != null && p != null) {
    dsri = safeDiv(
      safeDiv(t.receivables, t.revenue),
      safeDiv(p.receivables, p.revenue),
    );
    gmi = safeDiv(gm(p), gm(t));
    aqi = safeDiv(naoAmortizavel(t), naoAmortizavel(p));
    sgi = safeDiv(t.revenue, p.revenue);
    depi = safeDiv(taxaDep(p), taxaDep(t));
    sgai = safeDiv(
      safeDiv(t.sellingGeneralAdmin, t.revenue),
      safeDiv(p.sellingGeneralAdmin, p.revenue),
    );
    lvgi = safeDiv(alavanca(t), alavanca(p));
    tata = safeDiv(_sub(t.netIncome, t.operatingCashFlow), t.totalAssets);
  }

  // M = −4,84 + 0,920·DSRI + 0,528·GMI + 0,404·AQI + 0,892·SGI + 0,115·DEPI − 0,172·SGAI + 4,679·TATA − 0,327·LVGI
  final m = _comb([
    (1.0, -4.84),
    (dsri, 0.920),
    (gmi, 0.528),
    (aqi, 0.404),
    (sgi, 0.892),
    (depi, 0.115),
    (sgai, -0.172),
    (tata, 4.679),
    (lvgi, -0.327),
  ]);
  final alerta = m == null ? null : (m > beneishLimiarAlerta ? 1.0 : 0.0);

  return [
    Metric('beneish_dsri', dsri, MetricKind.ratio),
    Metric('beneish_gmi', gmi, MetricKind.ratio),
    Metric('beneish_aqi', aqi, MetricKind.ratio),
    Metric('beneish_sgi', sgi, MetricKind.ratio),
    Metric('beneish_depi', depi, MetricKind.ratio),
    Metric('beneish_sgai', sgai, MetricKind.ratio),
    Metric('beneish_tata', tata, MetricKind.ratio),
    Metric('beneish_lvgi', lvgi, MetricKind.ratio),
    Metric('beneish_m', m, MetricKind.score),
    Metric('beneish_alert', alerta, MetricKind.score),
  ];
}
