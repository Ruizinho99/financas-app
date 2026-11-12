import 'dart:convert';
import 'dart:io';

import 'package:financas/invest/data/yahoo_market_data.dart';
import 'package:financas/invest/metrics/financials.dart';
import 'package:financas/invest/metrics/metric_info.dart';
import 'package:financas/invest/metrics/risk_scores.dart';
import 'package:financas/invest/metrics/risk_scores_info.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../invest_data/support.dart';

YahooMarketData _yahoo() => YahooMarketData(
  client: mock((r) => timeseriesRoute(r) ?? http.Response('', 404)),
  now: () => DateTime(2026, 11, 12),
);

/// Igualdade relativa de 1e-9 (como no golden).
void expectRel(double? actual, num expected) {
  expect(actual, isNotNull);
  expect(actual, closeTo(expected.toDouble(), expected.abs() * 1e-9 + 1e-15));
}

Map<String, double?> porChave(List<Metric> ms) {
  final mapa = <String, double?>{};
  for (final x in ms) {
    expect(
      mapa.containsKey(x.key),
      isFalse,
      reason: 'chave duplicada ${x.key}',
    );
    mapa[x.key] = x.value;
  }
  return mapa;
}

FinPeriod _ano(
  int ano, {
  double? revenue,
  double? grossProfit,
  double? operatingIncome,
  double? ebit,
  double? netIncome,
  double? totalAssets,
  double? currentAssets,
  double? currentLiabilities,
  double? retainedEarnings,
  double? totalLiabilities,
  double? equity,
  double? receivables,
  double? depreciationAmortization,
  double? netPpe,
  double? sellingGeneralAdmin,
  double? longTermDebt,
  double? operatingCashFlow,
  double? sharesOutstanding,
}) => FinPeriod(
  end: DateTime(ano, 12, 31),
  annual: true,
  revenue: revenue,
  grossProfit: grossProfit,
  operatingIncome: operatingIncome,
  ebit: ebit,
  netIncome: netIncome,
  totalAssets: totalAssets,
  currentAssets: currentAssets,
  currentLiabilities: currentLiabilities,
  retainedEarnings: retainedEarnings,
  totalLiabilities: totalLiabilities,
  equity: equity,
  receivables: receivables,
  depreciationAmortization: depreciationAmortization,
  netPpe: netPpe,
  sellingGeneralAdmin: sellingGeneralAdmin,
  longTermDebt: longTermDebt,
  operatingCashFlow: operatingCashFlow,
  sharesOutstanding: sharesOutstanding,
);

void main() {
  group('Altman com a AAPL real (golden)', () {
    test('Z original e Z″ batem com golden_aapl.json (cur = último anual, capitalização 3e12)', () async {
      final f = await _yahoo().financials('AAPL');
      final g = jsonDecode(
        File('test/fixtures/golden_aapl.json').readAsStringSync(),
      ) as Map;
      final m = MarketSnapshot(
        symbol: 'AAPL',
        sector: 'Technology',
        marketCap: g['altman_z_market_cap'] as double,
      );
      final r = porChave(altmanMetrics(f, m, cur: f.lastAnnual));
      expectRel(r['altman_z'], g['altman_z'] as num);
      expectRel(r['altman_z2'], g['altman_z2'] as num);
    });

    test('setor Technology usa o Z″ e não o original; zona do Z″ é cinzenta na AAPL', () async {
      final f = await _yahoo().financials('AAPL');
      final m = MarketSnapshot(
        symbol: 'AAPL',
        sector: 'Technology',
        marketCap: 3e12,
      );
      expect(altmanModelForSector(m.sector), AltmanModel.doublePrime);
      final z2 = porChave(altmanMetrics(f, m, cur: f.lastAnnual))['altman_z2']!;
      expect(altmanZone(z2, AltmanModel.doublePrime), AltmanZone.grey);
    });
  });

  group('Altman: contas à mão', () {
    // TA 100; CA 50; CL 30; RE 20; resultado operacional 10; EBIT (não operacional incluído) 99;
    // receita 200; capitais próprios 60; passivo total 40; capitalização 80.
    Financials cenario({double? operatingIncome = 10, double? ebit = 99}) =>
        Financials(
          symbol: 'X',
          currency: 'USD',
          annual: [
            _ano(
              2025,
              revenue: 200,
              operatingIncome: operatingIncome,
              ebit: ebit,
              totalAssets: 100,
              currentAssets: 50,
              currentLiabilities: 30,
              retainedEarnings: 20,
              totalLiabilities: 40,
              equity: 60,
            ),
          ],
        );

    test('Z original e Z″ calculados à mão', () {
      final m = MarketSnapshot(
        symbol: 'X',
        sector: 'Industrials',
        marketCap: 80,
      );
      final r = porChave(altmanMetrics(cenario(), m));
      // Z = 1,2·0,2 + 1,4·0,2 + 3,3·0,1 + 0,6·(80/40) + 1,0·(200/100) = 4,05
      expectRel(r['altman_z'], 4.05);
      // Z″ = 6,56·0,2 + 3,26·0,2 + 6,72·0,1 + 1,05·(60/40) = 4,211
      expectRel(r['altman_z2'], 4.211);
    });

    test('EBIT = operatingIncome ?? ebit: com ebit ≠ operatingIncome usa o resultado operacional', () {
      final m = MarketSnapshot(
        symbol: 'X',
        sector: 'Technology',
        marketCap: 80,
      );
      final r = porChave(
        altmanMetrics(cenario(operatingIncome: 10, ebit: 99), m),
      );
      // X3 = 10/100 (e não 99/100): Z″ = 4,211
      expectRel(r['altman_z2'], 4.211);
    });

    test('sem resultado operacional usa o campo ebit', () {
      final m = MarketSnapshot(
        symbol: 'X',
        sector: 'Technology',
        marketCap: 80,
      );
      final r = porChave(
        altmanMetrics(cenario(operatingIncome: null, ebit: 99), m),
      );
      // X3 = 0,99: Z″ = 2,636 − 0,672 + 6,72·0,99 + 1,575
      expectRel(
        r['altman_z2'],
        6.56 * 0.2 + 3.26 * 0.2 + 6.72 * 0.99 + 1.05 * 1.5,
      );
    });

    test('setores financeiros e imobiliário: ambos null (não aplicável)', () {
      for (final s in ['Financial Services', 'Real Estate']) {
        final m = MarketSnapshot(symbol: 'X', sector: s, marketCap: 80);
        final r = porChave(altmanMetrics(cenario(), m));
        expect(r['altman_z'], isNull, reason: s);
        expect(r['altman_z2'], isNull, reason: s);
      }
    });

    test('mapeamento setor → modelo', () {
      expect(altmanModelForSector('Industrials'), AltmanModel.original);
      expect(altmanModelForSector('Basic Materials'), AltmanModel.original);
      expect(altmanModelForSector('Energy'), AltmanModel.original);
      expect(altmanModelForSector('Consumer Cyclical'), AltmanModel.original);
      expect(altmanModelForSector('Consumer Defensive'), AltmanModel.original);
      expect(
        altmanModelForSector('Financial Services'),
        AltmanModel.notApplicable,
      );
      expect(altmanModelForSector('Real Estate'), AltmanModel.notApplicable);
      expect(altmanModelForSector('Healthcare'), AltmanModel.doublePrime);
      expect(altmanModelForSector('Technology'), AltmanModel.doublePrime);
      expect(
        altmanModelForSector('Communication Services'),
        AltmanModel.doublePrime,
      );
      expect(altmanModelForSector(''), AltmanModel.doublePrime);
    });

    test('zonas: limites e nulos', () {
      expect(altmanZone(3.0, AltmanModel.original), AltmanZone.safe);
      expect(altmanZone(2.99, AltmanModel.original), AltmanZone.grey);
      expect(altmanZone(1.81, AltmanModel.original), AltmanZone.grey);
      expect(altmanZone(1.80, AltmanModel.original), AltmanZone.distress);
      expect(altmanZone(2.61, AltmanModel.doublePrime), AltmanZone.safe);
      expect(altmanZone(2.6, AltmanModel.doublePrime), AltmanZone.grey);
      expect(altmanZone(1.1, AltmanModel.doublePrime), AltmanZone.grey);
      expect(altmanZone(1.09, AltmanModel.doublePrime), AltmanZone.distress);
      expect(
        altmanZone(null, AltmanModel.doublePrime),
        AltmanZone.notApplicable,
      );
      expect(
        altmanZone(9, AltmanModel.notApplicable),
        AltmanZone.notApplicable,
      );
    });

    test('sem dados ou com ativo zero: null, sem exceções', () {
      final m = MarketSnapshot(
        symbol: 'X',
        sector: 'Technology',
        marketCap: 80,
      );
      final vazio = Financials(symbol: 'X');
      final r0 = porChave(altmanMetrics(vazio, m));
      expect(r0['altman_z'], isNull);
      expect(r0['altman_z2'], isNull);
      final zero = Financials(
        symbol: 'X',
        annual: [_ano(2025, totalAssets: 0, equity: 1, totalLiabilities: 1)],
      );
      final r1 = porChave(altmanMetrics(zero, m));
      expect(r1['altman_z2'], isNull);
    });
  });

  group('Piotroski', () {
    test('AAPL: os 9 testes, F = 8 e 9 avaliados, iguais ao golden', () async {
      final f = await _yahoo().financials('AAPL');
      final g = jsonDecode(
        File('test/fixtures/golden_aapl.json').readAsStringSync(),
      ) as Map;
      final r = porChave(piotroskiMetrics(f));
      final testes = g['piotroski_tests'] as List;
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
      for (var i = 0; i < 9; i++) {
        expect(
          r[chaves[i]],
          testes[i] == null ? isNull : (testes[i] as bool ? 1.0 : 0.0),
          reason: chaves[i],
        );
      }
      expect(r['piotroski_f'], g['piotroski_f']);
      expect(r['piotroski_n_avaliados'], g['piotroski_n_avaliados']);
    });

    test('com um só ano: só os testes sem t-1 são avaliados', () {
      final f = Financials(
        symbol: 'X',
        annual: [_ano(2025, operatingCashFlow: 50, netIncome: 30)],
      );
      final r = porChave(piotroskiMetrics(f));
      expect(r['piotroski_roa'], isNull); // precisa de TA(t−1)
      expect(r['piotroski_cfo'], 1.0);
      expect(r['piotroski_accruals'], 1.0); // CFO 50 > resultado 30
      expect(r['piotroski_d_roa'], isNull);
      expect(r['piotroski_no_dilution'], isNull);
      expect(r['piotroski_n_avaliados'], 2);
      expect(r['piotroski_f'], 2);
    });

    test('sem anuais: nada avaliado, f nulo, sem exceções', () {
      final r = porChave(piotroskiMetrics(const Financials(symbol: 'X')));
      expect(r['piotroski_f'], isNull);
      expect(r['piotroski_n_avaliados'], 0);
      expect(r['piotroski_cfo'], isNull);
    });

    test('dívida LP em falta: o teste de alavancagem não é avaliado', () {
      final f = Financials(
        symbol: 'X',
        annual: [
          _ano(2023, totalAssets: 100, netIncome: 10),
          _ano(
            2024,
            totalAssets: 110,
            netIncome: 12,
          ), // dívida LP do ano anterior em falta
          _ano(2025, totalAssets: 120, netIncome: 15, longTermDebt: 18),
        ],
      );
      expect(porChave(piotroskiMetrics(f))['piotroski_d_leverage'], isNull);
    });
  });

  group('Beneish', () {
    test('AAPL: 8 índices, M e batem com o golden', () async {
      final f = await _yahoo().financials('AAPL');
      final g = jsonDecode(
        File('test/fixtures/golden_aapl.json').readAsStringSync(),
      ) as Map;
      final b = g['beneish'] as Map;
      final r = porChave(beneishMetrics(f));
      expectRel(r['beneish_dsri'], b['dsri'] as num);
      expectRel(r['beneish_gmi'], b['gmi'] as num);
      expectRel(r['beneish_aqi'], b['aqi'] as num);
      expectRel(r['beneish_sgi'], b['sgi'] as num);
      expectRel(r['beneish_depi'], b['depi'] as num);
      expectRel(r['beneish_sgai'], b['sgai'] as num);
      expectRel(r['beneish_tata'], b['tata'] as num);
      expectRel(r['beneish_lvgi'], b['lvgi'] as num);
      expectRel(r['beneish_m'], g['beneish_m'] as num);
      expect(r['beneish_alert'], 0); // −2,29 não passa o limiar de −1,78
    });

    // Dois anos iguais: os índices dão 1 e o TATA depende só de t.
    // M = −4,84 + (0,920 + 0,528 + 0,404 + 0,892 + 0,115 − 0,172 − 0,327) + 4,679·TATA = −2,48 + 4,679·TATA
    Financials par({double? ocf = 30, double? sga = 40}) {
      FinPeriod ano(int y, {double? sgaV}) => _ano(
        y,
        revenue: 200,
        grossProfit: 80,
        netIncome: 30,
        totalAssets: 100,
        currentAssets: 50,
        currentLiabilities: 30,
        receivables: 20,
        depreciationAmortization: 5,
        netPpe: 30,
        sellingGeneralAdmin: sgaV,
        longTermDebt: 20,
        operatingCashFlow: y == 2025 ? ocf : 30,
      );
      return Financials(
        symbol: 'X',
        annual: [
          ano(2024, sgaV: sga),
          ano(2025, sgaV: sga),
        ],
      );
    }

    test('contas à mão: índices a 1 e M = −2,48 com TATA = 0', () {
      final r = porChave(beneishMetrics(par(ocf: 30)));
      for (final k in [
        'beneish_dsri',
        'beneish_gmi',
        'beneish_aqi',
        'beneish_sgi',
        'beneish_depi',
        'beneish_sgai',
        'beneish_lvgi',
      ]) {
        expectRel(r[k], 1);
      }
      expect(r['beneish_tata'], 0);
      expectRel(r['beneish_m'], -2.48);
      expect(r['beneish_alert'], 0);
    });

    test('contas à mão: TATA = 0,3 leva o M a −1,0763 e ativa o alerta', () {
      final r = porChave(beneishMetrics(par(ocf: 0)));
      expectRel(r['beneish_tata'], 0.3);
      expectRel(r['beneish_m'], -2.48 + 4.679 * 0.3);
      expect(r['beneish_m'], closeTo(-1.0763, 1e-9));
      expect(r['beneish_alert'], 1);
    });

    test('um índice em falta (SG&A) → M e alerta null, os outros índices mantêm-se', () {
      final r = porChave(beneishMetrics(par(sga: null)));
      expect(r['beneish_sgai'], isNull);
      expect(r['beneish_m'], isNull);
      expect(r['beneish_alert'], isNull);
      expectRel(r['beneish_dsri'], 1);
    });

    test('um só ano ou nenhum: tudo null, sem exceções', () {
      final r1 = porChave(
        beneishMetrics(
          Financials(symbol: 'X', annual: [_ano(2025, revenue: 1)]),
        ),
      );
      expect(r1['beneish_m'], isNull);
      expect(r1['beneish_alert'], isNull);
      final r0 = porChave(beneishMetrics(const Financials(symbol: 'X')));
      expect(r0['beneish_m'], isNull);
    });
  });

  group('Cobertura das fichas', () {
    test(
      'cada chave devolvida tem ficha, sem duplicados, com textos preenchidos',
      () async {
        final f = await _yahoo().financials('AAPL');
        final m = MarketSnapshot(
          symbol: 'AAPL',
          sector: 'Technology',
          marketCap: 3e12,
        );
        final devolvidas = [
          ...altmanMetrics(f, m),
          ...piotroskiMetrics(f),
          ...beneishMetrics(f),
          // cenários sem dados também devolvem as mesmas chaves
          ...altmanMetrics(const Financials(symbol: 'X'), m),
          ...piotroskiMetrics(const Financials(symbol: 'X')),
          ...beneishMetrics(const Financials(symbol: 'X')),
        ].map((x) => x.key).toSet();

        final fichas = riskScoresInfo.map((i) => i.key).toList();
        expect(
          fichas.toSet().length,
          fichas.length,
          reason: 'fichas duplicadas',
        );
        for (final k in devolvidas) {
          expect(fichas, contains(k), reason: 'falta a ficha de $k');
        }
        for (final i in riskScoresInfo) {
          expect(i.namePt.trim(), isNotEmpty, reason: i.key);
          expect(i.nameEn.trim(), isNotEmpty, reason: i.key);
          expect(i.meaningPt.trim(), isNotEmpty, reason: i.key);
          expect(i.meaningEn.trim(), isNotEmpty, reason: i.key);
          expect(i.readPt.trim(), isNotEmpty, reason: i.key);
          expect(i.readEn.trim(), isNotEmpty, reason: i.key);
          expect(i.availability, isA<MetricAvailability>());
        }
      },
    );
  });
}
