import 'package:financas/analysis/analytics.dart';
import 'package:financas/db/database.dart';
import 'package:financas/goals/goals.dart';
import 'package:financas/models.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppState s;
  late int lazer, viagens, poupanca;
  final day = DateTime(2026, 10, 5);
  final today = DateTime(2026, 10, 12);

  setUp(() {
    s = AppState(Db.memory());
    lazer = s.addCategory(const Categoria(id: 0, name: 'Lazer'));
    viagens = s.addCategory(const Categoria(id: 0, name: 'Viagens'));
    poupanca = s.addCategory(const Categoria(id: 0, name: 'Poupança'));
  });

  int idOf(String desc) =>
      s.transactions.lastWhere((t) => t.description == desc).id;

  test('exemplo: alvo 1000, pagamento de 500 associado → faltam 500; alvo passa a 1200 → faltam 700', () {
    final g = s.goals.isEmpty ? s.goals.length : 0; // só para não ficar sem uso
    expect(g, 0);
    final gid = s.addGoal(
      name: 'Férias',
      parentCategoryId: lazer,
      targetCents: 100000,
    );
    final goal = s.goals.firstWhere((x) => x.id == gid);
    s.addManual(
      date: day,
      description: 'Prestação férias',
      amount: -50000,
      categoryId: viagens,
    );
    s.linkMovement(idOf('Prestação férias'), gid, 50000);
    var p = s.goalProgressOf(goal);
    expect(p.remaining, 50000);
    expect(p.saved, 50000);

    s.changeGoalTarget(goal, 120000);
    final goal2 = s.goals.firstWhere((x) => x.id == gid);
    p = s.goalProgressOf(goal2);
    expect(p.target, 120000);
    expect(p.remaining, 70000);
    // o histórico guarda o valor antigo e o novo
    expect(s.goalHistory(gid).map((h) => h.cents), [100000, 120000]);
  });

  test('transferência dividida: 50 para férias e 50 para alimentação', () {
    final f = s.addGoal(
      name: 'Férias',
      parentCategoryId: lazer,
      targetCents: 100000,
    );
    final a = s.addGoal(
      name: 'Alimentação',
      parentCategoryId: lazer,
      targetCents: 40000,
    );
    s.addManual(
      date: day,
      description: 'Transferência Money',
      amount: -10000,
      categoryId: poupanca,
    );
    final id = idOf('Transferência Money');
    s.linkMovement(id, f, 5000);
    s.linkMovement(id, a, 5000);
    final pf = s.goalProgressOf(s.goals.firstWhere((x) => x.id == f));
    final pa = s.goalProgressOf(s.goals.firstWhere((x) => x.id == a));
    expect(pf.saved, 5000);
    expect(pa.saved, 5000);
    expect(s.goalAllocations.where((x) => x.txnId == id).length, 2);
    // um movimento dividido não pode ser associado por mais do que o seu valor
    expect(s.allocatedOf(id), 10000);
  });

  test('movimentos na subcategoria do objetivo contam como poupança e não como gasto', () {
    final gid = s.addGoal(
      name: 'Carro',
      parentCategoryId: lazer,
      targetCents: 2000000,
    );
    final goal = s.goals.firstWhere((x) => x.id == gid);
    s.addManual(
      date: day,
      description: 'Poupança mensal',
      amount: -30000,
      categoryId: goal.categoryId,
    );
    final p = s.goalProgressOf(goal);
    expect(p.saved, 30000);
    final a = Analytics(
      s,
      Period.month(DateTime(2026, 10)),
      const AnalysisFilter(),
    );
    expect(a.spent, 0);
  });

  test('previsão: com prazo, diz se o ritmo chega a tempo', () {
    const g = Goal(
      id: 1,
      name: 'x',
      categoryId: 1,
      targetCents: 120000,
      endDate: null,
    );
    final end = today.add(const Duration(days: 120)); // ~4 meses
    final goal = g.copyWith(endDate: end);
    // 300 € nos últimos 3 meses → 100 €/mês; faltam 1200 € → precisa de ~300/mês em 4 meses
    final txns = [
      Txn(
        id: 1,
        date: today.subtract(const Duration(days: 20)),
        description: 'Depósito',
        amount: -30000,
        merchantKey: 'd',
        categoryId: 1, // a subcategoria do objetivo de teste
      ),
    ];
    final p = goalProgress(goal, txns: txns, allocs: const [], today: today);
    expect(p.saved, 30000);
    expect(p.remaining, 90000);
    expect(p.onTrack, isFalse);
    expect(p.neededPerMonth, greaterThan(10000));
  });

  test('sem movimentos recentes não há previsão de data', () {
    const g = Goal(id: 1, name: 'x', categoryId: 1, targetCents: 50000);
    final p = goalProgress(g, txns: const [], allocs: const [], today: today);
    expect(p.eta, isNull);
    expect(p.remaining, 50000);
    expect(p.done, isFalse);
  });

  test('apagar o objetivo remove as associações e arquiva a subcategoria', () {
    final gid = s.addGoal(
      name: 'Telemóvel',
      parentCategoryId: lazer,
      targetCents: 50000,
    );
    s.addManual(
      date: day,
      description: 'Compra',
      amount: -10000,
      categoryId: viagens,
    );
    s.linkMovement(idOf('Compra'), gid, 10000);
    final goal = s.goals.firstWhere((x) => x.id == gid);
    s.deleteGoal(goal);
    expect(s.goals.where((x) => x.id == gid), isEmpty);
    expect(s.goalAllocations, isEmpty);
    expect(s.cat(goal.categoryId)?.archived, isTrue);
  });
}
