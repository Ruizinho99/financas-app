import '../models.dart';

/// Objetivo de poupança (ex.: férias). Cada objetivo tem uma subcategoria própria: os movimentos
/// nessa subcategoria são poupança para o objetivo, e os movimentos associados a ele reduzem o que falta.
class Goal {
  final int id;
  final String name;
  final String description;
  final int categoryId; // subcategoria do objetivo
  final int targetCents; // valor atual do objetivo (o histórico fica em [GoalTargetChange])
  final DateTime? endDate; // prazo (opcional)
  final bool archived;

  const Goal({
    required this.id,
    required this.name,
    this.description = '',
    required this.categoryId,
    required this.targetCents,
    this.endDate,
    this.archived = false,
  });

  Goal copyWith({
    String? name,
    String? description,
    int? targetCents,
    Object? endDate = _keep,
    bool? archived,
  }) => Goal(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    categoryId: categoryId,
    targetCents: targetCents ?? this.targetCents,
    endDate: identical(endDate, _keep) ? this.endDate : endDate as DateTime?,
    archived: archived ?? this.archived,
  );
}

const Object _keep = Object();

/// Movimento associado a um objetivo, com o valor que lhe corresponde (um movimento pode ser dividido).
class GoalAllocation {
  final int id;
  final int txnId;
  final int goalId;
  final int cents; // valor absoluto
  const GoalAllocation({
    required this.id,
    required this.txnId,
    required this.goalId,
    required this.cents,
  });
}

/// Alteração do valor do objetivo (o primeiro registo é a criação).
class GoalTargetChange {
  final DateTime date;
  final int cents;
  const GoalTargetChange(this.date, this.cents);
}

/// Uma parcela do progresso: um movimento que conta para o objetivo.
class GoalEntry {
  final Txn txn;
  final int cents;
  final bool manual; // true: associado à mão; false: pela categoria do objetivo
  final int? allocationId;
  const GoalEntry(this.txn, this.cents, this.manual, this.allocationId);
}

/// Estado de um objetivo, calculado a partir dos movimentos.
class GoalProgress {
  final int target;
  final int saved; // tudo o que já entrou ou foi pago para o objetivo
  final List<GoalEntry> entries; // mais recentes primeiro
  final int monthly; // média mensal dos últimos 3 meses
  final int? neededPerMonth; // o que falta poupar por mês até ao prazo (nulo sem prazo ou se já atingido)
  final bool? onTrack; // ao ritmo atual chega a tempo? (nulo sem prazo)
  final DateTime?
  eta; // quando chega ao ritmo atual (nulo se não há ritmo ou já está atingido)

  const GoalProgress({
    required this.target,
    required this.saved,
    required this.entries,
    required this.monthly,
    this.neededPerMonth,
    this.onTrack,
    this.eta,
  });

  int get remaining => target - saved;
  bool get done => remaining <= 0;
  double get fraction => target <= 0 ? 1 : (saved / target).clamp(0.0, 1.0);
}

/// Progresso de [g]. Falta = alvo − (associado à mão + movimentos na categoria do objetivo).
/// Um movimento associado a algum objetivo deixa de contar pela categoria: manda a associação.
GoalProgress goalProgress(
  Goal g, {
  required List<Txn> txns,
  required List<GoalAllocation> allocs,
  required DateTime today,
}) {
  final byId = {for (final t in txns) t.id: t};
  final allocatedTxns = {for (final a in allocs) a.txnId};
  final entries = <GoalEntry>[];
  for (final a in allocs) {
    if (a.goalId != g.id) continue;
    final t = byId[a.txnId];
    if (t != null) entries.add(GoalEntry(t, a.cents, true, a.id));
  }
  for (final t in txns) {
    if (t.categoryId != g.categoryId || allocatedTxns.contains(t.id)) continue;
    entries.add(GoalEntry(t, t.amount.abs(), false, null));
  }
  entries.sort((a, b) => b.txn.date.compareTo(a.txn.date));
  final saved = entries.fold(0, (s, e) => s + e.cents);

  final since = today.subtract(const Duration(days: 90));
  final recent = entries
      .where((e) => !e.txn.date.isBefore(since))
      .fold(0, (s, e) => s + e.cents);
  final monthly = recent ~/ 3;

  final remaining = g.targetCents - saved;
  int? needed;
  bool? onTrack;
  final end = g.endDate;
  if (end != null && remaining > 0) {
    final days = end.difference(today).inDays;
    final months = days <= 0 ? 1 : (days / 30.44).ceil();
    needed = remaining ~/ months + (remaining % months == 0 ? 0 : 1);
    onTrack = monthly >= needed;
  }
  DateTime? eta;
  if (remaining > 0 && monthly > 0) {
    eta = today.add(Duration(days: (remaining / monthly * 30.44).round()));
  }
  return GoalProgress(
    target: g.targetCents,
    saved: saved,
    entries: entries,
    monthly: monthly,
    neededPerMonth: needed,
    onTrack: onTrack,
    eta: eta,
  );
}
