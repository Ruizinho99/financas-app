import 'package:financas/db/database.dart';
import 'package:financas/models.dart';
import 'package:financas/recurring/recurring.dart';
import 'package:financas/state/app_state.dart';
import 'package:financas/util/month_cycle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppState s;
  final dia = DateTime(2026, 6, 10);

  int cat(String n, {int? parent, int budget = 0, bool percent = false, String? from, String? to}) =>
      s.addCategory(
        Categoria(
          id: 0,
          name: n,
          parentId: parent,
          budgetValue: budget,
          budgetPercent: percent,
          hasBudget: budget > 0,
          activeFrom: from,
          activeTo: to,
        ),
      );
  void gasto(int c, int cents, {String d = 'x'}) => s.addManual(
    date: dia,
    description: '$d $cents $c',
    amount: -cents,
    categoryId: c,
  );

  setUp(() => s = AppState(Db.memory()));

  test('os movimentos antigos passam para a categoria de destino e a origem desaparece', () {
    final a = cat('Restaurantes');
    final b = cat('Comer fora');
    gasto(a, 1000);
    gasto(a, 500);
    gasto(b, 200);
    expect(s.mergeCategories(a, b), isNull);
    expect(s.cat(a), isNull);
    expect(s.transactions.every((t) => t.categoryId == b), isTrue);
    expect(s.transactions.length, 3);
    expect(s.rollup(s.cat(b)!, s.totalsByCategory(Period.month(DateTime(2026, 6)))), 1700);
  });

  test('regras, períodos obrigatórios, planeamento e recorrentes seguem para o destino', () {
    final a = cat('A');
    final b = cat('B');
    s.db.upsertRule('loja x', a);
    s.addRange(a, '2026-01', '2026-06');
    s.db.savePlannedItem(month: '2026-06', categoryId: a, cents: 5000, mandatory: false);
    s.reload();
    s.saveRecurring(
      RecurringRule(
        description: 'Renda',
        amount: -50000,
        categoryId: a,
        freq: RecurrenceFreq.monthly,
        day: 1,
        start: DateTime(2030, 1, 1),
      ),
      today: DateTime(2026, 6, 1),
    );
    s.mergeCategories(a, b);
    expect(s.recurringRules.single.categoryId, b);
    expect(s.rules.firstWhere((r) => r.pattern == 'loja x').categoryId, b);
    expect(s.mandatoryRanges.single.categoryId, b);
    expect(s.plannedItems.single.categoryId, b);
  });

  test('o ordenado definido como categoria do salário acompanha a unificação', () {
    final a = cat('Salário A');
    final b = cat('Salário B');
    s.setMonthCycle(mode: CycleMode.salary, salaryCategory: a);
    s.mergeCategories(a, b);
    expect(s.salaryCategoryId, b);
  });

  group('subcategorias da origem', () {
    test('passam para dentro do destino, com os seus movimentos', () {
      final a = cat('A');
      final a1 = cat('A1', parent: a);
      final a11 = cat('A11', parent: a1);
      final b = cat('B');
      gasto(a11, 300);
      s.mergeCategories(a, b);
      expect(s.cat(a), isNull);
      expect(s.path(a11), 'B › A1 › A11');
      expect(s.transactions.single.categoryId, a11);
    });

    test('as que têm o mesmo nome unem-se, em qualquer nível', () {
      final a = cat('A');
      final a1 = cat('Casa', parent: a);
      final a1x = cat('Luz', parent: a1);
      final a2 = cat('Só em A', parent: a);
      final b = cat('B');
      final b1 = cat('casa', parent: b); // mesmo nome (sem distinguir maiúsculas)
      final b1x = cat('Luz', parent: b1);
      gasto(a1, 100);
      gasto(a1x, 200);
      gasto(b1x, 50);
      final pv = s.previewMerge(a, b);
      expect(pv.clashes, 2); // A → B, e depois "Casa" e "Luz"
      expect(pv.subcategories, 1); // só "Só em A" muda de sítio
      s.mergeCategories(a, b);
      expect(s.cat(a1), isNull);
      expect(s.cat(a1x), isNull);
      expect(s.cat(a2)!.parentId, b);
      final tx = {for (final t in s.transactions) t.amount: t.categoryId};
      expect(tx[-100], b1);
      expect(tx[-200], b1x);
      expect(tx[-50], b1x);
    });
  });

  group('orçamentos', () {
    test('só a origem tem: o destino herda-o', () {
      final a = cat('A', budget: 20000);
      final b = cat('B');
      expect(s.previewMerge(a, b).bothBudgets, isFalse);
      s.mergeCategories(a, b);
      expect(s.cat(b)!.hasBudget, isTrue);
      expect(s.cat(b)!.budgetValue, 20000);
    });

    test('só o destino tem: mantém-se', () {
      final a = cat('A');
      final b = cat('B', budget: 30000);
      s.mergeCategories(a, b);
      expect(s.cat(b)!.budgetValue, 30000);
    });

    test('os dois têm: somar, manter o destino ou manter a origem', () {
      for (final (mode, esperado) in [
        (BudgetMerge.sum, 50000),
        (BudgetMerge.keepTarget, 30000),
        (BudgetMerge.keepSource, 20000),
      ]) {
        s = AppState(Db.memory());
        final a = cat('A', budget: 20000);
        final b = cat('B', budget: 30000);
        final pv = s.previewMerge(a, b);
        expect(pv.bothBudgets, isTrue);
        expect(pv.sourceBudget, 20000);
        expect(pv.targetBudget, 30000);
        expect(pv.sumBudget, 50000);
        s.mergeCategories(a, b, budget: mode);
        expect(s.cat(b)!.budgetValue, esperado, reason: '$mode');
        expect(s.cat(b)!.hasBudget, isTrue);
      }
    });

    test('somar duas percentagens dá uma percentagem; misto dá valor em euros', () {
      s.setDefaultSalary(100000);
      final a = cat('A', budget: 1000, percent: true); // 10%
      final b = cat('B', budget: 500, percent: true); // 5%
      s.mergeCategories(a, b);
      expect(s.cat(b)!.budgetPercent, isTrue);
      expect(s.cat(b)!.budgetValue, 1500);
      final c = cat('C', budget: 1000, percent: true); // 10% de 1000 € = 100 €
      final d = cat('D', budget: 5000); // 50 €
      s.mergeCategories(c, d);
      expect(s.cat(d)!.budgetPercent, isFalse);
      expect(s.cat(d)!.budgetValue, 15000);
    });
  });

  test('as datas da categoria unida cobrem as duas', () {
    final a = cat('A', from: '2026-01', to: '2026-03');
    final b = cat('B', from: '2026-02', to: '2026-06');
    s.mergeCategories(a, b);
    expect(s.cat(b)!.activeFrom, '2026-01');
    expect(s.cat(b)!.activeTo, '2026-06');
    final c = cat('C'); // sem datas = sempre
    final d = cat('D', from: '2026-02', to: '2026-06');
    s.mergeCategories(c, d);
    expect(s.cat(d)!.activeFrom, isNull);
    expect(s.cat(d)!.activeTo, isNull);
  });

  test('não deixa unificar consigo própria nem com uma subcategoria sua', () {
    final a = cat('A');
    final a1 = cat('A1', parent: a);
    expect(s.canMergeCategories(a, a), MergeError.self);
    expect(s.canMergeCategories(a, a1), MergeError.intoDescendant);
    expect(s.mergeCategories(a, a1), MergeError.intoDescendant);
    expect(s.cat(a), isNotNull);
    // unificar uma filha na mãe é possível
    gasto(a1, 100);
    expect(s.canMergeCategories(a1, a), isNull);
    s.mergeCategories(a1, a);
    expect(s.transactions.single.categoryId, a);
  });
}
