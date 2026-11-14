import '../goals/goals.dart';
import '../state/app_state.dart';

/// Saldo no fim de cada um dos [n] meses (o mês em curso termina hoje), do mais antigo para o mais recente.
/// [accountId] nulo = soma de todas as contas. Saldo = saldo inicial + movimentos até essa data.
List<({DateTime end, int cents})> balanceSeries(
  AppState s, {
  int? accountId,
  int n = 12,
  DateTime? today,
}) {
  final now = today ?? DateTime.now();
  final accounts = accountId == null
      ? s.accounts
      : s.accounts.where((a) => a.id == accountId).toList();
  final ids = {for (final a in accounts) a.id};
  final opening = accounts.fold<int>(0, (a, c) => a + c.openingCents);
  final txns = s.transactions
      .where((t) => t.accountId != null && ids.contains(t.accountId))
      .toList();
  return [
    for (var i = n - 1; i >= 0; i--)
      () {
        // fim do mês i meses atrás (exclusivo: dia 1 do mês seguinte); o atual vai até amanhã
        final next = DateTime(now.year, now.month - i + 1);
        final end = i == 0 ? DateTime(now.year, now.month, now.day + 1) : next;
        var sum = opening;
        for (final t in txns) {
          if (t.date.isBefore(end)) sum += t.amount;
        }
        return (end: i == 0 ? now : next.subtract(const Duration(days: 1)), cents: sum);
      }(),
  ];
}

/// Acumulado de um objetivo ao longo do tempo: (data, total guardado até essa data), por ordem cronológica.
List<({DateTime date, int cents})> goalCumulative(GoalProgress p) {
  final es = [...p.entries]..sort((a, b) => a.txn.date.compareTo(b.txn.date));
  var total = 0;
  return [
    for (final e in es)
      () {
        total += e.cents;
        return (date: e.txn.date, cents: total);
      }(),
  ];
}
