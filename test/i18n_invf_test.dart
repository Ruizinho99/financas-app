import 'dart:convert';

import 'package:financas/db/database.dart';
import 'package:financas/invest/forms.dart';
import 'package:financas/invest/import_trades_screen.dart';
import 'package:financas/invest/invest.dart';
import 'package:financas/l10n/app_localizations.dart';
import 'package:financas/state/app_state.dart';
import 'package:financas/util/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'support/fonts.dart';
import 'support/invest_data.dart';

// Dados inventados, só para testes.
const csvEn = '''Date;Type;Name;Symbol;Quantity;Price;Amount;Currency
06/01/2026;Buy;Vanguard FTSE All-World;VWCE.DE;3;110,50;331,50;EUR
''';

Future<void> pumpEn(WidgetTester tester, AppState s, Widget screen) async {
  tester.view.physicalSize = const Size(360, 2400) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: s,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: ThemeData(useMaterial3: true),
        home: screen,
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_PT');
    await initializeDateFormatting('en');
    await loadRoboto();
  });

  setUp(() => setFormatLocale('en'));
  tearDown(() => setFormatLocale('pt'));

  testWidgets('import screen shows English texts', (tester) async {
    final s = AppState(Db.memory(), prices: fakePrices());
    final acc = s.addInvestAccount('XTB');
    await pumpEn(
      tester,
      s,
      ImportTradesScreen(
        accountId: acc,
        preloaded: (name: 'trades.csv', bytes: utf8.encode(csvEn) as dynamic),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Import buys and sells'), findsOneWidget);
    expect(find.text('Assets found'), findsOneWidget);
    expect(find.textContaining('Import 1 transaction'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('operation form shows English labels', (tester) async {
    final s = AppState(Db.memory(), prices: fakePrices());
    final acc = s.addInvestAccount('XTB');
    final h = s.addHolding(
      Holding(
        id: 0,
        accountId: acc,
        name: 'Vanguard FTSE All-World',
        symbol: 'VWCE.DE',
        provider: PriceProvider.yahoo,
        lastPrice: 120,
      ),
    );
    await pumpEn(
      tester,
      s,
      OpFormScreen(type: OpType.buy, accountId: acc, holdingId: h),
    );
    expect(find.text('New transaction'), findsOneWidget);
    expect(find.text('Buy'), findsWidgets);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Quantity'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('link transfers screen shows English texts', (tester) async {
    final s = AppState(Db.memory(), prices: fakePrices());
    final acc = s.addInvestAccount('XTB');
    await pumpEn(tester, s, LinkTransfersScreen(accountId: acc));
    expect(find.text('Link to XTB'), findsOneWidget);
    expect(find.text('No transactions to link.'), findsOneWidget);
    expect(find.text('Remember these titles'), findsOneWidget);
    expect(find.text('Link'), findsOneWidget);
  });
}
