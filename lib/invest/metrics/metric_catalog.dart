import 'dcf_info.dart';
import 'liquidity_solvency_cash_info.dart';
import 'market_risk_info.dart';
import 'metric_info.dart';
import 'profitability_growth_info.dart';
import 'risk_scores_info.dart';
import 'sector_redflags_info.dart';
import 'valuation_dividends_info.dart';

/// Todas as fichas de explicação das métricas, de todos os grupos. A interface procura aqui a explicação
/// escondida (ícone "i") de qualquer métrica pela sua chave.
final List<MetricInfo> allMetricInfo = [
  ...profitabilityGrowthInfo,
  ...liquiditySolvencyCashInfo,
  ...valuationDividendsInfo,
  ...riskScoresInfo,
  ...dcfInfo,
  ...marketRiskInfo,
  ...sectorRedflagsInfo,
];

/// Ficha por chave (`Metric.key`).
final Map<String, MetricInfo> metricCatalog = {
  for (final i in allMetricInfo) i.key: i,
};

/// A ficha de uma métrica, ou nulo se não existir (nunca deve acontecer: há um teste de cobertura).
MetricInfo? metricInfoFor(String key) => metricCatalog[key];
