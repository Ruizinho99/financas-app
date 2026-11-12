import 'package:financas/invest/metrics/metric_catalog.dart';
import 'package:financas/invest/metrics/metric_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('o catálogo junta as fichas de todos os grupos, sem chaves repetidas entre grupos', () {
    final vistas = <String, int>{};
    for (final i in allMetricInfo) {
      vistas[i.key] = (vistas[i.key] ?? 0) + 1;
    }
    final repetidas = [
      for (final e in vistas.entries)
        if (e.value > 1) e.key,
    ];
    expect(
      repetidas,
      isEmpty,
      reason: 'chaves repetidas entre grupos: $repetidas',
    );
    expect(metricCatalog.length, allMetricInfo.length);
    expect(allMetricInfo.length, greaterThan(150));
  });

  test('cada ficha tem todos os textos preenchidos nas duas línguas', () {
    for (final i in allMetricInfo) {
      for (final lang in ['pt', 'en']) {
        expect(i.name(lang).trim(), isNotEmpty, reason: '${i.key} nome $lang');
        expect(
          i.meaning(lang).trim(),
          isNotEmpty,
          reason: '${i.key} significado $lang',
        );
        expect(
          i.howToRead(lang).trim(),
          isNotEmpty,
          reason: '${i.key} como ler $lang',
        );
      }
      if (i.availability == MetricAvailability.unavailable) {
        expect(i.caution('pt') ?? i.howToRead('pt'), isNotEmpty);
      }
    }
  });

  test('metricInfoFor encontra uma ficha por chave', () {
    expect(metricInfoFor('gross_margin')?.namePt, isNotEmpty);
    expect(metricInfoFor('chave_que_nao_existe'), isNull);
  });
}
