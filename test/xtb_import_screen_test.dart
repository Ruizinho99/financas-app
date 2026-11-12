import 'dart:typed_data';

import 'package:excel/excel.dart' as xl;
import 'package:financas/db/database.dart';
import 'package:financas/invest/import_trades_screen.dart';
import 'package:financas/l10n/app_localizations.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'support/fonts.dart';

/// Relatório da XTB inventado, em .xlsx: um lote fechado (compra e venda) e um dividendo.
Uint8List _xtbXlsx() {
  final x = xl.Excel.createExcel();
  final cp = x['Closed Positions'];
  cp.appendRow([
    for (final h in ['Instrument', 'Ticker', 'Category', 'Type', 'Volume', 'Open Price', 'Open Time (UTC)', 'Close Price', 'Close Time (UTC)', 'Purchase Value', 'Sale Value', 'Position ID'])
      xl.TextCellValue(h),
  ]);
  cp.appendRow([
    xl.TextCellValue('Alpha'), xl.TextCellValue('ALP.DE'), xl.TextCellValue('STOCK'), xl.TextCellValue('BUY'),
    xl.DoubleCellValue(2), xl.DoubleCellValue(100),
    xl.DateTimeCellValue(year: 2026, month: 1, day: 10, hour: 9, minute: 15),
    xl.DoubleCellValue(120),
    xl.DateTimeCellValue(year: 2026, month: 3, day: 10, hour: 10, minute: 0),
    xl.DoubleCellValue(200), xl.DoubleCellValue(240), xl.IntCellValue(1001),
  ]);
  final co = x['Cash Operations'];
  co.appendRow([for (final h in ['Type', 'Instrument', 'Ticker', 'Category', 'Time', 'Amount']) xl.TextCellValue(h)]);
  co.appendRow([
    xl.TextCellValue('Dividend'), xl.TextCellValue('Alpha'), xl.TextCellValue('ALP.DE'), xl.TextCellValue('STOCK'),
    xl.DateTimeCellValue(year: 2026, month: 2, day: 1, hour: 10, minute: 0), xl.DoubleCellValue(1.5),
  ]);
  final op = x['Open Positions'];
  op.appendRow([xl.TextCellValue('Product'), xl.TextCellValue('Instrument/Position')]);
  x.delete('Sheet1');
  return Uint8List.fromList(x.encode()!);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_PT');
    await loadRoboto();
  });

  testWidgets('um relatório da XTB (.xlsx) é reconhecido e importado sem escolher folhas nem colunas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 2400) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final s = AppState(Db.memory());
    final acc = s.addInvestAccount('XTB');
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: s,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('pt', 'PT'),
          home: ImportTradesScreen(
            accountId: acc,
            preloaded: (name: 'EUR_123_2006-01-01_2026-11-12.xlsx', bytes: _xtbXlsx()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Relatório da XTB reconhecido: 1 compras, 1 vendas e 1 dividendos de 1 títulos.'),
      findsOneWidget,
    );
    expect(find.textContaining('depósitos e levantamentos'), findsOneWidget);
    expect(find.text('Ativos encontrados'), findsOneWidget);
    expect(find.textContaining('Importar 3 operações'), findsOneWidget);
    // não pede folha nem colunas
    expect(find.text('Folha do Excel'), findsNothing);
    expect(tester.takeException(), isNull);
    // importar de facto: 3 operações, e a posição fica a zero (comprada e vendida)
    await tester.tap(find.textContaining('Importar 3 operações'));
    await tester.pumpAndSettle();
    expect(s.investOps.length, 3);
    expect(s.investOps.map((o) => o.type.name).toSet(), {'buy', 'sell', 'dividend'});
  });
}
