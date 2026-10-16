import 'package:financas/models.dart';
import 'package:financas/screens/txn_form_screen.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'support/analysis_data.dart';
import 'support/fonts.dart';
import 'support/invest_data.dart';

Future<void> _pump(
  WidgetTester tester,
  AppState s, {
  Txn? edit,
  Brightness b = Brightness.light,
  Size size = const Size(360, 1100),
  double scale = 1.0,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: s,
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF2E7D6B),
          brightness: b,
        ),
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Builder(
          builder: (c) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                c,
                MaterialPageRoute(builder: (_) => TxnFormScreen(edit: edit)),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_PT');
    await loadRoboto();
  });

  testWidgets(
    'despesa em poucos toques: montante, categoria na folha única, guardar',
    (tester) async {
      final d = buildAnalysisData();
      final before = d.s.transactions.length;
      await _pump(tester, d.s);
      // só o essencial à vista: nada de dropdowns nem de recibo/conta
      expect(find.byType(DropdownButtonFormField<int>), findsNothing);
      expect(find.text('Escolher categoria'), findsOneWidget);
      expect(find.text('Tira uma foto ou escolhe um ficheiro'), findsNothing);
      await tester.enterText(find.byType(TextField).first, '12,5');
      await tester.tap(find.text('Escolher categoria'));
      await tester.pumpAndSettle();
      // passo 1: a categoria principal; passo 2: a subcategoria
      await tester.tap(find.widgetWithText(ChoiceChip, 'Alimentação ›'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Restaurantes').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('Alimentação › Restaurantes'), findsOneWidget);
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(d.s.transactions.length, before + 1);
      final t = d.s.transactions.firstWhere(
        (x) => x.description == 'Restaurantes',
      );
      expect((t.amount, t.categoryId), (-1250, d.rest));
      final now = DateTime.now();
      expect(
        (t.date.year, t.date.month, t.date.day),
        (now.year, now.month, now.day),
      );
    },
  );

  testWidgets(
    'data com um toque (Ontem) e sugestões das categorias mais usadas',
    (tester) async {
      final d = buildAnalysisData();
      await _pump(tester, d.s);
      await tester.enterText(find.byType(TextField).first, '3');
      // as categorias mais usadas aparecem como chips
      expect(find.widgetWithText(ChoiceChip, 'Lazer'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Lazer'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Ontem'));
      await tester.pump();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      final t = d.s.transactions.firstWhere((x) => x.description == 'Lazer');
      final y = DateTime.now().subtract(const Duration(days: 1));
      expect(
        (t.categoryId, t.date.day, t.date.month),
        (d.lazer, y.day, y.month),
      );
    },
  );

  testWidgets('montante em falta mostra o erro e não grava', (tester) async {
    final d = buildAnalysisData();
    final before = d.s.transactions.length;
    await _pump(tester, d.s);
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Indica um montante válido.'), findsOneWidget);
    expect(d.s.transactions.length, before);
  });

  testWidgets('receita só mostra categorias de rendimento', (tester) async {
    final d = buildAnalysisData();
    await _pump(tester, d.s);
    await tester.tap(find.text('Receita'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escolher categoria'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ChoiceChip, 'Salário'), findsWidgets);
    expect(find.widgetWithText(ChoiceChip, 'Casa'), findsNothing);
  });

  testWidgets(
    'categoria de despesas e receitas mantém-se ao mudar de despesa para receita',
    (tester) async {
      final d = buildAnalysisData();
      final olx = d.s.addCategory(
        const Categoria(id: 0, name: 'OLX', emoji: '🛒', both: true),
      );
      await _pump(tester, d.s);
      await tester.enterText(find.byType(TextField).first, '150');
      await tester.tap(find.text('Escolher categoria'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'OLX').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Receita'));
      await tester.pumpAndSettle();
      expect(find.textContaining('OLX'), findsWidgets); // não foi limpa
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      final t = d.s.transactions.firstWhere((x) => x.categoryId == olx);
      expect(t.amount, 15000);
    },
  );

  testWidgets(
    'transferência para uma plataforma de investimento fica associada e fora das despesas',
    (tester) async {
      final d = buildInvestData();
      await _pump(tester, d.s);
      await tester.tap(find.text('Transferência'));
      await tester.pumpAndSettle();
      expect(find.text('Escolher categoria'), findsNothing);
      await tester.enterText(find.byType(TextField).first, '400');
      await tester.tap(find.text('Plataforma de investimento'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('XTB').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      final t = d.s.transactions.firstWhere((x) => x.amount == -40000);
      expect((t.isTransfer, t.investAccountId), (true, d.xtb));
    },
  );

  testWidgets('editar mantém os dados; recibo e conta ficam em "Mais opções"', (
    tester,
  ) async {
    final d = buildAnalysisData();
    final t = d.s.transactions.firstWhere((x) => x.description == 'NETFLIX');
    await _pump(tester, d.s, edit: t);
    expect(find.text('Editar movimento'), findsOneWidget);
    expect(
      (tester.widget(
        find.byType(TextField).first,
      ) as TextField).controller!.text,
      '12,99',
    );
    expect(find.textContaining('Lazer'), findsWidgets);
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    final after = d.s.transactions.firstWhere((x) => x.id == t.id);
    expect((after.amount, after.categoryId), (t.amount, t.categoryId));
  });

  for (final (name, b, size, scale) in [
    ('360 dp claro', Brightness.light, const Size(360, 780), 1.0),
    ('360 dp escuro', Brightness.dark, const Size(360, 780), 1.0),
    ('fonte 130%', Brightness.light, const Size(360, 780), 1.3),
    ('ecrã grande', Brightness.light, const Size(800, 1280), 1.0),
  ]) {
    testWidgets('sem erros de layout ($name)', (tester) async {
      final d = buildAnalysisData();
      await _pump(tester, d.s, b: b, size: size, scale: scale);
      expect(tester.takeException(), isNull);
      for (final t in ['Receita', 'Transferência', 'Despesa']) {
        await tester.tap(find.text(t));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
}
