import 'package:financas/db/database.dart';
import 'package:financas/models.dart';
import 'package:financas/screens/goals_screen.dart';
import 'package:financas/state/app_state.dart';
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

  testWidgets('lista e detalhe de um objetivo: progresso, falta e movimentos', (
    tester,
  ) async {
    final s = AppState(Db.memory());
    final lazer = s.addCategory(const Categoria(id: 0, name: 'Lazer'));
    final viagens = s.addCategory(const Categoria(id: 0, name: 'Viagens'));
    final gid = s.addGoal(
      name: 'Férias',
      parentCategoryId: lazer,
      targetCents: 100000,
    );
    s.addManual(
      date: DateTime.now(),
      description: 'Prestação',
      amount: -50000,
      categoryId: viagens,
    );
    s.linkMovement(
      s.transactions.firstWhere((t) => t.description == 'Prestação').id,
      gid,
      50000,
    );
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
          home: GoalsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Férias'), findsOneWidget);
    expect(find.textContaining('faltam'), findsOneWidget);

    await tester.tap(find.textContaining('Férias'));
    await tester.pumpAndSettle();
    expect(find.text('Faltam'), findsOneWidget);
    expect(find.textContaining('associado'), findsOneWidget);
    expect(find.text('Histórico do valor'), findsOneWidget);
  });
}
