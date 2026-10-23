import 'package:financas/db/database.dart';
import 'package:financas/l10n/app_localizations.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/fonts.dart';

import 'package:financas/screens/transactions_screen.dart';
import 'package:financas/screens/month_screen.dart';

void main() {
  setUpAll(() async {
    await loadRoboto();
  });

  test('idioma por omissão é o do telemóvel e fica guardado', () {
    final db = Db.memory();
    final s = AppState(db);
    expect(s.appLanguage, 'system');
    s.setAppLanguage('en');
    expect(s.appLanguage, 'en');
    // uma nova instância lê a mesma definição
    expect(AppState(db).appLanguage, 'en');
  });

  test('as traduções carregam em inglês e em português', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final pt = await AppLocalizations.delegate.load(const Locale('pt', 'PT'));
    expect(en.onboardingStart, 'Get started');
    expect(pt.onboardingStart, 'Começar');
    expect(en.appearanceTitle, 'Appearance');
    expect(pt.appearanceTitle, 'Aparência');
  });

  testWidgets('Movimentos e Mês aparecem em inglês quando o idioma é inglês', (
    tester,
  ) async {
    final s = AppState(Db.memory());
    s.setAppLanguage('en');
    tester.view.physicalSize = const Size(400, 1400) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: s,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const TransactionsScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.textContaining('No transactions.'), findsOneWidget);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: s,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const MonthScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Start here'), findsOneWidget);
    expect(find.text('Import a statement'), findsOneWidget);
  });

  test(
    'plurais: zero não aparece como singular (em português 0 e 1 são "um")',
    () async {
      final pt = await AppLocalizations.delegate.load(const Locale('pt', 'PT'));
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      expect(pt.morAccountsCount(0), '0 contas');
      expect(pt.morAccountsCount(1), '1 conta');
      expect(pt.morAccountsCount(2), '2 contas');
      expect(pt.impTxnCount(0), '0 movimentos');
      expect(pt.invAssetsCount(0), '0 ativos');
      expect(en.morAccountsCount(0), '0 accounts');
      expect(en.morAccountsCount(1), '1 account');
      expect(en.impTxnCount(0), '0 transactions');
    },
  );
}
