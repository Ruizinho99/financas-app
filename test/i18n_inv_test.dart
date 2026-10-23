import 'package:financas/db/database.dart';
import 'package:financas/invest/account_screen.dart';
import 'package:financas/invest/holding_screen.dart';
import 'package:financas/invest/invest_screen.dart';
import 'package:financas/l10n/app_localizations.dart';
import 'package:financas/state/app_state.dart';
import 'package:financas/util/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'support/fonts.dart';
import 'support/invest_data.dart';

Future<void> _pumpEn(WidgetTester tester, AppState s, Widget home) async {
  tester.view.physicalSize = const Size(360, 1800) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: s,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_PT');
    await initializeDateFormatting('en');
    await loadRoboto();
  });

  tearDown(() => setFormatLocale('pt'));

  testWidgets('estado vazio da Carteira aparece em inglês', (tester) async {
    setFormatLocale('en');
    final s = AppState(Db.memory(), prices: fakePrices());
    await _pumpEn(tester, s, const InvestScreen());
    expect(find.text('Investments'), findsOneWidget);
    expect(find.text("Track what you've invested"), findsOneWidget);
    expect(find.text('Create the first platform'), findsOneWidget);
    expect(find.text('Acompanha o que tens investido'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Carteira com dados: títulos, botões e tipos em inglês', (
    tester,
  ) async {
    setFormatLocale('en');
    final d = buildInvestData();
    await _pumpEn(tester, d.s, const InvestScreen());
    expect(find.text('My portfolio'), findsOneWidget);
    expect(find.text('Total value'), findsOneWidget);
    expect(find.text('Allocate'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('plataforma e ativo em inglês', (tester) async {
    setFormatLocale('en');
    final d = buildInvestData();
    await _pumpEn(tester, d.s, AccountScreen(accountId: d.xtb));
    expect(find.text('Cash to allocate'), findsOneWidget);
    expect(find.text('Bank transfers'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _pumpEn(tester, d.s, HoldingScreen(holdingId: d.vwce));
    expect(find.text('My position'), findsOneWidget);
    expect(find.text('Current price'), findsOneWidget);
    expect(find.text('Buy'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
