import 'package:financas/db/database.dart';
import 'package:financas/models.dart';
import 'package:financas/screens/transactions_screen.dart';
import 'package:financas/state/app_state.dart';
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

  testWidgets(
    'lista mostra a ligação entre a receita de anulação e a despesa',
    (tester) async {
      final s = AppState(Db.memory());
      final subs = s.addCategory(const Categoria(id: 0, name: 'Subscrições'));
      final reemb = s.addCategory(
        const Categoria(id: 0, name: 'Reembolsos', isIncome: true),
      );
      final day = DateTime(2026, 10, 5);
      s.addManual(
        date: day,
        description: 'Claude',
        amount: -2200,
        categoryId: subs,
      );
      final claude = s.transactions.firstWhere(
        (t) => t.description == 'Claude',
      );
      s.addManual(
        date: day,
        description: 'Reembolso empresa',
        amount: 500,
        categoryId: reemb,
        reversesId: claude.id,
        reversedCents: 500,
      );
      tester.view.physicalSize = const Size(400, 1200) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: s,
          child: const MaterialApp(home: TransactionsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Anula Claude'), findsOneWidget);
      expect(find.textContaining('Anulado'), findsOneWidget);
      expect(find.textContaining('fica'), findsOneWidget);
    },
  );
}
