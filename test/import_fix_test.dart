import 'package:financas/import/parsers.dart';
import 'package:flutter_test/flutter_test.dart';

// Todos os dados são inventados.
void main() {
  group('PDF: montantes sem separador de milhares', () {
    test('valor na descrição não contamina o montante (salário de 1220)', () {
      const t = '''
SALDO INICIAL 100,00
02-06-2026 02-06-2026 SALARIO 1220 EUR 1220,00 1.320,00
''';
      final r = parseStatementText(t);
      expect(r.length, 1);
      expect(r[0].description, 'SALARIO 1220 EUR');
      expect(r[0].amount, 122000);
      expect(r[0].balance, 132000);
    });

    test(
      'número na descrição + montante + saldo: o "00" não cola ao montante',
      () {
        const t = '''
SALDO INICIAL 100,00
02-06-2026 02-06-2026 SALARIO 1220,00 400,00 500,00
''';
        final r = parseStatementText(t);
        expect(r.length, 1);
        expect(r[0].description, 'SALARIO 1220,00');
        expect(r[0].amount, 40000);
        expect(r[0].balance, 50000);
      },
    );

    test(
      'saldos de 4 dígitos sem ponto (1234,56) não são lidos como montante',
      () {
        const t = '''
SALDO INICIAL 1150,00
02-06-2026 02-06-2026 COMPRA LOJA A 50,00 1100,00
03-06-2026 03-06-2026 COMPRA LOJA B 120,50 979,50
04-06-2026 04-06-2026 TRF RECEBIDA 300,00 1279,50
05-06-2026 05-06-2026 COMPRA LOJA C -10,00 1269,50
''';
        final r = parseStatementText(t);
        expect(r.map((x) => x.amount), [-5000, -12050, 30000, -1000]);
        expect(r.map((x) => x.balance), [110000, 97950, 127950, 126950]);
        expect(r[0].description, 'COMPRA LOJA A');
      },
    );

    test('milhares com ponto, espaço e sem separador convivem', () {
      const t = '''
SALDO INICIAL 1.000,00
02-06-2026 02-06-2026 PAGAMENTO A 1 200,00 -200,00
03-06-2026 03-06-2026 DEPOSITO 2.500,00 2.300,00
04-06-2026 04-06-2026 DEPOSITO 2500,00 4800,00
''';
      final r = parseStatementText(t);
      expect(r.map((x) => x.amount), [-120000, 250000, 250000]);
      expect(r.map((x) => x.balance), [-20000, 230000, 480000]);
    });

    test('movimento partido em linhas com valores de 4 dígitos', () {
      const t = '''
SALDO INICIAL 100,00
02-06-2026 02-06-2026 TRF SALARIO
EMPRESA XPTO 1220,00 1320,00
''';
      final r = parseStatementText(t);
      expect(r.length, 1);
      expect(r[0].amount, 122000);
      expect(r[0].balance, 132000);
    });

    test('PDF: linha que não bate certo com o saldo fica marcada, sem mexer no valor', () {
      const t = '''
SALDO INICIAL 500,00
02-06-2026 02-06-2026 COMPRA A 20,00 480,00
03-06-2026 03-06-2026 COMPRA B 480,00 450,00
''';
      final r = parseStatementDetailed(t).rows;
      expect(r[1].amount, 48000);
      expect(r[1].balanceMismatch, isTrue);
      expect(r[0].balanceMismatch, isFalse);
    });
  });

  group('CSV / Excel', () {
    test('cabeçalho "Saldo após movimento" é o saldo e não a descrição', () {
      final table = [
        ['Data', 'Saldo após movimento', 'Descrição', 'Montante'],
        ['2026-06-02', '1000,00', 'SALARIO 1220', '400,00'],
      ];
      final m = guessMapping(table);
      expect(m.balance, 1);
      expect(m.description, 2);
      expect(m.amount, 3);
      final r = rowsFromTable(table, m);
      expect(r.single.amount, 40000);
      expect(r.single.description, 'SALARIO 1220');
    });

    test('cabeçalho repetido a meio do ficheiro volta a mapear as colunas', () {
      final table = [
        ['Data', 'Descrição', 'Montante', 'Saldo'],
        ['2026-06-02', 'COMPRA A', '-10,00', '90,00'],
        [
          'Data',
          'Descrição',
          'Saldo',
          'Montante',
        ], // 2.ª tabela, colunas trocadas
        ['2026-06-03', 'COMPRA B', '80,00', '-10,00'],
        ['2026-06-04', 'SALARIO 1220', '1300,00', '1220,00'],
      ];
      final r = rowsFromTable(table, guessMapping(table));
      expect(r.map((x) => x.amount), [-1000, -1000, 122000]);
      expect(r.map((x) => x.balance), [9000, 8000, 130000]);
    });

    test(
      'montante igual ao saldo (coluna errada) é corrigido pela variação',
      () {
        final table = [
          ['Data', 'Descrição', 'Montante', 'Saldo'],
          ['2026-06-02', 'COMPRA A', '-10,00', '90,00'],
          ['2026-06-03', 'SALARIO 1220', '1310,00', '1310,00'],
        ];
        final r = rowsFromTable(table, guessMapping(table));
        expect(r[1].amount, 122000);
      },
    );

    test('linha que não bate certo com o saldo fica marcada', () {
      final table = [
        ['Data', 'Descrição', 'Montante', 'Saldo'],
        ['2026-06-02', 'COMPRA A', '-10,00', '90,00'],
        ['2026-06-03', 'COMPRA B', '-5,00', '50,00'], // devia ser 85,00
        ['2026-06-04', 'COMPRA C', '-5,00', '45,00'],
      ];
      final r = rowsFromTable(table, guessMapping(table));
      expect(r.map((x) => x.balanceMismatch), [false, true, false]);
    });
  });
}
