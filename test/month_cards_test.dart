import 'package:financas/db/database.dart';
import 'package:financas/invest/invest.dart';
import 'package:financas/models.dart';
import 'package:financas/screens/month_screen.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'support/fonts.dart';

Future<void> _pump(WidgetTester tester, AppState s) async {
  tester.view.physicalSize = const Size(360, 1400) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: s,
      child: const MaterialApp(home: MonthScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

String _mesAtual() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}';
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_PT');
    await loadRoboto();
  });

  testWidgets(
    'sem objetivos, planeamento nem entregas, nenhum cartão aparece',
    (tester) async {
      await _pump(tester, AppState(Db.memory()));
      expect(find.text('Objetivos'), findsNothing);
      expect(find.text('Planeamento'), findsNothing);
      expect(find.text('Entregas para distribuir'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('com objetivo e plano do mês, os cartões aparecem', (
    tester,
  ) async {
    final s = AppState(Db.memory());
    s.addAccount('Conta');
    final cat = s.addCategory(
      const Categoria(id: 0, name: 'Alimentação', emoji: '🛒'),
    );
    s.addGoal(
      name: 'Férias',
      parentCategoryId: cat,
      targetCents: 100000,
      endDate: DateTime.now().add(const Duration(days: 90)),
    );
    s.addPlanned(
      month: _mesAtual(),
      categoryId: cat,
      cents: 40000,
      mandatory: true,
    );
    await _pump(tester, s);
    expect(find.text('Objetivos'), findsOneWidget);
    expect(find.textContaining('Férias'), findsWidgets);
    expect(find.text('Planeamento'), findsOneWidget);
    expect(find.text('Ver todos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('entregas por distribuir aparecem com o número e o total', (
    tester,
  ) async {
    final s = AppState(Db.memory());
    final bank = s.addAccount('Banco');
    final acc = s.addInvestAccount('XTB');
    final vwce = s.addHolding(Holding(id: 0, accountId: acc, name: 'VWCE'));
    final today = DateTime.now();
    final midnight = DateTime(today.year, today.month, today.day);
    s.setInvestPlan(acc, {vwce: 10000});
    s.addManual(
      date: midnight,
      description: 'Entrega',
      amount: -100000,
      accountId: bank,
      isTransfer: true,
      investAccountId: acc,
    );
    await _pump(tester, s);
    expect(find.text('Entregas para distribuir'), findsOneWidget);
    expect(find.textContaining('1 entrega'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
