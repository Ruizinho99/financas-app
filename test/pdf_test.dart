import 'dart:io';

import 'package:financas/import/parsers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PDF com 3 páginas e colunas em blocos separados: lê todos os movimentos', () {
    final text = pdfText(File('test/fixtures/extrato_multipagina.pdf').readAsBytesSync());
    final rows = parseStatementText(text);
    expect(rows.length, 45); // 15 por página × 3 páginas
    expect(rows.first.description, 'COMPRA LOJA 1 LISBOA');
    expect(rows.first.amount, -1508);
    expect(rows.first.balance, 98492);
    expect(rows.last.description, 'COMPRA LOJA 45 LISBOA');
    expect(rows.every((r) => r.amount < 0), isTrue);
  });

  test('linhas com data que não dão movimento são devolvidas para avisar', () {
    const text = '''
02-01-2026 02-01-2026 COMPRA LOJA A -10,00 990,00
03-01-2026 03-01-2026 LINHA SEM VALOR NENHUM
04-01-2026 04-01-2026 COMPRA LOJA B -5,00 985,00
''';
    final r = parseStatementDetailed(text);
    expect(r.rows.length, 2);
    expect(r.skipped.length, 1);
    expect(r.skipped.first, contains('LINHA SEM VALOR NENHUM'));
  });

  // Extrato inventado no mesmo formato de um extrato combinado de 2 contas: datas "mês.dia", sem sinais,
  // movimentos partidos em 3 linhas, saldo inicial/transporte, rodapés de página e transferências entre contas.
  const combinado = '''
CE 12345/01
Banco Exemplo Bank, S.A. - Sede: Rua Exemplo 1
RESUMO DAS CONTAS
CONTA CORRENTE 100.00
CONTA POUPANCA 300.00
CONTA CORRENTE
N.
99900011122 MOEDA: EUR
EXTRATO DE 2025/06/02 A 2025/06/30
DATA
LANC.
DATA
VALOR
DESCRITIVO DEBITO CREDITO SALDO
SALDO INICIAL
200.00
6.02 6.02 COMPRA 1111 SUPERMERCADO A 50.00 150.00
6.03 6.03 DD OPERADORA TV 10.00 140.00
A TRANSPORTAR 140.00
B a n c o E x e m p l o B a n k , S . A . - S e d e : R u a E x e m p l o 1
25/06/30 EXT. N. 2025/006 DEPOSITO A ORDEM: 99900011122
PAG:
00002
DATA
LANC.
DATA
VALOR DESCRITIVO DEBITO CREDITO SALDO
TRANSPORTE
140.00
6.05 6.05 TRF DE POUPANCA - FIXAS 100.00 240.00
6.09 6.07
COMPRA 1111 CAFE CENTRAL
3.50 236.50
6.10 6.10 TRF P/ POUPANCA - FUNDO 36.50 200.00
6.20 6.20
TRANSFERENCIA - VENCIMENTO
900.00 1100.00
SALDO FINAL 1100.00
SALDO DISPONIVEL
1100.00
CONTA POUPANCA
N.
99900033344 MOEDA: EUR
EXTRATO DE 2025/06/02 A 2025/06/30
SALDO INICIAL
136.50
6.05 6.05 TRF P/ CONTA CORRENTE 100.00 36.50
6.10 6.10 TRF DE CONTA CORRENTE 36.50 73.00
SALDO FINAL 73.00
''';

  test('extrato combinado (2 contas, mês.dia, sem sinais, linhas partidas e rodapés)', () {
    final det = parseStatementDetailed(combinado);
    expect(det.skipped, isEmpty);
    expect(det.rows.length, 8);
    final cc = det.rows.where((r) => r.account == 'Conta Corrente').toList();
    final pp = det.rows.where((r) => r.account == 'Conta Poupanca').toList();
    expect(cc.length, 6);
    expect(pp.length, 2);
    // datas lidas como mês.dia (6.02 = 2 de junho), não como dia.mês
    expect(cc.first.date, DateTime(2025, 6, 2));
    expect(cc.first.amount, -5000); // sinal deduzido a partir do SALDO INICIAL
    expect(cc[1].amount, -1000);
    expect(cc[2].amount, 10000); // crédito (usa o TRANSPORTE da página seguinte)
    // linha partida em 3 e com a descrição a meio
    final cafe = cc.firstWhere((r) => r.description.contains('CAFE'));
    expect(cafe.description, 'COMPRA 1111 CAFE CENTRAL');
    expect(cafe.amount, -350);
    expect(cafe.date, DateTime(2025, 6, 9));
    // o rodapé com data fora do extrato e o texto com letras espaçadas não viram movimentos
    expect(det.rows.any((r) => r.description.contains('EXT. N.') || r.description.startsWith('B a n c o')), isFalse);
    // os saldos fecham: saldo inicial + movimentos = saldo final
    expect(20000 + cc.fold(0, (a, r) => a + r.amount), 110000);
    expect(13650 + pp.fold(0, (a, r) => a + r.amount), 7300);
    // transferências entre as duas contas (2 pares)
    expect(markTransfers(det.rows), 2);
    expect(det.rows.where((r) => r.isTransfer).length, 4);
    expect(cc.firstWhere((r) => r.description.contains('VENCIMENTO')).isTransfer, isFalse);
  });
}
