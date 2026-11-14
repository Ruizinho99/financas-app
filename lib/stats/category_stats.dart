import '../models.dart';
import '../state/app_state.dart';

/// Estatísticas de gasto de uma categoria (com todas as subcategorias) nos últimos [months] meses.
class CategoryStats {
  final List<String> monthKeys; // do mais antigo para o mais recente
  final List<int> monthly; // gasto (cêntimos) por mês, alinhado com monthKeys
  final int total;
  final int averagePerMonth; // sobre os meses desde o primeiro com gasto
  final int count; // número de movimentos de despesa
  final Txn? biggest; // maior despesa individual
  final List<MapEntry<String, int>> bySubcategory; // nome → cêntimos (ordem decrescente)
  final List<MapEntry<String, int>> byMerchant; // título → cêntimos (top 5)
  const CategoryStats({
    required this.monthKeys,
    required this.monthly,
    required this.total,
    required this.averagePerMonth,
    required this.count,
    required this.biggest,
    required this.bySubcategory,
    required this.byMerchant,
  });
  bool get isEmpty => count == 0;
}

/// Calcula as estatísticas. Só contam saídas que não são transferências, pelo valor efetivo
/// (movimentos ligados valem pelo líquido), como no resto da app.
CategoryStats categoryStats(
  AppState s,
  int categoryId, {
  int months = 12,
  String? endMonthKey,
}) {
  final ids = s.subtreeIds(categoryId);
  final end = endMonthKey ?? s.monthKeyOf(DateTime.now());
  final y = int.parse(end.substring(0, 4)), m = int.parse(end.substring(5, 7));
  final keys = [
    for (var i = months - 1; i >= 0; i--)
      () {
        final d = DateTime(y, m - i);
        return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
      }(),
  ];
  final monthly = <int>[];
  final sub = <String, int>{};
  final merchants = <String, int>{};
  final names = <String, String>{};
  Txn? biggest;
  var biggestCents = 0, count = 0;
  final root = s.cat(categoryId);
  for (final k in keys) {
    var sum = 0;
    for (final t in s.txnsIn(s.periodOfMonth(k))) {
      if (t.isTransfer || t.categoryId == null || !ids.contains(t.categoryId)) {
        continue;
      }
      if (s.flowAmount(t) >= 0) continue;
      final cents = -s.effectiveAmount(t);
      if (cents <= 0) continue;
      sum += cents;
      count++;
      if (cents > biggestCents) {
        biggestCents = cents;
        biggest = t;
      }
      // subcategoria direta (ou a própria categoria, "Geral")
      final chain = [s.cat(t.categoryId)!, ...s.ancestorsOf(s.cat(t.categoryId)!)];
      final top = chain.where((c) => c.parentId == categoryId).firstOrNull;
      final label = top?.name ?? (root?.name ?? '');
      sub.update(label, (v) => v + cents, ifAbsent: () => cents);
      final mk = t.merchantKey.isEmpty ? t.description : t.merchantKey;
      merchants.update(mk, (v) => v + cents, ifAbsent: () => cents);
      names.putIfAbsent(mk, () => t.description);
    }
    monthly.add(sum);
  }
  final total = monthly.fold(0, (a, b) => a + b);
  final first = monthly.indexWhere((v) => v > 0);
  final span = first < 0 ? 1 : monthly.length - first;
  List<MapEntry<String, int>> sorted(Map<String, int> m, [int? take]) {
    final l = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return take == null ? l : l.take(take).toList();
  }

  return CategoryStats(
    monthKeys: keys,
    monthly: monthly,
    total: total,
    averagePerMonth: first < 0 ? 0 : (total / span).round(),
    count: count,
    biggest: biggest,
    bySubcategory: sorted(sub),
    byMerchant: [
      for (final e in sorted(merchants, 5)) MapEntry(names[e.key] ?? e.key, e.value),
    ],
  );
}
