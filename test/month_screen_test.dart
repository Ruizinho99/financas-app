import 'package:financas/db/database.dart';
import 'package:financas/screens/month_screen.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'support/analysis_data.dart';
import 'support/fonts.dart';

Future<void> _pump(WidgetTester tester, AppState s, {Brightness b = Brightness.light, Size size = const Size(360, 780), double scale = 1.0}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
    value: s,
    child: MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF2E7D6B), brightness: b),
      builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
      home: const MonthScreen(),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_PT');
    await loadRoboto();
  });

  testWidgets('sem movimentos convida a importar ou adicionar', (tester) async {
    await _pump(tester, AppState(Db.memory()));
    expect(find.text('Começa por aqui'), findsOneWidget);
    expect(find.text('Importar um extrato'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mês com dados: anel, receitas, poupado, onde gastas mais e por tratar', (tester) async {
    final d = buildAnalysisData(); // abril–junho de 2026, com um movimento sem categoria
    await _pump(tester, d.s, size: const Size(360, 1500));
    // vai para junho de 2026 a partir do mês atual, mês a mês
    final now = DateTime.now();
    final back = (now.year - 2026) * 12 + now.month - 6;
    for (var i = 0; i < back; i++) {
      await tester.tap(find.byTooltip('Mês anterior'));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text('Junho 2026'), findsOneWidget);
    expect(find.text('Gasto'), findsOneWidget);
    expect(find.text('Onde gastas mais'), findsOneWidget);
    expect(find.text('Alimentação'), findsWidgets); // a categoria-mãe soma os supermercados e restaurantes
    expect(find.textContaining('Receitas'), findsOneWidget);
    expect(find.text('Poupado'), findsOneWidget);
    expect(find.textContaining('por classificar'), findsOneWidget);
    expect(find.text('Orçamento'), findsOneWidget);
    expect(find.text('Análise'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
