import 'dart:convert';
import 'dart:io';

import 'package:financas/invest/data/yahoo_market_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'support.dart';

YahooMarketData _yahoo({List<Uri>? log}) => YahooMarketData(
  client: mock((r) {
    log?.add(r.url);
    return timeseriesRoute(r) ?? http.Response('', 404);
  }),
  now: () => DateTime(2026, 11, 12),
);

void main() {
  group('Financials a partir das fixtures reais', () {
    test('AAPL: último exercício igual à fixture e ao golden', () async {
      final f = await _yahoo().financials('AAPL');
      expect(f.currency, 'USD');
      expect(f.annual.length, 4);
      // ordem cronológica ascendente
      final ends = f.annual.map((p) => p.end).toList();
      expect([...ends]..sort(), ends);
      expect(f.annual.every((p) => p.annual), isTrue);
      expect(f.lastAnnual!.end, DateTime(2025, 9, 30));

      final a = f.lastAnnual!;
      double v(String t) =>
          tsValue('ts_AAPL_annual.json', 'annual$t', '2025-09-30')!;
      expect(a.revenue, v('TotalRevenue'));
      expect(a.netIncome, v('NetIncome'));
      expect(a.cash, v('CashAndCashEquivalents'));
      expect(a.grossProfit, v('GrossProfit'));
      expect(a.totalDebt, v('TotalDebt'));
      expect(a.equity, v('StockholdersEquity'));
      expect(a.capex, v('CapitalExpenditure')); // negativo, como reportado
      expect(a.capex!, lessThan(0));
      expect(a.dividendsPaid!, lessThan(0));
      expect(a.sharesOutstanding, v('OrdinarySharesNumber'));
      expect(a.dilutedEps, v('DilutedEPS'));
      // a locação só existe até 2023 na fonte: 2025 nulo, 2023 igual à fixture
      expect(a.leaseLiabilities, isNull);
      expect(
        f.annual[1].leaseLiabilities,
        tsValue(
          'ts_AAPL_annual.json',
          'annualCapitalLeaseObligations',
          '2023-09-30',
        ),
      );
      expect(a.depreciationAmortization, v('DepreciationAndAmortization'));
      // campos que a fonte não tem ficam nulos
      expect(a.goodwill, isNull);
      expect(a.minorityInterest, isNull);

      // conferido com o golden (calculado por um script independente)
      final g = jsonDecode(
        File('test/fixtures/golden_aapl.json').readAsStringSync(),
      ) as Map;
      expect(a.grossProfit! / a.revenue!, closeTo(g['gross_margin'], 1e-12));
      expect(a.netIncome! / a.revenue!, closeTo(g['net_margin'], 1e-12));
      expect(a.freeCashFlow, g['fcf']);
      expect(a.ebitda! / a.revenue!, closeTo(g['ebitda_margin'], 1e-12));
      // crescimento anual
      expect(
        f.lastAnnual!.revenue! / f.prevAnnual!.revenue! - 1,
        closeTo(g['revenue_growth'], 1e-12),
      );
    });

    test('AAPL: trimestres em ordem cronológica e TTM', () async {
      final f = await _yahoo().financials('AAPL');
      expect(f.quarterly.length, 5);
      expect(f.quarterly.every((p) => !p.annual), isTrue);
      final ends = f.quarterly.map((p) => p.end).toList();
      expect([...ends]..sort(), ends);
      expect(f.quarterly.last.end, DateTime(2026, 6, 30));

      final t = f.ttm!;
      expect(t.end, DateTime(2026, 6, 30));
      // nesta fixture o `trailing` é de 2025-06-30, anterior ao último trimestre (2026-06-30): não se mistura
      // períodos e os fluxos saem da soma dos últimos 4 trimestres
      final q4 = f.quarterly.skip(1).toList();
      expect(
        t.revenue,
        closeTo(q4.map((p) => p.revenue!).reduce((a, b) => a + b), 1),
      );
      expect(
        t.netIncome,
        closeTo(q4.map((p) => p.netIncome!).reduce((a, b) => a + b), 1),
      );
      // balanço: o último trimestre
      final q = f.quarterly.last;
      expect(t.totalAssets, q.totalAssets);
      expect(t.cash, q.cash);
      expect(t.equity, q.equity);
      expect(f.latest, same(t));
    });

    test('TTM com trailing em dia com o último trimestre: usa o trailing', () async {
      const trail =
          '{"timeseries":{"result":[{"meta":{"symbol":["AAPL"],"type":["trailingTotalRevenue"]},'
          '"trailingTotalRevenue":[{"asOfDate":"2026-06-30","currencyCode":"USD","reportedValue":{"raw":123.0}}]}]}}';
      final y = YahooMarketData(
        client: mock((r) {
          if (r.url.queryParameters['type']!.startsWith('trailing')) {
            return jsonResp(trail);
          }
          return timeseriesRoute(r)!;
        }),
      );
      final f = await y.financials('AAPL');
      expect(f.ttm!.revenue, 123);
      // sem trailing de outros campos: soma dos 4 trimestres
      expect(f.ttm!.netIncome, isNotNull);
    });

    test('TTM sem trailing: soma dos últimos 4 trimestres', () async {
      final y = YahooMarketData(
        client: mock((r) {
          if (r.url.queryParameters['type']!.startsWith('trailing')) {
            return jsonResp('{"timeseries":{"result":[],"error":null}}');
          }
          return timeseriesRoute(r)!;
        }),
      );
      final f = await y.financials('AAPL');
      final soma = f.quarterly
          .skip(1)
          .map((p) => p.revenue!)
          .reduce((a, b) => a + b);
      expect(f.ttm!.revenue, closeTo(soma, 1));
      expect(f.ttm!.cash, f.quarterly.last.cash);
      // um trimestre em falta não se inventa: campo sem 4 trimestres fica nulo
      expect(f.ttm!.goodwill, isNull);
    });

    test('pede os 3 prefixos, com os tipos do contrato', () async {
      final log = <Uri>[];
      await _yahoo(log: log).financials('AAPL');
      expect(log.length, 3);
      final tipos = {
        for (final u in log)
          u.queryParameters['type']!
              .split(',')
              .first
              .replaceAll(RegExp(r'[A-Z].*'), ''): u.queryParameters['type']!
              .split(','),
      };
      expect(tipos.keys.toSet(), {'annual', 'quarterly', 'trailing'});
      final anual = tipos['annual']!;
      for (final t in [
        'annualTotalRevenue',
        'annualReconciledDepreciation',
        'annualStockBasedCompensation',
        'annualNetInterestIncome',
        'annualCapitalLeaseObligations',
        'annualIncomeTaxPaidSupplementalData',
        'annualChangeInWorkingCapital',
        'annualPreferredStockEquity',
      ]) {
        expect(anual, contains(t));
      }
      expect(anual.length, greaterThanOrEqualTo(50));
      // fluxos apenas nos trailing: não há balanço
      expect(tipos['trailing']!, isNot(contains('trailingTotalAssets')));
      expect(
        log.every((u) => u.queryParameters['period1'] == '1400000000'),
        isTrue,
      );
    });

    test('JPM (banco): sem CostOfRevenue/EBIT/CurrentAssets -> nulos, sem exceções', () async {
      final f = await _yahoo().financials('JPM');
      expect(f.annual, isNotEmpty);
      for (final p in [...f.annual, ...f.quarterly, f.ttm!]) {
        expect(p.costOfRevenue, isNull);
        expect(p.ebit, isNull);
        expect(p.currentAssets, isNull);
        expect(p.currentLiabilities, isNull);
        expect(p.grossProfit, isNull);
      }
      final a = f.lastAnnual!;
      expect(a.netIncome, isNotNull);
      expect(a.revenue, isNotNull);
      expect(a.netInterestIncome, isNotNull);
      expect(a.totalAssets, isNotNull);
      expect(a.ebitOrOperating, isNull);
    });

    test('AMZN.DE: sem dados -> listas vazias, sem exceção', () async {
      final f = await _yahoo().financials('AMZN.DE');
      expect(f.symbol, 'AMZN.DE');
      expect(f.annual, isEmpty);
      expect(f.quarterly, isEmpty);
      expect(f.ttm, isNull);
      expect(f.latest, isNull);
    });

    test('NVD.DE: moeda de reporte USD (não a de cotação)', () async {
      final f = await _yahoo().financials('NVD.DE');
      expect(f.currency, 'USD');
      expect(f.annual, isNotEmpty);
      expect(f.lastAnnual!.revenue, isNotNull);
    });

    test('erro de rede, 429 e JSON inválido -> vazio, sem lançar', () async {
      for (final h in <http.Response Function(http.Request)>[
        (r) => http.Response('', 429),
        (r) => http.Response('isto não é json', 200),
        (r) => http.Response('{"timeseries":null}', 200),
        (r) => throw const SocketException('sem rede'),
      ]) {
        final f = await YahooMarketData(client: mock(h)).financials('AAPL');
        expect(f.annual, isEmpty);
        expect(f.ttm, isNull);
      }
    });

    test('entradas nulas e valores nulos na resposta são ignorados', () async {
      const body =
          '{"timeseries":{"result":[{"meta":{"symbol":["X"],"type":["annualTotalRevenue"]},'
          '"annualTotalRevenue":[null,{"asOfDate":"2024-12-31","currencyCode":"EUR","reportedValue":{"raw":100.0}},'
          '{"asOfDate":"2025-12-31","currencyCode":"EUR","reportedValue":{}}]}]}}';
      final y = YahooMarketData(
        client: mock((r) {
          return r.url.queryParameters['type']!.startsWith('annual')
              ? jsonResp(body)
              : jsonResp('{}');
        }),
      );
      final f = await y.financials('X');
      expect(f.currency, 'EUR');
      expect(f.annual.length, 1);
      expect(f.annual.single.revenue, 100);
    });
  });
}
