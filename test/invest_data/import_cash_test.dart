import 'package:financas/db/database.dart';
import 'package:financas/invest/invest.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('compras importadas não mexem no dinheiro por alocar', () {
    final s = AppState(Db.memory());
    final acc = s.addInvestAccount('XTB', emoji: '📈');
    s.addOp(InvestOp(id: 0, accountId: acc, date: DateTime(2026, 1, 1),
        type: OpType.cash, amount: 50000));
    final n = s.importTradeOps(
      newHoldings: {'k': Holding(id: 0, accountId: acc, name: 'NVDA')},
      ops: [
        (
          key: 'k',
          op: InvestOp(id: 0, accountId: acc, date: DateTime(2026, 2, 3, 14, 30),
              type: OpType.buy, quantity: 2, price: 400, amount: 80000),
        ),
      ],
    );
    expect(n, 1);
    final a = s.portfolio.accounts.single;
    expect(a.cashCents, 50000); // não ficou negativo
    expect(a.positions.single.qty, 2); // mas a posição existe
  });
}
