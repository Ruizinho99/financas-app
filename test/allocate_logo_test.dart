import 'dart:typed_data';

import 'package:financas/db/database.dart';
import 'package:financas/invest/invest.dart';
import 'package:financas/invest/price_service.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final _png = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10, 1, 2, 3]);

AppState _state() => AppState(
  Db.memory(),
  prices: PriceService(
    client: MockClient((r) async {
      if (r.url.host == 'assets.parqet.com' &&
          r.url.path == '/logos/symbol/AAPL') {
        return http.Response.bytes(
          _png,
          200,
          headers: {'content-type': 'image/png'},
        );
      }
      return http.Response('', 404);
    }),
  ),
);

void main() {
  test('compra sem alocação não desconta do dinheiro por alocar', () {
    final s = _state();
    final acc = s.addInvestAccount('XTB');
    final aapl = s.addHolding(
      Holding(
        id: 0,
        accountId: acc,
        name: 'Apple',
        kind: HoldingKind.stock,
        lastPrice: 150,
      ),
    );
    final day = DateTime(2026, 10, 1);
    // compra registada antes da transferência: desconta (fica a dever)
    s.addOp(
      InvestOp(
        id: 0,
        accountId: acc,
        holdingId: aapl,
        date: day,
        type: OpType.buy,
        quantity: 2,
        price: 100,
        amount: 20000,
      ),
    );
    expect(s.portfolio.accounts.first.cashCents, -20000);
    // compra sem alocação: a transferência fica por registar e o saldo não muda
    s.addOp(
      InvestOp(
        id: 0,
        accountId: acc,
        holdingId: aapl,
        date: day,
        type: OpType.buy,
        quantity: 1,
        price: 50,
        amount: 5000,
        allocate: false,
      ),
    );
    final sum = s.portfolio.accounts.first;
    expect(sum.cashCents, -20000);
    // a flag persiste na base de dados e a posição conta as duas compras
    final ops = s.investOps.where((o) => !o.allocate).toList();
    expect(ops.length, 1);
    expect(sum.positions.first.qty, 3);
    expect(sum.positions.first.costCents, 25000);
  });

  test('logótipo: obtido uma vez pelo símbolo e guardado no ativo', () async {
    final s = _state();
    final acc = s.addInvestAccount('XTB');
    final aapl = s.addHolding(
      Holding(
        id: 0,
        accountId: acc,
        name: 'Apple',
        kind: HoldingKind.stock,
        provider: PriceProvider.yahoo,
        symbol: 'AAPL',
        lastPrice: 150,
      ),
    );
    expect(s.holding(aapl)!.logo, isNull);
    await s.fetchLogo(aapl);
    expect(s.holding(aapl)!.logo, _png);
  });

  test(
    'sem imagem no fornecedor: fica sem logótipo (mostra o emoji)',
    () async {
      final s = _state();
      final acc = s.addInvestAccount('XTB');
      final x = s.addHolding(
        Holding(
          id: 0,
          accountId: acc,
          name: 'Desconhecida',
          kind: HoldingKind.stock,
          provider: PriceProvider.yahoo,
          symbol: 'XYZQ',
          lastPrice: 1,
        ),
      );
      await s.fetchLogo(x);
      expect(s.holding(x)!.logo, isNull);
    },
  );
}
