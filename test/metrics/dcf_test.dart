import 'dart:convert';
import 'dart:io';

import 'package:financas/invest/data/yahoo_market_data.dart';
import 'package:financas/invest/metrics/dcf.dart';
import 'package:financas/invest/metrics/dcf_info.dart';
import 'package:financas/invest/metrics/financials.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../invest_data/support.dart';

Map<String, dynamic> _golden() =>
    jsonDecode(File('test/fixtures/golden_aapl.json').readAsStringSync())
        as Map<String, dynamic>;

/// Valor de uma métrica devolvida por `dcfMetrics`.
double? _m(List<Metric> ms, String key) =>
    ms.firstWhere((m) => m.key == key).value;

void _close(double? actual, double expected, {double rel = 1e-9}) {
  expect(actual, isNotNull);
  expect(actual, closeTo(expected, expected.abs() * rel + 1e-12));
}

FinPeriod _p({
  DateTime? end,
  bool annual = true,
  double? ebit,
  double? da,
  double? capex,
  double? cwc,
  double? totalDebt,
  double? cash,
  double? interestExpense,
  double? pretax,
  double? tax,
  double? revenue,
  double? shares,
}) => FinPeriod(
  end: end ?? DateTime(2025, 9, 30),
  annual: annual,
  operatingIncome: ebit,
  depreciationAmortization: da,
  capex: capex,
  changeInWorkingCapital: cwc,
  totalDebt: totalDebt,
  cash: cash,
  interestExpense: interestExpense,
  pretaxIncome: pretax,
  taxProvision: tax,
  revenue: revenue,
  sharesOutstanding: shares,
);

YahooMarketData _yahoo() => YahooMarketData(
  client: mock((r) => timeseriesRoute(r) ?? http.Response('', 404)),
  now: () => DateTime(2026, 11, 12),
);

void main() {
  final g = _golden();

  group('valores do golden (AAPL e testes fixos)', () {
    test('CAPM: Ke = rf + β × MRP (golden capm_ke)', () {
      _close(
        capmKe(rf: 0.04, beta: 1.2, mrp: 0.055),
        (g['capm_ke'] as num).toDouble(),
      );
    });

    test('WACC de teste (E 800, D 200, Ke 10,6 %, Kd 5 %, t 21 %) = golden wacc_teste', () {
      final w = waccOf(
        marketCap: 800,
        totalDebt: 200,
        ke: 0.106,
        kd: 0.05,
        t: 0.21,
      );
      _close(w, (g['wacc_teste'] as num).toDouble());
    });

    test(
      'DCF de teste: valor por ação, soma PV, TV e PV do TV = golden dcf_teste',
      () {
        final d = g['dcf_teste'] as Map<String, dynamic>;
        final r = computeDcf(
          fcff0: (d['fcf0'] as num).toDouble(),
          growth: (d['crescimento'] as num).toDouble(),
          terminalGrowth: (d['g'] as num).toDouble(),
          wacc: (d['wacc'] as num).toDouble(),
          years: 5,
          netDebt: (d['divida_liquida'] as num).toDouble(),
          shares: (d['acoes'] as num).toDouble(),
        )!;
        _close(r.sumPv, (d['soma_vp_fluxos'] as num).toDouble());
        _close(r.terminalValue, (d['valor_terminal'] as num).toDouble());
        _close(r.pvTerminal, (d['vp_valor_terminal'] as num).toDouble());
        _close(r.valuePerShare, (d['valor_por_acao'] as num).toDouble());
        expect(r.valuePerShare, closeTo(211.45, 0.01));
      },
    );

    test('AAPL: taxa efetiva e FCFF₀ = golden tax_rate e fcff', () async {
      final f = await _yahoo().financials('AAPL');
      final a = f.lastAnnual!;
      final t = effectiveTaxRate(a);
      _close(t, (g['tax_rate'] as num).toDouble());
      _close(fcff(cur: a, taxRate: t), (g['fcff'] as num).toDouble());
    });

    test('AAPL: crescimento explícito por omissão (CAGR 3 anos) = golden revenue_cagr_3y', () async {
      final f = await _yahoo().financials('AAPL');
      // Sem limite: o CAGR de AAPL (1,8 %) está dentro de [0; 0,15].
      _close(
        defaultExplicitGrowth(f),
        (g['revenue_cagr_3y'] as num).toDouble(),
        rel: 1e-9,
      );
    });
  });

  group('casos pequenos feitos à mão', () {
    test('DCF com 1 ano, gr 0, g 0, WACC 10 %: FCFF 10 → valor 100 por ação', () {
      final r = computeDcf(
        fcff0: 10,
        growth: 0,
        terminalGrowth: 0,
        wacc: 0.1,
        years: 1,
        netDebt: 0,
        shares: 1,
      )!;
      // PV = 10/1,1; TV = 10/0,1 = 100; PV TV = 100/1,1; total = 110/1,1 = 100.
      _close(r.sumPv, 10 / 1.1);
      _close(r.terminalValue, 100);
      _close(r.valuePerShare, 100);
    });

    test('dívida líquida e minoritários/preferenciais descontam o valor', () {
      final r = computeDcf(
        fcff0: 10,
        growth: 0,
        terminalGrowth: 0,
        wacc: 0.1,
        years: 1,
        netDebt: 20,
        minority: 5,
        preferred: 5,
        shares: 2,
      )!;
      // equity = 100 − 20 − 5 − 5 = 70; por ação = 35.
      _close(r.valuePerShare, 35);
    });

    test('DCF inverso: preço 150 → crescimento 50 % (caso de 1 ano)', () {
      final gr = impliedGrowth(
        fcff0: 10,
        terminalGrowth: 0,
        wacc: 0.1,
        years: 1,
        netDebt: 0,
        shares: 1,
        price: 150,
      );
      expect(gr, closeTo(0.5, 1e-6));
    });

    test('DCF inverso fora do intervalo [−50 %; 100 %] dá null', () {
      final gr = impliedGrowth(
        fcff0: 10,
        terminalGrowth: 0,
        wacc: 0.1,
        years: 1,
        netDebt: 0,
        shares: 1,
        price: 1000, // exigiria 900 % de crescimento
      );
      expect(gr, isNull);
    });

    test('margem de segurança: 1 − 80/100 = 20 %', () {
      expect(safetyMargin(100, 80), closeTo(0.2, 1e-12));
    });

    test('Kd: juros 100 sobre dívida média 1 000 = 10 %; fora de [0; 20 %] ou sem dados = 5 %', () {
      final cur = _p(totalDebt: 1000, interestExpense: 100);
      final prev = _p(totalDebt: 1000, end: DateTime(2024, 9, 30));
      expect(costOfDebt(cur, prev), closeTo(0.10, 1e-12));
      expect(
        costOfDebt(_p(totalDebt: 1000, interestExpense: 300), prev),
        kdFallback,
      );
      expect(costOfDebt(_p(totalDebt: 1000), prev), kdFallback);
      expect(costOfDebt(_p(interestExpense: 100), prev), kdFallback);
    });

    test('taxa efetiva: 21 % quando o resultado antes de impostos é <= 0, falta um dado, ou a taxa é > 50 %', () {
      expect(effectiveTaxRate(_p(pretax: 100, tax: 30)), closeTo(0.3, 1e-12));
      expect(
        effectiveTaxRate(_p(pretax: 100, tax: 70)),
        taxFallback,
      ); // 0,7 dá 0,21, não 0,5
      expect(effectiveTaxRate(_p(pretax: -5, tax: 1)), taxFallback);
      expect(effectiveTaxRate(_p(tax: 1)), taxFallback);
    });

    test('CAPM e WACC: sem dívida (null → 0) o WACC é o Ke; sem capitalização não há WACC', () {
      final ke = capmKe(rf: 0.04, beta: 1, mrp: 0.055);
      expect(
        waccOf(marketCap: 500, totalDebt: null, ke: ke, kd: 0.05, t: 0.2),
        closeTo(ke, 1e-12),
      );
      expect(
        waccOf(marketCap: null, totalDebt: 10, ke: ke, kd: 0.05, t: 0.2),
        isNull,
      );
    });

    test(
      'sensibilidade: 5 × 5 e o centro é o valor base; WACC <= g dá null',
      () {
        final m = sensitivityMatrix(
          fcff0: 100,
          growth: 0.05,
          wacc: 0.02,
          terminalGrowth: 0.015,
          years: 5,
          netDebt: 0,
          shares: 1,
        );
        expect(m.length, 5);
        expect(m.every((row) => row.length == 5), isTrue);
        // Linha 0 = WACC 0 %, coluna 0 = g 0,5 %: WACC <= g → null.
        expect(m[0][0], isNull);
        // Centro: WACC 2 %, g 1,5 %, igual ao cálculo direto.
        final centre = computeDcf(
          fcff0: 100,
          growth: 0.05,
          terminalGrowth: 0.015,
          wacc: 0.02,
          years: 5,
          netDebt: 0,
          shares: 1,
        )!.valuePerShare;
        _close(m[2][2], centre!);
      },
    );

    test(
      'cenários: pessimista < base < otimista quando o crescimento é positivo',
      () {
        final s = scenarios(
          fcff0: 100,
          growth: 0.10,
          terminalGrowth: 0.025,
          wacc: 0.09,
          years: 5,
          netDebt: 50,
          shares: 10,
        );
        final base = computeDcf(
          fcff0: 100,
          growth: 0.10,
          terminalGrowth: 0.025,
          wacc: 0.09,
          years: 5,
          netDebt: 50,
          shares: 10,
        )!.valuePerShare;
        _close(s['base'], base!);
        expect(s['pessimistic']!, lessThan(s['base']!));
        expect(s['optimistic']!, greaterThan(s['base']!));
      },
    );
  });

  group('dados em falta e divisão por zero dão null, sem exceções', () {
    test('FCFF₀ <= 0 ou WACC <= g: DCF null', () {
      expect(
        computeDcf(
          fcff0: -1,
          growth: 0.05,
          terminalGrowth: 0.02,
          wacc: 0.08,
          years: 5,
          netDebt: 0,
          shares: 1,
        ),
        isNull,
      );
      expect(
        computeDcf(
          fcff0: 1,
          growth: 0.05,
          terminalGrowth: 0.08,
          wacc: 0.08,
          years: 5,
          netDebt: 0,
          shares: 1,
        ),
        isNull,
      );
    });

    test('sem dívida líquida ou sem ações: valor por ação null, o resto calcula-se', () {
      final r = computeDcf(
        fcff0: 10,
        growth: 0.05,
        terminalGrowth: 0.02,
        wacc: 0.08,
        years: 5,
        netDebt: null,
        shares: 1,
      )!;
      expect(r.valuePerShare, isNull);
      expect(r.sumPv, greaterThan(0));
      final r2 = computeDcf(
        fcff0: 10,
        growth: 0.05,
        terminalGrowth: 0.02,
        wacc: 0.08,
        years: 5,
        netDebt: 0,
        shares: 0,
      )!;
      expect(r2.valuePerShare, isNull);
    });

    test('valor intrínseco não positivo: margem de segurança null', () {
      expect(safetyMargin(0, 10), isNull);
      expect(safetyMargin(-3, 10), isNull);
      expect(safetyMargin(null, 10), isNull);
    });

    test('empresa sem demonstrações: métricas do DCF null; o Ke só depende do beta (1,0)', () {
      final ms = dcfMetrics(
        const Financials(symbol: 'X'),
        const MarketSnapshot(symbol: 'X', price: 10),
      );
      for (final m in ms.where((m) => m.key != 'ke')) {
        expect(m.value, isNull, reason: m.key);
      }
      _close(_m(ms, 'ke'), capmKe(rf: 0.04, beta: 1, mrp: 0.055));
      expect(ms.map((m) => m.key).toSet(), dcfInfo.map((i) => i.key).toSet());
    });
  });

  group('dcfMetrics com AAPL (fixtures reais)', () {
    test('devolve valores finitos e cenários ordenados', () async {
      final f = await _yahoo().financials('AAPL');
      const snap = MarketSnapshot(
        symbol: 'AAPL',
        currency: 'USD',
        price: 355.42,
        marketCap: 3000000000000.0,
        sharesOutstanding: 14800000000.0,
        beta: 1.07,
      );
      final ms = dcfMetrics(f, snap);
      final fc = _m(ms, 'fcff');
      final wacc = _m(ms, 'wacc');
      final ke = _m(ms, 'ke');
      expect(fc, isNotNull);
      expect(ke, closeTo(0.04 + 1.07 * 0.055, 1e-12));
      expect(wacc, isNotNull);
      expect(wacc!, lessThan(ke!));
      final pess = _m(ms, 'dcf_scenario_pessimistic')!;
      final base = _m(ms, 'dcf_scenario_base')!;
      final opt = _m(ms, 'dcf_scenario_optimistic')!;
      expect(pess, lessThan(base));
      expect(opt, greaterThan(base));
      expect(_m(ms, 'dcf_value_per_share'), closeTo(base, 1e-9));
      expect(_m(ms, 'dcf_margin_of_safety'), closeTo(1 - 355.42 / base, 1e-9));
      expect(_m(ms, 'dcf_implied_growth'), isNotNull);
    });

    test(
      'premissas editáveis: taxa e beta do utilizador substituem os calculados',
      () async {
        final f = await _yahoo().financials('AAPL');
        const snap = MarketSnapshot(
          symbol: 'AAPL',
          price: 355.42,
          marketCap: 3e12,
          beta: 1.07,
        );
        final ms = dcfMetrics(
          f,
          snap,
          assumptions: const DcfAssumptions(
            beta: 1.2,
            taxRate: 0.15,
            terminalGrowth: 0.02,
          ),
        );
        _close(_m(ms, 'ke'), capmKe(rf: 0.04, beta: 1.2, mrp: 0.055));
      },
    );
  });

  group('cobertura das fichas', () {
    test(
      'cada chave devolvida tem ficha, sem duplicados, com textos preenchidos',
      () {
        final ms = dcfMetrics(
          const Financials(symbol: 'X'),
          const MarketSnapshot(symbol: 'X'),
        );
        final keys = ms.map((m) => m.key).toList();
        expect(keys.toSet().length, keys.length, reason: 'chaves duplicadas');
        final infoKeys = dcfInfo.map((i) => i.key).toList();
        expect(
          infoKeys.toSet().length,
          infoKeys.length,
          reason: 'fichas duplicadas',
        );
        expect(infoKeys.toSet(), keys.toSet());
        for (final i in dcfInfo) {
          expect(i.namePt, isNotEmpty, reason: i.key);
          expect(i.nameEn, isNotEmpty, reason: i.key);
          expect(i.meaningPt, isNotEmpty, reason: i.key);
          expect(i.meaningEn, isNotEmpty, reason: i.key);
          expect(i.readPt, isNotEmpty, reason: i.key);
          expect(i.readEn, isNotEmpty, reason: i.key);
          expect(i.formula, isNotEmpty, reason: i.key);
        }
      },
    );
  });
}
