import 'package:financas/db/database.dart';
import 'package:financas/models.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('poupança: não conta como gasto, herda para subcategorias e sobrevive à gravação', () {
    final s = AppState(Db.memory());
    final sav = s.addCategory(Categoria(id: 0, name: 'Poupanças', isSavings: true));
    final food = s.addCategory(Categoria(id: 0, name: 'Comida'));
    s.addManual(date: DateTime(2026, 11, 2), description: 'FUNDO', amount: -10000, categoryId: sav);
    s.addManual(date: DateTime(2026, 11, 3), description: 'MERCADO', amount: -4000, categoryId: food);
    final spend = s.transactions.where(s.isSpend).fold<int>(0, (a, t) => a + (-t.amount));
    expect(spend, 4000); // só a comida é gasto
    expect(s.db.categories().firstWhere((c) => c.id == sav).isSavings, isTrue);
    expect(s.cat(sav)!.isSetAside, isTrue);
    expect(s.cat(food)!.isSetAside, isFalse);
  });
}
