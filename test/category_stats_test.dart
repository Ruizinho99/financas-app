import 'package:financas/budget/budget_stats.dart';
import 'package:financas/db/database.dart';
import 'package:financas/models.dart';
import 'package:financas/stats/category_stats.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('estatísticas de categoria: meses, média, subcategorias e onde mais gastas', () {
    final s = AppState(Db.memory());
    final food = s.addCategory(Categoria(id: 0, name: 'Alimentação'));
    final sup = s.addCategory(Categoria(id: 0, name: 'Supermercado', parentId: food));
    final cafe = s.addCategory(Categoria(id: 0, name: 'Café', parentId: food));
    void add(DateTime d, String desc, int cents, int cat) {
      s.addManual(date: d, description: desc, amount: -cents, categoryId: cat);
    }
    add(DateTime(2026, 9, 5), 'CONTINENTE', 5000, sup);
    add(DateTime(2026, 10, 5), 'CONTINENTE', 7000, sup);
    add(DateTime(2026, 10, 9), 'PASTELARIA', 300, cafe);
    add(DateTime(2026, 11, 2), 'PINGO DOCE', 2000, sup);
    s.addManual(date: DateTime(2026, 11, 3), description: 'REEMBOLSO', amount: 1000, categoryId: sup);

    final st = categoryStats(s, food, months: 3, endMonthKey: '2026-11');
    expect(st.monthKeys, ['2026-09', '2026-10', '2026-11']);
    expect(st.monthly, [5000, 7300, 2000]);
    expect(st.total, 14300);
    expect(st.averagePerMonth, (14300 / 3).round());
    expect(st.count, 4);
    expect(st.biggest!.description, 'CONTINENTE');
    expect(st.bySubcategory.first.key, 'Supermercado');
    expect(st.bySubcategory.first.value, 14000);
    expect(st.byMerchant.first.value, 12000);
  });

  test('orçamento: tendência de 6 meses e previsão do fim do mês', () {
    final s = AppState(Db.memory());
    final c = s.addCategory(Categoria(id: 0, name: 'Compras'));
    s.addManual(date: DateTime(2026, 9, 5), description: 'LOJA', amount: -3000, categoryId: c);
    s.addManual(date: DateTime(2026, 11, 5), description: 'LOJA', amount: -5000, categoryId: c);
    final cat = s.cat(c)!;
    expect(trendOf(s, cat, '2026-11'), [0, 0, 0, 3000, 0, 5000]);
    expect(forecastEnd(5000, 0.5), 10000);
    expect(forecastEnd(0, 0.5), isNull);
    expect(forecastEnd(5000, null), isNull);
  });
}
