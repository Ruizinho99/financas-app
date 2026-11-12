/// Contrato partilhado da análise fundamental: os dados de entrada das fórmulas.
/// Todos os valores monetários estão na moeda de reporte da empresa, em unidades (não em milhares).
/// Campos que a fonte não tem ficam `null`; as fórmulas devolvem `null` quando falta um dado de que precisam.
library;

/// Um exercício anual (12 meses) ou um trimestre de demonstrações financeiras.
class FinPeriod {
  final DateTime end; // data de fecho do período
  final bool annual; // true = 12 meses; false = trimestre
  // --- demonstração de resultados
  final double? revenue,
      costOfRevenue,
      grossProfit,
      operatingIncome, // resultado operacional reportado
      ebit,
      ebitda,
      netIncome,
      pretaxIncome,
      taxProvision, // imposto sobre o rendimento (positivo = despesa)
      interestExpense, // positivo = despesa
      depreciationAmortization,
      stockBasedComp,
      dilutedEps,
      dilutedShares; // média de ações diluídas
  // --- balanço (no fecho do período)
  final double?
  totalAssets,
  currentAssets,
  currentLiabilities,
  cash, // caixa e equivalentes
  cashAndShortTermInvestments,
  receivables,
  inventory,
  payables,
  totalDebt, // dívida financeira total (inclui locações se a fonte as incluir)
  longTermDebt,
  currentDebt,
  equity, // capitais próprios dos acionistas
  tangibleBookValue,
  retainedEarnings,
  totalLiabilities,
  goodwill,
  minorityInterest,
  sharesOutstanding,
  netPpe,
  investedCapital;
  // --- fluxos de caixa
  final double? operatingCashFlow,
      capex, // como reportado: negativo = saída de caixa
      freeCashFlow,
      dividendsPaid, // como reportado: negativo = saída de caixa
      buybacks; // recompras de ações líquidas, como reportado: negativo = saída de caixa

  const FinPeriod({
    required this.end,
    required this.annual,
    this.revenue,
    this.costOfRevenue,
    this.grossProfit,
    this.operatingIncome,
    this.ebit,
    this.ebitda,
    this.netIncome,
    this.pretaxIncome,
    this.taxProvision,
    this.interestExpense,
    this.depreciationAmortization,
    this.stockBasedComp,
    this.dilutedEps,
    this.dilutedShares,
    this.totalAssets,
    this.currentAssets,
    this.currentLiabilities,
    this.cash,
    this.cashAndShortTermInvestments,
    this.receivables,
    this.inventory,
    this.payables,
    this.totalDebt,
    this.longTermDebt,
    this.currentDebt,
    this.equity,
    this.tangibleBookValue,
    this.retainedEarnings,
    this.totalLiabilities,
    this.goodwill,
    this.minorityInterest,
    this.sharesOutstanding,
    this.netPpe,
    this.investedCapital,
    this.operatingCashFlow,
    this.capex,
    this.freeCashFlow,
    this.dividendsPaid,
    this.buybacks,
  });

  /// Capex em valor positivo (o que se gastou).
  double? get capexSpent => capex == null ? null : capex!.abs();

  /// Dividendos pagos em valor positivo.
  double? get dividendsPaidPositive =>
      dividendsPaid == null ? null : dividendsPaid!.abs();

  /// Recompras líquidas em valor positivo.
  double? get buybacksPositive => buybacks == null ? null : buybacks!.abs();

  /// EBIT: o campo `ebit` ou, se faltar, o resultado operacional.
  double? get ebitOrOperating => ebit ?? operatingIncome;
}

/// Dados de mercado de uma empresa (agora).
class MarketSnapshot {
  final String symbol;
  final String name;
  final String currency;
  final double? price;
  final double? marketCap;
  final double? sharesOutstanding;
  final double? enterpriseValue;
  final double? beta;
  final double? fiftyTwoWeekHigh, fiftyTwoWeekLow;
  final double? averageVolume;
  final double? dividendPerShare; // últimos 12 meses
  final double? shortPercentOfFloat; // 0..1
  final double? insidersPercentHeld; // 0..1
  final String sector, industry;
  const MarketSnapshot({
    required this.symbol,
    this.name = '',
    this.currency = 'USD',
    this.price,
    this.marketCap,
    this.sharesOutstanding,
    this.enterpriseValue,
    this.beta,
    this.fiftyTwoWeekHigh,
    this.fiftyTwoWeekLow,
    this.averageVolume,
    this.dividendPerShare,
    this.shortPercentOfFloat,
    this.insidersPercentHeld,
    this.sector = '',
    this.industry = '',
  });
}

/// As demonstrações financeiras de uma empresa: períodos anuais e trimestrais por ordem cronológica
/// (do mais antigo para o mais recente) e o acumulado dos últimos 12 meses (TTM).
class Financials {
  final String symbol;
  final String currency; // moeda de reporte
  final List<FinPeriod> annual;
  final List<FinPeriod> quarterly;
  final FinPeriod?
  ttm; // fluxos dos últimos 12 meses + balanço do último trimestre
  const Financials({
    required this.symbol,
    this.currency = 'USD',
    this.annual = const [],
    this.quarterly = const [],
    this.ttm,
  });

  FinPeriod? get lastAnnual => annual.isEmpty ? null : annual.last;
  FinPeriod? get prevAnnual =>
      annual.length < 2 ? null : annual[annual.length - 2];

  /// O período mais recente para "agora": o TTM se existir, senão o último anual.
  FinPeriod? get latest => ttm ?? lastAnnual;
}

/// Que tipo de valor é uma métrica (para formatar na interface).
enum MetricKind { percent, ratio, days, money, perShare, score, years }

/// Uma métrica calculada. [value] é nulo quando faltam dados. Percentagens e taxas em fração (0,25 = 25 %).
class Metric {
  final String
  key; // identificador estável (a interface traduz o nome por esta chave)
  final double? value;
  final MetricKind kind;
  const Metric(this.key, this.value, this.kind);
  bool get available => value != null && value!.isFinite;
  @override
  String toString() => '$key=$value';
}

/// Divisão segura: nulo se faltar um valor ou o denominador for 0.
double? safeDiv(double? a, double? b) {
  if (a == null || b == null || b == 0 || !a.isFinite || !b.isFinite)
    return null;
  return a / b;
}

/// Média de dois valores (início e fim do período); se faltar o inicial usa só o final.
double? avgOf(double? now, double? before) {
  if (now == null) return null;
  return before == null ? now : (now + before) / 2;
}
