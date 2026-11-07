import 'package:financas/db/database.dart';
import 'package:financas/l10n/app_localizations.dart';
import 'package:financas/models.dart';
import 'package:financas/screens/transactions_screen.dart';
import 'package:financas/screens/txn_form_screen.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'support/fonts.dart';

AppState _dados() {
  final s = AppState(Db.memory());
  final jogo = s.addCategory(const Categoria(id: 0, name: 'Jogo'));
  final ganhos = s.addCategory(
    const Categoria(id: 0, name: 'Ganhos', isIncome: true),
  );
  s.addManual(
    date: DateTime(2026, 10, 3),
    description: 'Betclic envio',
    amount: -1000,
    categoryId: jogo,
  );
  s.addManual(
    date: DateTime(2026, 10, 9),
    description: 'Levantamento XYZ',
    amount: 1100,
    categoryId: ganhos,
  );
  return s;
}

Widget _app(AppState s, Widget home) =>
    ChangeNotifierProvider<AppState>.value(
      value: s,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'PT'),
        home: home,
      ),
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_PT');
    await loadRoboto();
  });

  testWidgets('formulário: ligar 10 -> 11 mostra o líquido; desligar repõe', (
    tester,
  ) async {
    final s = _dados();
    final envio = s.transactions.firstWhere(
      (t) => t.description == 'Betclic envio',
    );
    tester.view.physicalSize = const Size(400, 1400) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(s, TxnFormScreen(edit: envio)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Avançado')); // o bloco começa recolhido
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ligar a outro movimento'));
    await tester.pumpAndSettle();
    // o movimento de sinal oposto aparece nos sugeridos
    expect(find.textContaining('Sugeridos'), findsOneWidget);
    await tester.tap(find.text('Levantamento XYZ'));
    await tester.pumpAndSettle();

    expect(s.linkNet(s.transactions.first.linkGroup!), 100);
    expect(find.textContaining('Contam como uma só receita de'), findsOneWidget);
    expect(find.text('Desligar'), findsOneWidget);

    await tester.tap(find.text('Desligar'));
    await tester.pumpAndSettle();
    expect(s.transactions.every((t) => t.linkGroup == null), isTrue);
    expect(find.text('Desligar'), findsNothing);
  });

  testWidgets('lista mostra a ligação e o líquido nos dois movimentos', (
    tester,
  ) async {
    final s = _dados();
    s.linkTxns(s.transactions[0].id, s.transactions[1].id);
    tester.view.physicalSize = const Size(400, 1200) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(s, TransactionsScreen()));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ligado a Levantamento XYZ'), findsOneWidget);
    expect(find.textContaining('Ligado a Betclic envio'), findsOneWidget);
    expect(find.textContaining('líquido'), findsNWidgets(2));
  });
}
