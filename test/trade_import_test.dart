import 'dart:convert';
import 'dart:typed_data';

import 'package:financas/db/database.dart';
import 'package:financas/import/parsers.dart';
import 'package:financas/invest/import_trades_screen.dart';
import 'package:financas/invest/invest.dart';
import 'package:financas/invest/trade_import.dart';
import 'package:financas/invest/transfers_screen.dart';
import 'package:financas/state/app_state.dart';
import 'package:excel/excel.dart' as xl;
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

  group('validação do ficheiro', () {
    const csvBad = 'Data;Tipo;Nome;Quantidade;Preço;Moeda\n'
        '06/01/2026;Compra;Alpha SA;3;110,50;EUR\n'
        '07/01/2026;Permuta;Beta SA;2;50,00;EUR\n'
        'ontem;Compra;Gama SA;1;10,00;EUR\n'
        '08/01/2026;Venda;Alpha SA;abc;110,50;EUR\n'
        '09/01/2026;Depósito;;;;EUR\n'
        '10/01/2026;Compra;Delta SA;1;;EUR\n';

    test('cada linha problemática é explicada e os tipos novos podem ser escolhidos', () {
      final t = parseCsv(csvBad);
      final m = guessTradeMapping(t);
      final r = parseTradeTable(t, m);
      expect(r.trades.length, 1); // só a primeira está completa
      expect(r.unknownTypes, {'Permuta': 1});
      final reasons = r.skipped.map((e) => e.reason).toList();
      expect(reasons, containsAll(['Data inválida ou vazia', 'Quantidade em falta ou inválida', 'Preço em falta (e sem valor total para o calcular)']));
      expect(reasons.any((e) => e.startsWith('Tipo não reconhecido')), isTrue);
      expect(r.skipped.firstWhere((e) => e.reason.startsWith('Data')).row, 4);
      expect(r.ignoredByUser, 1); // o depósito não é uma operação
      expect(r.columns['quantity'], (ok: 4, total: 5)); // "abc" não é número; a linha do depósito não conta
      expect(r.columns['date']!.ok, 5);
      // decidir o que é "Permuta": passa a compra
      final r2 = parseTradeTable(t, m, typeOverrides: {typeKey('Permuta'): 'buy'});
      expect(r2.trades.length, 2);
      expect(r2.unknownTypes, isEmpty);
    });

    test('Excel: escolhe a folha certa, lê números e datas (inclusive em número de série)', () {
      final ex = xl.Excel.createExcel();
      ex.rename('Sheet1', 'Resumo');
      final r = ex['Resumo'];
      r.appendRow([xl.TextCellValue('Relatório'), xl.TextCellValue('2026')]);
      final d = ex['Operações'];
      d.appendRow([xl.TextCellValue('Data'), xl.TextCellValue('Tipo'), xl.TextCellValue('Produto'), xl.TextCellValue('Quantidade'), xl.TextCellValue('Preço'), xl.TextCellValue('Moeda')]);
      d.appendRow([xl.DateCellValue(year: 2026, month: 1, day: 6), xl.TextCellValue('Compra'), xl.TextCellValue('Alpha SA'), xl.IntCellValue(3), xl.DoubleCellValue(110.5), xl.TextCellValue('EUR')]);
      d.appendRow([xl.IntCellValue(46037), xl.TextCellValue('Venda'), xl.TextCellValue('Alpha SA'), xl.DoubleCellValue(1.5), xl.DoubleCellValue(0.00001234), xl.TextCellValue('EUR')]); // 2026-01-15 em série
      final sheets = parseXlsxSheets(Uint8List.fromList(ex.encode()!));
      expect(sheets.keys, containsAll(['Resumo', 'Operações']));
      final m = guessTradeMapping(sheets['Operações']!);
      expect(m.usable, isTrue);
      final rep = parseTradeTable(sheets['Operações']!, m);
      expect(rep.trades.length, 2);
      expect(rep.trades[1].date, DateTime(2026, 1, 15));
      expect(rep.trades[1].price, closeTo(0.00001234, 1e-12)); // sem notação científica
      expect(rep.skipped, isEmpty);
    });
  });

  testWidgets('ecrã mostra a validação das colunas e deixa resolver tipos novos', (tester) async {
    final s = AppState(Db.memory(), prices: fakePrices());
    final acc = s.addInvestAccount('XTB');
    tester.view.physicalSize = const Size(360, 3200) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    const csv = 'Data;Tipo;Nome;Quantidade;Preço;Moeda\n06/01/2026;Compra;Alpha SA;3;110,50;EUR\n07/01/2026;Permuta;Beta SA;2;50,00;EUR\nontem;Compra;Gama SA;1;10,00;EUR\n';
    await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
      value: s,
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Builder(builder: (c) => Scaffold(body: TextButton(onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => ImportTradesScreen(accountId: acc, preloaded: (name: 'e.csv', bytes: utf8.encode(csv) as dynamic)))), child: const Text('abrir')))),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Validação do ficheiro'), findsOneWidget);
    expect(find.textContaining('3 linhas com dados'), findsOneWidget);
    expect(find.textContaining('Data: 2 de 3 válidas'), findsOneWidget);
    expect(find.text('Tipos que não reconheci'), findsOneWidget);
    expect(find.textContaining('2 linhas não importadas'), findsOneWidget);
    await tester.tap(find.text('Escolher'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compra').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('1 linha não importada'), findsOneWidget); // só a data inválida
    expect(tester.takeException(), isNull);
  });

  group('export só com valor + comentário (formato XTB, dados inventados)', () {
    test('o comentário dá a quantidade e o preço; o câmbio sai do valor pago', () {
      expect(parseFillComment('OPEN BUY IONQ.US 1/1.8671 @ 45.73'), (qty: 1.0, price: 45.73));
      expect(parseFillComment('OPEN BUY 0.4296 @ 263.71'), (qty: 0.4296, price: 263.71));
      expect(parseFillComment('OPEN BUY 5 @ 181.16'), (qty: 5.0, price: 181.16));
      expect(parseFillComment('OPEN BUY'), isNull);
      expect(currencyFromTicker('IONQ.US'), 'USD');
      expect(currencyFromTicker('AMZN.DE'), 'EUR');
      expect(currencyFromTicker('AAPL'), '');
      expect(yahooSymbol('IONQ.US'), 'IONQ');
      expect(yahooSymbol('AMZN.DE'), 'AMZN.DE');

      const csv = 'Type;Instrument;Ticker;Category;Time;Amount;Comment\n'
          'Stock purchase;Alpha;ALFA.US;STOCK;2026-09-28T13:30:59.893Z;-40,44;OPEN BUY ALFA.US 1/1.8671 @ 45.73\n'
          'Stock purchase;Alpha;ALFA.US;STOCK;2026-09-28T13:30:02.081Z;-35,13;OPEN BUY ALFA.US 0.8671/1.8671 @ 45.81\n'
          'Stock purchase;Beta Euro;BETA.DE;ETF;2026-09-04T09:31:29.110Z;-99,99;OPEN BUY BETA.DE 0.4575 @ 218.55\n';
      final t = parseCsv(csv);
      final m = guessTradeMapping(t);
      expect(m.usable, isTrue);
      expect((m.quantity, m.price), (null, null));
      expect(m.comment, 6);
      final r = parseTradeTable(t, m);
      expect(r.skipped, isEmpty);
      expect(r.trades.length, 3);
      final a = r.trades[0];
      expect((a.quantity, a.price, a.currency, a.total, a.category), (1.0, 45.73, 'USD', 40.44, 'STOCK'));
      expect(a.rate, closeTo(45.73 / 40.44, 1e-9));
      expect(r.trades[2].currency, 'EUR');
      // a operação fica com exatamente o valor pago, em euros, e o preço em dólares
      final op = tradeToOp(a, accountId: 1, holdingId: 1, base: 'EUR', defaultCcy: 'EUR', rates: {}, holdingCcy: 'USD')!;
      expect(op.amount, 4044);
      expect(op.price, 45.73);
      expect(op.fx, closeTo(40.44 / 45.73, 1e-9));
      final eu = tradeToOp(r.trades[2], accountId: 1, holdingId: 2, base: 'EUR', defaultCcy: 'EUR', rates: {}, holdingCcy: 'EUR')!;
      expect(eu.amount, 9999);
      expect(eu.fx, isNull);
    });

    test('sem quantidade nem comentário, a compra fica "só valor" e pede a quantidade', () {
      const csv = 'Type;Instrument;Ticker;Time;Amount\nStock purchase;Alpha;ALFA.US;2026-09-28;-40,44\n';
      final t = parseCsv(csv);
      final r = parseTradeTable(t, guessTradeMapping(t));
      expect(r.trades.single.valueOnly, isTrue);
      expect(tradeToOp(r.trades.single, accountId: 1, holdingId: 1, base: 'EUR', defaultCcy: 'EUR', rates: {}, holdingCcy: 'EUR'), isNull);
    });

    testWidgets('importar o Excel (como o do XTB) cria os ativos pelo ticker e categoria, com os valores certos', (tester) async {
      final ex = xl.Excel.createExcel();
      ex.rename('Sheet1', 'Sheet1');
      final sh = ex['Sheet1'];
      sh.appendRow(['Type', 'Instrument', 'Ticker', 'Category', 'Time', 'Amount', 'Comment'].map((e) => xl.TextCellValue(e)).toList());
      void row(String inst, String tick, String cat, int d, double amt, String c) => sh.appendRow([xl.TextCellValue('Stock purchase'), xl.TextCellValue(inst), xl.TextCellValue(tick), xl.TextCellValue(cat), xl.DateTimeCellValue(year: 2026, month: 9, day: d, hour: 13, minute: 30), xl.DoubleCellValue(amt), xl.TextCellValue(c)]);
      row('Alpha', 'ALFA.US', 'STOCK', 28, -40.44, 'OPEN BUY ALFA.US 1/1.8671 @ 45.73');
      row('Alpha', 'ALFA.US', 'STOCK', 27, -35.13, 'OPEN BUY ALFA.US 0.8671/1.8671 @ 45.81');
      row('Gama ETF', 'GAMA.DE', 'ETF', 26, -50.0, 'OPEN BUY GAMA.DE 0.4 @ 125.00');
      final bytes = Uint8List.fromList(ex.encode()!);
      final s = AppState(Db.memory(), prices: fakePrices());
      final acc = s.addInvestAccount('XTB');
      tester.view.physicalSize = const Size(360, 3200) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
        value: s,
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Builder(builder: (c) => Scaffold(body: TextButton(onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => ImportTradesScreen(accountId: acc, preloaded: (name: 'Stock.xlsx', bytes: bytes)))), child: const Text('abrir')))),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Validação do ficheiro'), findsOneWidget);
      expect(find.textContaining('Falta o câmbio'), findsNothing); // o câmbio sai do valor pago
      expect(find.text('Importar 3 operações'), findsOneWidget);
      await tester.tap(find.text('Importar 3 operações'));
      await tester.pumpAndSettle();
      final h = {for (final x in s.holdings) x.name: x};
      expect((h['Alpha']!.symbol, h['Alpha']!.currency, h['Alpha']!.kind, h['Alpha']!.provider), ('ALFA', 'USD', HoldingKind.stock, PriceProvider.yahoo));
      expect((h['Gama ETF']!.symbol, h['Gama ETF']!.currency, h['Gama ETF']!.kind), ('GAMA.DE', 'EUR', HoldingKind.etf));
      final alpha = s.portfolio.positions.firstWhere((p) => p.holding.name == 'Alpha');
      expect(alpha.qty, closeTo(1.8671, 1e-9));
      expect(alpha.costCents, 4044 + 3513); // exatamente o que saiu da conta
      expect(alpha.avgCostOrig, closeTo((1 * 45.73 + 0.8671 * 45.81) / 1.8671, 1e-6)); // preço médio em USD
      expect(s.portfolio.positions.firstWhere((p) => p.holding.name == 'Gama ETF').costCents, 5000);
    });
  });
}
