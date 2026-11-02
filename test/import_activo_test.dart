import 'package:financas/import/parsers.dart';
import 'package:flutter_test/flutter_test.dart';

// Layout "DATA LANC. / DATA VALOR / DESCRITIVO / DEBITO / CREDITO / SALDO" com datas mês.dia,
// ponto decimal e espaço nos milhares ("1 223.78"). Dados inventados.
const _extrato = '''
CONTA SIMPLES
EXTRATO DE
2026/10/01 A 2026/10/30
DATA LANC. DATA VALOR DESCRITIVO DEBITO CREDITO SALDO
SALDO INICIAL
425.27
10.01 10.01
COMPRA 0000 LOJA A
20.00 405.27
10.26 10.26 TRANSFERENCIA - VENCIMENTO 1 223.78 1 629.05
10.27 10.27 COMPRA 0000 LOJA B CONTACTLESS 70.40 1 558.65
10.27 10.27
COMPRA 0000 LOJA C PT CONTACTLESS
16.16 1 542.49
10.27 10.27 TRF P/ BROKER X 400.00 1 142.49
10.27 10.27 TRF. P/O BROKER X 300.00 1 442.49
10.29 10.29 COMPRA 0000 LOJA D 5.00 1 437.49
SALDO FINAL 1 437.49
''';

void main() {
  test('milhares com espaço e ponto decimal: valores, saldos e sinais certos', () {
    final r = parseStatementDetailed(_extrato);
    expect(r.skipped, isEmpty);
    final rows = r.rows;
    expect(rows.map((x) => x.amount), [
      -2000, 122378, -7040, -1616, -40000, 30000, -500,
    ]);
    expect(rows.map((x) => x.balance), [
      40527, 162905, 155865, 154249, 114249, 144249, 143749,
    ]);
    expect(rows[1].description, 'TRANSFERENCIA - VENCIMENTO');
    expect(rows.any((x) => x.balanceMismatch), isFalse);
  });
}
