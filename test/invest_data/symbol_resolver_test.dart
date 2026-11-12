import 'dart:convert';

import 'package:financas/invest/data/symbol_resolver.dart';
import 'package:financas/invest/data/yahoo_market_data.dart';
import 'package:financas/invest/invest.dart';
import 'package:financas/invest/price_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support.dart';

/// Yahoo simulado: pesquisa por texto e demonstrações só para AAPL e NVD.DE.
class _Env {
  _Env(this.searches);
  final Map<String, List<List<String>>> searches; // texto -> [símbolo, nome]
  final symbolsAsked = <String>[]; // símbolos pedidos às demonstrações
  final queries = <String>[];
  final quoteTypes = <String, String>{}; // símbolo -> quoteType da pesquisa
  http.Response? searchError; // resposta de erro para a pesquisa

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
      if (searchError != null) return searchError!;
      final hits = searches[q] ?? const [];
      return jsonResp(
        jsonEncode({
          'quotes': [
            for (final h in hits)
              {
                'symbol': h[0],
                'shortname': h[1],
                'exchDisp': 'X',
                if (quoteTypes[h[0]] != null) 'quoteType': quoteTypes[h[0]],
              },
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
      // prefixo só vale se as palavras a mais forem genéricas (Motor, Group...): Apple ≠ Apple Hospitality REIT
      expect(nameMatch('Apple', 'Apple Hospitality REIT'), 0);
      expect(nameMatch('Ford', 'Ford Motor Company'), 1);
      expect(nameMatch('Apple', 'Anadarko Petroleum Corp'), 0);
      expect(nameMatch('APC', 'Apple Inc.'), 0);
      expect(nameMatch('Apple', 'Pineapple Energy'), 0);
      expect(nameMatch('', 'Apple'), 0);
    });
  });

  group('nameMatch (F3 R8)', () {
    test('falsos positivos: nomes que só partilham o prefixo', () {
      expect(nameMatch('Ford', 'FORD OTOSAN'), 0);
      expect(nameMatch('Coca-Cola', 'Coca-Cola Consolidated, Inc.'), 0);
      expect(nameMatch('Coca-Cola', 'Coca-Cola Europacific Partners PLC'), 0);
      expect(nameMatch('The Coca-Cola Company', 'Coca-Cola Co'), 2);
      expect(
        nameMatch(
          'Xtrackers MSCI World UCITS ETF 1C',
          'Xtrackers MSCI World Information Technology UCITS ETF 1C',
        ),
        0,
      );
      expect(
        nameMatch(
          'Xtrackers MSCI World UCITS ETF 1C',
          'Xtrackers MSCI World ex USA UCITS ETF 1C',
        ),
        0,
      );
    });

    test('falsos negativos: ruído de ETFs, juntar palavras, nome com travessão', () {
      expect(
        nameMatch(
          'Xtrackers MSCI World UCITS ETF 1C',
          'Xtrackers MSCI World UCITS ETF',
        ),
        2,
      );
      expect(nameMatch('VWCE Acc', 'VWCE Dist'), 2); // acc/dist são ruído
      expect(nameMatch('TOTAL ENERGIES SE', 'TotalEnergies SE'), 2);
      expect(nameMatch('EDP - Energias de Portugal', 'EDP'), 2);
      expect(nameMatch('EDP', 'EDP - Energias de Portugal, S.A.'), 2);
      expect(
        nameMatch('Energias de Portugal', 'EDP - Energias de Portugal'),
        2,
      );
    });

    test('a classe de ação distingue BRK-A de BRK-B (mas sem classe passa)', () {
      expect(
        nameMatch(
          'Berkshire Hathaway Inc. Class A',
          'Berkshire Hathaway Inc. Class B',
        ),
        0,
      );
      expect(
        nameMatch(
          'Berkshire Hathaway Inc. Class B',
          'Berkshire Hathaway Inc. Class B',
        ),
        2,
      );
      expect(
        nameMatch('Berkshire Hathaway Class B', 'Berkshire Hathaway Inc.'),
        2,
      );
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

    test('R1: erro de rede/429 no símbolo da posição propaga (não passa à pesquisa)', () async {
      for (final status in [429, 500]) {
        final e = _Env({
          'Apple': [
            ['AAPL', 'Apple Inc.'],
          ],
        });
        final data = YahooMarketData(client: mock((r) => http.Response('', status)));
        await expectLater(
          resolveAnalysisSymbol(
            name: 'Apple',
            symbol: 'APC.DE',
            data: data,
            prices: e.prices,
          ),
          throwsA(isA<PriceException>()),
        );
        expect(e.queries, isEmpty);
      }
    });

    test('R1: demonstrações do candidato falham na rede: propaga', () async {
      var n = 0;
      final e = _Env({
        'Apple': [
          ['AAPL', 'Apple Inc.'],
        ],
      });
      final data = YahooMarketData(
        client: MockClient((r) async {
          if (r.url.path.contains('fundamentals-timeseries')) {
            // o símbolo da posição responde vazio (3 pedidos); o candidato dá 429
            return n++ < 3
                ? jsonResp('{"timeseries":{"result":[],"error":null}}')
                : http.Response('', 429);
          }
          return e.client.get(r.url);
        }),
      );
      await expectLater(
        resolveAnalysisSymbol(
          name: 'Apple',
          symbol: 'APC.DE',
          data: data,
          prices: e.prices,
        ),
        throwsA(isA<PriceException>()),
      );
    });

    test('R1: falha da pesquisa sem outro resultado propaga; sem falha fica por resolver', () async {
      final e = _Env({})..searchError = http.Response('', 429);
      await expectLater(
        resolveAnalysisSymbol(
          name: 'Apple',
          symbol: 'APC.DE',
          data: e.data,
          prices: e.prices,
        ),
        throwsA(isA<PriceException>()),
      );
      // pesquisa a funcionar mas sem resultados: por resolver, sem lançar
      final e2 = _Env({});
      final r = await resolveAnalysisSymbol(
        name: 'Apple',
        symbol: 'APC.DE',
        data: e2.data,
        prices: e2.prices,
      );
      expect(r.resolved, isFalse);
    });

    test('R8: futuros, opções e índices ficam de fora (quoteType e =F)', () async {
      final e = _Env({
        'Apple': [
          ['AAPL=F', 'Apple Inc.'],
          ['AAPLX', 'Apple Inc.'],
          ['AAPL', 'Apple, Inc.'],
        ],
      })..quoteTypes.addAll({'AAPLX': 'FUTURE', 'AAPL': 'EQUITY'});
      final r = await resolveAnalysisSymbol(
        name: 'Apple',
        data: e.data,
        prices: e.prices,
      );
      expect(r.symbol, 'AAPL');
      // nem sequer pediu demonstrações dos futuros
      expect(e.symbolsAsked, ['AAPL']);
      expect(r.alternatives.map((h) => h.symbol), isEmpty);
    });

    test('R8: ETF só se aceita com nome igual (não por prefixo)', () async {
      final e = _Env({
        'Xtrackers MSCI World UCITS ETF 1C': [
          ['XDWT.DE', 'Xtrackers MSCI World Information Technology UCITS ETF 1C'],
          ['XDWD.DE', 'Xtrackers MSCI World UCITS ETF 1C'],
        ],
      })..quoteTypes.addAll({'XDWT.DE': 'ETF', 'XDWD.DE': 'ETF'});
      final r = await resolveAnalysisSymbol(
        name: 'Xtrackers MSCI World UCITS ETF 1C',
        data: e.data,
        prices: e.prices,
        requireFinancials: false,
      );
      expect(r.symbol, 'XDWD.DE');
      expect(r.needsConfirmation, isTrue);
    });

    test('R8: ETF só com parecido por prefixo fica por resolver', () async {
      final e = _Env({
        'Vanguard S&P 500': [
          ['VUSA.L', 'Vanguard S&P 500 Group'],
        ],
      })..quoteTypes['VUSA.L'] = 'ETF';
      final r = await resolveAnalysisSymbol(
        name: 'Vanguard S&P 500',
        data: e.data,
        prices: e.prices,
        requireFinancials: false,
      );
      expect(r.resolved, isFalse);
      expect(r.alternatives.single.symbol, 'VUSA.L');
    });
  });
}
