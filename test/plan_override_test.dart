import 'package:financas/db/database.dart';
import 'package:financas/models.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('valor planeado só para um mês manda sobre o orçamento da categoria', () {
    final s = AppState(Db.memory());
    final inv = s.addCategory(
      Categoria(id: 0, name: 'Investimento', isInvestment: true,
          hasBudget: true, budgetValue: 20000, budgetType: BudgetType.goal),
    );
    final c = s.cat(inv)!;
    expect(s.effectiveMonthlyTarget(c, 0, '2026-11'), 20000);
    s.addPlanned(month: '2026-11', categoryId: inv, cents: 35000, mandatory: false);
    expect(s.effectiveMonthlyTarget(c, 0, '2026-11'), 35000);
    expect(s.effectiveMonthlyTarget(c, 0, '2026-12'), 20000); // outros meses não mudam
    // o total alocado do mês usa o valor planeado
    expect(s.totalAllocated(0, '2026-11'), 35000);
  });

  test('distribuir pelas subcategorias: a soma dos filhos pode ser comparada com a mãe', () {
    final s = AppState(Db.memory());
    final inv = s.addCategory(Categoria(id: 0, name: 'Investimento', isInvestment: true,
        hasBudget: true, budgetValue: 30000, budgetType: BudgetType.goal));
    final a = s.addCategory(Categoria(id: 0, name: 'NVDA', parentId: inv, isInvestment: true));
    final b = s.addCategory(Categoria(id: 0, name: 'VWCE', parentId: inv, isInvestment: true));
    s.updateCategory(s.cat(a)!.copyWith(hasBudget: true, budgetValue: 10000, budgetType: BudgetType.goal));
    s.updateCategory(s.cat(b)!.copyWith(hasBudget: true, budgetValue: 20000, budgetType: BudgetType.goal));
    final kids = s.childrenOf(inv);
    expect(kids.fold<int>(0, (x, k) => x + k.monthlyTarget(0)), 30000);
    expect(s.effectiveMonthlyTarget(s.cat(inv)!, 0, '2026-11'), 30000); // não conta a dobrar
  });
}
