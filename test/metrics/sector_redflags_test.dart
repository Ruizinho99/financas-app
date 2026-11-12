import 'package:financas/invest/metrics/financials.dart';
import 'package:financas/invest/metrics/metric_info.dart';
import 'package:financas/invest/metrics/sector_redflags.dart';
import 'package:financas/invest/metrics/sector_redflags_info.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exercício anual fechado a 31 de dezembro do ano dado. Só os campos usados pelos testes.
FinPeriod fp(
  int year, {
  double? revenue,
  double? costOfRevenue,
  double? grossProfit,
  double? operatingIncome,
  double? netIncome,
  double? pretaxIncome,
  double? taxProvision,
  double? operatingCashFlow,
  double? capex,
  double? equity,
  double? totalDebt,
  double? cash,
  double? cashAndShortTermInvestments,
  double? receivables,
  double? inventory,
  double? goodwill,
  double? totalAssets,
  double? impairment,
  double? acquisitions,
  double? incomeTaxPaid,
  double? specialItems,
  double? sharesOutstanding,
  double? netInterestIncome,
  double? tangibleBookValue,
  double? stockBasedComp,
  double? researchDevelopment,
}) => FinPeriod(
  end: DateTime(year, 12, 31),
  annual: true,
  revenue: revenue,
  costOfRevenue: costOfRevenue,
  grossProfit: grossProfit,
  operatingIncome: operatingIncome,
  netIncome: netIncome,
  pretaxIncome: pretaxIncome,
  taxProvision: taxProvision,
  operatingCashFlow: operatingCashFlow,
  capex: capex,
  equity: equity,
  totalDebt: totalDebt,
  cash: cash,
  cashAndShortTermInvestments: cashAndShortTermInvestments,
  receivables: receivables,
  inventory: inventory,
  goodwill: goodwill,
  totalAssets: totalAssets,
  impairment: impairment,
  acquisitions: acquisitions,
  incomeTaxPaid: incomeTaxPaid,
  specialItems: specialItems,
  sharesOutstanding: sharesOutstanding,
  netInterestIncome: netInterestIncome,
  tangibleBookValue: tangibleBookValue,
  stockBasedComp: stockBasedComp,
  researchDevelopment: researchDevelopment,
);

Financials fin(List<FinPeriod> anuais) =>
    Financials(symbol: 'TEST', currency: 'USD', annual: anuais);

Metric met(List<Metric> ms, String key) =>
    ms.firstWhere((x) => x.key == key, orElse: () => throw StateError(key));

/// Valor de uma chave de red flag (com o teste de que existe e é um alerta de 0/1 ou nulo).
double? flag(Financials f, String key) =>
    met(redFlags(f, const MarketSnapshot(symbol: 'TEST')), key).value;

/// Exercícios com todos os campos preenchidos (para o teste de cobertura).
Financials rico({bool prejuizo = false}) => fin([
  for (var y = 2021; y <= 2024; y++)
    fp(
      y,
      revenue: 1000,
      costOfRevenue: 400,
      grossProfit: 600,
      operatingIncome: 100,
      netIncome: prejuizo ? -50 : 80,
      pretaxIncome: 100,
      taxProvision: 20,
      operatingCashFlow: prejuizo ? -100 : 150,
      capex: -20,
      equity: 500,
      totalDebt: 300,
      cash: 100,
      cashAndShortTermInvestments: 600,
      receivables: 100,
      inventory: 80,
      goodwill: 200,
      totalAssets: 1000,
      impairment: 10,
      acquisitions: -30,
      incomeTaxPaid: 15,
      specialItems: 15,
      sharesOutstanding: 100 + (y - 2021).toDouble(),
      netInterestIncome: 120,
      tangibleBookValue: 400,
      stockBasedComp: 50,
      researchDevelopment: 150,
    ),
]);

void main() {
  // =========================================================================================================
  group('qualityMetrics (secções 14 e 15)', () {
    test('ROIC e margens estáveis a partir de valores feitos à mão', () {
      // EBIT 100, 120, 100, 120; imposto 20 %; capital investido 100 em todos os anos.
      // ROIC anual (anos 2 a 4): 120×0,8/100 = 0,96; 100×0,8/100 = 0,80; 120×0,8/100 = 0,96.
      // Média 0,906667; desvio amostral sqrt(0,0170667/2) = 0,092376; variação 0,96 − 0,96 = 0.
      final f = fin([
        for (final (y, ebit) in [
          (2021, 100.0),
          (2022, 120.0),
          (2023, 100.0),
          (2024, 120.0),
        ])
          fp(
            y,
            revenue: 1000,
            grossProfit: 500,
            operatingIncome: ebit,
            netIncome: ebit * 0.8,
            pretaxIncome: 100,
            taxProvision: 20,
            equity: 100,
            totalDebt: 0,
            cash: 0,
          ),
      ]);
      final ms = qualityMetrics(f);
      expect(met(ms, 'quality_roic_mean').value, closeTo(0.906667, 1e-6));
      expect(met(ms, 'quality_roic_stdev').value, closeTo(0.092376, 1e-6));
      expect(met(ms, 'quality_roic_change').value, closeTo(0, 1e-9));
      // Margem bruta constante: desvio 0 e variação 0.
      expect(met(ms, 'quality_gross_margin_stdev').value, closeTo(0, 1e-12));
      expect(met(ms, 'quality_gross_margin_change').value, closeTo(0, 1e-12));
      // Margem operacional 0,10; 0,12; 0,10; 0,12: média 0,11, desvio amostral sqrt(0,0004/3) = 0,011547,
      // variação 0,12 − 0,10 = 0,02.
      expect(
        met(ms, 'quality_operating_margin_stdev').value,
        closeTo(0.011547, 1e-6),
      );
      expect(
        met(ms, 'quality_operating_margin_change').value,
        closeTo(0.02, 1e-9),
      );
    });

    test('com dois anos não há desvio (mínimo de 3 valores) nem variação de margens com um só valor', () {
      final f = fin([
        fp(
          2023,
          revenue: 1000,
          operatingIncome: 100,
          netIncome: 80,
          pretaxIncome: 100,
          taxProvision: 20,
          equity: 100,
          totalDebt: 0,
          cash: 0,
        ),
        fp(
          2024,
          revenue: 1000,
          operatingIncome: 120,
          netIncome: 96,
          pretaxIncome: 100,
          taxProvision: 20,
          equity: 100,
          totalDebt: 0,
          cash: 0,
        ),
      ]);
      final ms = qualityMetrics(f);
      // Só há 1 ROIC (o 2.º ano), logo média sim e desvio/variação não.
      expect(met(ms, 'quality_roic_mean').value, closeTo(0.96, 1e-9));
      expect(met(ms, 'quality_roic_stdev').value, isNull);
      expect(met(ms, 'quality_roic_change').value, isNull);
    });

    test('percentagem de insiders vem do snapshot; sem snapshot fica nula', () {
      final f = rico();
      final com = qualityMetrics(
        f,
        m: const MarketSnapshot(symbol: 'TEST', insidersPercentHeld: 0.0123),
      );
      expect(met(com, 'gov_insider_ownership').value, closeTo(0.0123, 1e-12));
      expect(met(qualityMetrics(f), 'gov_insider_ownership').value, isNull);
    });

    test('secções 14 e 15 sem dados gratuitos ficam nulas', () {
      final ms = qualityMetrics(rico());
      for (final k in [
        'quality_roic_10y',
        'quality_market_share',
        'quality_recurring_revenue',
        'quality_customer_concentration',
        'quality_supplier_concentration',
        'quality_moat_sources',
        'gov_capital_allocation',
        'gov_buyback_price_discipline',
        'gov_pay_linked_to_roic_fcf',
        'gov_board_independence',
        'gov_share_classes',
        'gov_auditor_risk',
      ]) {
        expect(met(ms, k).value, isNull, reason: k);
      }
    });

    test('sem exercícios anuais não há valores e não há exceções', () {
      final ms = qualityMetrics(const Financials(symbol: 'X'));
      expect(ms.every((x) => x.value == null), isTrue);
    });
  });

  // =========================================================================================================
  group('sectorGroupOf (classificação da secção 16)', () {
    test('cada indústria/setor cai no grupo certo', () {
      final casos = <(String, String, SectorGroup)>[
        ('Banks - Regional', 'Financial Services', SectorGroup.banks),
        ('Insurance - Life', 'Financial Services', SectorGroup.insurers),
        ('REIT - Office', 'Real Estate', SectorGroup.reits),
        ('Utilities - Regulated Electric', 'Utilities', SectorGroup.utilities),
        ('Oil & Gas E&P', 'Energy', SectorGroup.commodities),
        ('Gold', 'Basic Materials', SectorGroup.commodities),
        ('Software - Application', 'Technology', SectorGroup.software),
        ('Specialty Retail', 'Consumer Cyclical', SectorGroup.retail),
        ('Drug Manufacturers - General', 'Healthcare', SectorGroup.pharma),
        ('Biotechnology', 'Healthcare', SectorGroup.pharma),
        ('Conglomerates', 'Industrials', SectorGroup.holdings),
        ('Semiconductors', 'Technology', SectorGroup.generic),
        ('', '', SectorGroup.generic),
      ];
      for (final (ind, sec, grupo) in casos) {
        expect(
          sectorGroupOf(
            MarketSnapshot(symbol: 'X', sector: sec, industry: ind),
          ),
          grupo,
          reason: '$sec / $ind',
        );
      }
    });

    test('um nome com "Holding" (sem indústria) não torna holding (correção E3)', () {
      expect(
        sectorGroupOf(
          const MarketSnapshot(symbol: 'X', name: 'Alfa Holdings SA'),
        ),
        SectorGroup.generic,
      );
    });
  });

  // =========================================================================================================
  group('sectorMetrics (secção 16)', () {
    test('bancos: margem financeira, ROTE e P/TBV calculados; o resto não disponível', () {
      final f = fin([
        fp(
          2022,
          netInterestIncome: 100,
          netIncome: 40,
          tangibleBookValue: 340,
          sharesOutstanding: 100,
        ),
        fp(
          2023,
          netInterestIncome: 110,
          netIncome: 45,
          tangibleBookValue: 360,
          sharesOutstanding: 100,
        ),
        fp(
          2024,
          netInterestIncome: 121,
          netIncome: 50,
          tangibleBookValue: 400,
          sharesOutstanding: 100,
        ),
      ]);
      final ms = sectorMetrics(
        f,
        const MarketSnapshot(
          symbol: 'B',
          sector: 'Financial Services',
          industry: 'Banks - Regional',
          price: 20,
        ),
      );
      expect(met(ms, 'bank_nii').value, 121);
      expect(
        met(ms, 'bank_nii_growth').value,
        closeTo(0.1, 1e-9),
      ); // 121 / 110 − 1
      // ROTE = 50 / média(400, 360) = 50 / 380.
      expect(met(ms, 'bank_rote').value, closeTo(50 / 380, 1e-9));
      // P/TBV = 20 / (400 / 100) = 5.
      expect(met(ms, 'bank_p_tbv').value, closeTo(5, 1e-9));
      for (final k in [
        'bank_nim',
        'bank_cost_to_income',
        'bank_cost_of_risk',
        'bank_cet1',
        'bank_npl',
        'bank_npl_coverage',
        'bank_lcr',
      ]) {
        expect(met(ms, k).value, isNull, reason: k);
      }
      // Banco com prejuízo não entra no grupo "sem lucros".
      final prej = sectorMetrics(
        fin([fp(2024, netIncome: -10, netInterestIncome: 5)]),
        const MarketSnapshot(
          symbol: 'B',
          sector: 'Financial Services',
          industry: 'Banks - Regional',
        ),
      );
      expect(prej.any((x) => x.key.startsWith('nolp_')), isFalse);
    });

    test('software: regra dos 40, SBC/receita e margem bruta', () {
      final f = fin([
        fp(2023, revenue: 1000, netIncome: -10),
        fp(
          2024,
          revenue: 1200,
          grossProfit: 960,
          operatingCashFlow: 300,
          capex: -60,
          stockBasedComp: 120,
          netIncome: -5,
        ),
      ]);
      final ms = sectorMetrics(
        f,
        const MarketSnapshot(
          symbol: 'S',
          sector: 'Technology',
          industry: 'Software - Application',
        ),
      );
      expect(met(ms, 'saas_revenue_growth').value, closeTo(0.2, 1e-9));
      expect(
        met(ms, 'saas_fcf_margin').value,
        closeTo(0.2, 1e-9),
      ); // (300 − 60) / 1200
      expect(met(ms, 'saas_rule_of_40').value, closeTo(0.4, 1e-9));
      expect(met(ms, 'saas_sbc_to_revenue').value, closeTo(0.1, 1e-9));
      expect(met(ms, 'saas_gross_margin').value, closeTo(0.8, 1e-9));
      expect(met(ms, 'saas_arr').value, isNull);
      expect(met(ms, 'saas_nrr').value, isNull);
      expect(met(ms, 'saas_cac_payback').value, isNull);
    });

    test('farma: I&D / receita', () {
      final ms = sectorMetrics(
        fin([fp(2024, revenue: 1000, researchDevelopment: 300, netIncome: 50)]),
        const MarketSnapshot(
          symbol: 'P',
          sector: 'Healthcare',
          industry: 'Drug Manufacturers - General',
        ),
      );
      expect(met(ms, 'pharma_rd_to_revenue').value, closeTo(0.3, 1e-9));
      expect(met(ms, 'pharma_pipeline').value, isNull);
      expect(met(ms, 'pharma_rnpv').value, isNull);
    });

    test(
      'empresa sem lucros: receita, margem bruta, cash runway e diluição',
      () {
        final f = fin([
          fp(2023, revenue: 800, sharesOutstanding: 100),
          fp(
            2024,
            revenue: 1000,
            costOfRevenue: 400,
            netIncome: -50,
            operatingCashFlow: -100,
            capex: -20,
            cashAndShortTermInvestments: 600,
            sharesOutstanding: 110,
          ),
        ]);
        final ms = sectorMetrics(
          f,
          const MarketSnapshot(symbol: 'N', sector: '', industry: ''),
        );
        expect(met(ms, 'nolp_revenue').value, 1000);
        expect(
          met(ms, 'nolp_gross_margin').value,
          closeTo(0.6, 1e-9),
        ); // (1000 − 400) / 1000
        // FCF = −100 − 20 = −120 por ano → queima mensal 10 → 600 / 10 = 60 meses.
        expect(met(ms, 'nolp_cash_runway_months').value, closeTo(60, 1e-9));
        expect(met(ms, 'nolp_dilution').value, closeTo(0.1, 1e-9));
      },
    );

    test('runway nulo quando o FCF é positivo (não há queima)', () {
      final f = fin([
        fp(
          2024,
          revenue: 1000,
          netIncome: -5,
          operatingCashFlow: 50,
          capex: -20,
          cashAndShortTermInvestments: 600,
        ),
      ]);
      final ms = sectorMetrics(f, const MarketSnapshot(symbol: 'N'));
      expect(met(ms, 'nolp_cash_runway_months').value, isNull);
    });

    test('empresa genérica com lucro não devolve métricas setoriais', () {
      final ms = sectorMetrics(
        fin([fp(2024, revenue: 1000, netIncome: 50)]),
        const MarketSnapshot(
          symbol: 'G',
          sector: 'Industrials',
          industry: 'Farm & Heavy Construction Machinery',
        ),
      );
      expect(ms, isEmpty);
    });

    test('REIT, seguradora, utility, matérias-primas, retalho e holding: tudo não disponível', () {
      final f = rico();
      final casos = <(String, String, String, List<String>)>[
        (
          'Insurance - Life',
          'Financial Services',
          'I',
          ['insurer_combined_ratio', 'insurer_float', 'insurer_reserves'],
        ),
        (
          'REIT - Office',
          'Real Estate',
          'R',
          [
            'reit_ffo',
            'reit_affo',
            'reit_nav',
            'reit_cap_rate',
            'reit_ltv',
            'reit_occupancy',
          ],
        ),
        (
          'Utilities - Regulated',
          'Utilities',
          'U',
          ['utility_rab', 'utility_allowed_return'],
        ),
        (
          'Gold',
          'Basic Materials',
          'C',
          [
            'commodity_breakeven',
            'commodity_reserves',
            'commodity_cost_per_unit',
            'commodity_fcf_cycle',
            'commodity_normalized_earnings',
          ],
        ),
        (
          'Specialty Retail',
          'Consumer Cyclical',
          'T',
          [
            'retail_like_for_like',
            'retail_sales_per_sqm',
            'retail_store_margin',
          ],
        ),
        (
          'Conglomerates',
          'Industrials',
          'H',
          ['holding_sotp', 'holding_discount'],
        ),
      ];
      for (final (ind, sec, sym, keys) in casos) {
        final ms = sectorMetrics(
          f,
          MarketSnapshot(symbol: sym, sector: sec, industry: ind),
        );
        for (final k in keys) {
          expect(met(ms, k).value, isNull, reason: k);
        }
      }
    });
  });

  // =========================================================================================================
  group('redFlags (secção 17), um caso a 1, um a 0 e um nulo por alerta', () {
    test('flag_earnings_up_cfo_down', () {
      expect(
        flag(
          fin([
            fp(2023, netIncome: 100, operatingCashFlow: 200),
            fp(2024, netIncome: 120, operatingCashFlow: 150),
          ]),
          'flag_earnings_up_cfo_down',
        ),
        1,
      );
      // CFO a subir: sem alerta. Lucro a descer: sem alerta.
      expect(
        flag(
          fin([
            fp(2023, netIncome: 100, operatingCashFlow: 200),
            fp(2024, netIncome: 120, operatingCashFlow: 250),
          ]),
          'flag_earnings_up_cfo_down',
        ),
        0,
      );
      expect(
        flag(
          fin([
            fp(2023, netIncome: 100, operatingCashFlow: 200),
            fp(2024, netIncome: 90, operatingCashFlow: 150),
          ]),
          'flag_earnings_up_cfo_down',
        ),
        0,
      );
      expect(
        flag(
          fin([
            fp(2023, netIncome: 100),
            fp(2024, netIncome: 120, operatingCashFlow: 150),
          ]),
          'flag_earnings_up_cfo_down',
        ),
        isNull,
      );
    });

    test('flag_dso_rising (DSO = contas a receber / receita × 365)', () {
      // DSO 36,5 → 54,75: subiu 50 %.
      expect(
        flag(
          fin([
            fp(2023, revenue: 1000, receivables: 100),
            fp(2024, revenue: 1000, receivables: 150),
          ]),
          'flag_dso_rising',
        ),
        1,
      );
      // DSO 36,5 → 37,23: subiu 2 %, abaixo do limiar de 5 %.
      expect(
        flag(
          fin([
            fp(2023, revenue: 1000, receivables: 100),
            fp(2024, revenue: 1000, receivables: 102),
          ]),
          'flag_dso_rising',
        ),
        0,
      );
      expect(
        flag(
          fin([
            fp(2023, revenue: 1000, receivables: 100),
            fp(2024, revenue: 1000),
          ]),
          'flag_dso_rising',
        ),
        isNull,
      );
    });

    test('flag_dio_rising (DIO = inventário / custo das vendas × 365)', () {
      expect(
        flag(
          fin([
            fp(2023, costOfRevenue: 500, inventory: 100),
            fp(2024, costOfRevenue: 500, inventory: 150),
          ]),
          'flag_dio_rising',
        ),
        1,
      );
      expect(
        flag(
          fin([
            fp(2023, costOfRevenue: 500, inventory: 100),
            fp(2024, costOfRevenue: 500, inventory: 90),
          ]),
          'flag_dio_rising',
        ),
        0,
      );
      // Sem inventário (bancos, software): nulo, não zero.
      expect(
        flag(
          fin([fp(2023, costOfRevenue: 500), fp(2024, costOfRevenue: 500)]),
          'flag_dio_rising',
        ),
        isNull,
      );
    });

    test('flag_special_items_recurring (todos os anos, mínimo 3, ≥ 1 % da receita)', () {
      FinPeriod ano(int y, double? s) => fp(y, revenue: 1000, specialItems: s);
      expect(
        flag(
          fin([ano(2022, 20), ano(2023, -30), ano(2024, 15)]),
          'flag_special_items_recurring',
        ),
        1,
      );
      // Zero explícito num ano quebra o padrão.
      expect(
        flag(
          fin([ano(2022, 20), ano(2023, 0), ano(2024, 15)]),
          'flag_special_items_recurring',
        ),
        0,
      );
      // Um ano em falta, sem quebra: não se confirma.
      expect(
        flag(
          fin([ano(2022, 20), ano(2023, null), ano(2024, 15)]),
          'flag_special_items_recurring',
        ),
        isNull,
      );
      // Dois anos não bastam.
      expect(
        flag(
          fin([ano(2023, 20), ano(2024, 15)]),
          'flag_special_items_recurring',
        ),
        isNull,
      );
    });

    test('flag_goodwill_high (goodwill > 30 % do ativo)', () {
      expect(
        flag(
          fin([fp(2024, goodwill: 310, totalAssets: 1000)]),
          'flag_goodwill_high',
        ),
        1,
      );
      expect(
        flag(
          fin([fp(2024, goodwill: 290, totalAssets: 1000)]),
          'flag_goodwill_high',
        ),
        0,
      );
      expect(
        flag(fin([fp(2024, totalAssets: 1000)]), 'flag_goodwill_high'),
        isNull,
      );
    });

    test('flag_impairments (últimos 3 anos; imparidade ≥ 1 % do ativo)', () {
      FinPeriod ano(int y, double? imp, {double? ta = 1000}) =>
          fp(y, impairment: imp, totalAssets: ta);
      // 3 % num dos anos.
      expect(
        flag(
          fin([ano(2022, null), ano(2023, 30), ano(2024, null)]),
          'flag_impairments',
        ),
        1,
      );
      // 0,5 % em todos (e campos ausentes contam como zero).
      expect(
        flag(
          fin([ano(2022, null), ano(2023, 5), ano(2024, null)]),
          'flag_impairments',
        ),
        0,
      );
      // Sem ativo total não se sabe.
      expect(
        flag(
          fin([ano(2022, 30, ta: null), ano(2023, 30, ta: null)]),
          'flag_impairments',
        ),
        isNull,
      );
    });

    test('flag_debt_and_cash_high (caixa ≥ 20 % e dívida ≥ 25 % do ativo)', () {
      expect(
        flag(
          fin([fp(2024, totalAssets: 1000, cash: 250, totalDebt: 300)]),
          'flag_debt_and_cash_high',
        ),
        1,
      );
      expect(
        flag(
          fin([fp(2024, totalAssets: 1000, cash: 250, totalDebt: 100)]),
          'flag_debt_and_cash_high',
        ),
        0,
      );
      expect(
        flag(
          fin([fp(2024, totalAssets: 1000, cash: 100, totalDebt: 300)]),
          'flag_debt_and_cash_high',
        ),
        0,
      );
      expect(
        flag(
          fin([fp(2024, totalAssets: 1000, totalDebt: 300)]),
          'flag_debt_and_cash_high',
        ),
        isNull,
      );
    });

    test(
      'flag_tax_paid_low (imposto pago < 50 % do reportado, 3 últimos anos)',
      () {
        FinPeriod ano(int y, double? prov, double? pago) =>
            fp(y, taxProvision: prov, incomeTaxPaid: pago);
        expect(
          flag(
            fin([ano(2022, 100, 20), ano(2023, 100, 20), ano(2024, 100, 20)]),
            'flag_tax_paid_low',
          ),
          1,
        );
        expect(
          flag(
            fin([ano(2022, 100, 90), ano(2023, 100, 90), ano(2024, 100, 90)]),
            'flag_tax_paid_low',
          ),
          0,
        );
        expect(
          flag(
            fin([
              ano(2022, null, 20),
              ano(2023, null, 20),
              ano(2024, null, 20),
            ]),
            'flag_tax_paid_low',
          ),
          isNull,
        );
      },
    );

    test('flag_serial_acquisitions (aquisições negativas em todos os anos, mínimo 3)', () {
      // Receita de 1000 em todos os anos: as aquisições têm de ser ≥ 1 % (10) para contarem (correção R11).
      FinPeriod ano(int y, double? a) => fp(y, acquisitions: a, revenue: 1000);
      expect(
        flag(
          fin([ano(2022, -20), ano(2023, -30), ano(2024, -15)]),
          'flag_serial_acquisitions',
        ),
        1,
      );
      expect(
        flag(
          fin([ano(2022, -20), ano(2023, 0), ano(2024, -15)]),
          'flag_serial_acquisitions',
        ),
        0,
      );
      // Campo em falta conta como zero (correção R11): já não é nulo.
      expect(
        flag(
          fin([ano(2022, -20), ano(2023, null), ano(2024, -15)]),
          'flag_serial_acquisitions',
        ),
        0,
      );
    });

    test('alertas sem fonte de dados ficam sempre nulos', () {
      final f = rico();
      for (final k in [
        'flag_adjusted_vs_gaap',
        'flag_accounting_policy_changes',
        'flag_capitalized_costs',
      ]) {
        expect(flag(f, k), isNull, reason: k);
      }
    });

    test(
      'sem nenhuma demonstração, todos os alertas são nulos e não há exceções',
      () {
        final ms = redFlags(
          const Financials(symbol: 'X'),
          const MarketSnapshot(symbol: 'X'),
        );
        expect(ms.length, 12);
        expect(ms.every((x) => x.value == null), isTrue);
        expect(ms.every((x) => x.key.startsWith('flag_')), isTrue);
      },
    );
  });

  // =========================================================================================================
  group('cobertura das fichas', () {
    test('cada chave devolvida tem ficha, sem duplicados, com textos e com as indisponíveis a null', () {
      final rich = rico();
      final prej = rico(prejuizo: true);
      final snaps = [
        const MarketSnapshot(
          symbol: 'G',
          sector: 'Industrials',
          industry: 'Machinery',
          insidersPercentHeld: 0.05,
        ),
        const MarketSnapshot(
          symbol: 'B',
          sector: 'Financial Services',
          industry: 'Banks - Regional',
          price: 20,
        ),
        const MarketSnapshot(
          symbol: 'I',
          sector: 'Financial Services',
          industry: 'Insurance - Life',
        ),
        const MarketSnapshot(
          symbol: 'R',
          sector: 'Real Estate',
          industry: 'REIT - Office',
        ),
        const MarketSnapshot(
          symbol: 'U',
          sector: 'Utilities',
          industry: 'Utilities - Regulated',
        ),
        const MarketSnapshot(
          symbol: 'C',
          sector: 'Energy',
          industry: 'Oil & Gas E&P',
        ),
        const MarketSnapshot(
          symbol: 'S',
          sector: 'Technology',
          industry: 'Software - Application',
        ),
        const MarketSnapshot(
          symbol: 'T',
          sector: 'Consumer Cyclical',
          industry: 'Specialty Retail',
        ),
        const MarketSnapshot(
          symbol: 'P',
          sector: 'Healthcare',
          industry: 'Biotechnology',
        ),
        const MarketSnapshot(
          symbol: 'H',
          sector: 'Industrials',
          industry: 'Conglomerates',
        ),
      ];

      final todas = <Metric>[
        ...qualityMetrics(rich, m: snaps.first),
        ...qualityMetrics(const Financials(symbol: 'X')),
        ...redFlags(rich, snaps.first),
        ...redFlags(const Financials(symbol: 'X'), snaps.first),
        // Grupos setoriais, com e sem prejuízo (o bloco "sem lucros" só aparece com prejuízo).
        for (final s in snaps) ...sectorMetrics(rich, s),
        for (final s in snaps) ...sectorMetrics(prej, s),
      ];

      final chaves = todas.map((x) => x.key).toSet();
      final fichas = sectorRedflagsInfo;
      final porChave = <String, MetricInfo>{};
      for (final i in fichas) {
        expect(
          porChave.containsKey(i.key),
          isFalse,
          reason: 'ficha duplicada: ${i.key}',
        );
        porChave[i.key] = i;
        expect(i.namePt.trim(), isNotEmpty, reason: i.key);
        expect(i.nameEn.trim(), isNotEmpty, reason: i.key);
        expect(i.meaningPt.trim(), isNotEmpty, reason: i.key);
        expect(i.meaningEn.trim(), isNotEmpty, reason: i.key);
        expect(i.readPt.trim(), isNotEmpty, reason: i.key);
        expect(i.readEn.trim(), isNotEmpty, reason: i.key);
      }

      // Cada chave devolvida tem ficha.
      for (final k in chaves) {
        expect(porChave.containsKey(k), isTrue, reason: 'sem ficha: $k');
      }
      // Cada ficha corresponde a uma chave devolvida (não há fichas órfãs).
      for (final k in porChave.keys) {
        expect(chaves.contains(k), isTrue, reason: 'ficha sem métrica: $k');
      }

      // Uma ficha "não disponível" nunca tem valor.
      for (final x in todas) {
        final info = porChave[x.key]!;
        if (info.availability == MetricAvailability.unavailable) {
          expect(x.value, isNull, reason: x.key);
        }
      }
    });

    test('a ficha de uma métrica "não disponível" diz porquê (texto de leitura com a razão)', () {
      for (final i in sectorRedflagsInfo.where(
        (i) => i.availability == MetricAvailability.unavailable,
      )) {
        expect(
          i.readPt.toLowerCase(),
          contains('não disponível'),
          reason: i.key,
        );
        expect(
          i.readEn.toLowerCase(),
          contains('not available'),
          reason: i.key,
        );
      }
    });
  });

  // =========================================================================================================
  group('correções da revisão independente (F4)', () {
    test('E3: "Holding" no nome não torna holding (ASML Holding, Booking Holdings)', () {
      expect(
        sectorGroupOf(
          const MarketSnapshot(
            symbol: 'ASML',
            name: 'ASML Holding N.V.',
            sector: 'Technology',
            industry: 'Semiconductor Equipment & Materials',
          ),
        ),
        SectorGroup.generic,
      );
      expect(
        sectorGroupOf(
          const MarketSnapshot(
            symbol: 'BKNG',
            name: 'Booking Holdings Inc.',
            sector: 'Consumer Cyclical',
            industry: 'Travel Services',
          ),
        ),
        SectorGroup.generic,
      );
    });

    test('E3: conglomerados (industriais e financeiros) são holdings', () {
      for (final (ind, sec) in [
        ('Conglomerates', 'Industrials'),
        ('Financial Conglomerates', 'Financial Services'),
      ]) {
        expect(
          sectorGroupOf(MarketSnapshot(symbol: 'X', sector: sec, industry: ind)),
          SectorGroup.holdings,
          reason: ind,
        );
      }
    });

    test('E3: lojas de desconto, supermercados e grandes armazéns são retalho', () {
      for (final (ind, sec) in [
        ('Discount Stores', 'Consumer Defensive'),
        ('Grocery Stores', 'Consumer Defensive'),
        ('Department Stores', 'Consumer Cyclical'),
      ]) {
        expect(
          sectorGroupOf(MarketSnapshot(symbol: 'X', sector: sec, industry: ind)),
          SectorGroup.retail,
          reason: ind,
        );
      }
    });

    test('E3: matérias-primas só petróleo, gás, mineração, metais e agricultura (químicos ficam de fora)', () {
      final casos = <(String, String, SectorGroup)>[
        ('Specialty Chemicals', 'Basic Materials', SectorGroup.generic),
        ('Industrial Gases', 'Basic Materials', SectorGroup.generic),
        ('Copper', 'Basic Materials', SectorGroup.commodities),
        ('Agricultural Inputs', 'Basic Materials', SectorGroup.commodities),
        ('Oil & Gas Integrated', 'Energy', SectorGroup.commodities),
      ];
      for (final (ind, sec, grupo) in casos) {
        expect(
          sectorGroupOf(MarketSnapshot(symbol: 'X', sector: sec, industry: ind)),
          grupo,
          reason: '$sec / $ind',
        );
      }
    });

    test('E3: sem indústria, Real Estate é REIT; Financial Services não se presume grupo', () {
      expect(
        sectorGroupOf(const MarketSnapshot(symbol: 'X', sector: 'Real Estate')),
        SectorGroup.reits,
      );
      expect(
        sectorGroupOf(
          const MarketSnapshot(symbol: 'X', sector: 'Financial Services'),
        ),
        SectorGroup.generic,
      );
    });

    test('E4: subida de exatamente 5 % (42 / 40) não é alerta de DSO nem de DIO', () {
      expect(
        flag(
          fin([
            fp(2023, revenue: 365, receivables: 40),
            fp(2024, revenue: 365, receivables: 42),
          ]),
          'flag_dso_rising',
        ),
        0,
      );
      expect(
        flag(
          fin([
            fp(2023, costOfRevenue: 365, inventory: 40),
            fp(2024, costOfRevenue: 365, inventory: 42),
          ]),
          'flag_dio_rising',
        ),
        0,
      );
    });

    test('R10: cash runway devolve-se em meses (MetricKind.months)', () {
      final ms = sectorMetrics(
        fin([
          fp(
            2024,
            revenue: 1000,
            netIncome: -5,
            operatingCashFlow: -100,
            capex: -20,
            cashAndShortTermInvestments: 600,
          ),
        ]),
        const MarketSnapshot(symbol: 'N'),
      );
      expect(met(ms, 'nolp_cash_runway_months').kind, MetricKind.months);
    });

    test('R11: aquisições abaixo de 1 % da receita (0,2 %) não são série de aquisições', () {
      expect(
        flag(
          fin([
            fp(2022, revenue: 1000, acquisitions: -2),
            fp(2023, revenue: 1000, acquisitions: -2),
            fp(2024, revenue: 1000, acquisitions: -2),
          ]),
          'flag_serial_acquisitions',
        ),
        0,
      );
    });

    test('R11: aquisições de 1 % ou mais da receita em todos os anos dão alerta', () {
      expect(
        flag(
          fin([
            fp(2022, revenue: 1000, acquisitions: -10),
            fp(2023, revenue: 1000, acquisitions: -10),
            fp(2024, revenue: 1000, acquisitions: -10),
          ]),
          'flag_serial_acquisitions',
        ),
        1,
      );
    });

    test('R12: bancos e seguradoras não têm DSO, DIO nem alerta de dívida e caixa', () {
      final f = fin([
        fp(
          2023,
          revenue: 1000,
          costOfRevenue: 400,
          receivables: 100,
          inventory: 80,
          totalAssets: 1000,
          cash: 250,
          totalDebt: 300,
        ),
        fp(
          2024,
          revenue: 1000,
          costOfRevenue: 400,
          receivables: 150,
          inventory: 120,
          totalAssets: 1000,
          cash: 250,
          totalDebt: 300,
        ),
      ]);
      for (final ind in [
        const MarketSnapshot(symbol: 'JPM', sector: 'Financial Services', industry: 'Banks - Diversified'),
        const MarketSnapshot(symbol: 'ALV', sector: 'Financial Services', industry: 'Insurance - Diversified'),
      ]) {
        final ms = redFlags(f, ind);
        for (final k in ['flag_dso_rising', 'flag_dio_rising', 'flag_debt_and_cash_high']) {
          expect(met(ms, k).value, isNull, reason: '${ind.industry} / $k');
        }
      }
      // Uma empresa industrial com os mesmos números continua a ser avaliada.
      expect(
        redFlags(
          f,
          const MarketSnapshot(symbol: 'X', sector: 'Industrials', industry: 'Machinery'),
        ).firstWhere((x) => x.key == 'flag_dso_rising').value,
        1,
      );
    });
  });
}
