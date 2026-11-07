import 'package:financas/db/database.dart';
import 'package:financas/l10n/app_localizations.dart';
import 'package:financas/models.dart';
import 'package:financas/screens/txn_form_screen.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'support/analysis_data.dart';
import 'support/fonts.dart';

/// Abre o formulário (novo ou a editar) num ecrã de [size] dp com letra a [scale].
Future<void> _pump(
  WidgetTester tester,
  AppState s, {
  Txn? edit,
  Size size = const Size(360, 1400),
  double scale = 1.0,
}) async {
  await tester.pumpWidget(
    const SizedBox(),
  ); // recomeça (pode já haver um formulário aberto)
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: s,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'PT'),
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF2E7D6B),
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

TextField _valor(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField).first);

TextField _descricao(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField).at(1));

bool _selecionado(WidgetTester tester, String rotulo) =>
    tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, rotulo)).selected;

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_PT');
    await loadRoboto();
  });

  testWidgets('o tipo tem cor e o valor mostra o sinal na mesma cor', (
    tester,
  ) async {
    final d = buildAnalysisData();
    await _pump(tester, d.s);
    var f = _valor(tester);
    expect(f.decoration!.prefixText, startsWith('−'));
    expect(f.style!.color, Color(d.s.expenseColor));
    await tester.tap(find.text('Receita'));
    await tester.pumpAndSettle();
    f = _valor(tester);
    expect(f.decoration!.prefixText, startsWith('+'));
    expect(f.style!.color, Color(d.s.incomeColor));
    await tester.tap(find.text('Transferência'));
    await tester.pumpAndSettle();
    f = _valor(tester);
    expect(f.decoration!.prefixText, isNot(contains('−')));
    expect(f.decoration!.prefixText, isNot(contains('+')));
    expect(f.style!.color, const Color(0xFF1E88E5));
    // os rótulos do seletor têm a cor de cada tipo
    expect(
      tester.widget<Text>(find.text('Despesa')).style!.color,
      Color(d.s.expenseColor),
    );
    expect(
      tester.widget<Text>(find.text('Receita')).style!.color,
      Color(d.s.incomeColor),
    );
  });

  testWidgets('o valor aceita contas e mostra o resultado por baixo', (
    tester,
  ) async {
    final d = buildAnalysisData();
    final antes = d.s.transactions.length;
    await _pump(tester, d.s);
    expect(find.byIcon(Icons.calculate_outlined), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '12,50 + 11');
    await tester.pump();
    expect(find.textContaining('= 23,50'), findsOneWidget);
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(d.s.transactions.length, antes + 1);
    expect(d.s.transactions.any((t) => t.amount == -2350), isTrue);
  });

  testWidgets(
    'sugestões ao escrever: tocar preenche descrição, categoria e conta',
    (tester) async {
      final d = buildAnalysisData();
      final cartao = d.s.addAccount('Cartão');
      for (var i = 0; i < 3; i++) {
        d.s.addManual(
          date: DateTime(2026, 5, 2 + i),
          description: 'Pingo Doce',
          amount: -1500,
          categoryId: d.sup,
          accountId: cartao,
        );
      }
      await _pump(tester, d.s);
      expect(d.s.lastUsedAccountId, isNot(cartao));
      await tester.enterText(find.byType(TextField).at(1), 'Pingo');
      await tester.pump();
      expect(
        find.textContaining(
          'Pingo Doce — Alimentação › Supermercado · 3 vezes',
        ),
        findsOneWidget,
      );
      await tester.tap(find.textContaining('Pingo Doce — '));
      await tester.pumpAndSettle();
      expect(_descricao(tester).controller!.text, 'Pingo Doce');
      expect(find.textContaining('Alimentação › Supermercado'), findsOneWidget);
      expect(_selecionado(tester, 'Cartão'), isTrue);
      // a lista fecha depois de escolher
      expect(find.textContaining(' vezes'), findsNothing);
      await tester.enterText(find.byType(TextField).first, '9');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      final t = d.s.transactions.firstWhere(
        (x) => x.description == 'Pingo Doce' && x.amount == -900,
      );
      expect((t.categoryId, t.accountId), (d.sup, cartao));
    },
  );

  testWidgets('as sugestões respeitam o tipo (receita não sugere despesas)', (
    tester,
  ) async {
    final d = buildAnalysisData();
    await _pump(tester, d.s);
    await tester.enterText(find.byType(TextField).at(1), 'NETFLIX');
    await tester.pump();
    expect(find.textContaining('NETFLIX — '), findsOneWidget);
    await tester.tap(find.text('Receita'));
    await tester.pumpAndSettle();
    expect(find.textContaining('NETFLIX — '), findsNothing);
  });

  testWidgets(
    'categoria sugerida pelo nome, com etiqueta; deixa de sugerir após escolha manual',
    (tester) async {
      final d = buildAnalysisData();
      await _pump(tester, d.s);
      expect(find.text('Escolher categoria'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(1), 'CAFE CENTRAL');
      await tester.pump();
      expect(find.text('Escolher categoria'), findsNothing);
      expect(find.textContaining('🎬 Lazer'), findsOneWidget);
      expect(find.text('sugerida pelo nome · toca para mudar'), findsOneWidget);
      // escolher outra à mão tira a etiqueta e a sugestão deixa de mexer
      await tester.tap(find.widgetWithText(ChoiceChip, 'Casa'));
      await tester.pump();
      expect(find.text('sugerida pelo nome · toca para mudar'), findsNothing);
      await tester.enterText(find.byType(TextField).at(1), 'CAFE CENTRAL ');
      await tester.pump();
      await tester.enterText(find.byType(TextField).at(1), 'CAFE CENTRAL');
      await tester.pump();
      expect(find.textContaining('🏠 Casa'), findsOneWidget);
      expect(find.text('sugerida pelo nome · toca para mudar'), findsNothing);
      await tester.enterText(find.byType(TextField).first, '2');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      final t = d.s.transactions.lastWhere(
        (x) => x.description == 'CAFE CENTRAL' && x.amount == -200,
      );
      expect(t.categoryId, d.casa);
    },
  );

  testWidgets('categoria sugerida desaparece se o nome deixa de a reconhecer', (
    tester,
  ) async {
    final d = buildAnalysisData();
    await _pump(tester, d.s);
    await tester.enterText(find.byType(TextField).at(1), 'CAFE CENTRAL');
    await tester.pump();
    expect(find.textContaining('Lazer'), findsWidgets);
    await tester.enterText(find.byType(TextField).at(1), 'CAFE CENT');
    await tester.pump();
    expect(find.text('Escolher categoria'), findsOneWidget);
  });

  testWidgets('chips das categorias mais usadas, por tipo; somem se vazio', (
    tester,
  ) async {
    final d = buildAnalysisData();
    await _pump(tester, d.s);
    expect(find.byKey(const ValueKey('mais-usadas')), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Lazer'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Salário'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Casa'));
    await tester.pump();
    expect(_selecionado(tester, 'Casa'), isTrue);
    await tester.tap(find.text('Receita'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ChoiceChip, 'Salário'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Lazer'), findsNothing);
    await tester.tap(find.text('Transferência'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mais-usadas')), findsNothing);
  });

  testWidgets('sem histórico não há chips de categorias', (tester) async {
    final s = AppState(Db.memory());
    await _pump(tester, s);
    expect(find.byKey(const ValueKey('mais-usadas')), findsNothing);
    // sem contas: "Sem conta"
    expect(find.widgetWithText(ChoiceChip, 'Sem conta'), findsOneWidget);
  });

  testWidgets('conta por omissão é a última usada; muitas contas dão "+ N"', (
    tester,
  ) async {
    final d = buildAnalysisData();
    final ultima = d.s.account(d.s.lastUsedAccountId)!.name;
    await _pump(tester, d.s);
    expect(_selecionado(tester, ultima), isTrue);
    final outra = ultima == 'Ordem' ? 'Poupança' : 'Ordem';
    expect(_selecionado(tester, outra), isFalse);
    // escolher outra com um toque
    await tester.tap(find.widgetWithText(ChoiceChip, outra));
    await tester.pump();
    expect(_selecionado(tester, outra), isTrue);

    for (final n in ['A', 'B', 'C', 'D']) {
      d.s.addAccount(n);
    }
    await _pump(tester, d.s);
    expect(find.byType(ActionChip), findsOneWidget);
    expect(find.textContaining('+ '), findsOneWidget);
    expect(
      _selecionado(tester, ultima),
      isTrue,
    ); // a escolhida nunca fica escondida
  });

  testWidgets('ao editar, a conta é a do movimento', (tester) async {
    final d = buildAnalysisData();
    final t = d.s.transactions.firstWhere((x) => x.description == 'COMPRA X');
    await _pump(tester, d.s, edit: t);
    expect(_selecionado(tester, 'Poupança'), isTrue);
    expect(_selecionado(tester, 'Ordem'), isFalse);
  });

  testWidgets('Guardar e novo: guarda, limpa e mantém tipo, data e conta', (
    tester,
  ) async {
    final d = buildAnalysisData();
    final antes = d.s.transactions.length;
    await _pump(tester, d.s);
    await tester.tap(find.text('Receita'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ontem'));
    await tester.pump();
    final conta = d.s.account(d.s.lastUsedAccountId)!.name;
    await tester.enterText(find.byType(TextField).first, '10');
    await tester.enterText(find.byType(TextField).at(1), 'Prémio');
    await tester.tap(find.text('Guardar e novo'));
    await tester.pumpAndSettle();
    expect(d.s.transactions.length, antes + 1);
    final primeira = d.s.transactions.firstWhere(
      (x) => x.description == 'Prémio',
    );
    expect(primeira.amount, 1000);
    // o formulário continua aberto, vazio, com o mesmo tipo, data e conta
    expect(find.text('Novo movimento'), findsOneWidget);
    expect(find.text('Guardado'), findsOneWidget);
    expect(_valor(tester).controller!.text, '');
    expect(_descricao(tester).controller!.text, '');
    expect(_valor(tester).decoration!.prefixText, startsWith('+'));
    expect(_selecionado(tester, 'Ontem'), isTrue);
    expect(_selecionado(tester, conta), isTrue);
    expect(find.text('Escolher categoria'), findsOneWidget);
    // e guarda o segundo movimento no mesmo dia
    await tester.enterText(find.byType(TextField).first, '20');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(d.s.transactions.length, antes + 2);
    final segunda = d.s.transactions.firstWhere((x) => x.amount == 2000);
    expect(segunda.date, primeira.date);
    expect(segunda.accountId, primeira.accountId);
  });

  testWidgets('Guardar e novo sem valor mostra o erro e não guarda', (
    tester,
  ) async {
    final d = buildAnalysisData();
    final antes = d.s.transactions.length;
    await _pump(tester, d.s);
    await tester.tap(find.text('Guardar e novo'));
    await tester.pumpAndSettle();
    expect(find.text('Indica um montante válido.'), findsOneWidget);
    expect(d.s.transactions.length, antes);
  });

  testWidgets('ao editar há "Corrigir valor" e não "Guardar e novo"', (
    tester,
  ) async {
    final d = buildAnalysisData();
    final t = d.s.transactions.firstWhere((x) => x.description == 'NETFLIX');
    await _pump(tester, d.s, edit: t);
    expect(find.text('Guardar e novo'), findsNothing);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Corrigir valor'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      '15',
    );
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Guardar'),
      ),
    );
    await tester.pumpAndSettle();
    // o valor foi corrigido na base e o formulário acompanha-o
    expect(d.s.transactions.firstWhere((x) => x.id == t.id).amount, -1500);
    expect(_valor(tester).controller!.text, '15,00');
    expect(find.textContaining('Valor original'), findsOneWidget);
  });

  group('movimento importado', () {
    (AppState, Txn) importado() {
      final s = AppState(Db.memory());
      s.importRows('extrato.csv', 'csv', [
        ParsedRow(DateTime(2026, 10, 5), 'PINGO DOCE 123', -1250, 80000),
      ]);
      return (s, s.transactions.single);
    }

    testWidgets('faixa com o ficheiro, a descrição original e o saldo', (
      tester,
    ) async {
      final (s, t) = importado();
      await _pump(tester, s, edit: t);
      final faixa = find.byKey(const ValueKey('faixa-importado'));
      expect(faixa, findsOneWidget);
      expect(
        find.descendant(
          of: faixa,
          matching: find.textContaining('Importado de extrato.csv'),
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('descrição original: PINGO DOCE 123'),
        findsOneWidget,
      );
      expect(find.textContaining('saldo 800'), findsOneWidget);
      expect(find.textContaining('Valor original'), findsNothing);
    });

    testWidgets('valor editado mostra a etiqueta com o valor original', (
      tester,
    ) async {
      final (s, t) = importado();
      expect(s.setAmount(t, -2000), isNull);
      await _pump(tester, s, edit: s.transactions.single);
      expect(find.textContaining('Valor original: -12,50'), findsOneWidget);
      expect(find.textContaining('(editado)'), findsOneWidget);
    });

    testWidgets('movimento manual não tem faixa', (tester) async {
      final d = buildAnalysisData();
      final t = d.s.transactions.firstWhere((x) => x.description == 'NETFLIX');
      await _pump(tester, d.s, edit: t);
      expect(find.byKey(const ValueKey('faixa-importado')), findsNothing);
    });
  });

  group('bloco Avançado', () {
    testWidgets('recolhido por omissão num movimento novo', (tester) async {
      final d = buildAnalysisData();
      await _pump(tester, d.s);
      expect(find.text('Avançado'), findsOneWidget);
      expect(find.text('Recibo'), findsNothing);
      expect(find.text('Nota'), findsNothing);
      await tester.tap(find.text('Avançado'));
      await tester.pumpAndSettle();
      expect(find.text('Recibo'), findsOneWidget);
      expect(find.text('Nota'), findsOneWidget);
      // só ao editar: ligar e objetivos
      expect(find.text('Ligar a outro movimento'), findsNothing);
    });

    testWidgets('abre sozinho ao editar um movimento com nota', (tester) async {
      final d = buildAnalysisData();
      d.s.addManual(
        date: DateTime(2026, 6, 1),
        description: 'Com nota',
        amount: -500,
        categoryId: d.lazer,
        note: 'lembrar de pedir fatura',
      );
      final t = d.s.transactions.firstWhere((x) => x.description == 'Com nota');
      await _pump(tester, d.s, edit: t);
      expect(find.text('Recibo'), findsOneWidget);
      expect(find.text('Ligar a outro movimento'), findsOneWidget);
      // a nota aparece e edita-se
      expect(find.text('lembrar de pedir fatura'), findsWidgets);
      final campo = find.widgetWithText(TextField, 'lembrar de pedir fatura');
      await tester.enterText(campo, 'outra nota');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(
        d.s.transactions.firstWhere((x) => x.id == t.id).note,
        'outra nota',
      );
    });

    testWidgets('abre sozinho se há objetivos associados', (tester) async {
      final d = buildAnalysisData();
      final g = d.s.addGoal(
        name: 'Férias',
        parentCategoryId: d.lazer,
        targetCents: 100000,
      );
      d.s.addManual(
        date: DateTime(2026, 6, 1),
        description: 'Jantar',
        amount: -10000,
        categoryId: d.lazer,
      );
      final t = d.s.transactions.firstWhere((x) => x.description == 'Jantar');
      d.s.linkMovement(t.id, g, 4000);
      await _pump(tester, d.s, edit: t);
      expect(find.text('Objetivos'), findsOneWidget);
      expect(find.textContaining('Por associar'), findsOneWidget);
    });

    testWidgets('movimento sem extras fica recolhido ao editar', (
      tester,
    ) async {
      final d = buildAnalysisData();
      final t = d.s.transactions.firstWhere((x) => x.description == 'NETFLIX');
      await _pump(tester, d.s, edit: t);
      expect(find.text('Recibo'), findsNothing);
      expect(find.text('Avançado'), findsOneWidget);
    });

    testWidgets('receita: "Anula uma despesa" fica à vista, fora do bloco', (
      tester,
    ) async {
      final d = buildAnalysisData();
      await _pump(tester, d.s);
      await tester.tap(find.text('Receita'));
      await tester.pumpAndSettle();
      expect(
        find.text('Anula uma despesa (reembolso, devolução)'),
        findsOneWidget,
      );
      expect(find.text('Recibo'), findsNothing); // o bloco continua recolhido
    });
  });

  group('transferência', () {
    testWidgets('De e Para lado a lado, com botão de trocar', (tester) async {
      final d = buildAnalysisData();
      await _pump(tester, d.s);
      await tester.tap(find.text('Transferência'));
      await tester.pumpAndSettle();
      expect(find.text('De'), findsOneWidget);
      expect(find.text('Para'), findsOneWidget);
      expect(
        find.text('Não conta como despesa nem receita na Análise.'),
        findsOneWidget,
      );
      final de = tester.getTopLeft(find.text('De')).dy;
      final para = tester.getTopLeft(find.text('Para')).dy;
      expect((de - para).abs(), lessThan(20)); // na mesma linha
      // trocar contas e guardar
      final origem = d.s.lastUsedAccountId!;
      final destino = d.s.accounts.firstWhere((c) => c.id != origem);
      await tester.enterText(find.byType(TextField).first, '50');
      await tester.tap(find.text('Seleciona a conta de destino'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(destino.name).last);
      await tester.pumpAndSettle();
      expect(find.text('Seleciona a conta de destino'), findsNothing);
      await tester.tap(find.byTooltip('Trocar as contas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      final saida = d.s.transactions.firstWhere(
        (x) => x.isTransfer && x.amount == -5000,
      );
      expect(saida.accountId, destino.id); // trocou: sai do destino
    });
  });

  testWidgets('a barra de baixo fica por cima do teclado', (tester) async {
    final d = buildAnalysisData();
    await _pump(tester, d.s, size: const Size(360, 700));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getBottomLeft(find.text('Guardar')).dy, lessThan(700 - 300));
    expect(tester.getBottomLeft(find.text('Guardar e novo')).dy,
        lessThan(700 - 300));
  });

  testWidgets('ao editar não aparece a lista de sugestões sem escrever', (
    tester,
  ) async {
    final d = buildAnalysisData();
    final t = d.s.transactions.firstWhere((x) => x.description == 'NETFLIX');
    await _pump(tester, d.s, edit: t);
    expect(find.byKey(const ValueKey('sugestoes-descricao')), findsNothing);
  });

  for (final (nome, size, scale) in [
    ('360 dp', const Size(360, 700), 1.0),
    ('360 dp e letra 130%', const Size(360, 700), 1.3),
  ]) {
    testWidgets('sem overflow ($nome)', (tester) async {
      final d = buildAnalysisData();
      for (final n in ['Cartão com um nome bastante comprido', 'B', 'C']) {
        d.s.addAccount(n);
      }
      d.s.importRows('um-extrato-com-um-nome-muito-comprido-2026.csv', 'csv', [
        ParsedRow(
          DateTime(2026, 10, 5),
          'DESCRIÇÃO ORIGINAL MUITO COMPRIDA',
          -1250,
          80000,
        ),
      ]);
      final imp = d.s.transactions.firstWhere(
        (x) => x.description.startsWith('DESCRIÇÃO'),
      );
      await _pump(tester, d.s, size: size, scale: scale);
      expect(tester.takeException(), isNull);
      // com sugestões à vista
      await tester.enterText(find.byType(TextField).at(1), 'CAFE');
      await tester.pump();
      expect(tester.takeException(), isNull);
      for (final tp in ['Receita', 'Transferência', 'Despesa']) {
        await tester.tap(find.text(tp));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      // bloco Avançado aberto
      await tester.scrollUntilVisible(
        find.text('Avançado'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Avançado'));
      await tester.pump();
      await tester.tap(find.text('Avançado'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // a barra de baixo está sempre visível
      expect(find.text('Guardar'), findsOneWidget);
      expect(tester.getBottomLeft(find.text('Guardar')).dy, lessThan(700));
      // editar um importado (faixa + avançado)
      await _pump(tester, d.s, edit: imp, size: size, scale: scale);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('faixa-importado')), findsOneWidget);
      expect(find.text('Corrigir valor'), findsOneWidget);
    });
  }
}
