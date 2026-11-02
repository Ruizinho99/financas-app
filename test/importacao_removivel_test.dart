import 'package:financas/db/database.dart';
import 'package:financas/l10n/app_localizations.dart';
import 'package:financas/models.dart';
import 'package:financas/screens/transactions_screen.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'support/fonts.dart';

final _dia = DateTime(2026, 10, 5);

Widget _app(AppState s, Widget home) => ChangeNotifierProvider<AppState>.value(
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

  group('remover uma importação leva os movimentos todos com ela', () {
    test('só ficam os movimentos de outras importações e manuais', () {
      final s = AppState(Db.memory());
      s.importRows('a.pdf', 'pdf', [
        ParsedRow(_dia, 'A1', -1000, null),
        ParsedRow(_dia, 'A2', 500, null),
        ParsedRow(_dia, 'A3', -300, null),
      ]);
      s.importRows('b.pdf', 'pdf', [ParsedRow(_dia, 'B1', -200, null)]);
      final imps = s.db.imports();
      expect(imps.map((i) => i.count), [1, 3]); // contagem real, mais recente primeiro
      s.deleteImport(imps.last.id);
      expect(s.transactions.map((t) => t.description), ['B1']);
      expect(s.db.imports().length, 1);
    });

    test('limpa ligações órfãs e anulações que apontavam para os removidos', () {
      final s = AppState(Db.memory());
      s.importRows('a.pdf', 'pdf', [ParsedRow(_dia, 'Saida', -1000, null)]);
      s.importRows('b.pdf', 'pdf', [
        ParsedRow(_dia, 'Entrada', 1100, null),
        ParsedRow(_dia, 'Outra', 300, null),
      ]);
      final saida = s.transactions.firstWhere((t) => t.description == 'Saida');
      final entrada = s.transactions.firstWhere((t) => t.description == 'Entrada');
      expect(s.linkTxns(saida.id, entrada.id), isTrue);
      s.deleteImport(s.db.imports().last.id); // a.pdf (apaga a saída)
      final e = s.transactions.firstWhere((t) => t.description == 'Entrada');
      expect(s.isLinked(e), isFalse);
      expect(s.flowAmount(e), 1100);
    });

    test('a receita que anulava uma despesa removida volta a ser receita normal', () {
      final s = AppState(Db.memory());
      s.importRows('a.pdf', 'pdf', [ParsedRow(_dia, 'Despesa', -1000, null)]);
      s.importRows('b.pdf', 'pdf', [ParsedRow(_dia, 'Reembolso', 1000, null)]);
      final d = s.transactions.firstWhere((t) => t.description == 'Despesa');
      final r = s.transactions.firstWhere((t) => t.description == 'Reembolso');
      s.updateTxn(
        Txn(
          id: r.id,
          date: r.date,
          description: r.description,
          amount: r.amount,
          merchantKey: r.merchantKey,
          reversesId: d.id,
          reversedCents: 1000,
        ),
      );
      expect(s.transactions.firstWhere((t) => t.id == r.id).reversesId, d.id);
      s.deleteImport(s.db.imports().last.id); // a.pdf
      final n = s.transactions.single;
      expect(n.reversesId, isNull);
      expect(n.reversedCents, 0);
    });

    test('importação apagada: reimportar o mesmo ficheiro volta a funcionar', () {
      final s = AppState(Db.memory());
      final rows = [ParsedRow(_dia, 'X', -100, 1000)];
      expect(s.importRows('a.pdf', 'pdf', rows).$1, 1);
      s.deleteImport(s.db.imports().single.id);
      expect(s.transactions, isEmpty);
      expect(s.importRows('a.pdf', 'pdf', rows).$1, 1);
    });
  });

  test('apagar milhares de movimentos de uma vez, sem limite', () {
    final s = AppState(Db.memory());
    s.importRows('grande.csv', 'csv', [
      for (var i = 0; i < 3000; i++)
        ParsedRow(_dia.add(Duration(days: i % 28)), 'Mov $i', -(i + 1), null),
    ]);
    expect(s.transactions.length, 3000);
    s.deleteTxns(s.transactions.map((t) => t.id).toList());
    expect(s.transactions, isEmpty);
  });

  testWidgets('modo de seleção: caixas visíveis, selecionar tudo e apagar', (
    tester,
  ) async {
    final s = AppState(Db.memory());
    s.importRows('a.csv', 'csv', [
      for (var i = 0; i < 4; i++) ParsedRow(_dia, 'Mov $i', -100 * (i + 1), null),
    ]);
    await tester.pumpWidget(_app(s, const TransactionsScreen()));
    await tester.pump();
    expect(find.byType(Checkbox), findsNothing);
    await tester.tap(find.byTooltip('Selecionar'));
    await tester.pump();
    expect(find.byType(Checkbox), findsNWidgets(4));
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    expect(find.text('1 selecionados'), findsOneWidget);
    await tester.tap(find.byTooltip('Selecionar tudo'));
    await tester.pump();
    expect(find.text('4 selecionados'), findsOneWidget);
    await tester.tap(find.byTooltip('Apagar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apagar').last);
    await tester.pumpAndSettle();
    expect(s.transactions, isEmpty);
    expect(find.byType(Checkbox), findsNothing); // saiu do modo de seleção
  });
}
