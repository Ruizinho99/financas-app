import 'package:financas/db/database.dart';
import 'package:financas/invest/category_link.dart';
import 'package:financas/invest/invest.dart';
import 'package:financas/models.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ativo associado a categoria: compras do mês, quantidades e subcategorias', () {
    final s = AppState(Db.memory());
    final inv = s.addCategory(Categoria(id: 0, name: 'Investimentos'));
    final sub = s.addCategory(Categoria(id: 0, name: 'Ações', parentId: inv));
    final acc = s.addInvestAccount('XTB', emoji: '📈');
    final nv = s.addHolding(
      Holding(id: 0, accountId: acc, name: 'NVD.DE', categoryId: sub),
    );
    final outro = s.addHolding(Holding(id: 0, accountId: acc, name: 'Outro'));
    InvestOp buy(int h, DateTime d, double q, int cents) => InvestOp(
      id: 0, accountId: acc, holdingId: h, date: d,
      type: OpType.buy, quantity: q, price: cents / 100 / q, amount: cents,
    );
    s.addOp(buy(nv, DateTime(2026, 11, 3, 9, 41), 0.5, 7000));
    s.addOp(buy(nv, DateTime(2026, 11, 20, 15, 5), 0.3, 4000));
    s.addOp(buy(nv, DateTime(2026, 10, 20), 1, 9999)); // outro mês
    s.addOp(buy(outro, DateTime(2026, 11, 4), 1, 5000)); // sem categoria

    // a categoria principal conta a subcategoria
    final p = purchasesForCategory(s, inv, '2026-11');
    expect(p.count, 2);
    expect(p.cents, 11000);
    expect(p.quantityByAsset['NVD.DE'], closeTo(0.8, 1e-9));
    expect(purchasesForCategory(s, inv, '2026-09').isEmpty, isTrue);

    // a categoria sobrevive à gravação e a hora das compras também
    final h = s.db.holdings().firstWhere((x) => x.id == nv);
    expect(h.categoryId, sub);
    final ops = s.db.investOps().where((o) => o.holdingId == nv).toList();
    expect(ops.any((o) => o.date == DateTime(2026, 11, 3, 9, 41)), isTrue);
    expect(ops.any((o) => o.date == DateTime(2026, 10, 20)), isTrue); // sem hora: só o dia
  });
}
