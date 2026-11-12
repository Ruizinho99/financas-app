/// Modelos do histórico de preços (cotações diárias, dividendos e splits) de um ativo.
library;

/// Uma cotação diária.
class PricePoint {
  final DateTime date; // data da sessão (UTC, só dia)
  final double close; // fecho, na moeda do histórico
  final double?
  adjClose; // fecho ajustado a dividendos e splits (se a fonte o der)
  const PricePoint(this.date, this.close, [this.adjClose]);

  @override
  String toString() => 'PricePoint($date, $close)';
}

/// Histórico de um ativo: pontos por ordem cronológica (do mais antigo para o mais recente).
class PriceHistory {
  final String symbol;
  final String currency; // moeda de cotação (GBp/GBX já convertidos para GBP)
  final List<PricePoint> points;

  /// Dividendos por data ex (valor por ação, na moeda do histórico).
  final Map<DateTime, double> dividends;

  /// Splits por data: fator multiplicador de ações (4:1 = 4,0; agrupamento 1:10 = 0,1).
  final Map<DateTime, double> splits;

  const PriceHistory({
    required this.symbol,
    this.currency = 'USD',
    this.points = const [],
    this.dividends = const {},
    this.splits = const {},
  });

  bool get isEmpty => points.isEmpty;
  PricePoint? get last => points.isEmpty ? null : points.last;
}
