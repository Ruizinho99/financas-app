import 'package:financas/db/database.dart';
import 'package:financas/goals/goals.dart';
import 'package:financas/models.dart';
import 'package:financas/state/app_state.dart';
import 'package:financas/stats/balance_stats.dart';
import 'package:financas/stats/month_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('saldo no fim de cada mês: inicial + movimentos até aí', () {
    final s = AppState(Db.memory());
    final a = s.addAccount('Conta', openingCents: 100000);
    s.addManual(date: DateTime(2026, 9, 10), description: 'A', amount: 50000, accountId: a);
    s.addManual(date: DateTime(2026, 10, 10), description: 'B', amount: -20000, accountId: a);
    s.addManual(date: DateTime(2026, 11, 5), description: 'C', amount: -10000, accountId: a);
    final ser = balanceSeries(s, accountId: a, n: 4, today: DateTime(2026, 11, 14));
    expect([for (final p in ser) p.cents], [100000, 150000, 130000, 120000]);
    expect(balanceSeries(s, n: 4, today: DateTime(2026, 11, 14)).last.cents, 120000);
    expect(s.accountBalance(a), 120000); // o último ponto é o saldo atual
  });

  test('despesa dos últimos meses para o gráfico do Mês', () {
    final s = AppState(Db.memory());
    s.addManual(date: DateTime(2026, 10, 3), description: 'X', amount: -3000);
    s.addManual(date: DateTime(2026, 11, 3), description: 'Y', amount: -5000);
    final ser = spendSeries(s, '2026-11', n: 3);
    expect([for (final e in ser) e.key], ['2026-09', '2026-10', '2026-11']);
    expect([for (final e in ser) e.spent], [0, 3000, 5000]);
    expect(paletteIndex(9), paletteIndex(1)); // estável e dentro das 8 cores
  });

  test('objetivo: acumulado por ordem cronológica', () {
    Txn t(int id, DateTime d) => Txn(id: id, date: d, description: 'x', amount: 100, merchantKey: 'x');
    final p = GoalProgress(
      target: 1000,
      saved: 300,
      monthly: 0,
      entries: [
        GoalEntry(t(2, DateTime(2026, 10, 1)), 200, false, null), // mais recente primeiro
        GoalEntry(t(1, DateTime(2026, 9, 1)), 100, false, null),
      ],
    );
    final c = goalCumulative(p);
    expect([for (final e in c) e.cents], [100, 300]);
    expect(c.first.date, DateTime(2026, 9, 1));
  });
}
