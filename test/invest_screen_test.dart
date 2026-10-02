import 'package:financas/db/database.dart';
import 'package:financas/invest/account_screen.dart';
import 'package:financas/invest/forms.dart';
import 'package:financas/invest/holding_screen.dart';
import 'package:financas/invest/invest.dart';
import 'package:financas/invest/invest_screen.dart';
import 'package:financas/main.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'support/fonts.dart';
import 'support/invest_data.dart';

Future<void> _pump(WidgetTester tester, AppState s, Widget home, {Brightness brightness = Brightness.light, Size size = const Size(360, 640), double textScale = 1.0}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
    value: s,
    child: MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF2E7D6B), brightness: brightness),
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)), child: child!),
      home: home,
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _scroll(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 80));
  }
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_PT');
    await loadRoboto();
  });

  testWidgets('estado vazio explica os passos e cria a primeira plataforma', (tester) async {
    final s = AppState(Db.memory(), prices: fakePrices());
    await _pump(tester, s, const InvestScreen());
    expect(find.text('Acompanha o que tens investido'), findsOneWidget);
    await tester.tap(find.text('Criar a primeira plataforma'));
    await tester.pumpAndSettle();
    // nome vazio → erro
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Indica um nome'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Nome'), 'XTB');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(s.investAccounts.map((a) => a.name), ['XTB']);
    expect(find.text('A minha carteira'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final (name, b, size, scale) in [
    ('360 dp claro', Brightness.light, const Size(360, 640), 1.0),
    ('360 dp escuro', Brightness.dark, const Size(360, 640), 1.0),
    ('411 dp', Brightness.light, const Size(411, 890), 1.0),
    ('fonte 130%', Brightness.light, const Size(360, 640), 1.3),
    ('ecrã grande', Brightness.light, const Size(800, 1280), 1.0),
  ]) {
    testWidgets('Carteira, plataforma e ativo sem erros de layout ($name)', (tester) async {
      final d = buildInvestData();
      await _pump(tester, d.s, const InvestScreen(), brightness: b, size: size, textScale: scale);
      expect(find.text('A minha carteira'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _scroll(tester);
      expect(tester.takeException(), isNull);

      await _pump(tester, d.s, AccountScreen(accountId: d.xtb), brightness: b, size: size, textScale: scale);
      expect(find.text('Dinheiro por alocar'), findsOneWidget);
      await _scroll(tester);
      expect(tester.takeException(), isNull);

      await _pump(tester, d.s, HoldingScreen(holdingId: d.vwce), brightness: b, size: size, textScale: scale);
      expect(find.text('A minha posição'), findsOneWidget);
      await _scroll(tester);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('os números da Carteira batem certo', (tester) async {
    final d = buildInvestData();
    await _pump(tester, d.s, const InvestScreen(), size: const Size(360, 2400));
    final pf = d.s.portfolio;
    // XTB: VWCE 15 un. (custo 1551 €, médio 103,40 €) a 120 € + Apple 2 un. a 150 € ; entregas 900 € ; compras 551 + 280
    final x = pf.accounts.firstWhere((a) => a.account.id == d.xtb);
    expect(x.cashCents, 90000 - 55100 - 28000);
    expect(x.investedValue, 15 * 120 * 100 + 2 * 150 * 100);
    expect(pf.cash, x.cashCents + 0); // a exchange gastou tudo o que enviou
    expect(pf.total, pf.investedValue + pf.cash);
    expect(find.text('Dinheiro por alocar'), findsWidgets);
    expect(find.text('Alocar'), findsOneWidget); // só a XTB tem dinheiro por alocar
  });

  testWidgets('compra: calcula total, mostra o dinheiro por alocar e grava', (tester) async {
    final d = buildInvestData();
    await _pump(tester, d.s, OpFormScreen(type: OpType.buy, accountId: d.xtb, holdingId: d.aapl), size: const Size(360, 1800));
    expect(find.text('Compra'), findsWidgets);
    final fields = find.byType(TextField);
    // quantidade, preço (já sugerido: 150), comissão, nota
    await tester.enterText(fields.at(0), '2');
    await tester.enterText(fields.at(1), '155,5');
    await tester.enterText(fields.at(2), '1');
    await tester.pump();
    expect(find.textContaining('Total a pagar: 312,00'), findsOneWidget); // 2 × 155,50 + 1
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    final op = d.s.investOps.last;
    expect((op.type, op.quantity, op.price, op.amount, op.fee), (OpType.buy, 2.0, 155.5, 31200, 100));
    final pos = d.s.portfolio.positions.firstWhere((p) => p.holding.id == d.aapl);
    expect(pos.qty, 4);
    expect(pos.costCents, 28000 + 31200);
    expect(pos.avgCost, closeTo(148, 0.0001));
  });

  testWidgets('alocar o dinheiro por alocar: modo "valor e preço" calcula a quantidade', (tester) async {
    final d = buildInvestData();
    final cash = d.s.portfolio.accounts.firstWhere((a) => a.account.id == d.xtb).cashCents; // 69 €
    await _pump(tester, d.s, OpFormScreen(type: OpType.buy, accountId: d.xtb, holdingId: d.vwce, prefillCents: cash), size: const Size(360, 1800));
    // já vem em modo "valor": o preço sugerido é o último (120 €)
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), '100'); // preço
    await tester.pump();
    expect(find.textContaining('= 0,69 unidades'), findsOneWidget);
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    final op = d.s.investOps.last;
    expect(op.amount, cash);
    expect(op.quantity, closeTo(0.69, 1e-9));
    expect(d.s.portfolio.accounts.firstWhere((a) => a.account.id == d.xtb).cashCents, 0); // tudo alocado
  });

  testWidgets('vender mais do que tens é recusado', (tester) async {
    final d = buildInvestData();
    await _pump(tester, d.s, OpFormScreen(type: OpType.sell, accountId: d.xtb, holdingId: d.aapl), size: const Size(360, 1800));
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '5'); // só tens 2
    await tester.enterText(fields.at(1), '150');
    await tester.pump();
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Só tens 2 unidades'), findsOneWidget);
    expect(d.s.investOps.where((o) => o.type == OpType.sell), isEmpty);
  });

  testWidgets('posição inicial define o preço médio sem mexer no dinheiro', (tester) async {
    final d = buildInvestData();
    final before = d.s.portfolio.cash;
    await _pump(tester, d.s, OpFormScreen(type: OpType.initial, accountId: d.xtb, holdingId: d.aapl), size: const Size(360, 1800));
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '3');
    await tester.enterText(fields.at(1), '90');
    await tester.pump();
    expect(find.textContaining('Custo da posição: 270,00'), findsOneWidget);
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(d.s.portfolio.cash, before);
    final pos = d.s.portfolio.positions.firstWhere((p) => p.holding.id == d.aapl);
    expect(pos.qty, 5);
    expect(pos.costCents, 28000 + 27000);
  });

  testWidgets('associar transferências do banco e lembrar os títulos', (tester) async {
    final d = buildInvestData();
    d.s.addManual(date: DateTime(2026, 3, 1), description: 'TRF P/ XTB S.A', amount: -10000); // novo, ainda sem plataforma
    expect(d.s.transactions.firstWhere((t) => t.date == DateTime(2026, 3, 1)).investAccountId, isNull);
    await _pump(tester, d.s, LinkTransfersScreen(accountId: d.xtb), size: const Size(360, 1800));
    expect(find.textContaining('parece desta plataforma'), findsOneWidget);
    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pump();
    await tester.tap(find.textContaining('Associar 1'));
    await tester.pumpAndSettle();
    expect(d.s.transactions.firstWhere((t) => t.date == DateTime(2026, 3, 1)).investAccountId, d.xtb);
    expect(d.s.investPatterns.any((p) => p.accountId == d.xtb), isTrue);
  });

  testWidgets('definir preço à mão e atualizar por API (simulada)', (tester) async {
    final d = buildInvestData();
    await _pump(tester, d.s, HoldingScreen(holdingId: d.aapl));
    await tester.tap(find.text('Definir à mão'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Preço por unidade (€)'), '160,5');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(d.s.holding(d.aapl)!.lastPrice, 160.5);

    await _pump(tester, d.s, HoldingScreen(holdingId: d.vwce));
    await tester.tap(find.text('Atualizar preço'));
    await tester.pumpAndSettle();
    expect(d.s.holding(d.vwce)!.lastPrice, 125.5);
  });

  testWidgets('etiquetas da barra de navegação ficam numa só linha em 360 dp', (tester) async {
    final d = buildInvestData();
    tester.view.physicalSize = const Size(360, 640) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    // usa o tema real da app (com a letra reduzida das etiquetas)
    await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(value: d.s, child: const FinancasApp()));
    await tester.pumpAndSettle();
    final one = tester.getSize(find.text('Movimentos').last).height;
    expect(one, lessThan(16), reason: 'Movimentos deve ocupar uma só linha');
    for (final (icon, label) in [(Icons.style_outlined, 'Classificar'), (Icons.savings_outlined, 'Orçamento'), (Icons.insights_outlined, 'Análise'), (Icons.account_balance_outlined, 'Carteira')]) {
      await tester.tap(find.byIcon(icon));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.text(label).last).height, lessThan(16), reason: '$label deve ocupar uma só linha');
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('barra de navegação com 6 separadores e o separador Carteira', (tester) async {
    final d = buildInvestData();
    await _pump(tester, d.s, const HomeShell());
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.account_balance_outlined));
    await tester.pumpAndSettle();
    expect(find.text('A minha carteira'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
