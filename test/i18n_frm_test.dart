import 'package:financas/db/database.dart';
import 'package:financas/l10n/app_localizations.dart';
import 'package:financas/onboarding/onboarding_screen.dart';
import 'package:financas/screens/accounts_screen.dart';
import 'package:financas/screens/txn_form_screen.dart';
import 'package:financas/state/app_state.dart';
import 'package:financas/util/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'support/fonts.dart';

Widget _app(AppState s, Widget home) => ChangeNotifierProvider<AppState>.value(
  value: s,
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: home,
  ),
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('pt_PT');
    await loadRoboto();
  });

  setUp(() => setFormatLocale('en'));
  tearDown(() => setFormatLocale('pt'));

  testWidgets('novo movimento em inglês: título, tipos e botão Guardar', (
    tester,
  ) async {
    final s = AppState(Db.memory());
    tester.view.physicalSize = const Size(400, 1400) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(s, const TxnFormScreen()));
    await tester.pumpAndSettle();
    expect(find.text('New transaction'), findsOneWidget);
    expect(find.text('Expense'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Transfer'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('contas em inglês: título e estado vazio', (tester) async {
    final s = AppState(Db.memory());
    tester.view.physicalSize = const Size(400, 1400) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(s, const AccountsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Accounts'), findsOneWidget);
    expect(
      find.textContaining("You don't have any accounts yet"),
      findsOneWidget,
    );
  });

  testWidgets('primeira utilização em inglês: boas-vindas e Skip', (
    tester,
  ) async {
    final s = AppState(Db.memory());
    tester.view.physicalSize = const Size(400, 1400) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(s, OnboardingScreen(onDone: () {})));
    await tester.pumpAndSettle();
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Welcome to Finances'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });
}
