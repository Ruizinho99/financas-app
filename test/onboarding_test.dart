import 'package:financas/db/database.dart';
import 'package:financas/onboarding/onboarding_screen.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'support/analysis_data.dart';
import 'support/fonts.dart';

Future<void> _pump(WidgetTester tester, AppState s) async {
  tester.view.physicalSize = const Size(360, 780) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: s,
      child: const MaterialApp(home: OnboardingGate(child: Text('APP'))),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_PT');
    await loadRoboto();
  });

  testWidgets('instalação nova mostra a primeira utilização', (tester) async {
    await _pump(tester, AppState(Db.memory()));
    expect(find.text('Bem-vindo às Finanças'), findsOneWidget);
    expect(find.text('APP'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'concluir cria a conta e o salário, sem categorias, e grava a flag',
    (tester) async {
      final s = AppState(Db.memory());
      await _pump(tester, s);

      await tester.tap(find.text('Começar'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Nome da conta'),
        'Conta teste',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Saldo inicial (€)'),
        '100,00',
      );
      await tester.tap(find.text('Seguinte'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Salário líquido mensal (€)'),
        '1500',
      );
      await tester.tap(find.text('Seguinte'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Concluir'));
      await tester.pumpAndSettle();

      expect(find.text('APP'), findsOneWidget);
      expect(s.accounts.map((a) => a.name), ['Conta teste']);
      expect(s.accounts.single.openingCents, 10000);
      expect(s.defaultSalary, 150000);
      // a app não cria categorias por omissão: o utilizador cria as suas
      expect(s.categories, isEmpty);
      expect(s.db.setting(kOnboardingKey), '1');
    },
  );

  testWidgets('saltar não cria nada e grava a flag', (tester) async {
    final s = AppState(Db.memory());
    await _pump(tester, s);
    await tester.tap(find.text('Saltar'));
    await tester.pumpAndSettle();
    expect(find.text('APP'), findsOneWidget);
    expect(s.accounts, isEmpty);
    expect(s.categories, isEmpty);
    expect(s.db.setting(kOnboardingKey), '1');
  });

  testWidgets('base com movimentos nunca mostra a primeira utilização', (
    tester,
  ) async {
    final d = buildAnalysisData();
    await _pump(tester, d.s);
    expect(find.text('Bem-vindo às Finanças'), findsNothing);
    expect(find.text('APP'), findsOneWidget);
    expect(d.s.db.setting(kOnboardingKey), '1');
  });

  testWidgets('base só com conta também não mostra', (tester) async {
    final s = AppState(Db.memory());
    s.addAccount('Conta antiga');
    await _pump(tester, s);
    expect(find.text('Bem-vindo às Finanças'), findsNothing);
    expect(find.text('APP'), findsOneWidget);
  });
}
