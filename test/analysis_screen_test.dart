import 'package:financas/screens/analysis_screen.dart';
import 'package:financas/state/app_state.dart';
import 'package:financas/db/database.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/analysis_data.dart';
import 'support/fonts.dart';

Future<void> _pump(WidgetTester tester, AppState s, {Brightness brightness = Brightness.light, Size size = const Size(360, 640), double textScale = 1.0}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
    value: s,
    child: MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF2E7D6B), brightness: brightness),
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)), child: child!),
      home: AnalysisScreen(initialMonth: DateTime(2026, 6)),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _scrollThrough(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_PT');
    await loadRoboto();
  });

  for (final (name, b, size, scale) in [
    ('telemóvel pequeno, claro', Brightness.light, const Size(360, 640), 1.0),
    ('telemóvel pequeno, escuro', Brightness.dark, const Size(360, 640), 1.0),
    ('telemóvel médio (411 dp)', Brightness.light, const Size(411, 890), 1.0),
    ('fonte a 130%', Brightness.light, const Size(360, 640), 1.3),
    ('ecrã grande', Brightness.light, const Size(800, 1280), 1.0),
  ]) {
    testWidgets('percorre os 4 separadores sem erros de layout ($name)', (tester) async {
      final d = buildAnalysisData();
      await _pump(tester, d.s, brightness: b, size: size, textScale: scale);
      expect(find.text('Visão geral'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(find.text('Despesas'), findsWidgets);
      expect(find.text('Rendimentos'), findsWidgets);
      await _scrollThrough(tester);
      expect(tester.takeException(), isNull);

      for (final tab in ['Gastos', 'Poupar', 'Evolução']) {
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'separador $tab');
        await _scrollThrough(tester);
        expect(tester.takeException(), isNull, reason: 'separador $tab (scroll)');
      }
    });
  }

  testWidgets('Poupar mostra sugestões e o simulador responde', (tester) async {
    final d = buildAnalysisData();
    await _pump(tester, d.s);
    await tester.tap(find.text('Poupar'));
    await tester.pumpAndSettle();
    expect(find.text('Potencial de poupança'), findsOneWidget);
    expect(find.text('E se cortasse nas opcionais?'), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('Alimentação subiu'), 300, scrollable: find.byType(Scrollable).last);
    expect(find.textContaining('Alimentação subiu'), findsOneWidget); // +74% face a maio
    await tester.ensureVisible(find.text('20%'));
    await tester.tap(find.text('20%'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Gastos: abrir o detalhe de uma categoria e filtrar só por ela', (tester) async {
    final d = buildAnalysisData();
    await _pump(tester, d.s);
    await tester.tap(find.text('Gastos'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.widgetWithText(InkWell, 'Alimentação'), 200, scrollable: find.byType(Scrollable).last);
    tester.widget<InkWell>(find.widgetWithText(InkWell, 'Alimentação')).onTap!();
    await tester.pumpAndSettle();
    expect(find.text('De onde vem'), findsOneWidget);
    expect(find.text('Analisar só esta'), findsOneWidget);
    await tester.tap(find.text('Analisar só esta'));
    await tester.pumpAndSettle();
    // o filtro fica ativo e visível (o cabeçalho tinha saído do ecrã com o scroll)
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 1200));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, 'Alimentação'), findsOneWidget);
    // e a lista de gastos passa a ter só a Alimentação
    expect(find.text('Casa'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Filtros: abrir a folha, escolher "Opcionais" e aplicar', (tester) async {
    final d = buildAnalysisData();
    await _pump(tester, d.s);
    await tester.tap(find.text('Filtros'));
    await tester.pumpAndSettle();
    expect(find.text('Tipo de despesa'), findsOneWidget);
    await tester.tap(find.text('Opcionais'));
    await tester.pump();
    await tester.tap(find.text('Aplicar filtros'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, 'Opcionais'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sem dados não rebenta', (tester) async {
    final s = AppState(Db.memory());
    await _pump(tester, s);
    expect(find.textContaining('Sem movimentos'), findsOneWidget);
    for (final tab in ['Gastos', 'Poupar', 'Evolução']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: tab);
    }
  });
}
