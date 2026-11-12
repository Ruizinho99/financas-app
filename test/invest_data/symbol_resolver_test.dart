import 'dart:convert';

import 'package:financas/invest/data/symbol_resolver.dart';
import 'package:financas/invest/data/yahoo_market_data.dart';
import 'package:financas/invest/invest.dart';
import 'package:financas/invest/price_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'support.dart';

/// Yahoo simulado: pesquisa por texto e demonstrações só para AAPL e NVD.DE.
class _Env {
  _Env(this.searches);
  final Map<String, List<List<String>>> searches; // texto -> [símbolo, nome]
  final symbolsAsked = <String>[]; // símbolos pedidos às demonstrações
  final queries = <String>[];

  late final http.Client client = mock((r) {
    if (r.url.path.contains('fundamentals-timeseries')) {
      final sym = r.url.pathSegments.last;
      if (r.url.queryParameters['type']!.startsWith('annual')) {
        symbolsAsked.add(sym);
      }
      if (sym == 'AAPL' || sym == 'NVD.DE') return timeseriesRoute(r)!;
      return jsonResp('{"timeseries":{"result":[],"error":null}}');
    }
    if (r.url.path.contains('/search')) {
      final q = r.url.queryParameters['q']!;
      queries.add(q);
      final hits = searches[q] ?? const [];
      return jsonResp(
        jsonEncode({
          'quotes': [
            for (final h in hits)
              {'symbol': h[0], 'shortname': h[1], 'exchDisp': 'X'},
          ],
        }),
      );
    }
    return http.Response('', 404);
  });

  YahooMarketData get data => YahooMarketData(client: client);
  PriceService get prices => PriceService(client: client);
}

Holding _h(String name, String symbol, {String analysis = ''}) => Holding(
  id: 1,
  accountId: 1,
  name: name,
  symbol: symbol,
  provider: PriceProvider.yahoo,
  analysisSymbol: analysis,
);

void main() {
  group('nameMatch', () {
    test('tolerante a sufixos, acentos e maiúsculas', () {
      expect(nameMatch('Apple', 'Apple Inc.'), 2);
      expect(nameMatch('APPLE INC', 'apple'), 2);
      expect(nameMatch('NVIDIA', 'NVIDIA CORP.   R'), 2);
      expect(nameMatch('Amazon.com', 'Amazon.com, Inc.'), 2);
      expect(nameMatch('SAP SE', 'Sap'), 2);
      expect(nameMatch('Siemens AG', 'SIEMENS AG'), 2);
      expect(nameMatch('Nestlé', 'Nestle S.A.'), 2);
      expect(nameMatch('Alphabet Inc Class A', 'Alphabet Inc.'), 2);
      expect(nameMatch('Heineken NV', 'Heineken N.V.'), 2);
    });
    test('prefixo próximo vale menos; nomes diferentes não correspondem', () {
      expect(nameMatch('Apple', 'Apple Hospitality REIT'), 1);
      expect(nameMatch('Apple', 'Anadarko Petroleum Corp'), 0);
      expect(nameMatch('APC', 'Apple Inc.'), 0);
      expect(nameMatch('Apple', 'Pineapple Energy'), 0);
      expect(nameMatch('', 'Apple'), 0);
    });
  });

  group('resolveAnalysisSymbol', () {
    test('1) símbolo de análise explícito ganha a tudo', () async {
      final e = _Env({});
      final r = await resolveAnalysisSymbol(
        holding: _h('Apple', 'APC.DE', analysis: 'AAPL'),
        data: e.data,
        prices: e.prices,
      );
      expect(r.symbol, 'AAPL');
      expect(r.source, SymbolSource.explicit);
      expect(r.needsConfirmation, isFalse);
      expect(e.symbolsAsked, isEmpty);
      expect(e.queries, isEmpty);
    });

    test('2) o símbolo da posição, se devolver demonstrações', () async {
      final e = _Env({});
      final r = await resolveAnalysisSymbol(
        holding: _h('NVIDIA', 'NVD.DE'),
        data: e.data,
        prices: e.prices,
      );
      expect(r.symbol, 'NVD.DE'); // sem cortar o sufixo
      expect(r.source, SymbolSource.own);
      expect(r.needsConfirmation, isFalse);
      expect(e.queries, isEmpty);
    });

    test(
      'APC.DE sem dados: pesquisa por nome; nunca corta para APC; Apple aceite',
      () async {
        final e = _Env({
          'Apple': [
            [
              'APC',
              'Anadarko Petroleum Corp',
            ], // o "APC" cortado seria outra empresa
            ['APC.DE', 'Apple Inc.'],
            ['AAPL', 'Apple Inc.'],
            ['APLE', 'Apple Hospitality REIT'],
          ],
        });
        final r = await resolveAnalysisSymbol(
          holding: _h('Apple', 'APC.DE'),
          data: e.data,
          prices: e.prices,
        );
        expect(r.symbol, 'AAPL');
        expect(r.source, SymbolSource.searched);
        expect(r.needsConfirmation, isTrue);
        expect(
          e.symbolsAsked,
          isNot(contains('APC')),
        ); // nunca testou o símbolo cortado
        expect(e.symbolsAsked.first, 'APC.DE');
        // alternativas para o utilizador (sem repetir o escolhido nem o símbolo próprio)
        final alt = r.alternatives.map((h) => h.symbol).toList();
        expect(alt, containsAll(['APC', 'APLE']));
        expect(alt, isNot(contains('AAPL')));
      },
    );

    test(
      'nome que não corresponde é recusado: fica por resolver com sugestões',
      () async {
        final e = _Env({
          'Apple': [
            ['APC', 'Anadarko Petroleum Corp'],
            ['APLS', 'Apellis Pharmaceuticals'],
          ],
        });
        final r = await resolveAnalysisSymbol(
          holding: _h('Apple', 'APC.DE'),
          data: e.data,
          prices: e.prices,
        );
        expect(r.resolved, isFalse);
        expect(r.symbol, '');
        expect(r.source, SymbolSource.none);
        expect(r.needsConfirmation, isTrue);
        expect(r.alternatives.map((h) => h.symbol), ['APC', 'APLS']);
        expect(e.symbolsAsked, ['APC.DE']);
      },
    );

    test('3) ISIN primeiro, depois nome', () async {
      final e = _Env({
        'US0378331005': [
          ['AAPL', 'Apple Inc.'],
        ],
        'Apple': [
          ['APLE', 'Apple Hospitality REIT'],
        ],
      });
      final r = await resolveAnalysisSymbol(
        name: 'Apple',
        isin: 'US0378331005',
        symbol: 'APC.DE',
        data: e.data,
        prices: e.prices,
      );
      expect(r.symbol, 'AAPL');
      expect(r.source, SymbolSource.searched);
      expect(e.queries.first, 'US0378331005');
    });

    test('só com o ISIN (sem nome): aceita o resultado, a confirmar', () async {
      final e = _Env({
        'US0378331005': [
          ['AAPL', 'Apple Inc.'],
        ],
      });
      final r = await resolveAnalysisSymbol(
        isin: 'US0378331005',
        data: e.data,
        prices: e.prices,
      );
      expect(r.symbol, 'AAPL');
      expect(r.needsConfirmation, isTrue);
    });

    test(
      'resultado cujo nome corresponde mas sem demonstrações é recusado',
      () async {
        final e = _Env({
          'Apple': [
            ['APC.F', 'Apple Inc.'], // corresponde, mas sem dados
          ],
        });
        final r = await resolveAnalysisSymbol(
          name: 'Apple',
          data: e.data,
          prices: e.prices,
        );
        expect(r.resolved, isFalse);
        expect(r.alternatives.single.symbol, 'APC.F');
      },
    );

    test(
      'ETF/cripto (requireFinancials: false): aceita o símbolo da posição',
      () async {
        final e = _Env({});
        final r = await resolveAnalysisSymbol(
          holding: _h('VWCE', 'VWCE.DE'),
          data: e.data,
          prices: e.prices,
          requireFinancials: false,
        );
        expect(r.symbol, 'VWCE.DE');
        expect(r.source, SymbolSource.own);
        expect(e.symbolsAsked, isEmpty);
      },
    );

    test('erro na pesquisa: por resolver, sem lançar', () async {
      final data = YahooMarketData(client: mock((r) => http.Response('', 500)));
      final prices = PriceService(client: mock((r) => http.Response('', 500)));
      final r = await resolveAnalysisSymbol(
        name: 'Apple',
        symbol: 'APC.DE',
        data: data,
        prices: prices,
      );
      expect(r.resolved, isFalse);
    });
  });
}
