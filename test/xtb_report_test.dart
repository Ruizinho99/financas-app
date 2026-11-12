import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:financas/import/parsers.dart' show parseXlsxSheets;
import 'package:financas/invest/invest.dart';
import 'package:financas/invest/trade_import.dart';
import 'package:financas/invest/xtb_report.dart';
import 'package:flutter_test/flutter_test.dart';

/// Relatório da XTB inventado: ALP.DE (euros) com um lote fechado e um em carteira; BET.US (dólares)
/// com um lote fechado, um dividendo com retenção e um dividendo que fica a 0,00 €.
Map<String, List<List<String>>> _sheets() {
  // número de série do Excel de um instante (dias desde 1899-12-30), como vem nos relatórios reais
  String serial(DateTime d) =>
      (d.difference(DateTime.utc(1899, 12, 30)).inMilliseconds / 86400000).toString();
  return {
    'Closed Positions': [
      ['Account number', '123'],
      ['Closed Positions', ''],
      [
        'Instrument', 'Ticker', 'Category', 'Type', 'Volume', 'Open Price',
        'Open Time (UTC)', 'Close Price', 'Close Time (UTC)', 'Product',
        'Profit/Loss', 'Gross Profit', 'Purchase Value', 'Sale Value', 'Position ID',
      ],
      [
        'Alpha', 'ALP.DE', 'STOCK', 'BUY', '2', '100', serial(DateTime.utc(2026, 1, 10, 9)),
        '120', serial(DateTime.utc(2026, 3, 10, 10)), 'My Trades', '40', '40', '200', '240', '1001',
      ],
      [
        'Beta', 'BET.US', 'STOCK', 'BUY', '1', '50', '2026-01-11 14:30',
        '60', '2026-02-11 15:00', 'My Trades', '8.7', '8.7', '46.3', '55', '1002',
      ],
      ['Total', '', '', '', '', '', '', '', '', '', '48.7'],
    ],
    'Open Positions': [
      ['Data as of report generated', serial(DateTime.utc(2026, 11, 12))],
      [
        'Product', 'Instrument/Position', 'Ticker', 'Type', 'Volume', 'Open price',
        'Open time (UTC)', 'Current price', 'Value', 'Gross Profit',
      ],
      ['My Trades', 'Alpha', 'ALP.DE', '', '3', '', '', '110', '330', '30'],
      ['My Trades', '2001', 'ALP.DE', 'BUY', '3', '100', serial(DateTime.utc(2026, 4, 2, 8, 5)), '110', '330', '30'],
    ],
    'Cash Operations': [
      ['Cash Operations', ''],
      ['Type', 'Instrument', 'Ticker', 'Category', 'Time', 'Amount', 'ID', 'Comment', 'Product', 'Position ID'],
      ['Deposit', '', '', '', serial(DateTime.utc(2026, 1, 1)), '1000', '1', '', '', ''],
      ['Dividend', 'Beta', 'BET.US', 'STOCK', serial(DateTime.utc(2026, 6, 25, 11, 28)), '0.5', '2', '', '', ''],
      ['Withholding tax', 'Beta', 'BET.US', 'STOCK', serial(DateTime.utc(2026, 6, 25, 11, 28, 0, 3)), '-0.07', '3', '', '', ''],
      ['Dividend', 'Alpha', 'ALP.DE', 'STOCK', serial(DateTime.utc(2026, 7, 1, 10)), '0.01', '4', '', '', ''],
      ['Withholding tax', 'Alpha', 'ALP.DE', 'STOCK', serial(DateTime.utc(2026, 7, 1, 10)), '-0.01', '5', '', '', ''],
      ['Total', '', '', '', '', '1000'],
    ],
  };
}

List<String> _row(List<List<String>> t, String type, String ticker, {int nth = 0}) =>
    t.skip(1).where((r) => r[1] == type && r[2] == ticker).elementAt(nth);

void main() {
  test('reconhece o relatório pelas três folhas', () {
    expect(isXtbReport(_sheets()), isTrue);
    expect(isXtbReport({'Folha1': []}), isFalse);
    expect(isXtbReport({'Closed Positions': [], 'Cash Operations': []}), isFalse);
  });

  group('conversão em operações', () {
    final r = xtbReportToTable(_sheets());
    final t = r.table;

    test('uma compra por lote, uma venda por lote fechado e dividendos líquidos', () {
      expect(t.first, xtbTableHeader);
      expect((r.summary.buys, r.summary.sells, r.summary.dividends), (3, 2, 1));
      expect(r.summary.instruments, 2);
      expect(r.summary.zeroDividends, 1);
      expect(r.summary.unmatchedWithholdings, 0);
      expect(t.length, 1 + 3 + 2 + 1);
    });

    test('ordena por data e leva o nome, a categoria e a posição', () {
      final datas = [for (final x in t.skip(1)) x[0]];
      expect(datas, [...datas]..sort());
      final c = _row(t, 'Buy', 'ALP.DE');
      expect(c[0], '2026-01-10 09:00');
      expect((c[3], c[4], c[5], c[6], c[7]), ('Alpha', 'STOCK', '2', '100', 'EUR'));
      expect(c[8], ''); // euros: sem câmbio
      expect(c[9], '200');
      expect(c[10], 'posição 1001');
      final aberto = _row(t, 'Buy', 'ALP.DE', nth: 1);
      expect(aberto[0], '2026-04-02 08:05');
      expect(aberto[9], '300'); // valor atual - lucro
    });

    test('em dólares, o câmbio sai do valor em euros da XTB', () {
      final c = _row(t, 'Buy', 'BET.US');
      expect(c[7], 'USD');
      expect(double.parse(c[8].replaceAll(',', '.')), closeTo(50 / 46.3, 1e-8));
      final v = _row(t, 'Sell', 'BET.US');
      expect(v[0], '2026-02-11 15:00');
      expect(double.parse(v[8].replaceAll(',', '.')), closeTo(60 / 55, 1e-8));
    });

    test('dividendo líquido da retenção, em euros mesmo numa ação em dólares', () {
      final d = _row(t, 'Dividend', 'BET.US');
      expect(d[9], '0,43');
      expect(d[7], 'EUR');
      expect(d[5], '');
      expect(d[10], 'bruto 0.50, retenção 0.07');
      expect(t.where((x) => x[1] == 'Dividend' && x[2] == 'ALP.DE'), isEmpty); // 0,00 €
    });
  });

  test('o importador reconstrói os euros ao cêntimo e as posições vendidas ficam a zero', () {
    final table = xtbReportToTable(_sheets()).table;
    final m = guessTradeMapping(table);
    expect(m.usable, isTrue);
    final rep = parseTradeTable(table, m);
    expect(rep.skipped, isEmpty);
    expect(rep.unknownTypes, isEmpty);
    expect(rep.trades.length, 6);
    final qty = <String, double>{};
    var compras = 0, vendas = 0, divs = 0;
    for (final tr in rep.trades) {
      final op = tradeToOp(
        tr,
        accountId: 1,
        holdingId: 1,
        base: 'EUR',
        defaultCcy: 'EUR',
        rates: const {},
        holdingCcy: tr.currency.isEmpty ? 'EUR' : tr.currency,
      )!;
      if (tr.kind == 'buy') {
        qty[tr.symbol] = (qty[tr.symbol] ?? 0) + tr.quantity;
        compras += op.amount;
      } else if (tr.kind == 'sell') {
        qty[tr.symbol] = (qty[tr.symbol] ?? 0) - tr.quantity;
        vendas += op.amount;
      } else {
        divs += op.amount;
        expect(op.type, OpType.dividend);
      }
    }
    expect(qty['ALP.DE'], 3); // só o lote em carteira
    expect(qty['BET.US'], closeTo(0, 1e-9)); // comprado e vendido
    expect(compras, 20000 + 4630 + 30000);
    expect(vendas, 24000 + 5500);
    expect(divs, 43);
  });

  test('retenção sem dividendo e posições que não são compras entram nos avisos', () {
    final s = _sheets();
    s['Cash Operations']!.insert(3, ['Withholding tax', 'Gama', 'GAM.DE', 'STOCK', '2026-02-01 10:00', '-0.2', '9', '', '', '']);
    s['Closed Positions']!.insert(5, [
      'Delta', 'DEL.DE', 'STOCK', 'SELL', '1', '10', '2026-01-01 10:00', '9', '2026-01-02 10:00', 'My Trades', '1', '1', '10', '9', '1003',
    ]);
    final r = xtbReportToTable(s);
    expect(r.summary.unmatchedWithholdings, 1);
    expect(r.summary.skippedPositions, 1);
    expect(r.summary.sells, 2); // a venda a descoberto não conta
  });

  test('de um ficheiro .xlsx: as horas das células com data mantêm-se', () {
    final x = Excel.createExcel();
    final cp = x['Closed Positions'];
    cp.appendRow([TextCellValue('Instrument'), TextCellValue('Ticker'), TextCellValue('Category'), TextCellValue('Type'), TextCellValue('Volume'), TextCellValue('Open Price'), TextCellValue('Open Time (UTC)'), TextCellValue('Close Price'), TextCellValue('Close Time (UTC)'), TextCellValue('Purchase Value'), TextCellValue('Sale Value'), TextCellValue('Position ID')]);
    cp.appendRow([
      TextCellValue('Alpha'), TextCellValue('ALP.DE'), TextCellValue('STOCK'), TextCellValue('BUY'),
      DoubleCellValue(2), DoubleCellValue(100),
      DateTimeCellValue(year: 2026, month: 1, day: 10, hour: 9, minute: 15),
      DoubleCellValue(120),
      DateTimeCellValue(year: 2026, month: 3, day: 10, hour: 0, minute: 0),
      DoubleCellValue(200), DoubleCellValue(240), IntCellValue(1001),
    ]);
    final co = x['Cash Operations'];
    co.appendRow([TextCellValue('Type'), TextCellValue('Time'), TextCellValue('Amount')]);
    final op = x['Open Positions'];
    op.appendRow([TextCellValue('Product'), TextCellValue('Instrument/Position')]);
    x.delete('Sheet1');
    final sheets = parseXlsxSheets(Uint8List.fromList(x.encode()!));
    expect(isXtbReport(sheets), isTrue);
    final t = xtbReportToTable(sheets).table;
    expect(t[1][0], '2026-01-10 09:15'); // compra com hora
    expect(t[2][0], '2026-03-10 00:00'); // à meia-noite: só a data, lida como 00:00
    expect(t[1][5], '2');
    expect(t[1][10], 'posição 1001');
  });
}
