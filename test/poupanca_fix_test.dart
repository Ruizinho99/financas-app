import 'package:financas/analysis/analytics.dart';
import 'package:financas/db/database.dart';
import 'package:financas/invest/category_link.dart';
import 'package:financas/invest/invest.dart';
import 'package:financas/models.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('poupança conta em saved, investimento em invested, nenhum é gasto', () {
    final s = AppState(Db.memory());
    final sav = s.addCategory(Categoria(id: 0, name: 'Poup', isSavings: true));
    final inv = s.addCategory(Categoria(id: 0, name: 'Inv', isInvestment: true));
    final food = s.addCategory(Categoria(id: 0, name: 'Comida'));
    s.addManual(date: DateTime(2026, 6, 2), description: 'P', amount: -10000, categoryId: sav);
    s.addManual(date: DateTime(2026, 6, 3), description: 'I', amount: -7000, categoryId: inv);
    s.addManual(date: DateTime(2026, 6, 4), description: 'C', amount: -4000, categoryId: food);
    final a = Analytics(
      s,
      Period.month(DateTime(2026, 6)),
      const AnalysisFilter(),
      today: DateTime(2026, 6, 15),
    );
    expect(a.saved, 10000);
    expect(a.invested, 7000);
    expect(a.spent, 4000);
  });

  group('budgetTypeAfterKindChange', () {
    BudgetType f(BudgetType cur, bool hb, bool changed, bool was, bool now) =>
        budgetTypeAfterKindChange(
          current: cur,
          hasBudget: hb,
          kindChanged: changed,
          wasSetAside: was,
          isSetAside: now,
        );
    test('despesa sem orçamento -> poupança/investimento vira meta', () {
      expect(f(BudgetType.limit, false, true, false, true), BudgetType.goal);
    });
    test('de volta a despesa normal vira limite', () {
      expect(f(BudgetType.goal, false, true, true, false), BudgetType.limit);
      expect(f(BudgetType.goal, true, true, true, false), BudgetType.limit);
    });
    test('orçamento explícito com tipo não habitual não é mexido', () {
      expect(f(BudgetType.goal, true, true, false, true), BudgetType.goal);
      expect(f(BudgetType.goal, true, true, false, false), BudgetType.goal);
    });
    test('sem mudança de tipo nada muda', () {
      expect(f(BudgetType.limit, false, false, false, true), BudgetType.limit);
    });
  });

  test('plannedForAsset: orçamento da categoria manda sobre o plano do ativo', () {
    expect(
      plannedForAsset(holdingPlanCents: 150, categoryHasBudget: true, categoryMonthlyTarget: 100),
      100,
    );
    expect(
      plannedForAsset(holdingPlanCents: 150, categoryHasBudget: false, categoryMonthlyTarget: 0),
      150,
    );
  });

  test('purchasesForCategory usa o orçamento da subcategoria', () {
    final s = AppState(Db.memory());
    final inv = s.addCategory(Categoria(id: 0, name: 'Inv', isInvestment: true));
    final sub = s.addCategory(
      Categoria(
        id: 0,
        name: 'VWCE',
        parentId: inv,
        isInvestment: true,
        hasBudget: true,
        budgetType: BudgetType.goal,
        budgetValue: 100,
      ),
    );
    final plain = s.addCategory(
      Categoria(id: 0, name: 'Outro', parentId: inv, isInvestment: true),
    );
    final acc = s.addInvestAccount('XTB');
    s.addHolding(Holding(id: 0, accountId: acc, name: 'A', monthlyPlanCents: 150, categoryId: sub));
    s.addHolding(Holding(id: 0, accountId: acc, name: 'B', monthlyPlanCents: 150, categoryId: plain));
    final r = purchasesForCategory(s, inv, '2026-06');
    expect({for (final a in r.assets) a.name: a.plannedCents}, {'A': 100, 'B': 150});
  });
}
