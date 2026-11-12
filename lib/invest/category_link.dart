import '../state/app_state.dart';
import 'invest.dart';

/// Compras de ativos associados a uma categoria do orçamento, num mês.
class CategoryPurchases {
  final int count; // número de compras
  final int cents; // valor pago (com comissões)
  final Map<String, double> quantityByAsset; // nome do ativo → quantidade comprada
  const CategoryPurchases(this.count, this.cents, this.quantityByAsset);
  bool get isEmpty => count == 0;
}

/// Compras (tipo "compra") do mês [monthKey] ('AAAA-MM') de ativos cuja categoria é [categoryId]
/// ou uma das suas subcategorias.
CategoryPurchases purchasesForCategory(
  AppState s,
  int categoryId,
  String monthKey,
) {
  final ids = s.subtreeIds(categoryId);
  final byId = {
    for (final h in s.holdings)
      if (h.categoryId != null && ids.contains(h.categoryId)) h.id: h,
  };
  if (byId.isEmpty) return const CategoryPurchases(0, 0, {});
  var n = 0, cents = 0;
  final qty = <String, double>{};
  for (final o in s.investOps) {
    if (o.type != OpType.buy || !byId.containsKey(o.holdingId)) continue;
    final k =
        '${o.date.year.toString().padLeft(4, '0')}-${o.date.month.toString().padLeft(2, '0')}';
    if (k != monthKey) continue;
    n++;
    cents += o.amount;
    qty.update(
      byId[o.holdingId]!.name,
      (v) => v + o.quantity,
      ifAbsent: () => o.quantity,
    );
  }
  return CategoryPurchases(n, cents, qty);
}
