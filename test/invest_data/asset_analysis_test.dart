import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:financas/invest/analysis/asset_analysis.dart';
import 'package:financas/invest/data/yahoo_market_data.dart';
import 'package:financas/invest/metrics/metric_catalog.dart';

import 'support.dart';

http.Response _nvidia(http.Request r) {
  final p = r.url.path;
  final ts = timeseriesRoute(r);
  if (ts != null) return ts;
  if (r.url.host == 'fc.yahoo.com') {
    return http.Response('', 404, headers: {'set-cookie': 'A3=x; Path=/'});
  }
  if (p.endsWith('/getcrumb')) return http.Response('CRUMB', 200);
  if (p.contains('quoteSummary')) {
    return jsonResp(yahooFixture('quotesummary_NVDA.json'));
  }
  if (p.endsWith('EURUSD=X')) return jsonResp(fxChart(1.08, 'USD'));
  if (p.contains('GSPC')) return jsonResp(yahooFixture('chart_GSPC_2y.json'));
  if (p.contains('/chart/')) return jsonResp(yahooFixture('chart_NVD_DE_2y.json'));
  return http.Response('', 404);
}

void main() {
  test('NVIDIA (NVD.DE): relatório completo, todas as métricas com ficha', () async {
    final y = YahooMarketData(
      client: mock(_nvidia),
      now: () => DateTime.utc(2026, 11, 12),
    );
    final a = await analyzeSymbol(y, 'NVD.DE');
    expect(a.marketOnly, isFalse);
    expect(a.financialsFailed, isFalse);
    expect(a.snapshot.currency, 'USD');
    expect(a.snapshot.quoteCurrency, 'EUR');
    for (final id in ['valuation', 'profitability', 'returns', 'cashflow',
        'scores', 'dcf', 'risk', 'redflags']) {
      expect(a.section(id), isNotNull, reason: id);
    }
    // margem bruta da NVIDIA é alta, P/E calculado, Piotroski entre 0 e 9
    expect(a.metric('gross_margin')?.value, greaterThan(0.5));
    expect(a.metric('pe_ttm')?.available ?? a.metric('pe')?.available, isTrue);
    final f = a.metric('piotroski_f')!.value!;
    expect(f, inInclusiveRange(0, 9));
    // cada métrica mostrada tem a sua explicação escondida
    for (final s in a.sections) {
      for (final m in s.metrics) {
        expect(metricInfoFor(m.key), isNotNull, reason: m.key);
      }
    }
    // premissas do DCF mudam o resultado sem rede
    final b = a.withAssumptions(
      a.assumptions.copyWithGrowth(0.02),
    );
    expect(b.metric('dcf_value_per_share')?.value,
        isNot(a.metric('dcf_value_per_share')?.value));
  });
}
