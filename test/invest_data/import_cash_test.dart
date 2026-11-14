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

  InvestOp buy(int acc, DateTime d, int amount) => InvestOp(
    id: 0,
    accountId: acc,
    date: d,
    type: OpType.buy,
    quantity: 1,
    price: amount / 100,
    amount: amount,
  );

  test('ajuste de saldo datado do extrato fixa o dinheiro por alocar', () {
    final s = AppState(Db.memory());
    final acc = s.addInvestAccount('XTB', emoji: '📈');
    s.importTradeOps(
      newHoldings: {'k': Holding(id: 0, accountId: acc, name: 'NVDA')},
      ops: [(key: 'k', op: buy(acc, DateTime(2026, 2, 3), 80000))],
    );
    final asOf = DateTime(2026, 7, 1, 10);
    final cur = s.portfolio.accounts.single.cashCents; // compras importadas não mexem
    s.addOp(InvestOp(id: 0, accountId: acc, date: asOf, type: OpType.cash,
        amount: 100043 - cur, note: 'Saldo do extrato'));
    expect(s.portfolio.accounts.single.cashCents, 100043);
    expect(s.investOps.singleWhere((o) => o.type == OpType.cash).date, asOf);
  });

  test('depósitos ligados não se acumulam: ligar compras e dinheiro movem-se juntos', () {
    final s = AppState(Db.memory());
    final acc = s.addInvestAccount('XTB', emoji: '📈');
    s.addManual(date: DateTime(2026, 1, 5), description: 'Entrega XTB',
        amount: -100000, isTransfer: true, investAccountId: acc);
    s.importTradeOps(
      newHoldings: {'k': Holding(id: 0, accountId: acc, name: 'NVDA')},
      ops: [(key: 'k', op: buy(acc, DateTime(2026, 2, 3), 80000))],
    );
    final t = s.investDeliveries.single;
    // antes de ligar: depósito por alocar na íntegra, nada em espera a menos
    expect(s.portfolio.accounts.single.cashCents, 100000);
    expect(s.transferAllocation(t).onHold, 100000);
    final op = s.investOps.singleWhere((o) => o.type == OpType.buy);
    s.allocateTransfer(t.id, [op.id]);
    expect(s.transferAllocation(t).onHold, 20000);
    expect(s.portfolio.accounts.single.cashCents, 20000); // movem-se juntos
    expect(s.investOps.singleWhere((o) => o.type == OpType.buy).allocate, isTrue);
  });
}
