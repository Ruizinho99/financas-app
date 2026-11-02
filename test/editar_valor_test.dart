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

final _dia = DateTime(2026, 10, 5);

/// Estado com um movimento importado (com saldo) e devolve-o.
(AppState, Txn) _importado({int valor = -1250}) {
  final s = AppState(Db.memory());
  s.importRows('x.csv', 'csv', [ParsedRow(_dia, 'Pingo Doce', valor, 80000)]);
  return (s, s.transactions.single);
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

  group('estado', () {
    test('corrigir o valor de um movimento importado mantém saldo e marca editado', () {
      final (s, t) = _importado();
      expect(t.valueEdited, isFalse);
      expect(s.setAmount(t, -1520), isNull);
      final n = s.transactions.single;
      expect(n.amount, -1520);
      expect(n.balance, 80000); // saldo importado intocado
      expect(n.valueEdited, isTrue);
      expect(n.originalAmount, -1250);
      // voltar ao valor original deixa de contar como editado
      expect(s.setAmount(n, -1250), isNull);
      expect(s.transactions.single.valueEdited, isFalse);
    });

    test('trocar o sinal de despesa para receita atualiza os totais', () {
      final (s, t) = _importado();
      final antes = s.transactions.fold<int>(0, (a, x) => a + x.amount);
      expect(antes, -1250);
      expect(s.setAmount(t, 1250), isNull);
      expect(s.transactions.single.amount, 1250);
      expect(s.transactions.fold<int>(0, (a, x) => a + x.amount), 1250);
    });

    test('importar de novo o mesmo extrato não recria o original após editar', () {
      final (s, t) = _importado();
      s.setAmount(t, 1250); // sinal trocado
      s.updateTxn(
        Txn(
          id: t.id,
          date: _dia,
          description: 'Outro nome',
          amount: 1300,
          balance: 80000,
          merchantKey: 'outro',
        ),
      );
      final (added, dup) = s.importRows('x.csv', 'csv', [
        ParsedRow(_dia, 'Pingo Doce', -1250, 80000),
      ]);
      expect(added, 0);
      expect(dup, 1);
      expect(s.transactions.length, 1);
    });

    test('despesa com anulações não pode ficar abaixo do anulado nem virar receita', () {
      final (s, desp) = _importado(valor: -5000);
      s.addManual(
        date: _dia,
        description: 'Reembolso',
        amount: 2000,
        reversesId: desp.id,
        reversedCents: 2000,
      );
      final r = s.transactions.firstWhere((x) => x.amount == 2000);
      expect(s.setAmount(desp, -1500)?.$1, AmountIssue.belowReversed);
      expect(s.setAmount(desp, 5000)?.$1, AmountIssue.hasReversals);
      expect(s.transactions.firstWhere((x) => x.id == desp.id).amount, -5000);
      // acima do anulado já pode
      expect(s.setAmount(desp, -2000), isNull);
      expect(s.reversibleLeft(s.transactions.firstWhere((x) => x.id == desp.id)), 0);
      // a receita que anula não pode ficar abaixo da parte anulada...
      expect(s.setAmount(r, 1000)?.$1, AmountIssue.belowOwnReversal);
      // ...mas se passar a despesa deixa de anular
      expect(s.setAmount(r, -1000), isNull);
      final n = s.transactions.firstWhere((x) => x.id == r.id);
      expect(n.reversesId, isNull);
      expect(n.reversedCents, 0);
      expect(s.reversedByExpense[desp.id] ?? 0, 0);
    });

    test('corrigir o valor de uma transferência troca saída por entrada', () {
      final s = AppState(Db.memory());
      s.addTransfer(date: _dia, description: 'Poupança', amount: 3000);
      final t = s.transactions.single;
      expect(t.amount, -3000);
      expect(s.setAmount(t, 3500), isNull);
      expect(s.transactions.single.amount, 3500);
      expect(s.transactions.single.isTransfer, isTrue);
    });
  });

  group('ecrãs', () {
    testWidgets('formulário: editar o valor de um movimento importado', (tester) async {
      final (s, t) = _importado();
      await tester.pumpWidget(_app(s, TxnFormScreen(edit: t)));
      await tester.pump();
      await tester.enterText(find.byType(TextField).first, '20,00');
      await tester.tap(find.text('Guardar'));
      await tester.pump();
      expect(s.transactions.single.amount, -2000);
      expect(s.transactions.single.balance, 80000);
    });

    testWidgets('formulário: trocar para receita e mostrar o valor original', (tester) async {
      final (s, t) = _importado();
      await tester.pumpWidget(_app(s, TxnFormScreen(edit: t)));
      await tester.pump();
      await tester.tap(find.text('Receita'));
      await tester.pump();
      await tester.scrollUntilVisible(find.text('Guardar'), 300, scrollable: find.byType(Scrollable).first);
      await tester.pump();
      await tester.tap(find.text('Guardar'));
      await tester.pump();
      expect(s.transactions.single.amount, 1250);
      // reabre: indica o valor original
      await tester.pumpWidget(_app(s, TxnFormScreen(edit: s.transactions.single)));
      await tester.pump();
      expect(find.textContaining('Valor original'), findsOneWidget);
    });

    testWidgets('lista: ação rápida corrige o valor e o sinal', (tester) async {
      final (s, _) = _importado();
      await tester.pumpWidget(_app(s, const TransactionsScreen()));
      await tester.pump();
      await tester.longPress(find.text('Pingo Doce'));
      await tester.pump();
      await tester.tap(find.byTooltip('Corrigir valor'));
      await tester.pump();
      await tester.tap(find.text('Receita'));
      await tester.pump();
      await tester.enterText(find.byType(TextField).last, '13,00');
      await tester.tap(find.text('Guardar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(s.transactions.single.amount, 1300);
      expect(find.byIcon(Icons.edit_note), findsOneWidget); // indicação "editado"
    });

    testWidgets('lista: despesa com anulação maior que o novo valor dá aviso', (tester) async {
      final (s, desp) = _importado(valor: -5000);
      s.addManual(
        date: _dia,
        description: 'Reembolso',
        amount: 2000,
        reversesId: desp.id,
        reversedCents: 2000,
      );
      await tester.pumpWidget(_app(s, const TransactionsScreen()));
      await tester.pump();
      await tester.longPress(find.text('Pingo Doce'));
      await tester.pump();
      await tester.tap(find.byTooltip('Corrigir valor'));
      await tester.pump();
      await tester.enterText(find.byType(TextField).last, '10,00');
      await tester.tap(find.text('Guardar'));
      await tester.pump();
      expect(find.textContaining('já foi anulado'), findsOneWidget);
      expect(s.transactions.firstWhere((x) => x.id == desp.id).amount, -5000);
    });
  });
}
