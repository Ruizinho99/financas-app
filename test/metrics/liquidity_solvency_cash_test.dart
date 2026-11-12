import 'dart:convert';
import 'dart:io';
import 'dart:math' show max;

import 'package:financas/invest/data/yahoo_market_data.dart';
import 'package:financas/invest/metrics/financials.dart';
import 'package:financas/invest/metrics/liquidity_solvency_cash.dart';
import 'package:financas/invest/metrics/metric_info.dart';
import 'package:financas/invest/metrics/liquidity_solvency_cash_info.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../invest_data/support.dart';

YahooMarketData _yahoo() => YahooMarketData(
  client: mock((r) => timeseriesRoute(r) ?? http.Response('', 404)),
  now: () => DateTime(2026, 11, 12),
);

/// Sem TTM e sem trimestres: `latest` é o último anual e `prev` o anual anterior (como no golden).
Financials _soAnuais(Financials f) =>
    Financials(symbol: f.symbol, currency: f.currency, annual: f.annual);

Metric _m(List<Metric> ms, String key) =>
    ms.firstWhere((m) => m.key == key, orElse: () => throw 'sem a chave $key');

/// Chaves de todas as funções do módulo, para os testes de cobertura.
List<Metric> _todas(Financials f) => [
  ...liquidityMetrics(f),
  ...solvencyMetrics(f),
  ...cashFlowMetrics(f),
  ...perShareMetrics(f),
];

void main() {
  late Map golden;
  setUpAll(() {
    golden = jsonDecode(
      File('test/fixtures/golden_aapl.json').readAsStringSync(),
    ) as Map;
  });

  group('valores AAPL contra o golden (fonte: fixtures Yahoo reais)', () {
    test(
      'liquidez, solvência, fluxo de caixa e por ação batem com o golden',
      () async {
        final f = _soAnuais(await _yahoo().financials('AAPL'));
        final liq = liquidityMetrics(f);
        final sol = solvencyMetrics(f);
        final cf = cashFlowMetrics(f);
        final ps = perShareMetrics(f);

        final esperado = <String, List<Metric>>{
          'current_ratio': liq,
          'quick_ratio': liq,
          'cash_ratio': liq,
          'working_capital': liq,
          'net_debt': sol,
          'net_debt_to_ebitda': sol,
          'debt_to_equity': sol,
          'interest_coverage': sol,
          'net_debt_to_fcf': sol,
          'fcf': cf,
          'fcf_reported': cf,
          'fcf_after_sbc': cf,
          'cash_conversion': cf,
          'sloan_accruals': cf,
          'capex_to_revenue': cf,
          'capex_to_da': cf,
          'owner_earnings': cf,
          'maintenance_capex': cf,
          'eps': ps,
          'bvps': ps,
          'fcf_per_share': ps,
          'share_dilution': ps,
        };
        for (final entrada in esperado.entries) {
          final valor = _m(entrada.value, entrada.key).value;
          final e = golden[entrada.key];
          if (e == null) {
            expect(valor, isNull, reason: entrada.key);
          } else {
            final ref = (e as num).toDouble();
            expect(
              valor,
              closeTo(ref, 1e-9 * max(1.0, ref.abs())),
              reason: entrada.key,
            );
          }
        }
      },
    );

    test(
      'cobertura de juros da AAPL é null (sem juros na fonte), como no golden',
      () async {
        final f = _soAnuais(await _yahoo().financials('AAPL'));
        expect(golden['interest_coverage'], isNull);
        expect(_m(solvencyMetrics(f), 'interest_coverage').value, isNull);
      },
    );

    test(
      'dívida líquida e capex são os da fixture, com capex positivo',
      () async {
        final f = await _yahoo().financials('AAPL');
        final a = f.lastAnnual!;
        final ms = cashFlowMetrics(_soAnuais(f));
        expect(_m(ms, 'capex').value, a.capexSpent);
        expect(_m(ms, 'capex').value!, greaterThan(0));
        expect(
          _m(solvencyMetrics(_soAnuais(f)), 'net_debt').value,
          a.totalDebt! - a.cash!,
        );
      },
    );

    test(
      'caixa do golden: fcf = CFO − |capex| e fcf_reported = freeCashFlow',
      () async {
        final f = _soAnuais(await _yahoo().financials('AAPL'));
        final ms = cashFlowMetrics(f);
        expect(_m(ms, 'fcf').value, golden['fcf']);
        expect(_m(ms, 'fcf_reported').value, golden['fcf_reported']);
      },
    );
  });

  group('TTM e base temporal', () {
    test('"médio" do TTM usa o trimestre ~1 ano antes (Sloan)', () {
      final ttm = FinPeriod(
        end: DateTime(2026, 6, 30),
        annual: true,
        netIncome: 100,
        operatingCashFlow: 80,
        totalAssets: 200,
      );
      final anterior = FinPeriod(
        end: DateTime(2025, 6, 30),
        annual: false,
        totalAssets: 100,
      );
      final f = Financials(
        symbol: 'X',
        currency: 'USD',
        quarterly: [anterior],
        ttm: ttm,
      );
      // ativo médio = (200 + 100) / 2 = 150; Sloan = (100 − 80) / 150
      expect(
        _m(cashFlowMetrics(f), 'sloan_accruals').value,
        closeTo(20 / 150, 1e-12),
      );
    });

    test('TTM sem período de ~1 ano antes: média só com o saldo corrente', () {
      final ttm = FinPeriod(
        end: DateTime(2026, 6, 30),
        annual: true,
        netIncome: 100,
        operatingCashFlow: 80,
        totalAssets: 200,
      );
      final f = Financials(symbol: 'X', currency: 'USD', ttm: ttm);
      expect(
        _m(cashFlowMetrics(f), 'sloan_accruals').value,
        closeTo(20 / 200, 1e-12),
      );
    });

    test('o TTM é o período corrente (fluxos e saldos do latest)', () {
      final anual = FinPeriod(
        end: DateTime(2025, 9, 30),
        annual: true,
        currentAssets: 10,
        currentLiabilities: 5,
      );
      final ttm = FinPeriod(
        end: DateTime(2026, 6, 30),
        annual: true,
        currentAssets: 40,
        currentLiabilities: 20,
      );
      final f = Financials(symbol: 'X', annual: [anual], ttm: ttm);
      expect(_m(liquidityMetrics(f), 'current_ratio').value, 2);
    });
  });

  group('dados em falta e divisões por zero dão null, sem exceções', () {
    test('sem demonstrações: todas as métricas existem e são null', () {
      final f = Financials(symbol: 'X');
      final ms = _todas(f);
      expect(ms, isNotEmpty);
      for (final m in ms) {
        expect(m.value, isNull, reason: m.key);
      }
      expect(perShareMetrics(f).length, 6);
    });

    test('passivo corrente zero: rácios de liquidez null', () {
      final f = Financials(
        symbol: 'X',
        annual: [
          FinPeriod(
            end: DateTime(2025, 12, 31),
            annual: true,
            currentAssets: 100,
            currentLiabilities: 0,
            cash: 10,
            cashAndShortTermInvestments: 20,
            receivables: 5,
          ),
        ],
      );
      expect(_m(liquidityMetrics(f), 'current_ratio').value, isNull);
      expect(_m(liquidityMetrics(f), 'quick_ratio').value, isNull);
      expect(_m(liquidityMetrics(f), 'cash_ratio').value, isNull);
      expect(_m(liquidityMetrics(f), 'working_capital').value, 100);
    });

    test('quick ratio exige as três parcelas', () {
      final f = Financials(
        symbol: 'X',
        annual: [
          FinPeriod(
            end: DateTime(2025, 12, 31),
            annual: true,
            currentLiabilities: 10,
            cashAndShortTermInvestments: 20,
          ),
        ],
      );
      expect(_m(liquidityMetrics(f), 'quick_ratio').value, isNull);
    });

    test('EBITDA negativo: dívida líquida / EBITDA null', () {
      final f = Financials(
        symbol: 'X',
        annual: [
          FinPeriod(
            end: DateTime(2025, 12, 31),
            annual: true,
            currentAssets: 1, // empresa não financeira
            totalDebt: 100,
            cash: 20,
            ebitda: -5,
          ),
        ],
      );
      expect(_m(solvencyMetrics(f), 'net_debt').value, 80);
      expect(_m(solvencyMetrics(f), 'net_debt_to_ebitda').value, isNull);
    });

    test('caixa líquida: dívida líquida negativa mostra-se negativa', () {
      final f = Financials(
        symbol: 'X',
        annual: [
          FinPeriod(
            end: DateTime(2025, 12, 31),
            annual: true,
            currentAssets: 1, // empresa não financeira
            totalDebt: 10,
            cash: 30,
            ebitda: 50,
          ),
        ],
      );
      expect(_m(solvencyMetrics(f), 'net_debt').value, -20);
      expect(
        _m(solvencyMetrics(f), 'net_debt_to_ebitda').value,
        closeTo(-0.4, 1e-12),
      );
    });

    test('capitais próprios negativos: dívida / capitais próprios null', () {
      final f = Financials(
        symbol: 'X',
        annual: [
          FinPeriod(
            end: DateTime(2025, 12, 31),
            annual: true,
            totalDebt: 100,
            equity: -50,
          ),
        ],
      );
      expect(_m(solvencyMetrics(f), 'debt_to_equity').value, isNull);
    });

    test(
      'juros zero ou ausentes: cobertura null; interestPaid como alternativa',
      () {
        final semJuros = Financials(
          symbol: 'X',
          annual: [
            FinPeriod(
              end: DateTime(2025, 12, 31),
              annual: true,
              operatingIncome: 50,
              interestExpense: 0,
            ),
          ],
        );
        expect(
          _m(solvencyMetrics(semJuros), 'interest_coverage').value,
          isNull,
        );

        final comPago = Financials(
          symbol: 'X',
          annual: [
            FinPeriod(
              end: DateTime(2025, 12, 31),
              annual: true,
              operatingIncome: 50,
              interestPaid: 10,
            ),
          ],
        );
        expect(_m(solvencyMetrics(comPago), 'interest_coverage').value, 5);
      },
    );

    test('EBIT é o resultado operacional, não o EBIT da fonte', () {
      final f = Financials(
        symbol: 'X',
        annual: [
          FinPeriod(
            end: DateTime(2025, 12, 31),
            annual: true,
            operatingIncome: 40,
            ebit: 90,
            interestExpense: 10,
          ),
        ],
      );
      expect(_m(solvencyMetrics(f), 'interest_coverage').value, 4);
    });

    test('FCF ≤ 0: dívida líquida / FCF null', () {
      final f = Financials(
        symbol: 'X',
        annual: [
          FinPeriod(
            end: DateTime(2025, 12, 31),
            annual: true,
            totalDebt: 100,
            cash: 10,
            operatingCashFlow: 20,
            capex: -30,
          ),
        ],
      );
      expect(_m(solvencyMetrics(f), 'net_debt_to_fcf').value, isNull);
    });

    test('FCF cai para o freeCashFlow da fonte se faltar CFO ou capex', () {
      final f = Financials(
        symbol: 'X',
        annual: [
          FinPeriod(
            end: DateTime(2025, 12, 31),
            annual: true,
            currentAssets: 1, // empresa não financeira
            freeCashFlow: 77,
          ),
        ],
      );
      expect(_m(cashFlowMetrics(f), 'fcf').value, 77);
    });

    test(
      'capex de manutenção e de crescimento: min(|capex|, D&A) e o resto',
      () {
        final f = Financials(
          symbol: 'X',
          annual: [
            FinPeriod(
              end: DateTime(2025, 12, 31),
              annual: true,
              currentAssets: 1, // empresa não financeira
              capex: -100,
              depreciationAmortization: 60,
              netIncome: 50,
              changeInWorkingCapital: -10,
            ),
          ],
        );
        final ms = cashFlowMetrics(f);
        expect(_m(ms, 'maintenance_capex').value, 60);
        expect(_m(ms, 'growth_capex').value, 40);
        // owner earnings = 50 + 60 − 60 + (−10)
        expect(_m(ms, 'owner_earnings').value, 40);
      },
    );

    test('conversão de caixa com resultado ≤ 0 é null', () {
      final f = Financials(
        symbol: 'X',
        annual: [
          FinPeriod(
            end: DateTime(2025, 12, 31),
            annual: true,
            operatingCashFlow: 10,
            netIncome: -5,
          ),
        ],
      );
      expect(_m(cashFlowMetrics(f), 'cash_conversion').value, isNull);
    });

    test('capex / D&A com amortizações nulas é null', () {
      final f = Financials(
        symbol: 'X',
        annual: [
          FinPeriod(
            end: DateTime(2025, 12, 31),
            annual: true,
            capex: -10,
            revenue: 100,
          ),
        ],
      );
      expect(_m(cashFlowMetrics(f), 'capex_to_da').value, isNull);
      expect(
        _m(cashFlowMetrics(f), 'capex_to_revenue').value,
        closeTo(0.1, 1e-12),
      );
    });

    test('EPS usa dilutedEps e, sem ele, resultado / ações diluídas', () {
      final com = Financials(
        symbol: 'X',
        annual: [
          FinPeriod(
            end: DateTime(2025, 12, 31),
            annual: true,
            dilutedEps: 2.5,
            netIncome: 100,
            dilutedShares: 10,
          ),
        ],
      );
      expect(_m(perShareMetrics(com), 'eps').value, 2.5);
      final sem = Financials(
        symbol: 'X',
        annual: [
          FinPeriod(
            end: DateTime(2025, 12, 31),
            annual: true,
            netIncome: 100,
            dilutedShares: 40,
          ),
        ],
      );
      expect(_m(perShareMetrics(sem), 'eps').value, 2.5);
    });

    test('diluição com um só anual: null; recompras dão negativo', () {
      final um = Financials(
        symbol: 'X',
        annual: [
          FinPeriod(
            end: DateTime(2025, 12, 31),
            annual: true,
            sharesOutstanding: 100,
          ),
        ],
      );
      expect(_m(perShareMetrics(um), 'share_dilution').value, isNull);
      final dois = Financials(
        symbol: 'X',
        annual: [
          FinPeriod(
            end: DateTime(2024, 12, 31),
            annual: true,
            sharesOutstanding: 100,
          ),
          FinPeriod(
            end: DateTime(2025, 12, 31),
            annual: true,
            sharesOutstanding: 95,
          ),
        ],
      );
      expect(
        _m(perShareMetrics(dois), 'share_dilution').value,
        closeTo(-0.05, 1e-12),
      );
    });

    test('DPS vem do MarketSnapshot; sem snapshot é null', () {
      final f = Financials(
        symbol: 'X',
        annual: [FinPeriod(end: DateTime(2025, 12, 31), annual: true)],
      );
      expect(_m(perShareMetrics(f), 'dps').value, isNull);
      final mercado = const MarketSnapshot(symbol: 'X', dividendPerShare: 0.96);
      expect(_m(perShareMetrics(f, market: mercado), 'dps').value, 0.96);
    });

    test(
      'maturidades e dívida a taxa variável são sempre null (não disponíveis)',
      () {
        final f = Financials(symbol: 'X');
        expect(_m(solvencyMetrics(f), 'debt_maturities').value, isNull);
        expect(_m(solvencyMetrics(f), 'variable_rate_debt').value, isNull);
      },
    );

    test('dívida total não soma locações: a fonte é a única referência', () {
      final f = Financials(
        symbol: 'X',
        annual: [
          FinPeriod(
            end: DateTime(2025, 12, 31),
            annual: true,
            currentAssets: 1, // empresa não financeira
            totalDebt: 100,
            cash: 10,
            leaseLiabilities: 40,
          ),
        ],
      );
      expect(_m(solvencyMetrics(f), 'net_debt').value, 90);
    });
  });

  group('cobertura das fichas (MetricInfo)', () {
    test(
      'cada chave devolvida tem uma ficha, sem duplicados, com textos',
      () async {
        final f = await _yahoo().financials('AAPL');
        final chaves = _todas(f).map((m) => m.key).toList();
        expect(
          chaves.toSet().length,
          chaves.length,
          reason: 'chaves duplicadas',
        );

        final fichas = {for (final i in liquiditySolvencyCashInfo) i.key: i};
        expect(
          fichas.length,
          liquiditySolvencyCashInfo.length,
          reason: 'fichas duplicadas',
        );
        for (final k in chaves) {
          expect(fichas.containsKey(k), isTrue, reason: 'sem ficha: $k');
        }
        for (final i in liquiditySolvencyCashInfo) {
          expect(i.namePt.trim(), isNotEmpty, reason: i.key);
          expect(i.nameEn.trim(), isNotEmpty, reason: i.key);
          expect(i.meaningPt.trim(), isNotEmpty, reason: i.key);
          expect(i.meaningEn.trim(), isNotEmpty, reason: i.key);
          expect(i.readPt.trim(), isNotEmpty, reason: i.key);
          expect(i.readEn.trim(), isNotEmpty, reason: i.key);
        }
      },
    );

    test('as "não disponível" estão marcadas como tal', () {
      final fichas = {for (final i in liquiditySolvencyCashInfo) i.key: i};
      expect(
        fichas['debt_maturities']!.availability,
        MetricAvailability.unavailable,
      );
      expect(
        fichas['variable_rate_debt']!.availability,
        MetricAvailability.unavailable,
      );
    });
  });

  group('Correções da revisão (F1)', () {
    test(
      'E1: dívida líquida / EBITDA usa EBIT + D&A e não o ebitda do Yahoo',
      () {
        final f = Financials(
          symbol: 'X',
          annual: [
            FinPeriod(
              end: DateTime(2025, 12, 31),
              annual: true,
              operatingIncome: 100,
              depreciationAmortization: 20,
              ebitda: 770,
              totalDebt: 300,
              cash: 60,
            ),
          ],
        );
        // dívida líquida 240 / (100 + 20)
        expect(
          _m(solvencyMetrics(f), 'net_debt_to_ebitda').value,
          closeTo(2.0, 1e-12),
        );
      },
    );

    test('R1: banco dá null em liquidez, dívida líquida, FCF e derivadas', () {
      final f = Financials(
        symbol: 'B',
        annual: [
          FinPeriod(
            end: DateTime(2025, 12, 31),
            annual: true,
            revenue: 1000,
            netIncome: 200,
            equity: 1500,
            totalAssets: 20000,
            totalDebt: 5000,
            cash: 800,
            receivables: 900,
            operatingCashFlow: -300,
            capex: -20,
            stockBasedComp: 10,
            depreciationAmortization: 30,
            changeInWorkingCapital: 5,
            dilutedShares: 100,
            sharesOutstanding: 100,
          ),
        ],
      );
      for (final x in [...liquidityMetrics(f), ...solvencyMetrics(f)]) {
        if (x.key == 'interest_coverage') continue;
        expect(x.value, isNull, reason: x.key);
      }
      final cf = cashFlowMetrics(f);
      for (final k in [
        'fcf',
        'fcf_after_sbc',
        'owner_earnings',
        'cash_conversion',
      ]) {
        expect(_m(cf, k).value, isNull, reason: k);
      }
      expect(_m(perShareMetrics(f), 'fcf_per_share').value, isNull);
      // BVPS mantém-se
      expect(_m(perShareMetrics(f), 'bvps').value, closeTo(15, 1e-12));
    });

    test('E2: ADR com ações em base diferente: BVPS e TBVPS são null', () {
      final f = Financials(
        symbol: 'TSM',
        annual: [
          FinPeriod(
            end: DateTime(2025, 12, 31),
            annual: true,
            equity: 1000,
            tangibleBookValue: 900,
            sharesOutstanding: 500,
            dilutedShares: 500,
          ),
        ],
      );
      // 1 ADR = 5 ações: o snapshot tem 100 ADR equivalentes
      const adr = MarketSnapshot(
        symbol: 'TSM',
        sharesOutstanding: 100,
        price: 10,
      );
      final ps = perShareMetrics(f, market: adr);
      expect(_m(ps, 'bvps').value, isNull);
      expect(_m(ps, 'tbvps').value, isNull);
      // sem snapshot, ou com a mesma base, calcula
      expect(_m(perShareMetrics(f), 'bvps').value, closeTo(2, 1e-12));
      const igual = MarketSnapshot(symbol: 'TSM', sharesOutstanding: 500);
      expect(
        _m(perShareMetrics(f, market: igual), 'bvps').value,
        closeTo(2, 1e-12),
      );
    });
  });
}
