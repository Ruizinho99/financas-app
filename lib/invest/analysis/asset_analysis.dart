/// Junta os dados de mercado e as fórmulas num relatório por secções para o ecrã "Analisar um ativo".
library;

import '../data/price_history.dart';
import '../data/yahoo_market_data.dart';
import '../metrics/dcf.dart';
import '../metrics/financials.dart';
import '../metrics/liquidity_solvency_cash.dart';
import '../metrics/market_risk.dart';
import '../metrics/profitability_growth.dart';
import '../metrics/risk_scores.dart';
import '../metrics/sector_redflags.dart';
import '../metrics/valuation_dividends.dart';

/// Uma secção do relatório (ex.: Margens). [id] serve para o título traduzido na interface.
class AnalysisSection {
  final String id;
  final List<Metric> metrics;
  const AnalysisSection(this.id, this.metrics);

  /// Há pelo menos uma métrica calculada.
  bool get hasData => metrics.any((m) => m.available);
}

/// Resultado completo da análise de um símbolo.
class AssetAnalysis {
  final String symbol;
  final MarketSnapshot snapshot;
  final Financials financials;
  final PriceHistory history;
  final DcfAssumptions assumptions;
  final List<AnalysisSection> sections;

  /// Só mercado e risco (ETF, fundo, cripto, índice) ou sem demonstrações disponíveis.
  final bool marketOnly;

  /// A fonte de demonstrações falhou (rede/limite): não significa "sem dados".
  final bool financialsFailed;
  final PriceHistory? benchmark;
  const AssetAnalysis({
    required this.symbol,
    required this.snapshot,
    required this.financials,
    required this.history,
    required this.assumptions,
    required this.sections,
    required this.marketOnly,
    required this.financialsFailed,
    this.benchmark,
  });

  /// Procura uma métrica pela chave em todas as secções.
  Metric? metric(String key) {
    for (final s in sections) {
      for (final m in s.metrics) {
        if (m.key == key) return m;
      }
    }
    return null;
  }

  /// Todas as métricas calculadas e a lista das chaves para a secção [id].
  AnalysisSection? section(String id) {
    for (final s in sections) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Recalcula com outras premissas do DCF (sem ir à rede).
  AssetAnalysis withAssumptions(DcfAssumptions a) => buildAnalysis(
    snapshot: snapshot,
    financials: financials,
    history: history,
    benchmark: benchmark,
    assumptions: a,
  );
}

/// Constrói o relatório. Função pura (sem rede) para ser testável com dados fixos.
AssetAnalysis buildAnalysis({
  required MarketSnapshot snapshot,
  required Financials financials,
  required PriceHistory history,
  PriceHistory? benchmark,
  DcfAssumptions assumptions = const DcfAssumptions(),
}) {
  final f = financials;
  final m = snapshot;
  final temDemonstracoes = f.annual.isNotEmpty || f.quarterly.isNotEmpty;
  final soMercado = m.quoteType != QuoteType.equity || !temDemonstracoes;

  final datas = [for (final p in history.points) p.date];
  final fechos = [for (final p in history.points) p.close];
  final risco = marketRiskMetrics(
    datas,
    fechos,
    benchDates: benchmark == null
        ? null
        : [for (final p in benchmark.points) p.date],
    benchCloses: benchmark == null
        ? null
        : [for (final p in benchmark.points) p.close],
    snapshot: m,
    riskFree: assumptions.riskFreeRate,
  );
  final beta = risco.where((x) => x.key == 'beta').firstOrNull?.value;

  final sections = <AnalysisSection>[
    if (!soMercado) ...[
      AnalysisSection('valuation', valuationMetrics(f, m)),
      AnalysisSection('profitability', profitabilityMetrics(f)),
      AnalysisSection('growth', growthMetrics(f)),
      AnalysisSection('returns', returnMetrics(f)),
      AnalysisSection('efficiency', efficiencyMetrics(f)),
      AnalysisSection('liquidity', liquidityMetrics(f)),
      AnalysisSection('solvency', solvencyMetrics(f)),
      AnalysisSection('cashflow', cashFlowMetrics(f)),
      AnalysisSection('pershare', perShareMetrics(f, market: m)),
      AnalysisSection(
        'dividends',
        dividendMetrics(f, m, dividendHistory: history.dividends),
      ),
      AnalysisSection('scores', [
        ...piotroskiMetrics(f),
        ...altmanMetrics(f, m),
        ...beneishMetrics(f),
      ]),
      AnalysisSection(
        'dcf',
        dcfMetrics(f, m, assumptions: assumptions, computedBeta: beta),
      ),
      AnalysisSection('quality', qualityMetrics(f, m: m)),
      AnalysisSection('sector', sectorMetrics(f, m)),
      AnalysisSection('redflags', redFlags(f, m)),
    ],
    AnalysisSection('risk', risco),
  ];

  return AssetAnalysis(
    symbol: m.symbol,
    snapshot: m,
    financials: f,
    history: history,
    assumptions: assumptions,
    sections: sections,
    marketOnly: soMercado,
    financialsFailed: f.failed,
    benchmark: benchmark,
  );
}

/// Vai buscar os dados de [symbol] e constrói o relatório. Lança `PriceException` se o preço falhar.
Future<AssetAnalysis> analyzeSymbol(
  YahooMarketData data,
  String symbol, {
  String benchmark = '^GSPC',
  DcfAssumptions assumptions = const DcfAssumptions(),
}) async {
  final fin = await data.financials(symbol);
  final snap = await data.snapshot(symbol, reportingCurrency: fin.currency);
  final hist = await data.history(symbol, range: '5y');
  PriceHistory? bench;
  try {
    bench = await data.history(benchmark, range: '5y');
  } catch (_) {
    bench = null; // sem referência: só não há beta nem alfa
  }
  return buildAnalysis(
    snapshot: snap,
    financials: fin,
    history: hist,
    benchmark: bench,
    assumptions: assumptions,
  );
}
