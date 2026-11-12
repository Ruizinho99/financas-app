import 'package:financas/db/database.dart';
import 'package:financas/invest/analysis/portfolio_analysis.dart';
import 'package:financas/invest/data/price_history.dart';
import 'package:financas/invest/invest.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

PriceHistory _hist(String sym, double Function(int) f) => PriceHistory(
  symbol: sym,
  points: [
    for (var i = 0; i < 120; i++)
      PricePoint(DateTime.utc(2026, 1, 1).add(Duration(days: i)), f(i)),
  ],
);

void main() {
  test('carteira: XIRR, pesos, concentração, risco e dividendos', () {
    final s = AppState(Db.memory());
    final acc = s.addInvestAccount('XTB', emoji: '📈');
    final a = s.addHolding(Holding(id: 0, accountId: acc, name: 'A', symbol: 'AAA',
        provider: PriceProvider.yahoo, lastPrice: 110));
    final b = s.addHolding(Holding(id: 0, accountId: acc, name: 'B', symbol: 'BBB',
        provider: PriceProvider.yahoo, lastPrice: 50));
    // A: 10 un a 100 há ~1 ano (investido 1000, vale 1100); B: 20 un a 50 (1000 → 1000)
    s.addOp(InvestOp(id: 0, accountId: acc, holdingId: a,
        date: DateTime(2025, 11, 12), type: OpType.buy, quantity: 10, price: 100, amount: 100000));
    s.addOp(InvestOp(id: 0, accountId: acc, holdingId: b,
        date: DateTime(2025, 11, 12), type: OpType.buy, quantity: 20, price: 50, amount: 100000));
    s.addOp(InvestOp(id: 0, accountId: acc, holdingId: a,
        date: DateTime(2026, 5, 1), type: OpType.dividend, amount: 2000));

    final r = buildPortfolioReport(
      portfolio: s.portfolio,
      ops: s.investOps,
      now: DateTime(2026, 11, 12),
      histories: {
        'AAA': _hist('AAA', (i) => 100 + i * 0.1),
        'BBB': _hist('BBB', (i) => 50 + (i.isEven ? 1 : -1)),
      },
    );
    expect(r.valueCents, 210000);
    expect(r.weights.first.position.holding.name, 'A');
    expect(r.weights.first.weight, closeTo(1100 / 2100, 1e-9));
    // (1100+1000+20) / 2000 ≈ +6% em 1 ano
    expect(r.xirr, closeTo(0.06, 0.01));
    expect(r.dividendsCents, 2000);
    expect(r.yieldOnCost, closeTo(20 / 2000, 1e-9));
    expect(r.concentration.firstWhere((m) => m.key == 'hhi').value, closeTo(0.5011, 0.001));
    expect(r.riskCovered, 2);
    expect(r.riskMetric('volatilidade_anualizada')?.available, isTrue);
    expect(r.byCurrency.values.fold<double>(0, (a, b) => a + b), closeTo(1, 1e-9));
  });

  test('sem histórico: só retorno e concentração, risco vazio', () {
    final s = AppState(Db.memory());
    final r = buildPortfolioReport(
      portfolio: s.portfolio,
      ops: s.investOps,
      now: DateTime(2026, 11, 12),
    );
    expect(r.risk, isEmpty);
    expect(r.xirr, isNull);
  });
}
