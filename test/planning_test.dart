import 'package:financas/db/database.dart';
import 'package:financas/models.dart';
import 'package:financas/planning/planning.dart';
import 'package:financas/screens/planning_screen.dart';
import 'package:financas/state/app_state.dart';
import 'package:financas/util/format.dart';
import 'package:financas/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'support/fonts.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_PT');
    await loadRoboto();
  });

  test('totais: obrigatórias e opcionais somam-se e o que sobra é o salário menos o planeado', () {
    final items = [
      const PlannedItem(
        id: 1,
        month: '2026-10',
        categoryId: 1,
        cents: 90000,
        mandatory: true,
      ),
      const PlannedItem(
        id: 2,
        month: '2026-10',
        categoryId: 2,
        cents: 15000,
        mandatory: false,
      ),
    ];
    final t = planTotals(200000, items);
    expect(t.mandatory, 90000);
    expect(t.optional, 15000);
    expect(t.planned, 105000);
    expect(t.left, 95000);
    // plano acima do salário: o que sobra fica negativo
    expect(planTotals(100000, items).left, -5000);
  });

  test('no mesmo mês cada categoria só pode estar planeada uma vez; copiar não repete', () {
    final s = AppState(Db.memory());
    final casa = s.addCategory(const Categoria(id: 0, name: 'Casa'));
    final lazer = s.addCategory(const Categoria(id: 0, name: 'Lazer'));
    expect(
      s.addPlanned(
        month: '2026-10',
        categoryId: casa,
        cents: 80000,
        mandatory: true,
      ),
      isTrue,
    );
    expect(
      s.addPlanned(
        month: '2026-10',
        categoryId: casa,
        cents: 1,
        mandatory: true,
      ),
      isFalse,
    );
    s.addPlanned(
      month: '2026-10',
      categoryId: lazer,
      cents: 5000,
      mandatory: false,
    );
    expect(s.copyPlan('2026-10', '2026-11'), 2);
    expect(s.copyPlan('2026-10', '2026-11'), 0);
    expect(s.planFor('2026-11').map((p) => p.cents).toList()..sort(), [
      5000,
      80000,
    ]);
  });

  test('gasto real: categoria principal inclui subcategorias; subcategoria só a sua', () {
    final s = AppState(Db.memory());
    final casa = s.addCategory(const Categoria(id: 0, name: 'Casa'));
    final luz = s.addCategory(Categoria(id: 0, name: 'Luz', parentId: casa));
    s.addManual(
      date: DateTime(2026, 10, 3),
      description: 'EDP',
      amount: -4000,
      categoryId: luz,
    );
    s.addManual(
      date: DateTime(2026, 10, 4),
      description: 'Renda',
      amount: -70000,
      categoryId: casa,
    );
    expect(s.actualSpent(casa, '2026-10'), 74000);
    expect(s.actualSpent(luz, '2026-10'), 4000);
  });

  testWidgets('ecrã: mostra o que sobra e as linhas planeadas', (tester) async {
    final s = AppState(Db.memory());
    final casa = s.addCategory(const Categoria(id: 0, name: 'Casa'));
    final now = DateTime.now();
    final key = monthKey(DateTime(now.year, now.month));
    s.setSalary(key, 200000);
    s.addPlanned(month: key, categoryId: casa, cents: 90000, mandatory: true);
    tester.view.physicalSize = const Size(400, 1400) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: s,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('pt', 'PT'),
          home: PlanningScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Por planear'), findsOneWidget);
    expect(find.text('Obrigatórias'), findsOneWidget);
    expect(find.textContaining('Casa'), findsWidgets);
  });
}
