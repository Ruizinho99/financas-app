/// Contrato partilhado da análise fundamental: os dados de entrada das fórmulas.
/// Todos os valores monetários estão na moeda de reporte da empresa, em unidades (não em milhares).
/// Campos que a fonte não tem ficam `null`; as fórmulas devolvem `null` quando falta um dado de que precisam.
library;

/// Um exercício anual (12 meses) ou um trimestre de demonstrações financeiras.
class FinPeriod {
  final DateTime end; // data de fecho do período
  final bool annual; // true = 12 meses; false = trimestre
  // --- demonstração de resultados
  final double? revenue;
  final double? costOfRevenue;
  final double? grossProfit;
  final double? operatingIncome; // resultado operacional reportado
  final double? ebit;
  final double? ebitda;
  final double? netIncome;
  final double? pretaxIncome;
  final double? taxProvision; // imposto sobre o rendimento (positivo = despesa)
  final double? interestExpense; // positivo = despesa
  final double? depreciationAmortization;
  final double? stockBasedComp;
  final double? sellingGeneralAdmin; // SG&A (Beneish SGAI)
  final double? researchDevelopment; // I&D (farma, software)
  final double? netInterestIncome; // margem financeira (bancos)
  final double?
  specialItems; // itens especiais/não recorrentes (positivo = ganho)
  final double? impairment; // imparidades de ativos (positivo = despesa)
  final double? dilutedEps;
  final double? dilutedShares; // média de ações diluídas
  // --- balanço (no fecho do período)
  final double? totalAssets;
  final double? currentAssets;
  final double? currentLiabilities;
  final double? cash; // caixa e equivalentes
  final double? cashAndShortTermInvestments;
  final double? receivables;
  final double? inventory;
  final double? payables;
  final double?
  totalDebt; // dívida financeira total (inclui locações se a fonte as incluir)
  final double? longTermDebt;
  final double? currentDebt;
  final double? equity; // capitais próprios dos acionistas
  final double? tangibleBookValue;
  final double? retainedEarnings;
  final double? totalLiabilities;
  final double? goodwill;
  final double? minorityInterest;
  final double? sharesOutstanding;
  final double? netPpe;
  final double? investedCapital;
  final double? preferredStock; // ações preferenciais (EV)
  final double? leaseLiabilities; // obrigações de locação (IFRS 16)
  // --- fluxos de caixa
  final double? operatingCashFlow;
  final double? capex; // como reportado: negativo = saída de caixa
  final double? freeCashFlow;
  final double? dividendsPaid; // como reportado: negativo = saída de caixa
  final double?
  buybacks; // recompras líquidas, como reportado: negativo = saída de caixa
  final double? incomeTaxPaid; // imposto pago em dinheiro (positivo = pago)
  final double? interestPaid; // juros pagos em dinheiro (positivo = pago)
  final double?
  acquisitions; // compra de empresas, como reportado: negativo = saída de caixa
  final double? stockIssuance; // emissão de ações (positivo = entrada de caixa)
  final double? changeInWorkingCapital; // variação do fundo de maneio no fluxo de caixa, como reportado

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
    this.sellingGeneralAdmin,
    this.researchDevelopment,
    this.netInterestIncome,
    this.specialItems,
    this.impairment,
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
    this.preferredStock,
    this.leaseLiabilities,
    this.operatingCashFlow,
    this.capex,
    this.freeCashFlow,
    this.dividendsPaid,
    this.buybacks,
    this.incomeTaxPaid,
    this.interestPaid,
    this.acquisitions,
    this.stockIssuance,
    this.changeInWorkingCapital,
  });

  /// Capex em valor positivo (o que se gastou).
  double? get capexSpent => capex == null ? null : capex!.abs();

  /// Dividendos pagos em valor positivo.
  double? get dividendsPaidPositive =>
      dividendsPaid == null ? null : dividendsPaid!.abs();

  /// Recompras líquidas de emissões, em valor positivo: `-buybacks - stockIssuance` (o `buybacks` do Yahoo é
  /// um valor bruto de sinal de caixa; com emissão líquida o resultado seria negativo, e não se usa `abs`).
  double? get netBuybacks =>
      buybacks == null ? null : -buybacks! - (stockIssuance ?? 0);

  /// EBIT para as fórmulas: o resultado operacional e, se faltar, o campo `ebit` (ordem da especificação).
  double? get ebitOrOperating => operatingIncome ?? ebit;
}

/// Tipo de instrumento. Só as ações (equity) têm análise fundamental; ETFs, fundos e cripto
/// só têm métricas de mercado e de risco (preço, volatilidade, drawdown, retornos...).
enum QuoteType { equity, etf, fund, crypto, marketIndex, other }

/// Dados de mercado de uma empresa (agora).
///
/// **Regra de moeda**: todos os valores monetários deste objeto (preço, market cap, EV, dividendo por ação,
/// máximo/mínimo de 52 semanas) estão na **moeda de reporte** das demonstrações (`currency`, a mesma de
/// `Financials.currency`), já convertidos pela camada de dados com a taxa de câmbio atual (`fxApplied` =
/// unidades da moeda de reporte por 1 unidade de `quoteCurrency`). Assim os múltiplos (P/E, P/B, EV/EBIT...)
/// comparam sempre valores na mesma moeda, mesmo em títulos cotados noutra (NVD.DE cota em EUR e reporta em USD).
class MarketSnapshot {
  final String symbol;
  final String name;
  final String currency; // moeda de reporte
  final String quoteCurrency; // moeda em que o título cota
  final double fxApplied; // reporte por 1 de cotação (1 se for a mesma)
  final QuoteType quoteType;
  final double? price;
  final double? marketCap;
  final double? sharesOutstanding;
  final double? enterpriseValue;
  final double? beta;
  final double? fiftyTwoWeekHigh, fiftyTwoWeekLow;
  final double? averageVolume;
  final double? dividendPerShare; // últimos 12 meses
  final double? forwardEps; // EPS esperado (quoteSummary, melhor esforço), na moeda de reporte
  final double? shortPercentOfFloat; // 0..1
  final double? insidersPercentHeld; // 0..1
  final String sector, industry;
  const MarketSnapshot({
    required this.symbol,
    this.name = '',
    this.currency = 'USD',
    this.quoteCurrency = 'USD',
    this.fxApplied = 1,
    this.quoteType = QuoteType.equity,
    this.price,
    this.marketCap,
    this.sharesOutstanding,
    this.enterpriseValue,
    this.beta,
    this.fiftyTwoWeekHigh,
    this.fiftyTwoWeekLow,
    this.averageVolume,
    this.dividendPerShare,
    this.forwardEps,
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
  final String currency; // moeda de reporte; vazia quando a fonte não tem dados
  final List<FinPeriod> annual;
  final List<FinPeriod> quarterly;

  /// Fluxos dos últimos 12 meses + balanço do último trimestre. Conta como um período de 12 meses
  /// (`annual: true`) para as fórmulas que dividem por receita ou resultado.
  final FinPeriod? ttm;
  const Financials({
    required this.symbol,
    this.currency = '',
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
