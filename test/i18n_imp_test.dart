import 'package:financas/db/database.dart';
import 'package:financas/l10n/app_localizations.dart';
import 'package:financas/screens/classify_screen.dart';
import 'package:financas/screens/groups_screen.dart';
import 'package:financas/screens/import_screen.dart';
import 'package:financas/state/app_state.dart';
import 'package:financas/util/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'support/fonts.dart';

Future<void> _pump(WidgetTester tester, AppState s, Widget home) async {
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

  testWidgets('import screen in English', (tester) async {
    await _pump(tester, AppState(Db.memory()), const ImportScreen());
    expect(find.text('Import Statement'), findsOneWidget);
    expect(find.text('Choose file'), findsOneWidget);
    expect(find.textContaining('Supported formats'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('classify screen in English', (tester) async {
    await _pump(tester, AppState(Db.memory()), const ClassifyScreen());
    expect(find.text('Classify'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Apply rules'), findsOneWidget);
    expect(find.text('All classified! 🎉'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('groups screen in English', (tester) async {
    await _pump(tester, AppState(Db.memory()), const GroupsScreen());
    expect(find.text('Groups'), findsOneWidget);
    expect(find.text('New group'), findsOneWidget);
    expect(
      find.textContaining("You don't have any groups yet."),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('remembered rules screen in English', (tester) async {
    await _pump(tester, AppState(Db.memory()), const RulesScreen());
    expect(find.text('Remembered rules'), findsOneWidget);
    expect(find.textContaining('No rules yet.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
