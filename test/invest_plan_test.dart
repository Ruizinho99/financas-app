import 'package:financas/db/database.dart';
import 'package:financas/invest/allocation_plan.dart';
import 'package:financas/invest/invest.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('divisão pelo plano', () {
    test('60/40 de 1000 € dá 600 e 400', () {
      final p = splitByPlan(100000, const [
        PlanLine(1, 6000),
        PlanLine(2, 4000),
      ]);
      expect(p.map((x) => x.cents).toList(), [60000, 40000]);
    });

    test('a soma é exata mesmo com arredondamentos (1/3 de 100 cêntimos)', () {
      final p = splitByPlan(100, const [
        PlanLine(1, 3333),
        PlanLine(2, 3333),
        PlanLine(3, 3334),
      ]);
      expect(p.fold<int>(0, (a, x) => a + x.cents), 100);
    });

    test('plano abaixo de 100%: o resto fica por distribuir', () {
      final p = splitByPlan(100000, const [PlanLine(1, 5000)]);
      expect(p.single.cents, 50000);
      expect(p.fold<int>(0, (a, x) => a + x.cents), 50000);
    });

    test('sem linhas ou valor zero não distribui nada', () {
      expect(splitByPlan(100000, const []), isEmpty);
      expect(splitByPlan(0, const [PlanLine(1, 10000)]), isEmpty);
    });
  });

  test(
    'entregas: só as de depois do plano, por ativo, até marcar como vistas',
    () {
      final s = AppState(Db.memory());
      final bank = s.addAccount('Banco');
      final acc = s.addInvestAccount('XTB');
      final vwce = s.addHolding(Holding(id: 0, accountId: acc, name: 'VWCE'));
      final aapl = s.addHolding(Holding(id: 0, accountId: acc, name: 'Apple'));
      final today = DateTime.now();
      final midnight = DateTime(today.year, today.month, today.day);

      // entrega antes de existir plano: não aparece
      s.addManual(
        date: midnight.subtract(const Duration(days: 5)),
        description: 'Antiga',
        amount: -50000,
        accountId: bank,
        isTransfer: true,
        investAccountId: acc,
      );
      s.setInvestPlan(acc, {vwce: 7000, aapl: 3000});
      expect(s.pendingAllocations, isEmpty);

      s.addManual(
        date: midnight,
        description: 'Entrega nova',
        amount: -100000,
        accountId: bank,
        isTransfer: true,
        investAccountId: acc,
      );
      final p = s.pendingAllocations.single;
      expect(p.txn.description, 'Entrega nova');
      expect(p.parts.map((x) => x.cents).toList(), [70000, 30000]);
      expect(p.undistributed, 0);

      s.dismissAllocation(p.txn.id);
      expect(s.pendingAllocations, isEmpty);
    },
  );

  test('plano incompleto mostra o que falta por distribuir', () {
    final s = AppState(Db.memory());
    final bank = s.addAccount('Banco');
    final acc = s.addInvestAccount('XTB');
    final vwce = s.addHolding(Holding(id: 0, accountId: acc, name: 'VWCE'));
    s.setInvestPlan(acc, {vwce: 5000});
    s.addManual(
      date: DateTime.now(),
      description: 'Entrega',
      amount: -20000,
      accountId: bank,
      isTransfer: true,
      investAccountId: acc,
    );
    final p = s.pendingAllocations.single;
    expect(p.parts.single.cents, 10000);
    expect(p.undistributed, 10000);
  });
}
