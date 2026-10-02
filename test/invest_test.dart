import 'dart:convert';

import 'package:financas/analysis/analytics.dart';
import 'package:financas/db/database.dart';
import 'package:financas/invest/invest.dart';
import 'package:financas/invest/price_service.dart';
import 'package:financas/models.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object o, [int code = 200]) => http.Response(jsonEncode(o), code, headers: {'content-type': 'application/json; charset=utf-8'});

Map<String, dynamic> _chart(double price, String ccy) => {
      'chart': {
        'result': [
          {'meta': {'regularMarketPrice': price, 'currency': ccy}}
        ],
        'error': null
      }
    };

void main() {
  group('motor da carteira', () {
    test('preço médio, dinheiro por alocar e totais', () {
      final s = AppState(Db.memory());
      final xtb = s.addInvestAccount('XTB', emoji: '📈');
      final vwce = s.addHolding(Holding(id: 0, accountId: xtb, name: 'VWCE', symbol: 'VWCE.DE', provider: PriceProvider.yahoo, lastPrice: 120));
      // 600 € enviados do banco para a XTB
      s.addManual(date: DateTime(2026, 1, 5), description: 'TRF P/ XTB S.A', amount: -60000);
      s.linkTransfers([s.transactions.first.id], xtb);

      // já tinha 10 unidades a 100 € antes de usar a app (não mexe no dinheiro)
      s.addOp(InvestOp(id: 0, accountId: xtb, holdingId: vwce, date: DateTime(2025, 6, 1), type: OpType.initial, quantity: 10, price: 100, amount: 100000));
      // compra 5 a 110 € com 1 € de comissão
      s.addOp(InvestOp(id: 0, accountId: xtb, holdingId: vwce, date: DateTime(2026, 1, 6), type: OpType.buy, quantity: 5, price: 110, amount: 55100, fee: 100));

      var p = s.portfolio;
      expect(p.accounts.length, 1);
      var a = p.accounts.first;
      expect(a.depositedCents, 60000);
      expect(a.cashCents, 60000 - 55100); // 49 € por alocar (standby)
      final pos = a.positions.first;
      expect(pos.qty, 15);
      expect(pos.costCents, 155100);
      expect(pos.avgCost, closeTo(103.40, 0.0001)); // preço médio de compra
      expect(pos.valueCents, 180000); // 15 × 120 €
      expect(pos.plCents, 24900);
      expect(pos.plPct, closeTo(0.1605, 0.001));
      expect(p.total, 180000 + 4900);
      expect(p.costBasis, 155100);

      // venda de 3 a 130 € (390 € recebidos): realiza ganho e mantém o preço médio
      s.addOp(InvestOp(id: 0, accountId: xtb, holdingId: vwce, date: DateTime(2026, 2, 1), type: OpType.sell, quantity: 3, price: 130, amount: 39000));
      // dividendo e acerto manual de dinheiro que já lá estava
      s.addOp(InvestOp(id: 0, accountId: xtb, holdingId: vwce, date: DateTime(2026, 2, 2), type: OpType.dividend, amount: 500));
      s.addOp(InvestOp(id: 0, accountId: xtb, date: DateTime(2026, 2, 3), type: OpType.cash, amount: 20000));
      p = s.portfolio;
      a = p.accounts.first;
      final after = a.positions.first;
      expect(after.qty, 12);
      expect(after.costCents, 155100 - 31020); // 3 × 103,40 € saem do custo
      expect(after.avgCost, closeTo(103.40, 0.0001));
      expect(after.realizedCents, 39000 - 31020);
      expect(after.dividendsCents, 500);
      expect(a.cashCents, 4900 + 39000 + 500 + 20000);

      // levantamento para o banco (entrada no banco) baixa o dinheiro por alocar
      s.addManual(date: DateTime(2026, 3, 1), description: 'TRF DE XTB S.A', amount: 10000);
      s.linkTransfers([s.transactions.firstWhere((t) => t.amount == 10000).id], xtb);
      expect(s.portfolio.accounts.first.cashCents, 4900 + 39000 + 500 + 20000 - 10000);
    });

    test('sem preço usa o custo; vender mais do que tens não dá quantidade negativa', () {
      final s = AppState(Db.memory());
      final a = s.addInvestAccount('Corretora');
      final h = s.addHolding(Holding(id: 0, accountId: a, name: 'Fundo X'));
      s.addOp(InvestOp(id: 0, accountId: a, holdingId: h, date: DateTime(2026, 1, 1), type: OpType.initial, quantity: 2, price: 50, amount: 10000));
      expect(s.portfolio.accounts.first.positions.first.valueCents, 10000); // sem preço: custo
      expect(s.portfolio.accounts.first.positions.first.priced, isFalse);
      s.addOp(InvestOp(id: 0, accountId: a, holdingId: h, date: DateTime(2026, 2, 1), type: OpType.sell, quantity: 5, price: 60, amount: 12000));
      final pos = s.portfolio.accounts.first.positions.first;
      expect(pos.qty, 0);
      expect(pos.open, isFalse);
      expect(pos.valueCents, 0);
    });

    test('ordem das operações importa e a data decide', () {
      final s = AppState(Db.memory());
      final a = s.addInvestAccount('Corretora');
      final h = s.addHolding(Holding(id: 0, accountId: a, name: 'ETF', lastPrice: 10));
      // introduzidas fora de ordem: a compra mais antiga entra primeiro no custo médio
      s.addOp(InvestOp(id: 0, accountId: a, holdingId: h, date: DateTime(2026, 3, 1), type: OpType.buy, quantity: 10, price: 20, amount: 20000));
      s.addOp(InvestOp(id: 0, accountId: a, holdingId: h, date: DateTime(2026, 1, 1), type: OpType.buy, quantity: 10, price: 10, amount: 10000));
      final pos = s.portfolio.accounts.first.positions.first;
      expect(pos.qty, 20);
      expect(pos.avgCost, closeTo(15, 0.0001)); // (100 + 200) / 20
      expect(pos.plCents, 20 * 10 * 100 - 30000); // preço 10 € < médio 15 €
    });
  });

  group('transferências para plataformas', () {
    test('ficam fora das despesas e a memória aplica-se às próximas importações', () {
      final s = AppState(Db.memory());
      final xtb = s.addInvestAccount('XTB');
      final food = s.addCategory(const Categoria(id: 0, name: 'Comida'));
      s.addManual(date: DateTime(2026, 4, 3), description: 'COMPRA LIDL', amount: -2000, categoryId: food);
      s.addManual(date: DateTime(2026, 4, 5), description: 'TRF P/ XTB S.A', amount: -10000);
      final t = s.transactions.firstWhere((x) => x.description.contains('XTB'));
      s.linkTransfers([t.id], xtb, rememberTitles: true);
      final linked = s.transactions.firstWhere((x) => x.id == t.id);
      expect(linked.isTransfer, isTrue);
      expect(linked.investAccountId, xtb);

      final p = Period.month(DateTime(2026, 4));
      expect(Analytics(s, p, const AnalysisFilter()).spent, 2000); // a entrega não é despesa
      expect(s.investedIn(p), 10000);

      // próxima importação: o mesmo título é reconhecido sozinho
      s.importRows('maio.csv', 'csv', [ParsedRow(DateTime(2026, 5, 6), 'TRF P/ XTB S.A', -15000), ParsedRow(DateTime(2026, 5, 7), 'COMPRA LIDL', -1500)]);
      final may = s.transactions.firstWhere((x) => x.date == DateTime(2026, 5, 6));
      expect(may.investAccountId, xtb);
      expect(may.isTransfer, isTrue);
      expect(may.categoryId, isNull);
      expect(s.transactions.firstWhere((x) => x.date == DateTime(2026, 5, 7)).investAccountId, isNull);
      expect(s.portfolio.accounts.first.depositedCents, 25000);

      // desmarcar volta a ser um movimento normal
      s.unlinkTransfers([may.id]);
      expect(s.transactions.firstWhere((x) => x.id == may.id).isTransfer, isFalse);
    });

    test('aplicar títulos memorizados a movimentos já existentes', () {
      final s = AppState(Db.memory());
      final xtb = s.addInvestAccount('XTB');
      s.addManual(date: DateTime(2026, 1, 1), description: 'TRF P/ XTB S.A', amount: -5000);
      s.linkTransfers([s.transactions.first.id], xtb, rememberTitles: true);
      s.addManual(date: DateTime(2026, 2, 1), description: 'TRF P/ XTB S.A', amount: -7000); // manual, não passou pela importação
      expect(s.applyInvestPatterns(), 1);
      expect(s.portfolio.accounts.first.depositedCents, 12000);
    });

    test('apagar a plataforma apaga ativos e operações, mas os movimentos ficam', () {
      final s = AppState(Db.memory());
      final x = s.addInvestAccount('XTB');
      final h = s.addHolding(Holding(id: 0, accountId: x, name: 'ETF'));
      s.addOp(InvestOp(id: 0, accountId: x, holdingId: h, date: DateTime(2026, 1, 1), type: OpType.buy, quantity: 1, price: 1, amount: 100));
      s.addManual(date: DateTime(2026, 1, 1), description: 'TRF P/ XTB', amount: -100);
      s.linkTransfers([s.transactions.first.id], x);
      s.deleteInvestAccount(x);
      expect(s.holdings, isEmpty);
      expect(s.investOps, isEmpty);
      expect(s.transactions.length, 1);
      expect(s.transactions.first.investAccountId, isNull);
    });
  });

  group('preços (APIs gratuitas)', () {
    test('Yahoo em euros', () async {
      final svc = PriceService(client: MockClient((r) async => _json(_chart(171.14, 'EUR'))));
      final q = await svc.quote(PriceProvider.yahoo, 'VWCE.DE');
      expect(q.eur, 171.14);
      expect(q.currency, 'EUR');
    });

    test('Yahoo noutra moeda converte para euros (e usa a cotação em cache)', () async {
      var calls = 0;
      final svc = PriceService(client: MockClient((r) async {
        calls++;
        if (r.url.path.contains('USDEUR')) return _json(_chart(0.9, 'EUR'));
        return _json(_chart(100, 'USD'));
      }));
      final a = await svc.quote(PriceProvider.yahoo, 'AAPL');
      expect(a.eur, closeTo(90, 0.0001));
      expect(a.currency, 'USD');
      expect(a.original, 100);
      await svc.quote(PriceProvider.yahoo, 'MSFT');
      expect(calls, 3); // 2 cotações + 1 câmbio (o segundo câmbio veio da cache)
    });

    test('o endereço do Yahoo leva o símbolo codificado uma só vez (câmbios e índices)', () async {
      final paths = <String>[];
      final svc = PriceService(client: MockClient((r) async {
        paths.add(r.url.toString());
        return _json(_chart(1, 'EUR'));
      }));
      await svc.quote(PriceProvider.yahoo, 'USDEUR=X');
      await svc.quote(PriceProvider.yahoo, '^GSPC');
      await svc.quote(PriceProvider.yahoo, 'VWCE.DE');
      expect(paths[0], 'https://query1.finance.yahoo.com/v8/finance/chart/USDEUR=X?range=1d&interval=1d');
      expect(paths[1], 'https://query1.finance.yahoo.com/v8/finance/chart/%5EGSPC?range=1d&interval=1d');
      expect(paths[2], 'https://query1.finance.yahoo.com/v8/finance/chart/VWCE.DE?range=1d&interval=1d');
      expect(paths.any((p) => p.contains('%25')), isFalse);
    });

    test('Yahoo em pence (GBp) passa por libras', () async {
      final svc = PriceService(client: MockClient((r) async {
        if (r.url.path.contains('GBPEUR')) return _json(_chart(1.2, 'EUR'));
        return _json(_chart(5000, 'GBp'));
      }));
      expect((await svc.quote(PriceProvider.yahoo, 'VUSA.L')).eur, closeTo(60, 0.0001)); // 5000 p = 50 £
    });

    test('CoinGecko', () async {
      final svc = PriceService(client: MockClient((r) async {
        expect(r.url.queryParameters['ids'], 'bitcoin');
        return _json({'bitcoin': {'eur': 74638}});
      }));
      expect((await svc.quote(PriceProvider.coingecko, 'Bitcoin')).eur, 74638);
    });

    test('erros com mensagens claras', () async {
      Future<String> msg(http.Response Function() f, PriceProvider p) async {
        final svc = PriceService(client: MockClient((r) async => f()));
        try {
          await svc.quote(p, 'X');
        } on PriceException catch (e) {
          return e.message;
        }
        return 'sem erro';
      }

      expect(await msg(() => _json({}, 404), PriceProvider.yahoo), contains('não encontrado'));
      expect(await msg(() => _json({}, 429), PriceProvider.yahoo), contains('Limite'));
      expect(await msg(() => _json({}, 500), PriceProvider.yahoo), contains('500'));
      expect(await msg(() => _json({'chart': {'result': null, 'error': {}}}), PriceProvider.yahoo), contains('não encontrado'));
      expect(await msg(() => _json({}), PriceProvider.coingecko), contains('Id não encontrado'));
      final offline = PriceService(client: MockClient((r) async => throw http.ClientException('offline')));
      expect(() => offline.quote(PriceProvider.yahoo, 'X'), throwsA(isA<PriceException>().having((e) => e.message, 'msg', contains('Sem ligação'))));
      expect(() => offline.quote(PriceProvider.manual, 'X'), throwsA(isA<PriceException>()));
    });

    test('pesquisa de símbolos', () async {
      final yahoo = PriceService(client: MockClient((r) async => _json({
            'quotes': [
              {'symbol': 'VWCE.DE', 'shortname': 'Vanguard FTSE All-World', 'exchDisp': 'XETRA'},
              {'shortname': 'sem símbolo'},
            ]
          })));
      final hits = await yahoo.search(PriceProvider.yahoo, 'vwce');
      expect(hits.length, 1);
      expect((hits.first.symbol, hits.first.exchange), ('VWCE.DE', 'XETRA'));
      final gecko = PriceService(client: MockClient((r) async => _json({
            'coins': [
              {'id': 'bitcoin', 'name': 'Bitcoin', 'symbol': 'btc'}
            ]
          })));
      final g = await gecko.search(PriceProvider.coingecko, 'bitcoin');
      expect((g.first.symbol, g.first.name), ('bitcoin', 'Bitcoin (BTC)'));
      expect(await yahoo.search(PriceProvider.manual, 'x'), isEmpty);
      expect(await yahoo.search(PriceProvider.yahoo, '  '), isEmpty);
    });

    test('atualizar preços: só os automáticos, e os que falham não bloqueiam os outros', () async {
      final svc = PriceService(client: MockClient((r) async {
        if (r.url.path.contains('BAD')) return _json({}, 404);
        return _json(_chart(50, 'EUR'));
      }));
      final s = AppState(Db.memory(), prices: svc);
      final a = s.addInvestAccount('XTB');
      final ok = s.addHolding(Holding(id: 0, accountId: a, name: 'Bom', symbol: 'GOOD', provider: PriceProvider.yahoo));
      s.addHolding(Holding(id: 0, accountId: a, name: 'Mau', symbol: 'BAD', provider: PriceProvider.yahoo));
      final manual = s.addHolding(Holding(id: 0, accountId: a, name: 'Manual', lastPrice: 7));
      final r = await s.refreshPrices();
      expect(r.updated, 1);
      expect(r.failed.keys, ['Mau']);
      expect(s.holding(ok)!.lastPrice, 50);
      expect(s.holding(ok)!.lastPriceAt, isNotNull);
      expect(s.holding(manual)!.lastPrice, 7); // manual não é tocado
      s.setHoldingPrice(manual, 8.5);
      expect(s.holding(manual)!.lastPrice, 8.5);
    });
  });
}
