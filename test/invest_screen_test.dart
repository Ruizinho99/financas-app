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

  testWidgets('definir a posição inicial outra vez traz o valor anterior e substitui-o', (tester) async {
    final d = buildInvestData(); // VWCE: posição inicial 10 × 100 + compra de 5
    await _pump(tester, d.s, OpFormScreen(type: OpType.initial, accountId: d.xtb, holdingId: d.vwce), size: const Size(360, 1800));
    expect(find.text('Este ativo já tem uma posição inicial'), findsOneWidget);
    final fields = find.byType(TextField);
    expect((tester.widget(fields.at(0)) as TextField).controller!.text, '10');
    expect((tester.widget(fields.at(1)) as TextField).controller!.text, '100');
    await tester.enterText(fields.at(0), '12');
    await tester.enterText(fields.at(1), '95');
    await tester.pump();
    await tester.ensureVisible(find.text('Guardar alterações'));
    await tester.tap(find.text('Guardar alterações'));
    await tester.pumpAndSettle();
    final inits = d.s.investOps.where((o) => o.type == OpType.initial && o.holdingId == d.vwce).toList();
    expect(inits.length, 1);
    expect((inits.first.quantity, inits.first.price, inits.first.amount), (12.0, 95.0, 114000));
    final pos = d.s.portfolio.positions.firstWhere((p) => p.holding.id == d.vwce);
    expect(pos.qty, 17); // 12 + 5 comprados
  });

  testWidgets('posições iniciais duplicadas (versão antiga) ficam numa só ao guardar', (tester) async {
    final d = buildInvestData();
    d.s.addOp(InvestOp(id: 0, accountId: d.xtb, holdingId: d.vwce, date: DateTime(2025, 7, 1), type: OpType.initial, quantity: 1, price: 100, amount: 10000));
    await _pump(tester, d.s, OpFormScreen(type: OpType.initial, accountId: d.xtb), size: const Size(360, 1800));
    // escolher o ativo: carrega a posição inicial mais recente
    await tester.tap(find.byType(DropdownButtonFormField<int>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Vanguard').last);
    await tester.pumpAndSettle();
    expect((tester.widget(find.byType(TextField).at(0)) as TextField).controller!.text, '1');
    await tester.enterText(find.byType(TextField).at(0), '10');
    await tester.pump();
    await tester.ensureVisible(find.text('Guardar alterações'));
    await tester.tap(find.text('Guardar alterações'));
    await tester.pumpAndSettle();
    expect(d.s.investOps.where((o) => o.type == OpType.initial && o.holdingId == d.vwce).length, 1);
    expect(d.s.portfolio.positions.firstWhere((p) => p.holding.id == d.vwce).qty, 15);
  });

  testWidgets('ativo em dólares: compra com câmbio, preço médio em USD e em EUR', (tester) async {
    final d = buildInvestData();
    final nvda = d.s.addHolding(Holding(id: 0, accountId: d.xtb, name: 'Nvidia', kind: HoldingKind.stock, currency: 'USD', lastPrice: 110, lastPriceOrig: 120, lastFx: 110 / 120));
    await _pump(tester, d.s, OpFormScreen(type: OpType.buy, accountId: d.xtb, holdingId: nvda), size: const Size(360, 1900));
    final fields = find.byType(TextField);
    // quantidade, preço (USD, sugerido 120), câmbio (sugerido 1/0,9167), comissão
    expect((tester.widget(fields.at(1)) as TextField).controller!.text, '120');
    await tester.enterText(fields.at(0), '2');
    await tester.enterText(fields.at(1), '200');
    await tester.enterText(fields.at(2), '1,25'); // 1 € = 1,25 USD → 1 USD = 0,80 €
    await tester.enterText(fields.at(3), '1');
    await tester.pump();
    expect(find.textContaining('Total a pagar: 321,00'), findsOneWidget); // 2 × 200 × 0,80 + 1
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    final op = d.s.investOps.last;
    expect((op.price, op.amount, op.fee), (200.0, 32100, 100));
    expect(op.fx, closeTo(0.8, 1e-9));
    final pos = d.s.portfolio.positions.firstWhere((p) => p.holding.id == nvda);
    expect(pos.avgCostOrig, closeTo(200.625, 1e-9)); // (400 + 1 € ÷ 0,80) ÷ 2
    expect(pos.avgCost, closeTo(160.5, 1e-9));
    expect(pos.valueCents, (2 * 110 * 100));
    expect(pos.plOrig, closeTo(2 * 120 - 401.25, 1e-6), reason: 'ganho só no preço, em USD');
  });

  testWidgets('editar uma compra antiga em euros de um ativo em USD mantém o custo em euros', (tester) async {
    final d = buildInvestData();
    final h = d.s.holding(d.aapl)!;
    d.s.updateHolding(h.copyWith(currency: 'USD', lastPriceOrig: 150 / 0.9, lastFx: 0.9));
    final op = d.s.investOps.firstWhere((o) => o.holdingId == d.aapl); // 2 × 140 € = 280 €, sem câmbio guardado
    await _pump(tester, d.s, OpFormScreen(type: op.type, edit: op), size: const Size(360, 1900));
    expect(find.textContaining('Total a pagar: 280,00'), findsOneWidget);
    await tester.ensureVisible(find.text('Guardar alterações'));
    await tester.tap(find.text('Guardar alterações'));
    await tester.pumpAndSettle();
    final saved = d.s.investOps.firstWhere((o) => o.id == op.id);
    expect(saved.amount, 28000);
    expect(saved.fx, closeTo(0.9, 1e-5));
  });
}
