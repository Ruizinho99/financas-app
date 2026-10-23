import 'package:financas/db/database.dart';
import 'package:financas/l10n/app_localizations.dart';
import 'package:financas/screens/appearance_screen.dart';
import 'package:financas/screens/backup_screen.dart';
import 'package:financas/screens/more_screen.dart';
import 'package:financas/state/app_state.dart';
import 'package:financas/util/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'support/fonts.dart';

Widget _app(Widget home) => ChangeNotifierProvider<AppState>.value(
  value: AppState(Db.memory()),
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: home,
  ),
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_PT');
    await initializeDateFormatting('en');
    await loadRoboto();
  });

  setUp(() => setFormatLocale('en'));
  tearDown(() => setFormatLocale('pt'));

  testWidgets('menu Mais em inglês', (tester) async {
    tester.view.physicalSize = const Size(360, 900) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const Scaffold(body: MoreScreen())));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Budget'), findsOneWidget);
    expect(find.text('Updates'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Orçamento'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ecrã de aparência em inglês', (tester) async {
    tester.view.physicalSize = const Size(360, 900) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const AppearanceScreen()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Automatic'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ecrã de cópia de segurança em inglês', (tester) async {
    tester.view.physicalSize = const Size(360, 900) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const BackupScreen()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Backup'), findsOneWidget);
    expect(find.textContaining('Save backup'), findsOneWidget);
    expect(find.text('Restore from a file'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
