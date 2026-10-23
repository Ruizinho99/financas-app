import 'package:financas/db/database.dart';
import 'package:financas/l10n/app_localizations.dart';
import 'package:financas/screens/month_cycle_screen.dart';
import 'package:financas/state/app_state.dart';
import 'package:financas/util/month_cycle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'support/fonts.dart';

Future<void> _pump(WidgetTester tester, AppState s, Locale locale) async {
  tester.view.physicalSize = const Size(400, 1200) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: s,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: const MonthCycleScreen(),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_PT');
    await initializeDateFormatting('en');
    await loadRoboto();
  });

  testWidgets('escolher dia fixo mostra o dia 25 e o mês calculado', (
    tester,
  ) async {
    final s = AppState(Db.memory());
    await _pump(tester, s, const Locale('pt', 'PT'));
    expect(find.text('Início do mês'), findsOneWidget);
    expect(s.monthMode, CycleMode.calendar);

    await tester.tap(find.text('Dia fixo'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(s.monthMode, CycleMode.fixedDay);
    expect(
      s.monthStartDay,
      25,
    ); // sugestão ao passar de calendário para dia fixo
    expect(find.text('Dia 25'), findsOneWidget);
    expect(find.textContaining('25'), findsWidgets);
    // o intervalo do mês atual tem de começar no dia 25
    final p = s.periodOfMonth(s.currentMonthKey);
    expect(p.start.day, 25);
  });

  testWidgets('modo salário pede a categoria do salário', (tester) async {
    final s = AppState(Db.memory());
    await _pump(tester, s, const Locale('pt', 'PT'));
    await tester.tap(find.text('Salário'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(s.monthMode, CycleMode.salary);
    expect(find.text('Categoria do salário'), findsOneWidget);
    expect(find.text('Escolher categoria'), findsOneWidget);
  });

  testWidgets('em inglês', (tester) async {
    final s = AppState(Db.memory());
    await _pump(tester, s, const Locale('en'));
    expect(find.text('Start of the month'), findsOneWidget);
    expect(find.text('Fixed day'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.textContaining('This month:'), findsOneWidget);
  });
}
