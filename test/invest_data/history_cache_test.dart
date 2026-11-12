import 'package:financas/invest/data/market_cache.dart';
import 'package:financas/invest/data/yahoo_market_data.dart';
import 'package:financas/invest/price_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'support.dart';

String _chart({
  String ccy = 'USD',
  List<int> ts = const [1700000000, 1700086400, 1700172800],
  String close = '[10.0, null, 12.0]',
  String? adj,
  String events = '',
}) =>
    '{"chart":{"result":[{"meta":{"currency":"$ccy","gmtoffset":0},"timestamp":$ts,'
    '$events"indicators":{"quote":[{"close":$close}]${adj == null ? '' : ',"adjclose":[{"adjclose":$adj}]'}}}]}}';

void main() {
  group('Histórico', () {
    test('fixture real: pontos ascendentes, ajustado, dividendos', () async {
      final y = YahooMarketData(
        client: mock((r) => jsonResp(yahooFixture('chart_AAPL_2y.json'))),
      );
      final h = await y.history('AAPL', range: '2y');
      expect(h.symbol, 'AAPL');
      expect(h.currency, 'USD');
      expect(h.points.length, 502);
      final d = h.points.map((p) => p.date).toList();
      expect([...d]..sort(), d);
      expect(h.points.every((p) => p.adjClose != null), isTrue);
      expect(h.dividends.length, greaterThanOrEqualTo(7));
      expect(h.dividends[DateTime.utc(2026, 8, 10)], 0.27);
      expect(h.splits, isEmpty);
    });

    test('pedido: range, interval e eventos', () async {
      Uri? u;
      final y = YahooMarketData(
        client: mock((r) {
          u = r.url;
          return jsonResp(_chart());
        }),
      );
      await y.history('^GSPC');
      expect(u!.pathSegments, ['v8', 'finance', 'chart', '^GSPC']);
      expect(u!.queryParameters['range'], '5y');
      expect(u!.queryParameters['events'], 'div,split');
    });

    test('pontos com fecho nulo são ignorados', () async {
      final y = YahooMarketData(client: mock((r) => jsonResp(_chart())));
      final h = await y.history('X');
      expect(h.points.map((p) => p.close), [10.0, 12.0]);
      expect(h.points.first.date, DateTime.utc(2023, 11, 14));
    });

    test('dividendos e splits lidos', () async {
      final ev =
          '"events":{"dividends":{"1700000000":{"amount":0.5,"date":1700000000}},'
          '"splits":{"1700086400":{"date":1700086400,"numerator":4,"denominator":1,"splitRatio":"4:1"},'
          '"1700172800":{"date":1700172800,"numerator":1,"denominator":10,"splitRatio":"1:10"}}},';
      final y = YahooMarketData(
        client: mock(
          (r) => jsonResp(_chart(events: ev, adj: '[9.0, null, 11.0]')),
        ),
      );
      final h = await y.history('X');
      expect(h.dividends, {DateTime.utc(2023, 11, 14): 0.5});
      expect(h.splits, {
        DateTime.utc(2023, 11, 15): 4.0,
        DateTime.utc(2023, 11, 16): 0.1,
      });
      expect(h.points.first.adjClose, 9.0);
    });

    test('GBp -> GBP (preços, ajustado e dividendos /100)', () async {
      final ev =
          '"events":{"dividends":{"1700000000":{"amount":25.0,"date":1700000000}}},';
      final y = YahooMarketData(
        client: mock(
          (r) => jsonResp(
            _chart(
              ccy: 'GBp',
              close: '[1000.0, 1100.0, 1200.0]',
              adj: '[900.0, 990.0, 1080.0]',
              events: ev,
            ),
          ),
        ),
      );
      final h = await y.history('VOD.L');
      expect(h.currency, 'GBP');
      expect(h.points.map((p) => p.close), [10.0, 11.0, 12.0]);
      expect(h.points.first.adjClose, 9.0);
      expect(h.dividends.values.single, 0.25);
    });

    test('erro do serviço -> PriceException', () async {
      final y = YahooMarketData(client: mock((r) => http.Response('', 404)));
      await expectLater(y.history('XXX'), throwsA(isA<PriceException>()));
      final y2 = YahooMarketData(
        client: mock((r) => jsonResp('{"chart":{"result":null}}')),
      );
      await expectLater(y2.history('XXX'), throwsA(isA<PriceException>()));
    });
  });

  group('MarketCache', () {
    test('hit, miss e expiração com `now` injetado', () async {
      var agora = DateTime(2026, 1, 1, 12);
      final c = MarketCache.memory(now: () => agora);
      var n = 0;
      Future<Object?> fetch() async => {'n': ++n};

      expect(c.get('k', MarketCache.priceTtl), isNull); // miss
      expect(await c.cachedOr('k', MarketCache.priceTtl, fetch), {'n': 1});
      expect(await c.cachedOr('k', MarketCache.priceTtl, fetch), {
        'n': 1,
      }); // hit
      expect(n, 1);

      agora = agora.add(const Duration(minutes: 14));
      expect(await c.cachedOr('k', MarketCache.priceTtl, fetch), {'n': 1});
      agora = agora.add(const Duration(minutes: 2)); // 16 min > 15 min
      expect(await c.cachedOr('k', MarketCache.priceTtl, fetch), {'n': 2});
      expect(n, 2);

      // a mesma entrada ainda vale para uma validade de 24 h
      agora = agora.add(const Duration(hours: 5));
      expect(c.get('k', MarketCache.fundamentalsTtl), {'n': 2});
      agora = agora.add(const Duration(hours: 20));
      expect(c.get('k', MarketCache.fundamentalsTtl), isNull);
    });

    test('validades por tipo', () {
      expect(MarketCache.priceTtl, const Duration(minutes: 15));
      expect(MarketCache.fundamentalsTtl, const Duration(hours: 24));
      expect(MarketCache.profileTtl, const Duration(hours: 24));
    });

    test('sem base de dados (objeto nulo): nunca guarda', () async {
      final c = MarketCache.none();
      var n = 0;
      await c.cachedOr('k', MarketCache.priceTtl, () async => {'n': ++n});
      await c.cachedOr('k', MarketCache.priceTtl, () async => {'n': ++n});
      expect(n, 2);
    });

    test('resultado nulo não se guarda', () async {
      final c = MarketCache.memory();
      var n = 0;
      await c.cachedOr('k', MarketCache.priceTtl, () async {
        n++;
        return null;
      });
      await c.cachedOr('k', MarketCache.priceTtl, () async {
        n++;
        return null;
      });
      expect(n, 2);
    });

    test('YahooMarketData usa a cache: o 2.º pedido não vai à rede', () async {
      var agora = DateTime(2026, 1, 1, 12);
      var pedidos = 0;
      final y = YahooMarketData(
        client: mock((r) {
          pedidos++;
          return timeseriesRoute(r)!;
        }),
        cache: MarketCache.memory(now: () => agora),
        now: () => agora,
      );
      final a = await y.financials('AAPL');
      expect(pedidos, 3);
      final b = await y.financials('AAPL');
      expect(pedidos, 3);
      expect(b.annual.length, a.annual.length);
      agora = agora.add(const Duration(hours: 25));
      await y.financials('AAPL');
      expect(pedidos, 6);
    });

    test('erros não ficam em cache', () async {
      var pedidos = 0;
      final y = YahooMarketData(
        client: mock((r) {
          pedidos++;
          return http.Response('', 500);
        }),
        cache: MarketCache.memory(),
      );
      await y.financials('AAPL');
      await y.financials('AAPL');
      expect(pedidos, 6);
    });
  });
}
