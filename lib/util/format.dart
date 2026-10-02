import 'package:intl/intl.dart';

final _money = NumberFormat.currency(locale: 'pt_PT', symbol: '€', decimalDigits: 2);
final _moneyShort = NumberFormat.currency(locale: 'pt_PT', symbol: '€', decimalDigits: 0);
final _dateFmt = DateFormat('dd/MM/yyyy');
final _monthFmt = DateFormat('MMMM yyyy', 'pt_PT');
final _monthShort = DateFormat('MMM yy', 'pt_PT');

/// Valores monetários são guardados em cêntimos (int).
String fmtMoney(int cents, {bool short = false}) =>
    short ? _moneyShort.format(cents / 100) : _money.format(cents / 100);
String fmtDate(DateTime d) => _dateFmt.format(d);
String fmtMonth(DateTime d) {
  final s = _monthFmt.format(d);
  return s[0].toUpperCase() + s.substring(1);
}

String fmtMonthShort(DateTime d) => _monthShort.format(d);
String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String monthKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
String fmtPercent(double v) => '${(v * 100).toStringAsFixed(0)}%';

/// "12,50" / "12.50" / "1.234,56" -> cêntimos. Devolve null se inválido.
int? parseCents(String input) {
  var s = input.trim().replaceAll(RegExp(r'[€\s]'), '');
  if (s.isEmpty) return null;
  final neg = s.startsWith('-') || s.endsWith('-') || (s.startsWith('(') && s.endsWith(')'));
  s = s.replaceAll(RegExp(r'[^\d,.]'), '');
  if (s.isEmpty) return null;
  final lastComma = s.lastIndexOf(',');
  final lastDot = s.lastIndexOf('.');
  if (lastComma >= 0 && lastDot >= 0) {
    if (lastComma > lastDot) {
      s = s.replaceAll('.', '').replaceAll(',', '.');
    } else {
      s = s.replaceAll(',', '');
    }
  } else if (lastComma >= 0) {
    final decimals = s.length - lastComma - 1;
    s = (decimals == 3 && lastComma > 0) ? s.replaceAll(',', '') : s.replaceAll(',', '.');
  } else if (lastDot >= 0) {
    final decimals = s.length - lastDot - 1;
    if (decimals == 3 || s.indexOf('.') != lastDot) s = s.replaceAll('.', '');
  }
  final v = double.tryParse(s);
  if (v == null) return null;
  final c = (v * 100).round();
  return neg ? -c : c;
}
