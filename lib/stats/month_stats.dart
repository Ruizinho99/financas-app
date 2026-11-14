import '../analysis/analytics.dart';
import '../state/app_state.dart';

/// Despesa de cada um dos [n] meses até [endKey] (inclusive), do mais antigo para o mais recente.
/// Usa a mesma conta do ecrã Mês (`Analytics.spent`).
List<({String key, int spent})> spendSeries(
  AppState s,
  String endKey, {
  int n = 6,
}) {
  final y = int.parse(endKey.substring(0, 4));
  final m = int.parse(endKey.substring(5, 7));
  return [
    for (var i = n - 1; i >= 0; i--)
      () {
        final d = DateTime(y, m - i);
        final key =
            '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
        final a = Analytics(s, s.periodOfMonth(key), const AnalysisFilter());
        return (key: key, spent: a.spent);
      }(),
  ];
}

/// Cor estável por categoria (a mesma categoria tem sempre a mesma cor): índice na paleta de 8.
int paletteIndex(int? categoryId) => categoryId == null ? 7 : categoryId % 8;
