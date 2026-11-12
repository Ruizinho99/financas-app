/// Métricas de mercado e de risco (secção 13 da lista do utilizador) e de carteira.
///
/// Funções PURAS: recebem listas simples (datas e fechos em ordem cronológica, sem pontos `null`) e devolvem
/// `null` quando faltam dados ou a divisão é por zero. Séries de preço = `close` do gráfico do Yahoo
/// (ajustado a splits, não a dividendos). Não dependem da camada de dados; só do contrato `financials.dart`.
library;

import 'dart:math' as math;

import 'financials.dart';

/// Sessões de bolsa por ano (anualização de volatilidade, Sharpe e Sortino).
const int kSessoesAno = 252;

/// Taxa sem risco por omissão: 4 % ao ano (a mesma do CAPM da app).
const double kRiskFreeDefault = 0.04;

/// Data de calendário local da bolsa de um timestamp Unix: `timestamp + gmtoffset`, convertido em UTC na data.
/// Usa-se para alinhar séries de bolsas diferentes (NVD.DE × ^GSPC nunca têm o mesmo timestamp).
DateTime marketDate(int unixSeconds, int gmtOffsetSeconds) {
  final d = DateTime.fromMillisecondsSinceEpoch(
    (unixSeconds + gmtOffsetSeconds) * 1000,
    isUtc: true,
  );
  return DateTime.utc(d.year, d.month, d.day);
}

DateTime _dia(DateTime d) => DateTime.utc(d.year, d.month, d.day);

/// Subtrai meses à data; o dia fica limitado ao último dia do mês de destino (31 mar − 1 mês = 28/29 fev).
DateTime _menosMeses(DateTime d, int meses) {
  final total = d.year * 12 + (d.month - 1) - meses;
  final ano = total ~/ 12;
  final mes = total % 12 + 1;
  final ultimoDia = DateTime.utc(ano, mes + 1, 0).day;
  return DateTime.utc(ano, mes, math.min(d.day, ultimoDia));
}

double? _menosUm(double? x) => x == null ? null : x - 1;

double _media(List<double> xs) => xs.fold(0.0, (a, b) => a + b) / xs.length;

/// Covariância amostral (divisão por n − 1). Nulo se houver menos de 2 pontos.
double? _covAmostral(List<double> xs, List<double> ys) {
  final n = xs.length;
  if (n < 2 || ys.length != n) return null;
  final mx = _media(xs), my = _media(ys);
  var s = 0.0;
  for (var i = 0; i < n; i++) {
    s += (xs[i] - mx) * (ys[i] - my);
  }
  return s / (n - 1);
}

/// Desvio-padrão amostral (n − 1).
double? _desvioAmostral(List<double> xs) {
  final c = _covAmostral(xs, xs);
  return c == null ? null : math.sqrt(c);
}

/// Correlação de Pearson (com covariâncias e desvios amostrais, o fator n − 1 cancela-se).
double? _pearson(List<double> xs, List<double> ys) {
  final c = _covAmostral(xs, ys);
  final sx = _desvioAmostral(xs), sy = _desvioAmostral(ys);
  if (c == null || sx == null || sy == null || sx == 0 || sy == 0) return null;
  return c / (sx * sy);
}

/// Percentil com interpolação linear (= numpy `linear` = Excel `PERCENTIL.INC`): `pos = q·(n−1)`.
double? _percentilLinear(List<double> xs, double q) {
  if (xs.isEmpty) return null;
  final ys = [...xs]..sort();
  final pos = q * (ys.length - 1);
  final lo = pos.floor();
  final hi = math.min(lo + 1, ys.length - 1);
  return ys[lo] + (ys[hi] - ys[lo]) * (pos - lo);
}

/// Retornos simples diários `r_i = P_i / P_{i−1} − 1`.
List<double> retornosSimples(List<double> precos) => [
  for (var i = 1; i < precos.length; i++) precos[i] / precos[i - 1] - 1,
];

/// Retorno desde a última data de referência: `P_último / P_ref − 1`, com `P_ref` o último fecho com data ≤ referência.
/// Nulo se não houver nenhum fecho até essa data.
double? _retornoDesde(
  List<DateTime> datas,
  List<double> fechos,
  DateTime referencia,
) {
  int? idx;
  for (var i = 0; i < datas.length; i++) {
    if (_dia(datas[i]).isAfter(referencia)) break;
    idx = i;
  }
  if (idx == null) return null;
  return _menosUm(safeDiv(fechos.last, fechos[idx]));
}

/// RSI(14) de Wilder sobre VARIAÇÕES de preço (não retornos). Menos de 15 preços → nulo.
double? _rsi14(List<double> p) {
  if (p.length < 15) return null;
  final ganhos = <double>[], perdas = <double>[];
  for (var i = 1; i < p.length; i++) {
    final c = p[i] - p[i - 1];
    ganhos.add(math.max(c, 0));
    perdas.add(math.max(-c, 0));
  }
  // Primeira média: média simples dos 14 primeiros ganhos/perdas; depois, alisamento de Wilder.
  var ag = _media(ganhos.sublist(0, 14));
  var al = _media(perdas.sublist(0, 14));
  for (var k = 14; k < ganhos.length; k++) {
    ag = (ag * 13 + ganhos[k]) / 14;
    al = (al * 13 + perdas[k]) / 14;
  }
  return al == 0 ? 100.0 : 100 - 100 / (1 + ag / al);
}

/// Drawdown máximo: mínimo de `P_i / max(P_0..P_i) − 1` (≤ 0).
double? _drawdownMaximo(List<double> p) {
  if (p.isEmpty) return null;
  var pico = p[0];
  var mdd = 0.0;
  for (final x in p) {
    if (x > pico) pico = x;
    final dd = x / pico - 1;
    if (dd < mdd) mdd = dd;
  }
  return mdd;
}

/// Alinha as duas séries pela data de calendário e devolve os retornos entre datas comuns consecutivas.
/// Nulo se houver menos de 2 retornos.
({List<double> ativo, List<double> mercado})? _retornosAlinhados(
  List<DateTime> datas,
  List<double> fechos,
  List<DateTime> datasIndice,
  List<double> fechosIndice,
) {
  final mapa = <DateTime, double>{};
  for (var i = 0; i < datasIndice.length; i++) {
    mapa[_dia(datasIndice[i])] = fechosIndice[i];
  }
  final precosAtivo = <double>[], precosMercado = <double>[];
  for (var i = 0; i < datas.length; i++) {
    final m = mapa[_dia(datas[i])];
    if (m == null) continue;
    precosAtivo.add(fechos[i]);
    precosMercado.add(m);
  }
  if (precosAtivo.length < 3) return null;
  return (
    ativo: retornosSimples(precosAtivo),
    mercado: retornosSimples(precosMercado),
  );
}

/// Métricas de mercado e de risco a partir do histórico diário (datas e fechos em ordem cronológica, sem `null`).
///
/// - [benchDates]/[benchCloses]: índice de referência (por omissão a app passa o ^GSPC) para beta e correlação.
///   As datas são alinhadas pelo dia de calendário da bolsa (usar [marketDate]).
/// - [volumes]: volumes diários, só para o volume médio de 63 sessões quando o snapshot não o tem.
/// - [snapshot]: se tiver o máximo e mínimo de 52 semanas (moeda de reporte), usa-os com o preço do snapshot
///   (par coerente). Caso contrário usa os fechos do gráfico e o último fecho.
/// - [riskFree]: taxa sem risco anual para Sharpe e Sortino.
List<Metric> marketRiskMetrics(
  List<DateTime> dates,
  List<double> closes, {
  List<DateTime>? benchDates,
  List<double>? benchCloses,
  List<double>? volumes,
  MarketSnapshot? snapshot,
  double riskFree = kRiskFreeDefault,
}) {
  if (dates.length != closes.length) {
    throw ArgumentError('dates e closes com tamanhos diferentes');
  }
  final vazio = dates.isEmpty;
  final ultima = vazio ? null : _dia(dates.last);
  final r = retornosSimples(closes);

  // Retornos por janela (datas de referência: dias, semanas, meses, anos; YTD = último fecho do ano civil anterior).
  double? janela(DateTime? Function(DateTime u) ref) {
    if (ultima == null) return null;
    final d = ref(ultima);
    return d == null ? null : _retornoDesde(dates, closes, d);
  }

  final retorno1d = janela((u) => u.subtract(const Duration(days: 1)));
  final retorno1s = janela((u) => u.subtract(const Duration(days: 7)));
  final retorno1m = janela((u) => _menosMeses(u, 1));
  final retorno3m = janela((u) => _menosMeses(u, 3));
  final retorno6m = janela((u) => _menosMeses(u, 6));
  final retornoYtd = janela((u) => DateTime.utc(u.year - 1, 12, 31));
  final retorno1a = janela((u) => _menosMeses(u, 12));
  final retorno3a = janela((u) => _menosMeses(u, 36));
  final retorno5a = janela((u) => _menosMeses(u, 60));
  final retornoTotal = vazio
      ? null
      : _menosUm(safeDiv(closes.last, closes.first));

  // 52 semanas: snapshot (par coerente) ou fechos do gráfico com data ≥ última data − 365 dias.
  double? maximo52, minimo52, distancia52;
  if (snapshot != null &&
      snapshot.fiftyTwoWeekHigh != null &&
      snapshot.fiftyTwoWeekLow != null) {
    maximo52 = snapshot.fiftyTwoWeekHigh;
    minimo52 = snapshot.fiftyTwoWeekLow;
    distancia52 = _menosUm(safeDiv(snapshot.price, maximo52));
  } else if (!vazio) {
    final inicio = DateTime.utc(ultima!.year, ultima.month, ultima.day - 365);
    final janelaFechos = [
      for (var i = 0; i < dates.length; i++)
        if (!_dia(dates[i]).isBefore(inicio)) closes[i],
    ];
    if (janelaFechos.isNotEmpty) {
      maximo52 = janelaFechos.reduce(math.max);
      minimo52 = janelaFechos.reduce(math.min);
      distancia52 = _menosUm(safeDiv(closes.last, maximo52));
    }
  }

  // Volume médio: o do snapshot (média de 3 meses da fonte) ou a média das últimas 63 sessões.
  double? volumeMedio = snapshot?.averageVolume;
  if (volumeMedio == null && volumes != null && volumes.length >= 63) {
    volumeMedio = _media(volumes.sublist(volumes.length - 63));
  }

  // Volatilidade, Sharpe e Sortino (retornos diários, rf anual).
  final desvio = r.length < 2 ? null : _desvioAmostral(r);
  final volatilidade = desvio == null ? null : desvio * math.sqrt(kSessoesAno);
  final mediaAnual = r.isEmpty ? null : _media(r) * kSessoesAno;
  final sharpe = (mediaAnual == null || desvio == null || desvio == 0)
      ? null
      : (mediaAnual - riskFree) / (desvio * math.sqrt(kSessoesAno));
  // Sortino: DD = sqrt(Σ_todos min(r_i, 0)² / N), MAR = 0 e N = total de retornos.
  double? sortino;
  if (mediaAnual != null) {
    final somaNeg = r.fold(0.0, (a, x) {
      final neg = math.min(x, 0.0);
      return a + neg * neg;
    });
    final dd = math.sqrt(somaNeg / r.length);
    if (dd > 0) {
      sortino = (mediaAnual - riskFree) / (dd * math.sqrt(kSessoesAno));
    }
  }

  // VaR histórico 95 % a 1 dia: percentil 5 dos retornos (negativo = perda).
  final var95 = _percentilLinear(r, 0.05);

  // Beta e correlação face ao índice, com retornos entre datas comuns consecutivas.
  double? beta, correlacao;
  if (benchDates != null && benchCloses != null && !vazio) {
    final alinhados = _retornosAlinhados(
      dates,
      closes,
      benchDates,
      benchCloses,
    );
    if (alinhados != null) {
      final covMercado = _covAmostral(alinhados.mercado, alinhados.mercado);
      final covCruzada = _covAmostral(alinhados.ativo, alinhados.mercado);
      if (covMercado != null && covCruzada != null && covMercado > 0) {
        beta = covCruzada / covMercado;
      }
      correlacao = _pearson(alinhados.ativo, alinhados.mercado);
    }
  }

  return [
    Metric('retorno_1d', retorno1d, MetricKind.percent),
    Metric('retorno_1s', retorno1s, MetricKind.percent),
    Metric('retorno_1m', retorno1m, MetricKind.percent),
    Metric('retorno_3m', retorno3m, MetricKind.percent),
    Metric('retorno_6m', retorno6m, MetricKind.percent),
    Metric('retorno_ytd', retornoYtd, MetricKind.percent),
    Metric('retorno_1a', retorno1a, MetricKind.percent),
    Metric('retorno_3a', retorno3a, MetricKind.percent),
    Metric('retorno_5a', retorno5a, MetricKind.percent),
    Metric('retorno_total_periodo', retornoTotal, MetricKind.percent),
    Metric('maximo_52s', maximo52, MetricKind.money),
    Metric('minimo_52s', minimo52, MetricKind.money),
    Metric('distancia_maximo_52s', distancia52, MetricKind.percent),
    Metric('volume_medio', volumeMedio, MetricKind.score),
    Metric('sma50', _sma(closes, 50), MetricKind.money),
    Metric('sma200', _sma(closes, 200), MetricKind.money),
    Metric('rsi14', _rsi14(closes), MetricKind.score),
    Metric('volatilidade_anualizada', volatilidade, MetricKind.percent),
    Metric('drawdown_maximo', _drawdownMaximo(closes), MetricKind.percent),
    Metric('sharpe', sharpe, MetricKind.ratio),
    Metric('sortino', sortino, MetricKind.ratio),
    Metric('var95_diario', var95, MetricKind.percent),
    Metric('beta_sp500', beta, MetricKind.ratio),
    Metric('correlacao_sp500', correlacao, MetricKind.ratio),
  ];
}

/// Média dos últimos [n] fechos (SMA). Menos de n pontos → nulo.
double? _sma(List<double> closes, int n) {
  if (closes.length < n) return null;
  return _media(closes.sublist(closes.length - n));
}

/// Métricas que vêm do snapshot de mercado (melhor esforço) e as que a fonte gratuita não dá.
List<Metric> snapshotRiskMetrics(MarketSnapshot m) => [
  Metric('short_percent_float', m.shortPercentOfFloat, MetricKind.percent),
  Metric('insiders_percent_held', m.insidersPercentHeld, MetricKind.percent),
  // O contrato não tem bid/ask: não disponível com dados gratuitos.
  const Metric('spread_bid_ask', null, MetricKind.percent),
];

/// XIRR: taxa anual `r` tal que `Σ c_i / (1+r)^((d_i − d_0)/365) = 0` (base 365, como o Excel).
/// `d_0` = data do primeiro fluxo. Bisseção em [−0,9999; 10], 200 iterações. Exige um fluxo negativo e um positivo;
/// se o VPL não mudar de sinal no intervalo, devolve nulo.
double? xirr(List<({DateTime date, double amount})> flows) {
  if (flows.isEmpty) return null;
  if (!flows.any((f) => f.amount < 0) || !flows.any((f) => f.amount > 0)) {
    return null;
  }
  final d0 = flows
      .map((f) => _dia(f.date))
      .reduce((a, b) => a.isBefore(b) ? a : b);
  double vpl(double r) {
    var s = 0.0;
    for (final f in flows) {
      final anos = _dia(f.date).difference(d0).inDays / 365.0;
      s += f.amount / math.pow(1 + r, anos).toDouble();
    }
    return s;
  }

  var lo = -0.9999, hi = 10.0;
  var fLo = vpl(lo);
  final fHi = vpl(hi);
  if (!fLo.isFinite || !fHi.isFinite || (fLo > 0) == (fHi > 0)) return null;
  for (var k = 0; k < 200; k++) {
    final mid = (lo + hi) / 2;
    final fMid = vpl(mid);
    if ((fMid > 0) == (fLo > 0)) {
      lo = mid;
      fLo = fMid;
    } else {
      hi = mid;
    }
  }
  return (lo + hi) / 2;
}

/// TWR (retorno ponderado no tempo). [pontos]: o primeiro é `(valueBefore ignorado, cashFlow = valor inicial)`;
/// cada fluxo externo seguinte é `(valueBefore = V_i⁻ valor imediatamente antes do fluxo, cashFlow = CF_i)`;
/// o último é `(valueBefore = valor final, cashFlow ignorado)`.
/// `r_i = V_i⁻ / (V_{i−1}⁻ + CF_{i−1}) − 1` com `V_0⁻ = 0`; `TWR = Π(1 + r_i) − 1`. Nulo se um denominador for 0.
/// Exemplo: 1000 → 1100, entra 500, → 1500: `[(0, 1000), (1100, 500), (1500, 0)]` dá 0,03125.
double? twr(List<({double valueBefore, double cashFlow})> pontos) {
  if (pontos.length < 2) return null;
  var acumulado = 1.0;
  for (var i = 1; i < pontos.length; i++) {
    final vAnteriorFim = i - 1 == 0 ? 0.0 : pontos[i - 1].valueBefore;
    final inicioSub = vAnteriorFim + pontos[i - 1].cashFlow;
    final ri = safeDiv(pontos[i].valueBefore, inicioSub);
    if (ri == null) return null;
    acumulado *= ri;
  }
  return acumulado - 1;
}

/// Pesos normalizados para soma 1 (valor de mercado de cada posição). Nulo se a soma não for positiva.
List<double>? _pesosNormalizados(List<double> pesos) {
  if (pesos.isEmpty) return null;
  final total = pesos.fold(0.0, (a, b) => a + b);
  if (!total.isFinite || total <= 0) return null;
  return [for (final w in pesos) w / total];
}

/// HHI da carteira: Σ peso², com pesos normalizados para soma 1. Varia entre 1/N e 1.
double? hhi(List<double> weights) {
  final p = _pesosNormalizados(weights);
  if (p == null) return null;
  return p.fold<double>(0.0, (a, w) => a + w * w);
}

/// Concentração top-N: soma dos N maiores pesos (normalizados para soma 1). Nulo se N < 1.
double? topNConcentration(List<double> weights, int n) {
  if (n < 1) return null;
  final p = _pesosNormalizados(weights);
  if (p == null) return null;
  final ordenados = [...p]..sort((a, b) => b.compareTo(a));
  return ordenados.take(n).fold<double>(0.0, (a, w) => a + w);
}

/// Correlação média de todos os pares de posições. Cada série é um mapa data → retorno diário; os pares usam
/// as datas comuns. Se algum par não tiver pelo menos 3 datas comuns ou variância nula, devolve nulo.
double? averageCorrelation(List<Map<DateTime, double>> returnsByDate) {
  if (returnsByDate.length < 2) return null;
  var soma = 0.0;
  var pares = 0;
  for (var i = 0; i < returnsByDate.length; i++) {
    for (var j = i + 1; j < returnsByDate.length; j++) {
      final a = returnsByDate[i], b = returnsByDate[j];
      final comuns = a.keys.where(b.containsKey).toList()
        ..sort((x, y) => x.compareTo(y));
      if (comuns.length < 3) return null;
      final r = _pearson(
        [for (final d in comuns) a[d]!],
        [for (final d in comuns) b[d]!],
      );
      if (r == null) return null;
      soma += r;
      pares++;
    }
  }
  return soma / pares;
}
