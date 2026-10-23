import 'package:financas/analysis/analytics.dart';
import 'package:financas/db/database.dart';
import 'package:financas/models.dart';
import 'package:financas/state/app_state.dart';
import 'package:financas/util/month_cycle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppState s;
  late int comida, salario;

  setUp(() {
    s = AppState(Db.memory());
    comida = s.addCategory(const Categoria(id: 0, name: 'Comida'));
    salario = s.addCategory(
      const Categoria(id: 0, name: 'Salário', isIncome: true),
    );
  });

  void gasto(DateTime d, int cents) => s.addManual(
    date: d,
    description: 'Compra',
    amount: -cents,
    categoryId: comida,
  );
  void ordenado(DateTime d, int cents) => s.addManual(
    date: d,
    description: 'Salário',
    amount: cents,
    categoryId: salario,
  );

  test('por omissão o mês é o do calendário', () {
    expect(s.monthMode, CycleMode.calendar);
    final p = s.periodOfMonth('2026-09');
    expect(p.start, DateTime(2026, 9, 1));
    expect(p.end, DateTime(2026, 10, 1));
    expect(s.monthKeyOf(DateTime(2026, 9, 30)), '2026-09');
    expect(s.customMonth, isFalse);
  });

  test('dia 25: setembro vai de 25 de agosto a 24 de setembro', () {
    s.setMonthCycle(mode: CycleMode.fixedDay, day: 25);
    gasto(DateTime(2026, 8, 24), 1000); // agosto
    gasto(DateTime(2026, 8, 25), 2000); // setembro
    gasto(DateTime(2026, 9, 24), 3000); // setembro
    gasto(DateTime(2026, 9, 25), 4000); // outubro

    final set = Analytics(
      s,
      s.periodOfMonth('2026-09'),
      const AnalysisFilter(),
    );
    expect(set.spent, 5000);
    final out = Analytics(
      s,
      s.periodOfMonth('2026-10'),
      const AnalysisFilter(),
    );
    expect(out.spent, 4000);
    expect(s.customMonth, isTrue);
    // a definição fica guardada
    expect(AppState(s.db).monthStartDay, 25);
  });

  test('o mês anterior é o mês anterior da app, não do calendário', () {
    s.setMonthCycle(mode: CycleMode.fixedDay, day: 25);
    final prev = s.previousMonthOf(
      s.periodOfMonth('2026-09'),
      today: DateTime(2027, 1, 1),
    );
    expect(prev!.start, DateTime(2026, 7, 25));
    expect(prev.end, DateTime(2026, 8, 25));
    expect(prev.cycleKey, '2026-08');
  });

  test(
    'automático pelo salário: o mês segue os dias em que o salário chegou',
    () {
      ordenado(DateTime(2026, 1, 24), 100000);
      ordenado(DateTime(2026, 2, 24), 100000);
      ordenado(DateTime(2026, 3, 26), 100000); // chegou mais tarde
      ordenado(DateTime(2026, 4, 25), 100000);
      s.setMonthCycle(mode: CycleMode.salary, salaryCategory: salario);

      gasto(DateTime(2026, 3, 25), 1000); // ainda é o mês de março
      gasto(DateTime(2026, 3, 26), 2000); // já é abril
      expect(s.monthKeyOf(DateTime(2026, 3, 25)), '2026-03');
      expect(s.monthKeyOf(DateTime(2026, 3, 26)), '2026-04');

      final mar = s.periodOfMonth('2026-03');
      expect(mar.start, DateTime(2026, 2, 24));
      expect(mar.end, DateTime(2026, 3, 26));
      expect(Analytics(s, mar, const AnalysisFilter()).spent, 1000);
      final abr = Analytics(
        s,
        s.periodOfMonth('2026-04'),
        const AnalysisFilter(),
      );
      expect(abr.spent, 2000);
    },
  );

  test('automático sem categoria de salário comporta-se como o calendário', () {
    s.setMonthCycle(mode: CycleMode.salary);
    expect(s.periodOfMonth('2026-02').start, DateTime(2026, 2, 1));
    expect(s.monthKeyOf(DateTime(2026, 2, 20)), '2026-02');
  });

  test('gasto real do planeamento segue o mês escolhido', () {
    s.setMonthCycle(mode: CycleMode.fixedDay, day: 25);
    gasto(DateTime(2026, 8, 28), 7000);
    gasto(DateTime(2026, 9, 10), 3000);
    expect(s.actualSpent(comida, '2026-09'), 10000);
    expect(s.actualSpent(comida, '2026-08'), 0);
  });
}
