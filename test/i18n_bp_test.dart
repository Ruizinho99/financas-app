import 'package:financas/db/database.dart';
import 'package:financas/screens/budget_screen.dart';
import 'package:financas/screens/goals_screen.dart';
import 'package:financas/screens/planning_screen.dart';
import 'package:financas/screens/recurring_screen.dart';
import 'package:financas/state/app_state.dart';
import 'package:financas/l10n/app_localizations.dart';
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
    await initializeDateFormatting('pt_PT');
    await initializeDateFormatting('en');
    await loadRoboto();
  });

  setUp(() => setFormatLocale('en'));
  tearDown(() => setFormatLocale('pt'));

  testWidgets('orcamento em ingles: titulo, salario e nova categoria', (
    tester,
  ) async {
    final s = AppState(Db.memory());
    tester.view.physicalSize = const Size(400, 1400) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(s, const BudgetScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Budget'), findsOneWidget);
    expect(find.text('Net salary'), findsOneWidget);
    expect(find.text('New category'), findsOneWidget);
    expect(find.textContaining('Set your net salary'), findsOneWidget);
  });

  testWidgets('planeamento em ingles: titulo e nova despesa planeada', (
    tester,
  ) async {
    final s = AppState(Db.memory());
    tester.view.physicalSize = const Size(400, 1400) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(s, const PlanningScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Planning'), findsOneWidget);
    expect(find.text('Planned expense'), findsOneWidget);
    expect(find.text('Planned mandatory'), findsOneWidget);
  });

  testWidgets('objetivos em ingles: lista vazia e botao de novo objetivo', (
    tester,
  ) async {
    final s = AppState(Db.memory());
    tester.view.physicalSize = const Size(400, 1400) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(s, const GoalsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Goals'), findsOneWidget);
    expect(find.text('Goal'), findsOneWidget);
    expect(find.textContaining('You have no goals yet.'), findsOneWidget);
  });

  testWidgets('recorrentes em ingles: titulo e botao de novo', (tester) async {
    final s = AppState(Db.memory());
    tester.view.physicalSize = const Size(400, 1400) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(s, const RecurringScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Recurring transactions'), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
  });
}
