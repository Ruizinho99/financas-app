import 'package:financas/invest/data/yahoo_market_data.dart';
import 'package:financas/invest/metrics/financials.dart';
import 'package:financas/invest/price_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'support.dart';

const _cookieHeader =
    'A3=d=AQABBL; Expires=Thu, 01 Jan 2027 00:00:00 GMT; Path=/; Domain=.yahoo.com, '
    'B=xyz123; Path=/; Domain=.yahoo.com';

/// Servidor simulado do Yahoo para o snapshot de NVD.DE (cota em EUR, reporta em USD).
class _Fake {
  final calls =
      <
        String
      >[]; // sequência de pedidos: cookie, crumb, quoteSummary, chart, fx
  final cookiesSeen = <String>[];
  var crumbs = ['CRUMB1', 'CRUMB2'];
  var crumbIdx = 0;
  var quoteSummaryOk = true; // falso: responde 401 Invalid Crumb sempre
  var consent =
      false; // fc.yahoo.com redireciona para a página de consentimento
  var invalidCrumbOnce = false; // o 1.º crumb é recusado uma vez
  String chart = 'chart_NVD_DE_2y.json';

  http.Response handle(http.Request r) {
    final p = r.url.path;
    final host = r.url.host;
    if (host == 'fc.yahoo.com') {
      calls.add('cookie');
      if (consent) {
        return http.Response(
          '',
          302,
          headers: {'location': 'https://consent.yahoo.com/collectConsent'},
        );
      }
      return http.Response('', 404, headers: {'set-cookie': _cookieHeader});
    }
    if (p.endsWith('/getcrumb')) {
      calls.add('crumb');
      cookiesSeen.add(r.headers['Cookie'] ?? '');
      return http.Response(crumbs[crumbIdx++ % crumbs.length], 200);
    }
    if (p.contains('quoteSummary')) {
      final c = r.url.queryParameters['crumb'];
      calls.add('quoteSummary:$c');
      cookiesSeen.add(r.headers['Cookie'] ?? '');
      if (!quoteSummaryOk || (invalidCrumbOnce && c == 'CRUMB1')) {
        return jsonResp(
          '{"finance":{"error":{"code":"Unauthorized","description":"Invalid Crumb"}}}',
          401,
        );
      }
      return jsonResp(yahooFixture('quotesummary_NVDA.json'));
    }
    if (p.endsWith('EURUSD=X')) {
      calls.add('fx');
      return jsonResp(fxChart(1.08, 'USD'));
    }
    if (p.contains('/chart/')) {
      calls.add('chart');
      return jsonResp(yahooFixture(chart));
    }
    return http.Response('', 404);
  }
}

YahooMarketData _yahoo(_Fake f) => YahooMarketData(
  client: mock(f.handle),
  now: () => DateTime.utc(2026, 11, 12),
);

void main() {
  group('Snapshot', () {
    test(
      'NVD.DE cota em EUR e reporta em USD: tudo na moeda de reporte',
      () async {
        final f = _Fake();
        final s = await _yahoo(f).snapshot('NVD.DE', reportingCurrency: 'USD');
        expect(s.currency, 'USD');
        expect(s.quoteCurrency, 'EUR');
        expect(s.fxApplied, 1.08);
        expect(s.quoteType, QuoteType.equity);
        expect(s.name, 'NVIDIA Corporation');
        expect(s.price, closeTo(150.08 * 1.08, 1e-9));
        expect(s.fiftyTwoWeekHigh, closeTo(216.25 * 1.08, 1e-9));
        expect(s.fiftyTwoWeekLow, closeTo(134.2 * 1.08, 1e-9));
        // market cap = preço (reporte) x ações
        expect(s.sharesOutstanding, 24147000000);
        expect(s.marketCap, closeTo(150.08 * 1.08 * 24147000000, 1));
        expect(s.enterpriseValue, closeTo(4163283976192 * 1.08, 1));
        // perfil e estatísticas (quoteSummary)
        expect(s.sector, 'Technology');
        expect(s.industry, 'Semiconductors');
        expect(s.beta, 2.247);
        expect(s.shortPercentOfFloat, 0.0121);
        expect(s.insidersPercentHeld, 0.04006);
        expect(s.averageVolume, 131091271);
        // dividendos dos últimos 12 meses (eventos do gráfico, em EUR), em USD
        // ex-dividendos depois de 2025-11-12: 2025-12-04, 2026-03-11, 2026-06-04 e 2026-09-10
        final eur = 0.009048 + 0.009048 + 0.2262 + 0.2262;
        expect(s.dividendPerShare, closeTo(eur * 1.08, 1e-6));
      },
    );

    test('sem moeda de reporte: usa a de cotação (câmbio 1)', () async {
      final f = _Fake();
      final s = await _yahoo(f).snapshot('NVD.DE');
      expect(s.currency, 'EUR');
      expect(s.fxApplied, 1);
      expect(s.price, 150.08);
      expect(f.calls, isNot(contains('fx')));
    });

    test('mesma moeda: não pede câmbio', () async {
      final f = _Fake();
      final s = await _yahoo(f).snapshot('NVD.DE', reportingCurrency: 'EUR');
      expect(s.fxApplied, 1);
      expect(f.calls, isNot(contains('fx')));
    });

    test('índice não pede perfil', () async {
      final f = _Fake()..chart = 'chart_GSPC_2y.json';
      final s = await _yahoo(f).snapshot('^GSPC');
      expect(s.quoteType, QuoteType.marketIndex);
      expect(f.calls.where((c) => c.startsWith('quoteSummary')), isEmpty);
      expect(f.calls, isNot(contains('cookie')));
      expect(s.sector, '');
    });

    test(
      'falha do preço lança PriceException; falha do câmbio também',
      () async {
        final y = YahooMarketData(client: mock((r) => http.Response('', 404)));
        await expectLater(y.snapshot('XXX'), throwsA(isA<PriceException>()));
        final f = _Fake();
        final y2 = YahooMarketData(
          client: mock((r) {
            if (r.url.path.endsWith('EURUSD=X')) return http.Response('', 404);
            return f.handle(r);
          }),
        );
        await expectLater(
          y2.snapshot('NVD.DE', reportingCurrency: 'USD'),
          throwsA(isA<PriceException>()),
        );
      },
    );
  });

  group('Cookie e crumb', () {
    test(
      'sequência cookie -> crumb -> quoteSummary, com Cookie enviado',
      () async {
        final f = _Fake();
        await _yahoo(f).snapshot('NVD.DE');
        expect(f.calls.indexOf('cookie'), lessThan(f.calls.indexOf('crumb')));
        expect(
          f.calls.indexOf('crumb'),
          lessThan(f.calls.indexOf('quoteSummary:CRUMB1')),
        );
        // os dois cookies do Set-Cookie (a data Expires tem vírgula) seguem no Cookie
        expect(f.cookiesSeen, everyElement('A3=d=AQABBL; B=xyz123'));
        expect(f.cookiesSeen.length, 2); // crumb + quoteSummary
      },
    );

    test(
      'o crumb fica em memória: o 2.º snapshot não repete cookie/crumb',
      () async {
        final f = _Fake();
        final y = _yahoo(f);
        await y.snapshot('NVD.DE');
        await y.snapshot('NVD.DE');
        expect(f.calls.where((c) => c == 'cookie').length, 1);
        expect(f.calls.where((c) => c == 'crumb').length, 1);
        expect(f.calls.where((c) => c.startsWith('quoteSummary')).length, 2);
      },
    );

    test('401 Invalid Crumb: renova uma vez e repete', () async {
      final f = _Fake()..invalidCrumbOnce = true;
      final s = await _yahoo(f).snapshot('NVD.DE');
      expect(f.calls.where((c) => c == 'cookie').length, 2);
      expect(f.calls.where((c) => c == 'crumb').length, 2);
      expect(f.calls.where((c) => c.startsWith('quoteSummary')).toList(), [
        'quoteSummary:CRUMB1',
        'quoteSummary:CRUMB2',
      ]);
      expect(s.sector, 'Technology');
    });

    test('401 persistente: só uma renovação e segue sem perfil', () async {
      final f = _Fake()..quoteSummaryOk = false;
      final s = await _yahoo(f).snapshot('NVD.DE');
      expect(f.calls.where((c) => c.startsWith('quoteSummary')).length, 2);
      expect(s.price, 150.08); // o preço continua a vir do gráfico
      expect(s.sector, '');
      expect(s.beta, isNull);
      expect(s.enterpriseValue, isNull);
      expect(s.shortPercentOfFloat, isNull);
      expect(s.insidersPercentHeld, isNull);
    });

    test(
      'redireção para consentimento (UE): falha silenciosa, sem lançar',
      () async {
        final f = _Fake()..consent = true;
        final y = _yahoo(f);
        final s = await y.snapshot('NVD.DE');
        expect(s.price, 150.08);
        expect(s.sector, '');
        expect(s.beta, isNull);
        expect(s.enterpriseValue, isNull);
        expect(f.calls, isNot(contains('crumb')));
        // não insiste a cada pedido (espera 10 minutos)
        await y.snapshot('NVD.DE');
        expect(f.calls.where((c) => c == 'cookie').length, 1);
      },
    );

    test(
      'crumb inválido (página HTML / Too Many Requests): sem lançar',
      () async {
        final f = _Fake()..crumbs = ['Too Many Requests'];
        final s = await _yahoo(f).snapshot('NVD.DE');
        expect(s.sector, '');
        expect(f.calls.where((c) => c.startsWith('quoteSummary')), isEmpty);
      },
    );

    test('erro de rede no quoteSummary: sem lançar', () async {
      final f = _Fake();
      final y = YahooMarketData(
        client: mock((r) {
          if (r.url.path.contains('quoteSummary')) throw Exception('rede');
          return f.handle(r);
        }),
      );
      final s = await y.snapshot('NVD.DE');
      expect(s.price, 150.08);
      expect(s.sector, '');
    });
  });
}
