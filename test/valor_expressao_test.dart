import 'package:financas/screens/txn_form/dialogos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('o valor aceita contas: avalia antes de ler como número', () {
    expect(centsFromText('12,50 + 11'), 2350);
    expect(centsFromText('12,50+3*2'), 1850);
    expect(centsFromText('10 x 3'), 3000);
    expect(centsFromText('(2+3)*4'), 2000);
  });

  test('números simples e entradas inválidas', () {
    expect(centsFromText('12,5'), 1250);
    expect(centsFromText('1.234,56'), 123456);
    expect(centsFromText('-7'), 700);
    expect(centsFromText(''), isNull);
    expect(centsFromText('abc'), isNull);
  });
}
