import 'package:financas/analysis/analytics.dart';
import 'package:financas/analysis/filter_sheet.dart';
import 'package:financas/db/database.dart';
import 'package:financas/l10n/app_localizations.dart';
import 'package:financas/models.dart';
import 'package:financas/state/app_state.dart';
import 'package:financas/widgets/category_picker.dart';
import 'package:financas/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/fonts.dart';

/// Seletores e filtros com categorias em árvore de 4 níveis: A > B > C > D.
void main() {
  setUpAll(() async {
    await loadRoboto();
  });

  late AppState s;
  late int a, b, c, d, outra;

  int cat(String n, {int? parent}) =>
      s.addCategory(Categoria(id: 0, name: n, parentId: parent));

  setUp(() {
    s = AppState(Db.memory());
    a = cat('A');
    b = cat('B', parent: a);
    c = cat('C', parent: b);
    d = cat('D', parent: c);
    outra = cat('Outra');
  });

  Widget app(Widget home) => ChangeNotifierProvider<AppState>.value(
    value: s,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('pt', 'PT'),
      home: Scaffold(body: home),
    ),
  );

  Widget abrir(
    void Function(int?) onRes, {
    int? selected,
    bool allowNew = true,
    int? suggestedId,
    List<int>? mostUsed,
    bool? income,
    DateTimeRange? when,
  }) => app(
    Builder(
      builder: (ctx) => TextButton(
        onPressed: () async => onRes(
          await chooseCategory(
            ctx,
            selected: selected,
            allowNew: allowNew,
            suggestedId: suggestedId,
            mostUsed: mostUsed,
            income: income,
            when: when,
          ),
        ),
        child: const Text('abrir'),
      ),
    ),
  );

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  Future<void> tapScrolled(WidgetTester tester, Finder f) async {
    await tester.scrollUntilVisible(
      f,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets('picker: abre com a lista; tocar na linha escolhe, na seta entra', (
    tester,
  ) async {
    int? res;
    await tester.pumpWidget(abrir((v) => res = v));
    await open(tester);
    expect(find.byKey(ValueKey('cat-pick-$a')), findsOneWidget);
    expect(find.byKey(ValueKey('cat-pick-$outra')), findsOneWidget);
    // sem histórico nem sugestão: não há essas secções
    expect(find.text('Mais usadas'), findsNothing);
    expect(find.text('Sugerida pelo nome'), findsNothing);
    // só A tem filhas: seta e contagem; Outra não
    expect(find.byKey(ValueKey('cat-open-$a')), findsOneWidget);
    expect(find.byKey(ValueKey('cat-open-$outra')), findsNothing);
    await tester.tap(find.byKey(ValueKey('cat-open-$a')));
    await tester.pumpAndSettle();
    expect(find.text('Só A — escolher esta categoria'), findsOneWidget);
    expect(find.text('Pesquisar em A'), findsOneWidget);
    expect(find.text('Nova subcategoria em A'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('cat-open-$b')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('cat-open-$c')));
    await tester.pumpAndSettle();
    // D é folha: tocar na linha escolhe
    expect(find.byKey(ValueKey('cat-open-$d')), findsNothing);
    await tester.tap(find.byKey(ValueKey('cat-pick-$d')));
    await tester.pumpAndSettle();
    expect(res, d);
  });

  testWidgets('picker: tocar na linha de uma categoria com filhas escolhe-a', (
    tester,
  ) async {
    int? res;
    await tester.pumpWidget(abrir((v) => res = v));
    await open(tester);
    await tester.tap(find.byKey(ValueKey('cat-pick-$a')));
    await tester.pumpAndSettle();
    expect(res, a);
  });

  testWidgets('picker: migalhas voltam, "Só B" escolhe B', (tester) async {
    int? res;
    await tester.pumpWidget(abrir((v) => res = v, selected: d));
    await open(tester);
    // abre já no nível da seleção (filhas de C), com D marcado
    expect(find.byKey(ValueKey('cat-pick-$d')), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('crumb-$a')));
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('cat-open-$b')), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('cat-open-$b')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cat-self')));
    await tester.pumpAndSettle();
    expect(res, b);
  });

  testWidgets('picker: a migalha "Todas" volta ao início', (tester) async {
    await tester.pumpWidget(abrir((_) {}, selected: d));
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('crumb-root')));
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('cat-pick-$outra')), findsOneWidget);
    expect(find.byKey(const ValueKey('cat-self')), findsNothing);
    expect(find.text('Procurar categoria'), findsOneWidget);
  });

  testWidgets('picker: a pesquisa mostra caminho completo e realce, sem acentos', (
    tester,
  ) async {
    final ed = s.addCategory(
      Categoria(id: 0, name: 'Eletrodomésticos', parentId: b),
    );
    int? res;
    await tester.pumpWidget(abrir((v) => res = v));
    await open(tester);
    await tester.enterText(find.byType(TextField), 'ELETRODOM');
    await tester.pumpAndSettle();
    expect(find.text('1 resultado, em todos os níveis'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(ValueKey('cat-path-$ed'))).data,
      'A › B',
    );
    // o troço que coincide está realçado num TextSpan próprio
    final rich = tester.widget<Text>(
      find.descendant(
        of: find.byKey(ValueKey('cat-pick-$ed')),
        matching: find.byWidgetPredicate(
          (w) => w is Text && w.textSpan != null,
        ),
      ),
    );
    final spans = (rich.textSpan! as TextSpan).children!.cast<TextSpan>();
    expect(spans[1].text, 'Eletrodom');
    await tester.enterText(find.byType(TextField), 'd');
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(ValueKey('cat-path-$d'))).data,
      'A › B › C',
    );
    await tester.tap(find.byKey(ValueKey('cat-pick-$d')));
    await tester.pumpAndSettle();
    expect(res, d);
  });

  testWidgets('picker: sem resultados oferece criar o texto escrito', (
    tester,
  ) async {
    int? res;
    await tester.pumpWidget(abrir((v) => res = v));
    await open(tester);
    await tester.enterText(find.byType(TextField).first, 'Viagens');
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma categoria encontrada.'), findsOneWidget);
    await tester.tap(find.text('Criar "Viagens"…'));
    await tester.pumpAndSettle();
    // o editor abre com o nome preenchido
    expect(find.widgetWithText(TextField, 'Viagens'), findsNWidgets(2)); // pesquisa + editor
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    final nova = s.categories.firstWhere((x) => x.name == 'Viagens');
    expect(res, nova.id);
  });

  testWidgets('picker: sugerida e mais usadas só aparecem com dados', (
    tester,
  ) async {
    int? res;
    final hoje = DateTime.now();
    for (var i = 0; i < 3; i++) {
      s.addManual(date: hoje, description: 'x$i', amount: -100, categoryId: d);
    }
    s.addManual(date: hoje, description: 'y', amount: -100, categoryId: outra);
    await tester.pumpWidget(abrir((v) => res = v, suggestedId: outra));
    await open(tester);
    expect(find.text('Sugerida pelo nome'), findsOneWidget);
    expect(find.text('Mais usadas'), findsOneWidget);
    expect(find.byKey(ValueKey('cat-sug-$outra')), findsOneWidget);
    // a sugerida não se repete nas mais usadas
    expect(find.byKey(ValueKey('cat-top-$outra')), findsNothing);
    expect(find.byKey(ValueKey('cat-top-$d')), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('cat-top-$d')));
    await tester.pumpAndSettle();
    expect(res, d);
  });

  testWidgets('picker: mais usadas distingue entradas de saídas', (tester) async {
    final hoje = DateTime.now();
    s.addManual(date: hoje, description: 'x', amount: -100, categoryId: d);
    s.addManual(date: hoje, description: 'y', amount: 500, categoryId: outra);
    await tester.pumpWidget(abrir((_) {}, income: true));
    await open(tester);
    expect(find.byKey(ValueKey('cat-top-$outra')), findsOneWidget);
    expect(find.byKey(ValueKey('cat-top-$d')), findsNothing);
  });

  testWidgets('picker: categorias terminadas ficam escondidas até "mostrar"', (
    tester,
  ) async {
    final velha = s.addCategory(
      const Categoria(
        id: 0,
        name: 'Velha',
        activeFrom: '2020-01',
        activeTo: '2020-12',
      ),
    );
    await tester.pumpWidget(abrir((_) {}));
    await open(tester);
    expect(find.byKey(ValueKey('cat-pick-$velha')), findsNothing);
    await tapScrolled(tester, find.text('👁  Mostrar terminadas e futuras'));
    expect(find.byKey(ValueKey('cat-pick-$velha')), findsOneWidget);
  });

  testWidgets('picker: "Sem categoria" só com seleção; allowNew=false esconde criar', (
    tester,
  ) async {
    int? res;
    await tester.pumpWidget(
      abrir((v) => res = v, selected: outra, allowNew: false),
    );
    await open(tester);
    expect(find.text('Nova categoria'), findsNothing);
    await tapScrolled(tester, find.text('Sem categoria'));
    expect(res, -1);
  });

  testWidgets('seletor: mostra o caminho completo e abre a escolha ao tocar', (
    tester,
  ) async {
    int? value = d;
    await tester.pumpWidget(
      app(
        StatefulBuilder(
          builder: (ctx, set) => CategorySelector(
            value: value,
            onChanged: (v) => set(() => value = v),
          ),
        ),
      ),
    );
    expect(find.text('A › B › C › D'), findsOneWidget);
    expect(find.byType(CatBadge), findsOneWidget);
    await tester.tap(find.text('A › B › C › D'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('crumb-root')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('cat-pick-$outra')));
    await tester.pumpAndSettle();
    expect(value, outra);
    expect(find.text('Outra'), findsOneWidget);
    // "Sem categoria" limpa
    await tester.tap(find.text('Outra'));
    await tester.pumpAndSettle();
    await tapScrolled(tester, find.text('Sem categoria'));
    expect(value, isNull);
  });

  testWidgets('filtro: escolher B marca C e D (bloqueadas) e devolve só B', (
    tester,
  ) async {
    AnalysisFilter? res;
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      app(
        Builder(
          builder: (ctx) => TextButton(
            onPressed: () async =>
                res = await showAnalysisFilterSheet(ctx, const AnalysisFilter()),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    // expande A e B
    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('B'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('tree-check-$b')));
    await tester.pumpAndSettle();
    bool? val(int id) =>
        tester.widget<Checkbox>(find.byKey(ValueKey('tree-check-$id'))).value;
    expect(val(b), isTrue);
    expect(val(a), isNull); // meio marcada
    await tester.tap(find.text('C'));
    await tester.pumpAndSettle();
    expect(val(c), isTrue);
    expect(val(d), isTrue);
    await tester.tap(find.text('Aplicar filtros'));
    await tester.pumpAndSettle();
    expect(res!.categoryIds, {b});
  });

  test('filtro: uma categoria escolhida inclui o que tem dentro, a qualquer nível', () {
    final dia = DateTime(2026, 6, 10);
    for (final (id, cents) in [(d, 1000), (c, 500), (b, 200), (a, 100), (outra, 700)]) {
      s.addManual(
        date: dia,
        description: 'mov $id',
        amount: -cents,
        categoryId: id,
      );
    }
    final p = Period.month(DateTime(2026, 6));
    expect(Analytics(s, p, AnalysisFilter(categoryIds: {c})).spent, 1500);
    expect(Analytics(s, p, AnalysisFilter(categoryIds: {a})).spent, 1800);
    expect(Analytics(s, p, AnalysisFilter(categoryIds: {d, outra})).spent, 1700);
  });
}
