import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:financas/invest/metrics/financials.dart';
import 'package:financas/invest/metrics/market_risk.dart';
import 'package:financas/invest/metrics/market_risk_info.dart';
import 'package:financas/invest/metrics/metric_info.dart';
import 'package:flutter_test/flutter_test.dart';

/// Resultado de um `chart` gravado do Yahoo (test/fixtures/yahoo/).
Map<String, dynamic> _chart(String ficheiro) {
  final j = jsonDecode(
    File('test/fixtures/yahoo/$ficheiro').readAsStringSync(),
  ) as Map<String, dynamic>;
  return ((j['chart'] as Map)['result'] as List).first as Map<String, dynamic>;
}

/// Datas (dia de calendário da bolsa), fechos e volumes de um gráfico, sem os pontos com `close == null`.
({List<DateTime> datas, List<double> fechos, List<double> volumes}) _serie(
  String ficheiro,
) {
  final c = _chart(ficheiro);
  final off = ((c['meta'] as Map)['gmtoffset'] as num).toInt();
  final ts = (c['timestamp'] as List).cast<num>();
  final q = ((c['indicators'] as Map)['quote'] as List).first as Map;
  final closes = (q['close'] as List).cast<num?>();
  final vols = (q['volume'] as List).cast<num?>();
  final datas = <DateTime>[], fechos = <double>[], volumes = <double>[];
  for (var i = 0; i < ts.length; i++) {
    final f = closes[i];
    if (f == null) continue;
    datas.add(marketDate(ts[i].toInt(), off));
    fechos.add(f.toDouble());
    volumes.add((vols[i] ?? 0).toDouble());
  }
  return (datas: datas, fechos: fechos, volumes: volumes);
}

double? _v(List<Metric> ms, String key) =>
    ms.firstWhere((m) => m.key == key).value;

/// Tolerância relativa 1e-9 contra os valores do script independente (tool/golden_metrics.py).
void _bate(double? actual, double esperado) {
  expect(actual, isNotNull);
  expect(actual, closeTo(esperado, esperado.abs() * 1e-9 + 1e-15));
}

void main() {
  final golden = jsonDecode(
    File('test/fixtures/golden_aapl.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final aapl = _serie('chart_AAPL_2y.json');
  final gspc = _serie('chart_GSPC_2y.json');
  final ms = marketRiskMetrics(
    aapl.datas,
    aapl.fechos,
    benchDates: gspc.datas,
    benchCloses: gspc.fechos,
    volumes: aapl.volumes,
  );

  group('AAPL 2 anos contra golden_aapl.json', () {
    test('número de preços (sem os nulos)', () {
      expect(aapl.fechos.length, golden['n_precos']);
    });

    for (final k in [
      'volatilidade_anualizada',
      'drawdown_maximo',
      'retorno_total_periodo',
      'rsi14',
      'sma50',
      'sma200',
      'sharpe',
      'sortino',
      'beta_sp500',
      'correlacao_sp500',
    ]) {
      test(k, () => _bate(_v(ms, k), (golden[k] as num).toDouble()));
    }

    test('VaR histórico 95 % (valor negativo)', () {
      _bate(_v(ms, 'var95_diario'), (golden['var95_diario'] as num).toDouble());
    });

    test('XIRR do teste (-1000, -500, +1700) bate com o golden', () {
      final r = xirr([
        (date: DateTime.utc(2024, 1, 1), amount: -1000),
        (date: DateTime.utc(2024, 7, 1), amount: -500),
        (date: DateTime.utc(2025, 1, 1), amount: 1700),
      ]);
      _bate(r, (golden['xirr_teste'] as num).toDouble());
    });

    test('TWR do teste bate com o golden e com o exemplo de 0,03125', () {
      final r = twr([
        (valueBefore: 0, cashFlow: 1000),
        (valueBefore: 1100, cashFlow: 500),
        (valueBefore: 1500, cashFlow: 0),
      ]);
      _bate(r, (golden['twr_teste'] as num).toDouble());
      expect(r, closeTo(0.03125, 1e-12));
    });

    test('volume médio = média das últimas 63 sessões (sem snapshot)', () {
      final ult = aapl.volumes.sublist(aapl.volumes.length - 63);
      _bate(_v(ms, 'volume_medio'), ult.reduce((a, b) => a + b) / 63);
    });
  });

  group('casos pequenos com números feitos à mão', () {
    test('drawdown: 100 → 120 → 90 → 150 dá -25 %', () {
      final m = marketRiskMetrics(_dias(4), [100, 120, 90, 150]);
      expect(_v(m, 'drawdown_maximo'), closeTo(-0.25, 1e-12));
    });

    test(
      'RSI: só subidas dá 100; só descidas dá 0; menos de 15 preços dá nulo',
      () {
        final subidas = [for (var i = 1; i <= 15; i++) i.toDouble()];
        final descidas = [for (var i = 15; i >= 1; i--) i.toDouble()];
        expect(_v(marketRiskMetrics(_dias(15), subidas), 'rsi14'), 100);
        expect(_v(marketRiskMetrics(_dias(15), descidas), 'rsi14'), 0);
        expect(
          _v(marketRiskMetrics(_dias(14), subidas.sublist(0, 14)), 'rsi14'),
          isNull,
        );
      },
    );

    test('Sortino: N = todos os retornos (2), DD = sqrt(0,04/2)', () {
      // retornos 0,1 e -0,2: média -0,05; rf = 0
      final m = marketRiskMetrics(_dias(3), [100, 110, 88], riskFree: 0);
      final esperado = (-0.05 * 252) / (math.sqrt(0.02) * math.sqrt(252));
      expect(_v(m, 'sortino'), closeTo(esperado, 1e-12));
    });

    test('VaR com interpolação linear: retornos -0,1 e 0,1 dão -0,09', () {
      final m = marketRiskMetrics(_dias(3), [100, 90, 99]);
      expect(_v(m, 'var95_diario'), closeTo(-0.09, 1e-12));
    });

    test('SMA 50 com 10 pontos é nula; com 3 pontos a SMA 200 é nula', () {
      final m = marketRiskMetrics(_dias(10), [
        for (var i = 1; i <= 10; i++) i.toDouble(),
      ]);
      expect(_v(m, 'sma50'), isNull);
      expect(_v(m, 'sma200'), isNull);
      expect(_v(m, 'rsi14'), isNull);
    });

    test('52 semanas: um máximo com mais de 365 dias não conta', () {
      final datas = _dias(401);
      final fechos = [
        for (var i = 0; i <= 400; i++)
          i == 0 ? 500.0 : (i == 200 ? 150.0 : (i == 400 ? 120.0 : 100.0)),
      ];
      final m = marketRiskMetrics(datas, fechos);
      expect(_v(m, 'maximo_52s'), 150);
      expect(_v(m, 'minimo_52s'), 100);
      expect(_v(m, 'distancia_maximo_52s'), closeTo(120 / 150 - 1, 1e-12));
    });

    test(
      '52 semanas do snapshot: par coerente (preço e máximo do snapshot)',
      () {
        final snap = MarketSnapshot(
          symbol: 'AAPL',
          price: 355.42,
          fiftyTwoWeekHigh: 400,
          fiftyTwoWeekLow: 200,
          averageVolume: 5000,
        );
        final m = marketRiskMetrics(_dias(3), [100, 110, 120], snapshot: snap);
        expect(_v(m, 'maximo_52s'), 400);
        expect(_v(m, 'minimo_52s'), 200);
        expect(_v(m, 'distancia_maximo_52s'), closeTo(355.42 / 400 - 1, 1e-12));
        expect(_v(m, 'volume_medio'), 5000);
      },
    );

    test('retorno YTD usa o último fecho do ano civil anterior', () {
      final datas = [
        DateTime.utc(2023, 12, 29),
        DateTime.utc(2024, 1, 2),
        DateTime.utc(2024, 6, 3),
      ];
      final m = marketRiskMetrics(datas, [90, 100, 150]);
      expect(_v(m, 'retorno_ytd'), closeTo(150 / 90 - 1, 1e-12));
    });

    test('retorno 1 mês: 31 de março menos 1 mês é 29 de fevereiro (2024)', () {
      final datas = [DateTime.utc(2024, 2, 29), DateTime.utc(2024, 3, 31)];
      final m = marketRiskMetrics(datas, [100, 110]);
      expect(_v(m, 'retorno_1m'), closeTo(0.1, 1e-12));
    });

    test('beta e correlação de um índice contra si próprio dão 1', () {
      final datas = _dias(5);
      final fechos = <double>[100, 102, 99, 105, 103];
      final m = marketRiskMetrics(
        datas,
        fechos,
        benchDates: datas,
        benchCloses: fechos,
      );
      expect(_v(m, 'beta_sp500'), closeTo(1, 1e-12));
      expect(_v(m, 'correlacao_sp500'), closeTo(1, 1e-12));
    });

    test('beta alinhado por data: o índice com horas diferentes conta como o mesmo dia', () {
      final datas = _dias(5);
      final fechos = <double>[100, 102, 99, 105, 103];
      final bDatas = [for (final d in datas) d.add(const Duration(hours: 20))];
      final m = marketRiskMetrics(
        datas,
        fechos,
        benchDates: bDatas,
        benchCloses: fechos,
      );
      expect(_v(m, 'beta_sp500'), closeTo(1, 1e-12));
    });

    test('datas sem dados (listas vazias) dão nulo e não lançam exceção', () {
      final m = marketRiskMetrics(const [], const []);
      expect(m.length, marketRiskInfo.length - 3);
      for (final x in m) {
        if (x.key == 'spread_bid_ask') continue;
        expect(x.value, isNull, reason: x.key);
      }
    });

    test('listas de tamanhos diferentes são erro de programação', () {
      expect(() => marketRiskMetrics(_dias(3), [1, 2]), throwsArgumentError);
    });
  });

  group('métricas de carteira', () {
    test(
      'XIRR: -1000 e +1100 com 365 dias de intervalo dá 10 % (base 365)',
      () {
        // 2024 é bissexto: 2024-01-01 a 2025-01-01 seriam 366 dias; usa-se 31-12 (365 dias)
        final r = xirr([
          (date: DateTime.utc(2024, 1, 1), amount: -1000),
          (date: DateTime.utc(2024, 12, 31), amount: 1100),
        ]);
        expect(r, closeTo(0.1, 1e-9));
      },
    );

    test(
      'XIRR sem fluxo negativo ou sem mudança de sinal no intervalo dá nulo',
      () {
        expect(xirr([(date: DateTime.utc(2024), amount: 100)]), isNull);
        expect(xirr(const []), isNull);
        // -100 e +1e9 um ano depois: a raiz (~1e7) está fora de [-0,9999; 10], o VPL não muda de sinal
        expect(
          xirr([
            (date: DateTime.utc(2024), amount: -100),
            (date: DateTime.utc(2025), amount: 1e9),
          ]),
          isNull,
        );
      },
    );

    test('TWR: uma só sub-período sem fluxos é o retorno simples', () {
      expect(
        twr([
          (valueBefore: 0, cashFlow: 1000),
          (valueBefore: 1200, cashFlow: 0),
        ]),
        closeTo(0.2, 1e-12),
      );
    });

    test(
      'HHI: dois pesos iguais dão 0,5; três iguais dão 1/3; vazio dá nulo',
      () {
        expect(hhi([0.5, 0.5]), closeTo(0.5, 1e-12));
        expect(hhi([1, 1, 1]), closeTo(1 / 3, 1e-12));
        expect(hhi(const []), isNull);
      },
    );

    test('concentração top-N soma os N maiores pesos', () {
      expect(topNConcentration([0.2, 0.5, 0.3], 2), closeTo(0.8, 1e-12));
      expect(topNConcentration([0.2, 0.5, 0.3], 0), isNull);
    });

    test('correlação média: pares com +1, -1 e -1 dão -1/3', () {
      final datas = _dias(3);
      final a = {datas[0]: 1.0, datas[1]: 2.0, datas[2]: 3.0};
      final b = {datas[0]: 2.0, datas[1]: 4.0, datas[2]: 6.0};
      final c = {datas[0]: 3.0, datas[1]: 2.0, datas[2]: 1.0};
      expect(averageCorrelation([a, b, c]), closeTo(-1 / 3, 1e-12));
    });

    test('correlação média dá nulo com menos de 3 datas comuns', () {
      final datas = _dias(3);
      final a = {datas[0]: 1.0, datas[1]: 2.0, datas[2]: 3.0};
      final b = {datas[0]: 1.0, datas[1]: 2.0};
      expect(averageCorrelation([a, b]), isNull);
    });
  });

  group('snapshot e cobertura das fichas', () {
    test('short interest e insiders vêm do snapshot; bid-ask fica nulo', () {
      final s = snapshotRiskMetrics(
        const MarketSnapshot(
          symbol: 'AAPL',
          shortPercentOfFloat: 0.012,
          insidersPercentHeld: 0.0007,
        ),
      );
      expect(_v(s, 'short_percent_float'), 0.012);
      expect(_v(s, 'insiders_percent_held'), 0.0007);
      expect(_v(s, 'spread_bid_ask'), isNull);
    });

    test(
      'marketRiskMetrics: tem ficha para cada chave, sem chaves repetidas',
      () {
        final chaves = [
          ...ms,
          ...snapshotRiskMetrics(const MarketSnapshot(symbol: 'X')),
        ].map((m) => m.key).toList();
        expect(chaves.toSet().length, chaves.length);
        final fichas = marketRiskInfo.map((i) => i.key).toList();
        expect(
          fichas.toSet().length,
          fichas.length,
          reason: 'chaves duplicadas nas fichas',
        );
        for (final k in chaves) {
          expect(fichas, contains(k), reason: 'sem ficha: $k');
        }
      },
    );

    test('todas as fichas têm textos PT e EN preenchidos', () {
      for (final i in marketRiskInfo) {
        expect(i.namePt.trim(), isNotEmpty, reason: i.key);
        expect(i.nameEn.trim(), isNotEmpty, reason: i.key);
        expect(i.meaningPt.trim(), isNotEmpty, reason: i.key);
        expect(i.meaningEn.trim(), isNotEmpty, reason: i.key);
        expect(i.readPt.trim(), isNotEmpty, reason: i.key);
        expect(i.readEn.trim(), isNotEmpty, reason: i.key);
      }
    });

    test('spread bid-ask está marcado como não disponível', () {
      final i = marketRiskInfo.firstWhere((x) => x.key == 'spread_bid_ask');
      expect(i.availability, MetricAvailability.unavailable);
    });
  });
}

/// Datas diárias consecutivas a partir de 2023-01-01 (só para os casos pequenos).
List<DateTime> _dias(int n) => [
  for (var i = 0; i < n; i++) DateTime.utc(2023, 1, 1).add(Duration(days: i)),
];
