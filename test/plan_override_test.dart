import 'package:financas/db/database.dart';
import 'package:financas/models.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

String _key(int monthsAhead) {
  final n = DateTime.now();
  final d = DateTime(n.year, n.month + monthsAhead);
  return '${d.year}-${d.month.toString().padLeft(2, '0')}';
}

void main() {
  test('valor planeado só para um mês manda sobre o orçamento da categoria', () {
    final s = AppState(Db.memory());
    final inv = s.addCategory(
      Categoria(id: 0, name: 'Investimento', isInvestment: true,
          hasBudget: true, budgetValue: 20000, budgetType: BudgetType.goal),
    );
    final c = s.cat(inv)!;
    final now = _key(0), next = _key(1);
    expect(s.effectiveMonthlyTarget(c, 0, now), 20000);
    s.addPlanned(month: now, categoryId: inv, cents: 35000, mandatory: false);
    expect(s.effectiveMonthlyTarget(c, 0, now), 35000);
    expect(s.effectiveMonthlyTarget(c, 0, next), 20000); // outros meses não mudam
    // o total alocado do mês usa o valor planeado
    expect(s.totalAllocated(0, now), 35000);
  });

  test('valor planeado de meses passados não altera o histórico', () {
    final s = AppState(Db.memory());
    final casa = s.addCategory(
      const Categoria(id: 0, name: 'Casa', hasBudget: true, budgetValue: 80000),
    );
    final past = _key(-2);
    s.addPlanned(month: past, categoryId: casa, cents: 99999, mandatory: true);
    expect(s.effectiveMonthlyTarget(s.cat(casa)!, 0, past), 80000);
    // o do mês atual e dos futuros continua a mandar
    s.addPlanned(month: _key(0), categoryId: casa, cents: 70000, mandatory: true);
    s.addPlanned(month: _key(1), categoryId: casa, cents: 60000, mandatory: true);
    expect(s.effectiveMonthlyTarget(s.cat(casa)!, 0, _key(0)), 70000);
    expect(s.effectiveMonthlyTarget(s.cat(casa)!, 0, _key(1)), 60000);
  });

  test('a mãe com orçamento próprio manda sobre o valor planeado de uma filha', () {
    final s = AppState(Db.memory());
    final casa = s.addCategory(
      const Categoria(id: 0, name: 'Casa', hasBudget: true, budgetValue: 80000),
    );
    final renda = s.addCategory(Categoria(id: 0, name: 'Renda', parentId: casa));
    s.addCategory(
      const Categoria(id: 0, name: 'Lazer', hasBudget: true, budgetValue: 20000),
    );
    s.addPlanned(month: _key(0), categoryId: renda, cents: 70000, mandatory: true);
    expect(s.totalAllocated(200000, _key(0)), 100000);
  });
}
