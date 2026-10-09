import 'dart:convert';

import 'package:financas/db/database.dart';
import 'package:financas/import/parsers.dart';
import 'package:financas/invest/import_trades_screen.dart';
import 'package:financas/invest/invest.dart';
import 'package:financas/invest/trade_import.dart';
import 'package:financas/invest/transfers_screen.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'support/fonts.dart';
import 'support/invest_data.dart';

// Dados inventados, só para testes.
const csvPt = '''Data;Tipo;Nome;Símbolo;ISIN;Quantidade;Preço;Valor;Comissão;Moeda
05/01/2026;Depósito;;;;;;500,00;;EUR
06/01/2026;Compra;Vanguard FTSE All-World;VWCE.DE;IE00BK5BQT80;3;110,50;331,50;1,00;EUR
10/02/2026;Compra;Apple Inc;AAPL;US0378331005;2;200,00;400,00;0,50;USD
20/03/2026;Venda;Apple Inc;AAPL;US0378331005;1;220,00;220,00;0,50;USD
15/04/2026;Dividendo;Apple Inc;AAPL;US0378331005;;;0,96;;USD
''';

const csvDegiro = '''Data,Hora,Produto,ISIN,Quantidade,Cotação,Moeda,Valor local,Taxa de câmbio,Custos de transação,Total
02-03-2026,10:15,ISHARES CORE MSCI WORLD,IE00B4L5Y983,4,90.25,EUR,-361.00,,-1.00,-362.00
05-03-2026,11:00,TESLA INC,US88160R1014,-1,250.00,USD,250.00,1.0800,-0.50,230.9
''';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_PT');
    await loadRoboto();
  });

  test('números em formato português e inglês', () {
    expect(parseDecimal('1.234,56'), 1234.56);
    expect(parseDecimal('1,234.56'), 1234.56);
    expect(parseDecimal('12,5'), 12.5);
    expect(parseDecimal('110.50'), 110.5);
    expect(parseDecimal('(3,00)'), -3);
    expect(parseDecimal('US\$ 10'), 10);
    expect(parseDecimal('1.234.567'), 1234567);
    expect(parseDecimal(''), isNull);
  });

  group('CSV / Excel', () {
    test('reconhece colunas em português e ignora o depósito', () {
      final t = parseCsv(csvPt);
      final m = guessTradeMapping(t);
      expect(m.usable, isTrue);
      final l = tradesFromTable(t, m);
      expect(l.map((e) => e.kind), ['buy', 'buy', 'sell', 'dividend']);
      expect(l[0].quantity, 3);
      expect(l[0].price, 110.5);
      expect(l[0].fee, 1);
      expect(l[0].isin, 'IE00BK5BQT80');
      expect(l[1].currency, 'USD');
      expect(l[3].total, 0.96);
      expect(l[0].date, DateTime(2026, 1, 6));
    });

    test('sem coluna de tipo: quantidade negativa é venda; câmbio e comissões lidos', () {
      final t = parseCsv(csvDegiro);
      final m = guessTradeMapping(t);
      expect(m.type, isNull);
      final l = tradesFromTable(t, m);
      expect(l.map((e) => e.kind), ['buy', 'sell']);
      expect(l[1].quantity, 1);
      expect(l[1].rate, 1.08);
      expect(l[1].currency, 'USD');
      expect(l[1].fee, 0.5);
    });
  });

  group('PDF (texto)', () {
    test('linhas com data, tipo, quantidade, preço e total', () {
      const text = '''Extrato de operações
05/01/2026 Compra Vanguard FTSE All-World IE00BK5BQT80 3 110,50 EUR 331,50
10/02/2026 Venda Apple Inc 1 220,00 USD 220,00
15/04/2026 Dividendo Apple Inc 0,96 USD
Total geral 1.000,00
''';
      final l = tradesFromText(text);
      expect(l.length, 3);
      expect((l[0].kind, l[0].quantity, l[0].price, l[0].currency, l[0].isin), ('buy', 3.0, 110.5, 'EUR', 'IE00BK5BQT80'));
      expect(l[0].name, 'Vanguard FTSE All-World');
      expect((l[1].kind, l[1].quantity, l[1].price, l[1].currency), ('sell', 1.0, 220.0, 'USD'));
      expect((l[2].kind, l[2].total), ('dividend', 0.96));
    });

    test('comissão deduzida do total quando o total difere de qtd × preço', () {
      final l = tradesFromText('06/01/2026 Compra Teste SA 2 100,00 EUR 201,00');
      expect(l.single.fee, closeTo(1, 1e-9));
    });
  });

  group('tradeToOp', () {
    final buy = ParsedTrade(date: DateTime(2026, 2, 10), kind: 'buy', quantity: 2, price: 200, currency: 'USD', fee: 0.5);
    test('compra em USD: valor em EUR pelo câmbio, preço em USD', () {
      final op = tradeToOp(buy, accountId: 1, holdingId: 7, base: 'EUR', defaultCcy: 'EUR', rates: {'USD': 1.25}, holdingCcy: 'USD')!;
      expect(op.amount, 32040); // (400 + 0,5) ÷ 1,25 = 320,40 €
      expect(op.fx, closeTo(0.8, 1e-9));
      expect(op.price, 200);
      expect(op.fee, 40);
    });
    test('sem câmbio não gera operação', () {
      expect(tradeToOp(buy, accountId: 1, holdingId: 7, base: 'EUR', defaultCcy: 'EUR', rates: {}, holdingCcy: 'USD'), isNull);
    });
    test('o câmbio da própria linha tem prioridade', () {
      final t = ParsedTrade(date: DateTime(2026, 3, 5), kind: 'sell', quantity: 1, price: 250, currency: 'USD', fee: 0.5, rate: 1.08);
      final op = tradeToOp(t, accountId: 1, holdingId: 7, base: 'EUR', defaultCcy: 'EUR', rates: {}, holdingCcy: 'USD')!;
      expect(op.amount, (249.5 / 1.08 * 100).round());
    });
    test('linha em EUR para ativo em USD: preço convertido para a moeda do ativo', () {
      final t = ParsedTrade(date: DateTime(2026, 3, 5), kind: 'buy', quantity: 2, price: 160, currency: 'EUR');
      final op = tradeToOp(t, accountId: 1, holdingId: 7, base: 'EUR', defaultCcy: 'EUR', rates: {'USD': 1.25}, holdingCcy: 'USD')!;
      expect(op.amount, 32000);
      expect(op.price, closeTo(200, 1e-9)); // 320 € = 400 USD ÷ 2
    });
  });

  group('ecrã de importação', () {
    Future<void> pump(WidgetTester tester, AppState s, Widget screen) async {
      tester.view.physicalSize = const Size(360, 2400) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
        value: s,
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Builder(builder: (c) => Scaffold(body: TextButton(onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => screen)), child: const Text('abrir')))),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('liga ao ativo existente, cria o novo, pede câmbio e grava; segunda vez ignora duplicados', (tester) async {
      final s = AppState(Db.memory(), prices: fakePrices());
      final acc = s.addInvestAccount('XTB');
      final vwce = s.addHolding(Holding(id: 0, accountId: acc, name: 'Vanguard FTSE All-World', symbol: 'VWCE.DE', provider: PriceProvider.yahoo, lastPrice: 120));
      final bytes = utf8.encode(csvPt);
      await pump(tester, s, ImportTradesScreen(accountId: acc, preloaded: (name: 'extrato.csv', bytes: bytes as dynamic)));
      await tester.pumpAndSettle();
      expect(find.text('Ativos encontrados'), findsOneWidget);
      expect(tester.takeException(), isNull);
      // falta o câmbio do USD
      expect(find.textContaining('Falta o câmbio'), findsOneWidget);
      expect(find.textContaining('Importar 1 operação'), findsOneWidget); // só a de EUR; as de USD esperam o câmbio
      await tester.enterText(find.widgetWithText(TextField, '1,0850').first, '1,25');
      await tester.pumpAndSettle();
      expect(find.textContaining('Falta o câmbio'), findsNothing);
      await tester.tap(find.textContaining('Importar 4 operações'));
      await tester.pumpAndSettle();

      final ops = s.investOps;
      expect(ops.length, 4);
      expect(ops.where((o) => o.holdingId == vwce).length, 1); // ligado ao ativo existente
      final apple = s.holdings.firstWhere((h) => h.name == 'Apple Inc');
      expect((apple.symbol, apple.currency, apple.provider), ('AAPL', 'USD', PriceProvider.yahoo));
      final pos = s.portfolio.positions.firstWhere((p) => p.holding.id == apple.id);
      expect(pos.qty, 1); // 2 comprados, 1 vendido
      final div = ops.firstWhere((o) => o.type == OpType.dividend);
      expect(div.amount, (0.96 / 1.25 * 100).round());

      // segunda importação do mesmo ficheiro: tudo duplicado
      await pump(tester, s, ImportTradesScreen(accountId: acc, preloaded: (name: 'extrato.csv', bytes: bytes as dynamic)));
      await tester.pumpAndSettle();
      expect(find.textContaining('já existentes'), findsWidgets);
      expect(find.textContaining('Importar 0 operações'), findsOneWidget);
    });
  });

  group('intervalo de datas e transferências', () {
    testWidgets('importar compras só num intervalo de datas', (tester) async {
      final s = AppState(Db.memory(), prices: fakePrices());
      final acc = s.addInvestAccount('XTB');
      tester.view.physicalSize = const Size(360, 2600) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
        value: s,
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Builder(builder: (c) => Scaffold(body: TextButton(onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => ImportTradesScreen(accountId: acc, preloaded: (name: 'e.csv', bytes: utf8.encode(csvPt) as dynamic)))), child: const Text('abrir')))),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Período a importar'), findsOneWidget);
      expect(find.textContaining('06/01/2026 a 15/04/2026'), findsOneWidget);
      expect(find.text('4 no ficheiro'), findsOneWidget);
      // só de 20/01 em diante: ficam a compra da Apple, a venda e o dividendo
      await tester.tap(find.text('06/01/2026'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('20'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('3 de 4 no período'), findsOneWidget);
      expect(find.textContaining('Vanguard'), findsNothing); // o ativo da compra de janeiro desapareceu da lista
      expect(tester.takeException(), isNull);
    });

    testWidgets('ecrã da transferência: sugerir, ver o que fica em espera e guardar', (tester) async {
      final d = buildInvestData();
      final t = d.s.transactions.firstWhere((x) => x.description.contains('XTB') && x.amount == -60000);
      tester.view.physicalSize = const Size(360, 1800) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(value: d.s, child: MaterialApp(theme: ThemeData(useMaterial3: true), home: TransferAllocScreen(txnId: t.id))));
      await tester.pumpAndSettle();
      expect(find.textContaining('Em espera 600,00'), findsOneWidget);
      await tester.tap(find.text('Sugerir'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Em espera'), findsWidgets);
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(d.s.transferAllocation(t).allocated, greaterThan(0));
    });

    test('transferência: compras associadas, resto em espera', () {
      final d = buildInvestData();
      final t = d.s.transactions.firstWhere((x) => x.description.contains('XTB') && x.amount == -60000);
      final buy = d.s.investOps.firstWhere((o) => o.type == OpType.buy && o.holdingId == d.vwce);
      expect(d.s.transferAllocation(t).allocated, 0);
      d.s.allocateTransfer(t.id, [buy.id]);
      final a = d.s.transferAllocation(t);
      expect(a.allocated, 55100);
      expect(a.onHold, 60000 - 55100);
      expect(d.s.investOps.firstWhere((o) => o.id == buy.id).txnId, t.id);
      // editar a compra não perde a ligação
      d.s.allocateTransfer(t.id, []);
      expect(d.s.transferAllocation(t).onHold, 60000);
      expect(d.s.investDeliveries.length, 3);
    });
  });
}
