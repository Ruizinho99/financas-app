import 'package:financas/util/format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_PT');
    await initializeDateFormatting('en');
  });
  tearDown(() => setFormatLocale('pt'));

  test('português: valores com vírgula e meses em português', () {
    setFormatLocale('pt');
    expect(fmtMoney(123456).replaceAll(RegExp(r'\s'), ' '), '1 234,56 €');
    expect(fmtDayMonth(DateTime(2026, 8, 25)), '25 ago');
    expect(fmtMonth(DateTime(2026, 9)), 'Setembro 2026');
  });

  test('inglês: valores com ponto e meses em inglês', () {
    setFormatLocale('en');
    expect(fmtMoney(123456), '€1,234.56');
    expect(fmtDayMonth(DateTime(2026, 8, 25)), '25 Aug');
    expect(fmtMonth(DateTime(2026, 9)), 'September 2026');
  });

  test('o intervalo de um mês não repete o ano (25 ago – 24 set)', () {
    setFormatLocale('pt');
    final a = fmtDayMonth(DateTime(2026, 8, 25));
    final b = fmtDayMonth(DateTime(2026, 9, 24));
    expect('$a – $b', '25 ago – 24 set');
  });
}
