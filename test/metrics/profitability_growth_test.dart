import 'dart:convert';
import 'dart:io';

import 'package:financas/invest/data/yahoo_market_data.dart';
import 'package:financas/invest/metrics/financials.dart';
import 'package:financas/invest/metrics/metric_info.dart';
import 'package:financas/invest/metrics/profitability_growth.dart';
import 'package:financas/invest/metrics/profitability_growth_info.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../invest_data/support.dart';

/// Financials reais do AAPL (fixtures do Yahoo gravadas, sem rede).
Future<Financials> _aapl() => YahooMarketData(
  client: mock((r) => timeseriesRoute(r) ?? http.Response('', 404)),
  now: () => DateTime(2026, 11, 12),
).financials('AAPL');

/// Período de demonstrações com os campos usados nestes testes; o resto fica nulo.
FinPeriod per({
  required int ano,
  bool anual = true,
  DateTime? fim,
  double? rev,
  double? cogs,
  double? bruto,
  double? opInc,
  double? ebit,
  double? ebitda,
  double? ni,
  double? pretax,
  double? tax,
  double? ocf,
  double? capex,
  double? fcfFonte,
  double? divs,
  double? eq,
  double? debt,
  double? cash,
  double? ativo,
  double? recv,
  double? inv,
  double? pay,
  double? tbv,
}) => FinPeriod(
  end: fim ?? DateTime(ano, 12, 31),
  annual: anual,
  revenue: rev,
  costOfRevenue: cogs,
  grossProfit: bruto,
  operatingIncome: opInc,
  ebit: ebit,
  ebitda: ebitda,
  netIncome: ni,
  pretaxIncome: pretax,
  taxProvision: tax,
  operatingCashFlow: ocf,
  capex: capex,
  freeCashFlow: fcfFonte,
  dividendsPaid: divs,
  equity: eq,
  totalDebt: debt,
  cash: cash,
  totalAssets: ativo,
  receivables: recv,
  inventory: inv,
  payables: pay,
  tangibleBookValue: tbv,
);

/// Caso pequeno com números feitos à mão. Quatro exercícios anuais (2022 a 2025) para o CAGR a 3 anos.
/// 2025 (cur): receita 1000, EBIT 200 (com `ebit` 999 de propósito, para testar a prioridade do resultado operacional).
/// 2024 (prev): receita 800, EBIT 160.
Financials _pequeno() => Financials(
  symbol: 'TST',
  currency: 'USD',
  annual: [
    per(ano: 2022, rev: 512),
    per(ano: 2023, rev: 640),
    per(
      ano: 2024,
      rev: 800,
      cogs: 500,
      opInc: 160,
      ni: 100,
      ocf: 150,
      capex: -50,
      eq: 450,
      debt: 250,
      cash: 150,
      ativo: 1300,
      recv: 100,
      inv: 70,
      pay: 40,
      tbv: 380,
    ),
    per(
      ano: 2025,
      rev: 1000,
      cogs: 600,
      opInc: 200,
      ebit: 999,
      ebitda: 250,
      ni: 120,
      pretax: 160,
      tax: 40,
      ocf: 180,
      capex: -60,
      divs: -30,
      eq: 500,
      debt: 300,
      cash: 100,
      ativo: 1500,
      recv: 150,
      inv: 90,
      pay: 60,
      tbv: 400,
    ),
  ],
);

Map<String, double?> _valores(List<Metric> ms) => {
  for (final m in ms) m.key: m.value,
};

void main() {
  group('golden AAPL (cur = annual.last, prev = annual[len-2])', () {
    test(
      'valores batem com golden_aapl.json (tolerância relativa 1e-9)',
      () async {
        final f = await _aapl();
        final g = jsonDecode(
          File('test/fixtures/golden_aapl.json').readAsStringSync(),
        ) as Map;
        final cur = f.annual.last;
        final prev = f.annual[f.annual.length - 2];

        final vals = {
          ..._valores(profitabilityMetrics(f, cur: cur)),
          ..._valores(growthMetrics(f)),
          ..._valores(returnMetrics(f, cur: cur, prev: prev)),
          ..._valores(efficiencyMetrics(f, cur: cur, prev: prev)),
        };
        const chaves = [
          'gross_margin',
          'ebitda_margin',
          'operating_margin',
          'net_margin',
          'fcf_margin',
          'revenue_growth',
          'net_income_growth',
          'revenue_cagr_3y',
          'roe',
          'roa',
          'roic',
          'tax_rate',
          'asset_turnover',
          'dso',
          'dio',
          'dpo',
          'cash_conversion_cycle',
          'inventory_turnover',
        ];
        for (final k in chaves) {
          final esperado = (g[k] as num).toDouble();
          expect(vals[k], isNotNull, reason: k);
          expect(
            (vals[k]! - esperado).abs(),
            lessThanOrEqualTo(1e-9 * esperado.abs() + 1e-15),
            reason: '$k: ${vals[k]} vs golden $esperado',
          );
        }
      },
    );

    test('CAGR a 5 e 10 anos e crescimento orgânico são null (sem dados gratuitos)', () async {
      final v = _valores(growthMetrics(await _aapl()));
      expect(v['revenue_cagr_5y'], isNull);
      expect(v['revenue_cagr_10y'], isNull);
      expect(v['organic_growth'], isNull);
    });
  });

  group('casos pequenos com números de manual', () {
    final f = _pequeno();
    final cur = f.annual.last;
    final prev = f.annual[2];

    test('margens (grossProfit ausente: receita − custo; EBIT = resultado operacional, não ebit)', () {
      final v = _valores(profitabilityMetrics(f));
      expect(v['gross_margin'], closeTo(0.4, 1e-12));
      expect(v['ebitda_margin'], closeTo(0.25, 1e-12));
      expect(v['operating_margin'], closeTo(0.2, 1e-12));
      expect(v['net_margin'], closeTo(0.12, 1e-12));
      // FCF = CFO − |capex| = 180 − 60 = 120
      expect(v['fcf_margin'], closeTo(0.12, 1e-12));
    });

    test('grossProfit da fonte tem prioridade sobre receita − custo', () {
      final g = Financials(
        symbol: 'X',
        annual: [per(ano: 2025, rev: 1000, cogs: 600, bruto: 300)],
      );
      expect(
        _valores(profitabilityMetrics(g))['gross_margin'],
        closeTo(0.3, 1e-12),
      );
    });

    test('FCF sem CFO ou sem capex usa freeCashFlow da fonte', () {
      final g = Financials(
        symbol: 'X',
        annual: [per(ano: 2025, rev: 1000, fcfFonte: 99, ocf: 180)],
      );
      expect(
        _valores(profitabilityMetrics(g))['fcf_margin'],
        closeTo(0.099, 1e-12),
      );
    });

    test('crescimento anual, CAGR a 3 anos e alavancagem operacional', () {
      final v = _valores(growthMetrics(f));
      expect(v['revenue_growth'], closeTo(1000 / 800 - 1, 1e-12));
      expect(v['net_income_growth'], closeTo(120 / 100 - 1, 1e-12));
      expect(v['fcf_growth'], closeTo(120 / 100 - 1, 1e-12));
      // (1000 / 512)^(1/3) = 1,25
      expect(v['revenue_cagr_3y'], closeTo(0.25, 1e-12));
      // EBIT +25 % / receita +25 % = 1
      expect(v['operating_leverage'], closeTo(1.0, 1e-12));
      // crescimento sustentável = ROE anual × (1 − 30/120)
      expect(v['sustainable_growth'], closeTo(120 / 475 * 0.75, 1e-12));
    });

    test('ROE, ROA, ROIC, ROTE, taxa de imposto e spread com médias', () {
      final v = _valores(returnMetrics(f, wacc: 0.10, cur: cur, prev: prev));
      expect(v['roe'], closeTo(120 / 475, 1e-12)); // média (500 + 450) / 2
      expect(v['roa'], closeTo(120 / 1400, 1e-12)); // média (1500 + 1300) / 2
      // capital investido: 500 + 300 − 100 = 700 e 450 + 250 − 150 = 550; média 625
      // NOPAT = 200 × (1 − 0,25) = 150
      expect(v['roic'], closeTo(150 / 625, 1e-12));
      expect(v['roic_wacc_spread'], closeTo(150 / 625 - 0.10, 1e-12));
      expect(v['rote'], closeTo(120 / 390, 1e-12)); // média (400 + 380) / 2
      expect(v['tax_rate'], closeTo(0.25, 1e-12));
    });

    test('DuPont: os três fatores e o produto igual ao ROE', () {
      final v = _valores(returnMetrics(f, cur: cur, prev: prev));
      expect(v['dupont_net_margin'], closeTo(0.12, 1e-12));
      expect(v['dupont_asset_turnover'], closeTo(1000 / 1400, 1e-12));
      expect(v['dupont_financial_leverage'], closeTo(1400 / 475, 1e-12));
      expect(v['dupont_roe'], closeTo(v['roe']!, 1e-12));
    });

    test('sem WACC não há spread', () {
      expect(
        _valores(returnMetrics(f)).containsKey('roic_wacc_spread'),
        isFalse,
      );
    });

    test('eficiência: rotação, prazos (saldo de fecho) e ciclo', () {
      final v = _valores(efficiencyMetrics(f, cur: cur, prev: prev));
      expect(v['asset_turnover'], closeTo(1000 / 1400, 1e-12));
      expect(v['dso'], closeTo(150 / 1000 * 365, 1e-9)); // 54,75
      expect(v['dio'], closeTo(90 / 600 * 365, 1e-9)); // 54,75
      expect(v['dpo'], closeTo(60 / 600 * 365, 1e-9)); // 36,5
      expect(v['cash_conversion_cycle'], closeTo(54.75 + 54.75 - 36.5, 1e-9));
      // custo / inventário médio = 600 / ((90 + 70) / 2)
      expect(v['inventory_turnover'], closeTo(600 / 80, 1e-12));
    });

    test('TTM: o período anterior é o trimestre cujo fecho está 320 a 410 dias antes', () {
      final q = per(
        ano: 2025,
        anual: false,
        fim: DateTime(2025, 6, 30),
        eq: 400,
        ativo: 1200,
        cash: 100,
        debt: 250,
      );
      final t = per(
        ano: 2026,
        anual: true,
        fim: DateTime(2026, 6, 30),
        ni: 130,
        eq: 500,
        ativo: 1500,
        cash: 100,
        debt: 300,
      );
      final g = Financials(
        symbol: 'TTM',
        annual: [
          per(ano: 2025, ni: 1, eq: 1),
        ], // fecho 2025-12-31: fora da janela de 320–410 dias
        quarterly: [q],
        ttm: t,
      );
      expect(periodoAnterior(g, t), same(q));
      // ROE TTM = 130 / média (500, 400)
      expect(_valores(returnMetrics(g))['roe'], closeTo(130 / 450, 1e-12));
    });

    test('ROE com capitais próprios médios negativos é null', () {
      final g = Financials(
        symbol: 'X',
        annual: [
          per(ano: 2024, eq: -50, ni: 1),
          per(ano: 2025, eq: -100, ni: 10),
        ],
      );
      expect(_valores(returnMetrics(g))['roe'], isNull);
    });
  });

  group('dados em falta e casos-limite (null, sem exceções)', () {
    test('sem dados: todas as métricas existem e são null', () {
      const f = Financials(symbol: 'NADA');
      final all = [
        ...profitabilityMetrics(f),
        ...growthMetrics(f),
        ...returnMetrics(f, wacc: 0.1),
        ...efficiencyMetrics(f),
      ];
      expect(all, isNotEmpty);
      for (final m in all) {
        expect(m.value, isNull, reason: m.key);
      }
    });

    test('receita zero: margens null (divisão por zero)', () {
      final f = Financials(
        symbol: 'X',
        annual: [per(ano: 2025, rev: 0, ni: 5, opInc: 5)],
      );
      final v = _valores(profitabilityMetrics(f));
      expect(v['net_margin'], isNull);
      expect(v['operating_margin'], isNull);
    });

    test('taxa de imposto: fallback de 21 % fora de [0; 0,5] ou com resultado antes de impostos ≤ 0', () {
      expect(taxRateOf(per(ano: 2025, pretax: 100, tax: 70)), 0.21);
      expect(taxRateOf(per(ano: 2025, pretax: 0, tax: 10)), 0.21);
      expect(taxRateOf(per(ano: 2025, pretax: -50, tax: -10)), 0.21);
      expect(taxRateOf(per(ano: 2025, pretax: 100)), 0.21);
      expect(
        taxRateOf(per(ano: 2025, pretax: 100, tax: 40)),
        closeTo(0.4, 1e-12),
      );
    });

    test(
      'crescimento com base ≤ 0 é null; CAGR com inicial negativo é null',
      () {
        final f = Financials(
          symbol: 'X',
          annual: [
            per(ano: 2022, rev: -10, ni: -5),
            per(ano: 2023, rev: -20, ni: -6),
            per(ano: 2024, rev: -30, ni: 3),
            per(ano: 2025, rev: 100, ni: 10),
          ],
        );
        final v = _valores(growthMetrics(f));
        expect(v['revenue_growth'], isNull); // receita anterior −30
        expect(
          v['net_income_growth'],
          closeTo(10 / 3 - 1, 1e-12),
        ); // 3 > 0, define-se
        expect(v['revenue_cagr_3y'], isNull); // receita inicial −10
      },
    );

    test(
      'alavancagem operacional é null se o EBIT do ano anterior for ≤ 0',
      () {
        final f = Financials(
          symbol: 'X',
          annual: [
            per(ano: 2024, rev: 800, opInc: -10),
            per(ano: 2025, rev: 1000, opInc: 20),
          ],
        );
        expect(_valores(growthMetrics(f))['operating_leverage'], isNull);
      },
    );

    test('dividendos em falta: payout 0 e crescimento sustentável = ROE', () {
      final f = Financials(
        symbol: 'X',
        annual: [
          per(ano: 2024, eq: 100, ni: 10),
          per(ano: 2025, eq: 100, ni: 10),
        ],
      );
      expect(
        _valores(growthMetrics(f))['sustainable_growth'],
        closeTo(0.1, 1e-12),
      );
    });

    test('lucro negativo: crescimento sustentável null', () {
      final f = Financials(
        symbol: 'X',
        annual: [
          per(ano: 2024, eq: 100, ni: -10),
          per(ano: 2025, eq: 100, ni: -10, divs: -5),
        ],
      );
      expect(_valores(growthMetrics(f))['sustainable_growth'], isNull);
    });

    test('DIO e ciclo são null sem inventário (software e serviços)', () {
      final f = Financials(
        symbol: 'X',
        annual: [
          per(ano: 2024, rev: 800, cogs: 300, recv: 80, pay: 30),
          per(ano: 2025, rev: 1000, cogs: 400, recv: 100, pay: 40),
        ],
      );
      final v = _valores(efficiencyMetrics(f));
      expect(v['dio'], isNull);
      expect(v['cash_conversion_cycle'], isNull);
      expect(v['dso'], closeTo(100 / 1000 * 365, 1e-9));
      expect(v['dpo'], closeTo(40 / 400 * 365, 1e-9));
    });

    test(
      'financeiras (banco): custo das vendas e EBIT em falta não dão exceções',
      () {
        final f = Financials(
          symbol: 'JPM',
          annual: [
            per(ano: 2024, rev: 100, ni: 20, eq: 200, ativo: 2000),
            per(ano: 2025, rev: 110, ni: 22, eq: 220, ativo: 2100),
          ],
        );
        final v = _valores([
          ...profitabilityMetrics(f),
          ...returnMetrics(f),
          ...efficiencyMetrics(f),
        ]);
        expect(v['gross_margin'], isNull);
        expect(v['operating_margin'], isNull);
        expect(v['roe'], closeTo(22 / 210, 1e-12));
        expect(v['inventory_turnover'], isNull);
      },
    );
  });

  group('cobertura do catálogo de explicações', () {
    test('cada chave devolvida tem ficha, sem duplicados, e os textos estão preenchidos', () async {
      final f = await _aapl();
      final pequeno = _pequeno();
      const vazio = Financials(symbol: 'NADA');
      final chaves = <String>{};
      for (final x in [f, pequeno, vazio]) {
        final ms = [
          ...profitabilityMetrics(x),
          ...growthMetrics(x),
          ...returnMetrics(x, wacc: 0.10),
          ...efficiencyMetrics(x),
        ];
        chaves.addAll(ms.map((m) => m.key));
      }

      final infoKeys = profitabilityGrowthInfo.map((i) => i.key).toList();
      expect(
        infoKeys.toSet().length,
        infoKeys.length,
        reason: 'chaves de ficha duplicadas',
      );
      expect(
        infoKeys.toSet(),
        chaves,
        reason: 'fichas e métricas devolvidas devem coincidir',
      );

      for (final MetricInfo i in profitabilityGrowthInfo) {
        for (final t in [
          i.namePt,
          i.nameEn,
          i.meaningPt,
          i.meaningEn,
          i.readPt,
          i.readEn,
        ]) {
          expect(t.trim(), isNotEmpty, reason: '${i.key}: texto vazio');
        }
        expect(i.formula.trim(), isNotEmpty, reason: '${i.key}: fórmula vazia');
        expect(
          i.cautionPt == null,
          i.cautionEn == null,
          reason: '${i.key}: cautela só numa língua',
        );
      }
    });

    test('as métricas não disponíveis estão marcadas como tal', () {
      final por = {for (final i in profitabilityGrowthInfo) i.key: i};
      for (final k in [
        'revenue_cagr_5y',
        'revenue_cagr_10y',
        'organic_growth',
      ]) {
        expect(por[k]!.availability, MetricAvailability.unavailable, reason: k);
      }
    });
  });
}
