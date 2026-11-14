import '../state/app_state.dart';
import 'invest.dart';

/// Compras de ativos associados a uma categoria do orçamento, num mês.
class CategoryPurchases {
  final int count; // número de compras
  final int cents; // valor pago (com comissões)
  final Map<String, double> quantityByAsset; // nome do ativo → quantidade comprada
  final List<AssetPurchases> assets; // por ativo (inclui os planeados sem compras)
  const CategoryPurchases(
    this.count,
    this.cents,
    this.quantityByAsset, [
    this.assets = const [],
  ]);
  bool get isEmpty => count == 0 && assets.every((a) => a.plannedCents == 0);
}

/// Compras de um ativo no mês, comparadas com o planeado.
class AssetPurchases {
  final String name;
  final int plannedCents; // 0 = sem plano
  final int boughtCents;
  final double quantity;
  final int count;
  const AssetPurchases(
    this.name,
    this.plannedCents,
    this.boughtCents,
    this.quantity,
    this.count,
  );
}

/// Categoria por omissão para um ativo novo (importação): a mais usada pelos ativos da mesma plataforma;
/// senão a única categoria de despesa marcada como investimento; senão nenhuma.
int? defaultCategoryForNewHolding(AppState s, int accountId) {
  final count = <int, int>{};
  for (final h in s.holdings) {
    if (h.accountId == accountId && h.categoryId != null) {
      count.update(h.categoryId!, (v) => v + 1, ifAbsent: () => 1);
    }
  }
  if (count.isNotEmpty) {
    return (count.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
        .first
        .key;
  }
  final inv = s.categories.where((c) => c.isInvestment && !c.isIncome).toList();
  return inv.length == 1 ? inv.first.id : null;
}

/// Fonte única do "planeado" por ativo: se a categoria do ativo tem orçamento próprio, vale esse
/// valor mensal; senão o plano do próprio ativo ([holdingPlanCents]).
int plannedForAsset({
  required int holdingPlanCents,
  required bool categoryHasBudget,
  required int categoryMonthlyTarget,
}) => categoryHasBudget ? categoryMonthlyTarget : holdingPlanCents;

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
  final per = <int, (int, double, int)>{}; // holdingId → (cêntimos, quantidade, compras)
  for (final o in s.investOps) {
    if (o.type != OpType.buy || !byId.containsKey(o.holdingId)) continue;
    final k =
        '${o.date.year.toString().padLeft(4, '0')}-${o.date.month.toString().padLeft(2, '0')}';
    if (k != monthKey) continue;
    n++;
    cents += o.amount;
    final a = per[o.holdingId] ?? (0, 0.0, 0);
    per[o.holdingId!] = (a.$1 + o.amount, a.$2 + o.quantity, a.$3 + 1);
    qty.update(
      byId[o.holdingId]!.name,
      (v) => v + o.quantity,
      ifAbsent: () => o.quantity,
    );
  }
  final salary = s.salaryFor(monthKey);
  int plan(Holding h) {
    final c = s.cat(h.categoryId);
    return plannedForAsset(
      holdingPlanCents: h.monthlyPlanCents,
      categoryHasBudget: c != null && c.hasBudget,
      categoryMonthlyTarget: c == null
          ? 0
          : s.effectiveMonthlyTarget(c, salary, monthKey),
    );
  }

  final assets = [
    for (final h in byId.values)
      if (per.containsKey(h.id) || plan(h) > 0)
        AssetPurchases(
          h.name,
          plan(h),
          per[h.id]?.$1 ?? 0,
          per[h.id]?.$2 ?? 0,
          per[h.id]?.$3 ?? 0,
        ),
  ];
  return CategoryPurchases(n, cents, qty, assets);
}
