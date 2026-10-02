import 'dart:convert';

import 'package:financas/db/database.dart';
import 'package:financas/invest/invest.dart';
import 'package:financas/invest/price_service.dart';
import 'package:financas/state/app_state.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Preços simulados (nunca vai à rede nos testes).
PriceService fakePrices() => PriceService(
      client: MockClient((r) async {
        if (r.url.host.contains('coingecko')) return http.Response(jsonEncode({'bitcoin': {'eur': 61000}}), 200);
        return http.Response(
          jsonEncode({
            'chart': {
              'result': [
                {'meta': {'regularMarketPrice': 125.5, 'currency': 'EUR'}}
              ]
            }
          }),
          200,
        );
      }),
    );

/// XTB (ETF + ação) e uma exchange (bitcoin), com entregas do banco, posição inicial, compras e dinheiro por alocar.
({AppState s, int xtb, int cripto, int vwce, int aapl, int btc}) buildInvestData() {
  final s = AppState(Db.memory(), prices: fakePrices());
  final xtb = s.addInvestAccount('XTB', emoji: '📈');
  final cripto = s.addInvestAccount('Exchange', emoji: '🪙');
  final vwce = s.addHolding(Holding(id: 0, accountId: xtb, name: 'Vanguard FTSE All-World', symbol: 'VWCE.DE', provider: PriceProvider.yahoo, lastPrice: 120));
  final aapl = s.addHolding(Holding(id: 0, accountId: xtb, name: 'Apple', kind: HoldingKind.stock, lastPrice: 150));
  final btc = s.addHolding(Holding(id: 0, accountId: cripto, name: 'Bitcoin', symbol: 'bitcoin', provider: PriceProvider.coingecko, kind: HoldingKind.crypto, lastPrice: 60000));
  s.addManual(date: DateTime(2026, 1, 5), description: 'TRF P/ XTB S.A', amount: -60000);
  s.addManual(date: DateTime(2026, 2, 5), description: 'TRF P/ XTB S.A', amount: -30000);
  s.addManual(date: DateTime(2026, 2, 8), description: 'TRF P/ EXCHANGE', amount: -50000);
  s.addManual(date: DateTime(2026, 2, 9), description: 'COMPRA LIDL', amount: -2500);
  s.linkTransfers(s.transactions.where((t) => t.description.contains('XTB')).map((t) => t.id).toList(), xtb, rememberTitles: true);
  s.linkTransfers(s.transactions.where((t) => t.description.contains('EXCHANGE')).map((t) => t.id).toList(), cripto);
  s.addOp(InvestOp(id: 0, accountId: xtb, holdingId: vwce, date: DateTime(2025, 6, 1), type: OpType.initial, quantity: 10, price: 100, amount: 100000));
  s.addOp(InvestOp(id: 0, accountId: xtb, holdingId: vwce, date: DateTime(2026, 1, 6), type: OpType.buy, quantity: 5, price: 110, amount: 55100, fee: 100));
  s.addOp(InvestOp(id: 0, accountId: xtb, holdingId: aapl, date: DateTime(2026, 2, 6), type: OpType.buy, quantity: 2, price: 140, amount: 28000));
  s.addOp(InvestOp(id: 0, accountId: cripto, holdingId: btc, date: DateTime(2026, 2, 9), type: OpType.buy, quantity: 0.01, price: 50000, amount: 50000));
  return (s: s, xtb: xtb, cripto: cripto, vwce: vwce, aapl: aapl, btc: btc);
}
