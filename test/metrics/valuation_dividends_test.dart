import 'dart:convert';
import 'dart:io';

import 'package:financas/invest/data/yahoo_market_data.dart';
import 'package:financas/invest/metrics/financials.dart';
import 'package:financas/invest/metrics/metric_info.dart';
import 'package:financas/invest/metrics/valuation_dividends.dart';
import 'package:financas/invest/metrics/valuation_dividends_info.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../invest_data/support.dart';

YahooMarketData _yahoo() => YahooMarketData(
  client: mock((r) => timeseriesRoute(r) ?? http.Response('', 404)),
  now: () => DateTime(2026, 11, 12),
);

/// Valor de uma chave no resultado.
double? _v(List<Metric> ms, String chave) =>
    ms.firstWhere((x) => x.key == chave).value;

/// Compara com tolerância relativa de 1e-9 (como os golden).
void _esperaRel(double? obtido, num esperado) {
  expect(obtido, isNotNull, reason: 'valor em falta (esperado $esperado)');
  expect(obtido!, closeTo(esperado.toDouble(), esperado.abs() * 1e-9));
}

/// Período anual mínimo, só com o que os testes precisam.
FinPeriod _ano(
  int ano, {
  double? eps,
  double? equity,
  double? totalDebt,
  double? cash,
}) => FinPeriod(
  end: DateTime(ano, 12, 31),
  annual: true,
  dilutedEps: eps,
  equity: equity,
  totalDebt: totalDebt,
  cash: cash,
);

void main() {
  group('Golden AAPL (período = último anual, como o golden)', () {
    late Map g;
    late Financials f;
    late MarketSnapshot m;
    late double preco;

    setUpAll(() async {
      final f0 = await _yahoo().financials('AAPL');
      // Sem TTM: o golden usa annual.last e annual[len-2] para tudo.
      f = Financials(
        symbol: f0.symbol,
        currency: f0.currency,
        annual: f0.annual,
        quarterly: f0.quarterly,
      );
      g = jsonDecode(
        File('test/fixtures/golden_aapl.json').readAsStringSync(),
      ) as Map;
      preco = (g['ultimo_preco'] as num).toDouble();
      // A capitalização de teste do golden (3 biliões), usada no EV e no rendimento EV/EBIT.
      m = MarketSnapshot(
        symbol: 'AAPL',
        currency: 'USD',
        price: preco,
        marketCap: (g['altman_z_market_cap'] as num).toDouble(),
      );
    });

    test('EV, rendimento EV/EBIT e shareholder yield batem com o golden', () {
      final val = valuationMetrics(f, m);
      final div = dividendMetrics(f, m);
      _esperaRel(_v(val, 'ev'), g['ev'] as num);
      _esperaRel(_v(val, 'earnings_yield_ev'), g['earnings_yield_ev'] as num);
      _esperaRel(_v(div, 'shareholder_yield'), g['shareholder_yield'] as num);
    });

    test('fórmula mágica: ROC de Greenblatt e ROIC batem com o golden', () {
      final val = valuationMetrics(f, m);
      _esperaRel(_v(val, 'magic_formula_roc'), g['greenblatt_roc'] as num);
      _esperaRel(_v(val, 'magic_formula_roic'), g['roic'] as num);
    });

    test('P/E trailing e P/B batem com o EPS e o VPA do golden', () {
      final val = valuationMetrics(f, m);
      _esperaRel(_v(val, 'pe_trailing'), preco / (g['eps'] as num));
      _esperaRel(_v(val, 'pb'), preco / (g['bvps'] as num));
    });

    test('payout sobre o lucro bate com o golden', () {
      final div = dividendMetrics(f, m);
      _esperaRel(_v(div, 'payout_ratio'), g['payout_ratio'] as num);
    });

    test('capitalização de teste e CAPE não disponível', () {
      final val = valuationMetrics(f, m);
      expect(_v(val, 'market_cap'), 3e12);
      expect(_v(val, 'cape'), isNull);
    });
  });

  group('Casos pequenos feitos à mão', () {
    // Quatro anuais: EPS 1,0 → 1,2 → 1,44 → 1,728 (CAGR 3 anos = 20 %).
    // Último anual: capitalização 1000, EV = 1000 + 300 − 100 + 10 + 5 = 1215.
    final anuais = [
      FinPeriod(
        end: DateTime(2022, 12, 31),
        annual: true,
        dilutedEps: 1.0,
        netIncome: 100,
        dilutedShares: 100,
      ),
      FinPeriod(
        end: DateTime(2023, 12, 31),
        annual: true,
        dilutedEps: 1.2,
        netIncome: 120,
        dilutedShares: 100,
      ),
      FinPeriod(
        end: DateTime(2024, 12, 31),
        annual: true,
        dilutedEps: 1.44,
        netIncome: 144,
        dilutedShares: 100,
        equity: 450,
        totalDebt: 280,
        cash: 80,
      ),
      FinPeriod(
        end: DateTime(2025, 12, 31),
        annual: true,
        revenue: 800,
        ebitda: 250,
        operatingIncome: 150,
        ebit:
            160, // o resultado operacional tem prioridade sobre o EBIT da fonte
        netIncome: 250,
        pretaxIncome: 150,
        taxProvision: 30, // taxa 20 %
        dilutedEps: 1.728,
        dilutedShares: 100,
        sharesOutstanding: 100,
        equity: 500,
        tangibleBookValue: 400,
        totalDebt: 300,
        cash: 100,
        minorityInterest: 10,
        preferredStock: 5,
        currentAssets: 500,
        currentLiabilities: 300,
        currentDebt: 50,
        netPpe: 200,
        operatingCashFlow: 300,
        capex: -100,
        dividendsPaid: -50,
        buybacks: -150,
        stockIssuance: 50,
      ),
    ];
    final f = Financials(symbol: 'TST', currency: 'USD', annual: anuais);
    final m = MarketSnapshot(
      symbol: 'TST',
      price: 24,
      marketCap: 1000,
      forwardEps: 2,
      dividendPerShare: 0.48,
    );

    test('avaliação: múltiplos calculados à mão', () {
      final val = valuationMetrics(f, m);
      _esperaRel(_v(val, 'ev'), 1215);
      _esperaRel(_v(val, 'pe_ttm'), 24 / 1.728);
      _esperaRel(_v(val, 'pe_trailing'), 24 / 1.728);
      _esperaRel(_v(val, 'pe_forward'), 12);
      _esperaRel(_v(val, 'earnings_yield'), 1.728 / 24);
      // PEG = 13,888… / (20 × 100 / 100)... = (24/1,728) / (0,2 × 100)
      _esperaRel(_v(val, 'peg'), (24 / 1.728) / 20);
      _esperaRel(_v(val, 'pb'), 24 / 5); // VPA = 500 / 100
      _esperaRel(_v(val, 'p_tbv'), 6); // VPTA = 400 / 100
      _esperaRel(_v(val, 'ps'), 1.25);
      _esperaRel(_v(val, 'p_fcf'), 5); // FCF = 300 − 100 = 200
      _esperaRel(_v(val, 'fcf_yield'), 0.2);
      _esperaRel(_v(val, 'ev_ebit'), 1215 / 150);
      _esperaRel(_v(val, 'ev_ebitda'), 1215 / 250);
      _esperaRel(_v(val, 'ev_revenue'), 1215 / 800);
      _esperaRel(_v(val, 'ev_fcf'), 1215 / 200);
      _esperaRel(_v(val, 'earnings_yield_ev'), 150 / 1215);
    });

    test('fórmula mágica: ROC de Greenblatt e ROIC à mão', () {
      final val = valuationMetrics(f, m);
      // Fundo de maneio líquido = (500 − 100) − (300 − 50) = 150; ROC = 150 / (150 + 200)
      _esperaRel(_v(val, 'magic_formula_roc'), 150 / 350);
      // NOPAT = 150 × 0,8 = 120; capital médio = (700 + 650) / 2 = 675
      _esperaRel(_v(val, 'magic_formula_roic'), 120 / 675);
    });

    test('dividendos e retorno aos acionistas à mão', () {
      final div = dividendMetrics(f, m);
      _esperaRel(_v(div, 'dividend_yield'), 0.02);
      _esperaRel(_v(div, 'payout_ratio'), 50 / 250);
      _esperaRel(_v(div, 'payout_fcf'), 50 / 200);
      // recompras líquidas = 150 − 50 = 100
      _esperaRel(_v(div, 'buyback_yield'), 100 / 1000);
      _esperaRel(_v(div, 'shareholder_yield'), (50 + 100) / 1000);
      // sem histórico de dividendos: crescimento e anos consecutivos são nulos
      expect(_v(div, 'dividend_growth'), isNull);
      expect(_v(div, 'dividend_consecutive_years'), isNull);
    });

    test('histórico de dividendos: ano civil completo e anos consecutivos', () {
      final historico = <DateTime, double>{
        DateTime(2020, 3, 1): 0.5,
        DateTime(2020, 9, 1): 0.5, // 2020 soma 1,0
        DateTime(2021, 6, 1): 1.1,
        DateTime(2022, 6, 1): 1.2,
        DateTime(2023, 6, 1): 1.2,
        DateTime(2024, 6, 1): 1.3,
        DateTime(2025, 6, 1): 1.4,
        DateTime(2026, 2, 1): 9.9, // ano corrente: fica de fora
      };
      final div = dividendMetrics(
        f,
        m,
        dividendHistory: historico,
        agora: DateTime(2026, 11, 12),
      );
      // Último ano completo 2025: 1,4 / 1,3 − 1
      _esperaRel(_v(div, 'dividend_growth'), 1.4 / 1.3 - 1);
      // 2025 > 2024 e 2024 > 2023; 2023 (1,2) não é > 2022 (1,2): dá 2 anos
      expect(_v(div, 'dividend_consecutive_years'), 2);
    });
  });

  group('Dados em falta e divisão por zero', () {
    test('sem demonstrações nem preço: tudo nulo e sem exceções', () {
      const f = Financials(symbol: 'VAZIO');
      const m = MarketSnapshot(symbol: 'VAZIO');
      final val = valuationMetrics(f, m);
      final div = dividendMetrics(
        f,
        m,
        dividendHistory: {DateTime(2025, 5, 1): 1.0},
        agora: DateTime(2026, 1, 1),
      );
      for (final x in [...val, ...div]) {
        if (x.key == 'cape' ||
            x.key == 'dividend_growth' ||
            x.key == 'dividend_consecutive_years')
          continue;
        expect(x.value, isNull, reason: x.key);
      }
    });

    test('EPS negativo: P/E e PEG nulos; rendimento dos lucros negativo', () {
      final f = Financials(
        symbol: 'P',
        annual: [
          _ano(2022, eps: 1.0),
          _ano(2023, eps: 0.8),
          _ano(2024, eps: 0.5),
          _ano(2025, eps: -0.2),
        ],
      );
      final val = valuationMetrics(
        f,
        const MarketSnapshot(symbol: 'P', price: 20),
      );
      expect(_v(val, 'pe_ttm'), isNull);
      expect(_v(val, 'pe_trailing'), isNull);
      expect(_v(val, 'peg'), isNull);
      _esperaRel(_v(val, 'earnings_yield'), -0.2 / 20);
    });

    test('dívida ou caixa em falta: EV nulo, e os múltiplos de EV também', () {
      final f = Financials(
        symbol: 'D',
        annual: [
          FinPeriod(
            end: DateTime(2025, 12, 31),
            annual: true,
            ebit: 100,
            cash: 10,
          ),
        ],
      );
      final val = valuationMetrics(
        f,
        const MarketSnapshot(symbol: 'D', marketCap: 1000),
      );
      expect(_v(val, 'ev'), isNull);
      expect(_v(val, 'ev_ebit'), isNull);
      expect(_v(val, 'earnings_yield_ev'), isNull);
    });

    test('capitais próprios negativos: P/B nulo; FCF negativo: P/FCF e payout de FCF nulos', () {
      final f = Financials(
        symbol: 'N',
        annual: [
          FinPeriod(
            end: DateTime(2025, 12, 31),
            annual: true,
            equity: -100,
            sharesOutstanding: 10,
            operatingCashFlow: 50,
            capex: -80, // FCF = −30
            dividendsPaid: -20,
            netIncome: 40,
          ),
        ],
      );
      const m = MarketSnapshot(symbol: 'N', price: 10, marketCap: 500);
      final val = valuationMetrics(f, m);
      final div = dividendMetrics(f, m);
      expect(_v(val, 'pb'), isNull);
      expect(_v(val, 'p_fcf'), isNull);
      expect(_v(div, 'payout_fcf'), isNull);
      _esperaRel(_v(div, 'payout_ratio'), 20 / 40);
    });

    test('resultado líquido negativo: payout nulo; recompras sem dados: shareholder yield nulo', () {
      final f = Financials(
        symbol: 'R',
        annual: [
          FinPeriod(
            end: DateTime(2025, 12, 31),
            annual: true,
            netIncome: -5,
            dividendsPaid: -2,
          ),
        ],
      );
      const m = MarketSnapshot(symbol: 'R', price: 10, marketCap: 500);
      final div = dividendMetrics(f, m);
      expect(_v(div, 'payout_ratio'), isNull);
      expect(_v(div, 'shareholder_yield'), isNull);
    });

    test('ROIC com capital investido médio ≤ 0 dá nulo', () {
      final f = Financials(
        symbol: 'C',
        annual: [
          _ano(2024, equity: -500, totalDebt: 0, cash: 0),
          FinPeriod(
            end: DateTime(2025, 12, 31),
            annual: true,
            operatingIncome: 100,
            taxProvision: 10,
            pretaxIncome: 100,
            equity: -100,
            totalDebt: 0,
            cash: 0,
          ),
        ],
      );
      final val = valuationMetrics(
        f,
        const MarketSnapshot(symbol: 'C', price: 10, marketCap: 100),
      );
      expect(_v(val, 'magic_formula_roic'), isNull);
    });
  });

  group('TTM: a média do capital investido usa o trimestre de há um ano', () {
    test('ROIC usa o trimestre a ~365 dias, e não o anual nem trimestres fora do intervalo', () {
      final f = Financials(
        symbol: 'T',
        annual: [
          _ano(2025, equity: 9000, totalDebt: 0, cash: 0), // não deve entrar
        ],
        quarterly: [
          FinPeriod(
            end: DateTime(2025, 6, 30),
            annual: false,
            equity: 400,
            totalDebt: 250,
            cash: 50,
          ), // IC 600
          FinPeriod(
            end: DateTime(2026, 3, 31),
            annual: false,
            equity: 1,
            totalDebt: 1,
            cash: 0,
          ), // fora do intervalo
        ],
        ttm: FinPeriod(
          end: DateTime(2026, 6, 30),
          annual: true,
          operatingIncome: 150,
          taxProvision: 30,
          pretaxIncome: 150,
          equity: 500,
          totalDebt: 300,
          cash: 100, // IC 700
        ),
      );
      final val = valuationMetrics(
        f,
        const MarketSnapshot(symbol: 'T', price: 10, marketCap: 1000),
      );
      // NOPAT = 150 × 0,8 = 120; capital médio = (700 + 600) / 2 = 650
      _esperaRel(_v(val, 'magic_formula_roic'), 120 / 650);
    });
  });

  group('Cobertura da ficha (MetricInfo)', () {
    final f = Financials(
      symbol: 'C',
      annual: [
        _ano(2024, eps: 1, equity: 1, totalDebt: 1, cash: 1),
        _ano(2025, eps: 2, equity: 2, totalDebt: 2, cash: 2),
      ],
    );
    final m = MarketSnapshot(
      symbol: 'C',
      price: 10,
      marketCap: 100,
      dividendPerShare: 0.1,
    );
    final historico = {DateTime(2024, 5, 1): 0.1, DateTime(2025, 5, 1): 0.2};
    final todas = [
      ...valuationMetrics(f, m),
      ...dividendMetrics(
        f,
        m,
        dividendHistory: historico,
        agora: DateTime(2026, 11, 12),
      ),
    ];
    final vazias = [
      ...valuationMetrics(
        const Financials(symbol: 'X'),
        const MarketSnapshot(symbol: 'X'),
      ),
      ...dividendMetrics(
        const Financials(symbol: 'X'),
        const MarketSnapshot(symbol: 'X'),
      ),
    ];

    test('cada chave devolvida tem uma ficha, sem duplicados', () {
      final chaves = todas.map((x) => x.key).toList();
      expect(chaves.toSet().length, chaves.length, reason: 'chaves duplicadas');
      final fichas = valuationDividendsInfo.map((x) => x.key).toList();
      expect(fichas.toSet().length, fichas.length, reason: 'fichas duplicadas');
      expect(fichas.toSet(), chaves.toSet());
    });

    test('mesmas chaves mesmo sem dados (com valor nulo)', () {
      expect(vazias.map((x) => x.key).toSet(), todas.map((x) => x.key).toSet());
    });

    test('textos preenchidos em PT e EN; CAPE não disponível', () {
      for (final MetricInfo i in valuationDividendsInfo) {
        expect(i.namePt.trim(), isNotEmpty, reason: i.key);
        expect(i.nameEn.trim(), isNotEmpty, reason: i.key);
        expect(i.meaningPt.trim(), isNotEmpty, reason: i.key);
        expect(i.meaningEn.trim(), isNotEmpty, reason: i.key);
        expect(i.readPt.trim(), isNotEmpty, reason: i.key);
        expect(i.readEn.trim(), isNotEmpty, reason: i.key);
        expect(i.formula.trim(), isNotEmpty, reason: i.key);
      }
      final cape = valuationDividendsInfo.firstWhere((x) => x.key == 'cape');
      expect(cape.availability, MetricAvailability.unavailable);
    });
  });

  group('Correções da revisão (F1)', () {
    test('E1: EV/EBITDA usa EBIT + D&A e não o ebitda do Yahoo', () {
      final f = Financials(
        symbol: 'X',
        annual: [
          FinPeriod(
            end: DateTime(2025, 12, 31),
            annual: true,
            operatingIncome: 100,
            depreciationAmortization: 20,
            ebitda: 770,
            totalDebt: 200,
            cash: 100,
          ),
        ],
      );
      final v = valuationMetrics(
        f,
        const MarketSnapshot(symbol: 'X', price: 10, marketCap: 1000),
      );
      // EV = 1000 + 200 − 100 = 1100; EBITDA = 120
      _esperaRel(_v(v, 'ev_ebitda'), 1100 / 120);
    });

    test(
      'R1: banco dá null em EV, múltiplos de EV, FCF; P/B e EPS mantêm-se',
      () {
        final f = Financials(
          symbol: 'B',
          annual: [
            FinPeriod(
              end: DateTime(2025, 12, 31),
              annual: true,
              revenue: 1000,
              netIncome: 200,
              dilutedEps: 2,
              equity: 1500,
              tangibleBookValue: 1200,
              sharesOutstanding: 100,
              totalDebt: 5000,
              cash: 800,
              operatingCashFlow: -300,
              capex: -20,
              dividendsPaid: -50,
            ),
          ],
        );
        const m = MarketSnapshot(
          symbol: 'B',
          price: 30,
          marketCap: 3000,
          dividendPerShare: 0.5,
        );
        final v = valuationMetrics(f, m);
        for (final k in [
          'ev',
          'ev_ebit',
          'ev_ebitda',
          'ev_revenue',
          'ev_fcf',
          'p_fcf',
          'fcf_yield',
          'earnings_yield_ev',
          'magic_formula_roic',
        ]) {
          expect(_v(v, k), isNull, reason: k);
        }
        _esperaRel(_v(v, 'pb'), 2);
        _esperaRel(_v(v, 'p_tbv'), 2.5);
        _esperaRel(_v(v, 'pe_ttm'), 15);
        final d = dividendMetrics(f, m);
        expect(_v(d, 'payout_fcf'), isNull);
        _esperaRel(_v(d, 'dividend_yield'), 0.5 / 30);
      },
    );

    test('R3: o primeiro ano do histórico, parcial, fica fora', () {
      final h = <DateTime, double>{
        DateTime(2021, 12, 15): 0.1,
        DateTime(2022, 6, 1): 0.4,
        DateTime(2023, 6, 1): 0.5,
        DateTime(2024, 6, 1): 0.6,
        DateTime(2025, 6, 1): 0.7,
      };
      final d = dividendMetrics(
        const Financials(symbol: 'X'),
        const MarketSnapshot(symbol: 'X', price: 10),
        dividendHistory: h,
        agora: DateTime(2026, 11, 12),
      );
      expect(_v(d, 'dividend_consecutive_years'), 3);
      _esperaRel(_v(d, 'dividend_growth'), 0.7 / 0.6 - 1);
    });

    test('R3: se o histórico começa em janeiro, o primeiro ano conta', () {
      final h = <DateTime, double>{
        DateTime(2022, 1, 10): 0.4,
        DateTime(2023, 6, 1): 0.5,
        DateTime(2024, 6, 1): 0.6,
        DateTime(2025, 6, 1): 0.7,
      };
      final d = dividendMetrics(
        const Financials(symbol: 'X'),
        const MarketSnapshot(symbol: 'X', price: 10),
        dividendHistory: h,
        agora: DateTime(2026, 11, 12),
      );
      expect(_v(d, 'dividend_consecutive_years'), 3);
    });

    test('E2: ADR em base diferente: P/B e P/TBV são null', () {
      final f = Financials(
        symbol: 'TSM',
        annual: [
          FinPeriod(
            end: DateTime(2025, 12, 31),
            annual: true,
            equity: 1000,
            tangibleBookValue: 900,
            sharesOutstanding: 500,
          ),
        ],
      );
      const adr = MarketSnapshot(
        symbol: 'TSM',
        price: 10,
        sharesOutstanding: 100,
        marketCap: 1000,
      );
      final v = valuationMetrics(f, adr);
      expect(_v(v, 'pb'), isNull);
      expect(_v(v, 'p_tbv'), isNull);
      const igual = MarketSnapshot(
        symbol: 'TSM',
        price: 10,
        sharesOutstanding: 500,
        marketCap: 5000,
      );
      _esperaRel(_v(valuationMetrics(f, igual), 'pb'), 10 / 2);
    });

    test('E1 forwardEps: só com a mesma moeda de reporte e de cotação', () {
      const f = Financials(symbol: 'X');
      const mesma = MarketSnapshot(symbol: 'X', price: 100, forwardEps: 5);
      _esperaRel(_v(valuationMetrics(f, mesma), 'pe_forward'), 20);
      const outra = MarketSnapshot(
        symbol: 'X',
        currency: 'TWD',
        quoteCurrency: 'USD',
        price: 100,
        forwardEps: 5,
      );
      expect(_v(valuationMetrics(f, outra), 'pe_forward'), isNull);
    });
  });
}
