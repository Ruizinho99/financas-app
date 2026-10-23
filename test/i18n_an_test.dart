import 'package:financas/l10n/app_localizations.dart';
import 'package:financas/screens/analysis_screen.dart';
import 'package:financas/state/app_state.dart';
import 'package:financas/util/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'support/analysis_data.dart';
import 'support/fonts.dart';

Future<void> _pump(WidgetTester tester, AppState s) async {
  tester.view.physicalSize = const Size(360, 640) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: s,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF2E7D6B),
        ),
        home: AnalysisScreen(initialMonth: DateTime(2026, 6)),
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

  tearDown(() => setFormatLocale('pt'));

  testWidgets('Análise em inglês: título e separadores', (tester) async {
    setFormatLocale('en');
    final d = buildAnalysisData();
    await _pump(tester, d.s);

    expect(find.text('Analysis'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Spending'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Trend'), findsOneWidget);
    expect(find.text('Visão geral'), findsNothing);
  });

  testWidgets('Visão geral e Poupar em inglês', (tester) async {
    setFormatLocale('en');
    final d = buildAnalysisData();
    await _pump(tester, d.s);

    expect(find.text('Expenses'), findsWidgets);
    expect(find.text('Income'), findsWidgets);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Saving potential'), findsOneWidget);
    expect(find.text('What if you cut optional spending?'), findsOneWidget);
  });

  testWidgets('Filtros em inglês: folha e botão de aplicar', (tester) async {
    setFormatLocale('en');
    final d = buildAnalysisData();
    await _pump(tester, d.s);

    await tester.tap(find.text('Filters'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Expense type'), findsOneWidget);
    expect(find.text('Apply filters'), findsOneWidget);
  });

  testWidgets('Gastos em inglês: separadores de vista e contagem', (
    tester,
  ) async {
    setFormatLocale('en');
    final d = buildAnalysisData();
    await _pump(tester, d.s);

    await tester.tap(find.text('Spending'));
    await tester.pumpAndSettle();
    expect(find.text('Categories'), findsWidgets);
    expect(find.text('Merchants'), findsOneWidget);
    expect(find.text('Where the money goes'), findsOneWidget);
  });
}
