import 'package:financas/analysis/analytics.dart';
import 'package:financas/db/database.dart';
import 'package:financas/models.dart';
import 'package:financas/state/app_state.dart';
import 'package:financas/widgets/category_picker.dart';
import 'package:financas/widgets/common.dart';
import 'package:financas/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget _app(
  AppState s, {
  Categoria? edit,
  int? parentId,
  void Function(int?)? onResult,
}) => ChangeNotifierProvider<AppState>.value(
  value: s,
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('pt', 'PT'),
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              final r = await showCategoryEditor(
                context,
                edit: edit,
                parentId: parentId,
              );
              onResult?.call(r);
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  test('categoria + subcategorias numa única operação', () {
    final s = AppState(Db.memory());
    final id = s.saveCategoryWithSubs(
      const Categoria(id: 0, name: 'Alimentação', emoji: '🥗'),
      [
        (id: null, name: 'Restaurantes', emoji: '🍔'),
        (id: null, name: 'Supermercado', emoji: '🛒'),
        (id: null, name: 'Cafés', emoji: '☕'),
      ],
    );
    expect(s.cat(id)!.name, 'Alimentação');
    expect(s.childrenOf(id).map((c) => c.name).toList()..sort(), [
      'Cafés',
      'Restaurantes',
      'Supermercado',
    ]);
    expect(s.childrenOf(id).every((c) => c.parentId == id), isTrue);

    // editar: renomear uma, remover outra, acrescentar nova
    final sup = s.childrenOf(id).firstWhere((c) => c.name == 'Supermercado');
    final cafe = s.childrenOf(id).firstWhere((c) => c.name == 'Cafés');
    s.addManual(
      date: DateTime(2026, 1, 1),
      description: 'x',
      amount: -100,
      categoryId: cafe.id,
    );
    s.saveCategoryWithSubs(
      s.cat(id)!.copyWith(name: 'Comida'),
      [
        (id: sup.id, name: 'Mercearia', emoji: '🧺'),
        (id: null, name: 'Takeaway', emoji: '🥡'),
      ],
      removedIds: [cafe.id],
    );
    expect(s.cat(id)!.name, 'Comida');
    expect(s.childrenOf(id).map((c) => c.name).toSet(), {
      'Restaurantes',
      'Mercearia',
      'Takeaway',
    });
    expect(s.cat(sup.id)!.emoji, '🧺');
    expect(
      s.transactions.first.categoryId,
      isNull,
    ); // apagar a subcategoria deixa os movimentos sem categoria
  });

  test(
    'subcategorias ao lado de uma categoria-mãe existente + rendimento herdado',
    () {
      final s = AppState(Db.memory());
      final rend = s.saveCategoryWithSubs(
        const Categoria(id: 0, name: 'Rendimentos', isIncome: true),
        [],
      );
      s.saveCategoryWithSubs(
        Categoria(id: 0, name: 'Salário', parentId: rend, isIncome: true),
        [(id: null, name: 'Extras', emoji: '')],
        subsAreSiblings: true,
      );
      final kids = s.childrenOf(rend);
      expect(kids.map((c) => c.name).toSet(), {'Salário', 'Extras'});
      expect(kids.every((c) => c.isIncome && c.parentId == rend), isTrue);
    },
  );

  test('nomes duplicados só contam no mesmo nível', () {
    final s = AppState(Db.memory());
    final a = s.saveCategoryWithSubs(const Categoria(id: 0, name: 'Casa'), [
      (id: null, name: 'Água', emoji: ''),
    ]);
    expect(s.categoryNameTaken('  casa ', null), isTrue);
    expect(
      s.categoryNameTaken('Casa', null, excludeId: a),
      isFalse,
    ); // a própria, ao editar
    expect(s.categoryNameTaken('água', a), isTrue);
    expect(s.categoryNameTaken('Água', null), isFalse); // outro nível
  });

  testWidgets(
    'modal: criar Alimentação com 3 subcategorias e guardar (ecrã pequeno)',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 1920); // 360×640 dp
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final s = AppState(Db.memory());
      int? result;
      await tester.pumpWidget(_app(s, onResult: (v) => result = v));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Nova categoria'), findsOneWidget);
      expect(
        find.text('Cria uma categoria e as suas subcategorias'),
        findsOneWidget,
      );

      // nome vazio -> erro, nada é guardado
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(find.text('Indica um nome'), findsOneWidget);
      expect(s.categories, isEmpty);

      await tester.enterText(
        find.widgetWithText(TextField, 'Nome'),
        '  Alimentação  ',
      );
      // campos: 0 = nome; depois uma linha por subcategoria (1..n); o último é a descrição
      var n = 0;
      for (final sub in ['Restaurantes', 'Supermercado', '']) {
        await tester.ensureVisible(find.text('Adicionar subcategoria'));
        await tester.tap(find.text('Adicionar subcategoria'));
        await tester.pumpAndSettle();
        n++;
        await tester.enterText(find.byType(TextField).at(n), sub);
      }
      // quarta linha com nome repetido (sem distinguir maiúsculas) é rejeitada
      await tester.ensureVisible(find.text('Adicionar subcategoria'));
      await tester.tap(find.text('Adicionar subcategoria'));
      await tester.pumpAndSettle();
      n++;
      await tester.enterText(find.byType(TextField).at(n), 'restaurantes');
      await tester.pump();
      await tester.ensureVisible(find.text('Guardar'));
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(find.text('Nome repetido'), findsOneWidget);
      expect(s.categories, isEmpty);
      await tester.enterText(find.byType(TextField).at(n), 'Cafés');

      // o botão Guardar continua visível/clicável num ecrã pequeno
      expect(tester.getRect(find.text('Guardar')).bottom, lessThan(640));
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      final main = s.cat(result)!;
      expect(main.name, 'Alimentação'); // espaços à volta removidos
      expect(s.childrenOf(main.id).map((c) => c.name).toList()..sort(), [
        'Cafés',
        'Restaurantes',
        'Supermercado',
      ]); // linha vazia ignorada
    },
  );

  testWidgets('modal: escolher categoria-mãe mostra que é uma subcategoria', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final s = AppState(Db.memory());
    final alim = s.addCategory(
      const Categoria(id: 0, name: 'Alimentação', emoji: '🍔'),
    );
    await tester.pumpWidget(_app(s, parentId: alim));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Nova subcategoria'), findsOneWidget);
    expect(find.textContaining('A criar subcategoria de'), findsOneWidget);
    expect(find.text('Mais subcategorias de Alimentação'), findsOneWidget);
  });

  testWidgets(
    'modal: editar mostra as subcategorias existentes e bloqueia a categoria-mãe',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final s = AppState(Db.memory());
      final id = s.saveCategoryWithSubs(const Categoria(id: 0, name: 'Casa'), [
        (id: null, name: 'Água', emoji: '💧'),
        (id: null, name: 'Luz', emoji: '💡'),
      ]);
      await tester.pumpWidget(_app(s, edit: s.cat(id)));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Editar categoria'), findsOneWidget);
      expect(find.text('Água'), findsOneWidget);
      expect(find.text('Luz'), findsOneWidget);
      expect(
        find.text('Tem subcategorias, por isso não pode ser uma subcategoria.'),
        findsOneWidget,
      );
    },
  );

  group('tipo da categoria (opcional, obrigatória, investimento)', () {
    Future<void> create(
      WidgetTester tester,
      AppState s,
      String name,
      String kindLabel,
    ) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(s));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Nome'), name);
      if (kindLabel != 'Despesa opcional') {
        await tester.ensureVisible(find.text('Despesa opcional'));
        await tester.tap(find.text('Despesa opcional'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(kindLabel).last);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
    }

    testWidgets('por omissão é despesa opcional', (tester) async {
      final s = AppState(Db.memory());
      await create(tester, s, 'Lazer', 'Despesa opcional');
      final c = s.categories.single;
      expect(
        (c.isIncome, c.isInvestment, s.rangesOf(c.id).isEmpty),
        (false, false, true),
      );
    });

    testWidgets('despesa obrigatória cria o período e conta como obrigatória', (
      tester,
    ) async {
      final s = AppState(Db.memory());
      await create(tester, s, 'Renda', 'Despesa obrigatória');
      final c = s.categories.single;
      expect(s.isMandatory(c, '2026-03'), isTrue);
      expect(s.isMandatory(c, '2031-12'), isTrue);
    });

    testWidgets('investimento fica marcado e as subcategorias herdam', (
      tester,
    ) async {
      final s = AppState(Db.memory());
      await create(tester, s, 'ETFs', 'Investimento');
      final c = s.categories.single;
      expect(
        (c.isInvestment, c.isIncome, c.budgetType),
        (true, false, BudgetType.goal),
      );
      final id = s.saveCategoryWithSubs(c, [
        (id: null, name: 'Mundo', emoji: ''),
      ]);
      expect(s.childrenOf(id).single.isInvestment, isTrue);
    });

    testWidgets(
      'o tipo já não oferece "Rendimento" nem "Despesas e receitas": todas as categorias servem para os dois',
      (tester) async {
        tester.view.physicalSize = const Size(900, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        final s = AppState(Db.memory());
        await tester.pumpWidget(_app(s));
        await tester.tap(find.text('abrir'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Despesa opcional'));
        await tester.tap(find.text('Despesa opcional'));
        await tester.pumpAndSettle();
        expect(find.text('Despesa obrigatória'), findsWidgets);
        expect(find.text('Investimento'), findsWidgets);
        expect(find.text('Rendimento'), findsNothing);
        expect(find.text('Despesas e receitas'), findsNothing);
      },
    );

    test('mudar de obrigatória para opcional apaga os períodos', () {
      final s = AppState(Db.memory());
      final id = s.addCategory(const Categoria(id: 0, name: 'Renda'));
      s.addRange(id, '2026-01', null);
      expect(s.isMandatory(s.cat(id)!, '2026-05'), isTrue);
      for (final r in s.rangesOf(id)) {
        s.removeRange(r.id);
      }
      expect(s.isMandatory(s.cat(id)!, '2026-05'), isFalse);
    });

    test('despesas em categorias de investimento não contam como gasto e contam como investido', () {
      final s = AppState(Db.memory());
      final lazer = s.addCategory(const Categoria(id: 0, name: 'Lazer'));
      final etf = s.addCategory(
        const Categoria(id: 0, name: 'ETFs', isInvestment: true),
      );
      s.addManual(
        date: DateTime(2026, 6, 5),
        description: 'cinema',
        amount: -2000,
        categoryId: lazer,
      );
      s.addManual(
        date: DateTime(2026, 6, 6),
        description: 'compra etf',
        amount: -30000,
        categoryId: etf,
      );
      final a = Analytics(
        s,
        Period.month(DateTime(2026, 6)),
        const AnalysisFilter(),
      );
      expect(a.spent, 2000);
      expect(a.invested, 30000);
      expect(a.byCategory().map((e) => e.label), ['Lazer']);
    });
  });

  group('categorias partilhadas entre despesas e receitas', () {
    test('numa categoria qualquer, a saída é despesa e a entrada é receita, sem se anularem', () {
      final s = AppState(Db.memory());
      final olx = s.addCategory(const Categoria(id: 0, name: 'OLX'));
      s.addManual(
        date: DateTime(2026, 6, 5),
        description: 'compra',
        amount: -4000,
        categoryId: olx,
      );
      s.addManual(
        date: DateTime(2026, 6, 9),
        description: 'venda',
        amount: 15000,
        categoryId: olx,
      );
      final a = Analytics(
        s,
        Period.month(DateTime(2026, 6)),
        const AnalysisFilter(),
      );
      expect(a.spent, 4000);
      expect(a.incomeReceived, 15000);
      // no orçamento, a entrada também não abate ao gasto da categoria
      final own = s.totalsByCategory(Period.month(DateTime(2026, 6)));
      expect(own[olx], 4000);
    });

    testWidgets(
      'todas as categorias aparecem na escolha, tanto em despesa como em receita',
      (tester) async {
        final s = AppState(Db.memory());
        s.addCategory(const Categoria(id: 0, name: 'OLX'));
        s.addCategory(const Categoria(id: 0, name: 'Salário', isIncome: true));
        s.addCategory(const Categoria(id: 0, name: 'Lazer'));
        await tester.pumpWidget(
          ChangeNotifierProvider<AppState>.value(
            value: s,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('pt', 'PT'),
              home: Scaffold(
                body: Builder(
                  builder: (c) => TextButton(
                    onPressed: () => chooseCategory(c, income: false),
                    child: const Text('d'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('d'));
        await tester.pumpAndSettle();
        expect(find.widgetWithText(ChoiceChip, 'OLX'), findsOneWidget);
        expect(find.widgetWithText(ChoiceChip, 'Lazer'), findsOneWidget);
        // as categorias antigas só de receita também servem para despesas
        expect(find.widgetWithText(ChoiceChip, 'Salário'), findsOneWidget);
        Navigator.of(tester.element(find.byType(Scaffold).first)).pop();
      },
    );
  });
}
