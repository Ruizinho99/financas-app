import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Texto de uma fixture real do Yahoo (test/fixtures/yahoo/).
String yahooFixture(String name) =>
    File('test/fixtures/yahoo/$name').readAsStringSync();

Object? yahooJson(String name) => jsonDecode(yahooFixture(name));

/// Valor de um tipo numa data de uma fixture fundamentals-timeseries (ex.: `annualTotalRevenue`).
double? tsValue(String file, String type, String date) {
  final j = yahooJson(file) as Map;
  for (final r in (j['timeseries'] as Map)['result'] as List) {
    final m = r as Map;
    final t = (m['meta'] as Map)['type'][0] as String;
    if (t != type || m[type] is! List) continue;
    for (final e in m[type] as List) {
      if (e is Map && e['asOfDate'] == date) {
        return ((e['reportedValue'] as Map)['raw'] as num).toDouble();
      }
    }
  }
  return null;
}

http.Response jsonResp(String body, [int status = 200]) =>
    http.Response(body, status, headers: {'content-type': 'application/json'});

/// Resposta mínima do gráfico (usada para câmbios como EURUSD=X).
String fxChart(double rate, String ccy) =>
    '{"chart":{"result":[{"meta":{"currency":"$ccy","regularMarketPrice":$rate}}]}}';

/// Router de fundamentals-timeseries com as fixtures: `AAPL`, `JPM`, `NVD.DE`, `AMZN.DE`.
/// Devolve nulo se o pedido não for deste tipo.
http.Response? timeseriesRoute(http.Request r) {
  final seg = r.url.pathSegments;
  if (!r.url.path.contains('fundamentals-timeseries')) return null;
  final sym = seg.last.replaceAll('.', '_');
  final type = r.url.queryParameters['type'] ?? '';
  final prefix = type.startsWith('annual')
      ? 'annual'
      : type.startsWith('quarterly')
      ? 'quarterly'
      : 'trailing';
  return jsonResp(yahooFixture('ts_${sym}_$prefix.json'));
}

MockClient mock(http.Response Function(http.Request) h) =>
    MockClient((r) async => h(r));
