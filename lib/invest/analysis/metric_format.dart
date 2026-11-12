import 'package:intl/intl.dart';

import '../../util/format.dart';
import '../metrics/financials.dart';

/// Formata o valor de uma métrica para mostrar. Percentagens vêm em fração (0,25 = 25 %).
/// [ccy] é a moeda de reporte (para valores monetários e por ação).
String formatMetric(Metric m, String ccy) {
  final v = m.value;
  if (v == null || !v.isFinite) return '—';
  switch (m.kind) {
    case MetricKind.percent:
      return '${fmtNum(v * 100, 1)} %';
    case MetricKind.ratio:
      return fmtNum(v, 2);
    case MetricKind.days:
      return '${fmtNum(v, 0)} d';
    case MetricKind.years:
      return '${fmtNum(v, 1)} a';
    case MetricKind.months:
      return '${fmtNum(v, 1)} m';
    case MetricKind.score:
      return fmtNum(v, v == v.roundToDouble() ? 0 : 2);
    case MetricKind.count:
      return fmtNum(v, 0);
    case MetricKind.perShare:
      return '${fmtNum(v, 2)} ${ccySymbol(ccy)}';
    case MetricKind.money:
      return '${compactNumber(v)} ${ccySymbol(ccy)}';
  }
}

/// 1,2 T / 3,4 mM / 5,6 M (abreviado, ao estilo português: mil milhões = mM).
String compactNumber(double v) {
  final a = v.abs();
  String f(double x, String s) => '${fmtNum(x, 1)} $s';
  if (a >= 1e12) return f(v / 1e12, 'T');
  if (a >= 1e9) return f(v / 1e9, 'mM');
  if (a >= 1e6) return f(v / 1e6, 'M');
  if (a >= 1e3) return f(v / 1e3, 'k');
  return NumberFormat.decimalPatternDigits(
    locale: formatLocale,
    decimalDigits: 0,
  ).format(v);
}
