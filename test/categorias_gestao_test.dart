import 'package:financas/db/database.dart';
import 'package:financas/l10n/app_localizations.dart';
import 'package:financas/models.dart';
import 'package:financas/screens/more_screen.dart';
import 'package:financas/state/app_state.dart';
import 'package:financas/widgets/category_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Árvore de 4 níveis: Casa > Cozinha > Eletrodomésticos > Frigorífico, mais "Lazer" à parte.
class _Tree {
  final AppState s;
  late final int casa, cozinha, eletro, frigo, lazer;
  _Tree(this.s) {
    casa = s.addCategory(const Categoria(id: 0, name: 'Casa'));
    cozinha = s.addCategory(Categoria(id: 0, name: 'Cozinha', parentId: casa));
    eletro = s.addCategory(
      Categoria(id: 0, name: 'Eletrodomésticos', parentId: cozinha),
    );
    frigo = s.addCategory(Categoria(id: 0, name: 'Frigorífico', parentId: eletro));
    lazer = s.addCategory(const Categoria(id: 0, name: 'Lazer'));
  }
}

Widget _wrap(AppState s, Widget home) => ChangeNotifierProvider<AppState>.value(
  value: s,
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('pt', 'PT'),
    home: home,
  ),
);

Widget _editorApp(AppState s, {Categoria? edit, int? parentId, void Function(int?)? onResult}) =>
    _wrap(
      s,
      Builder(
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
    );

void _bigScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

void main() {
  test('mover: erros e efeito na árvore de 4 níveis', () {
    final s = AppState(Db.memory());
    final t = _Tree(s);
    expect(s.depthOf(s.cat(t.frigo)!), 3);
    expect(s.canMoveCategory(t.casa, t.frigo), MoveError.intoDescendant);
    expect(s.canMoveCategory(t.cozinha, t.cozinha), MoveError.self);
    s.addCategory(Categoria(id: 0, name: 'Cozinha', parentId: t.lazer));
    expect(s.canMoveCategory(t.cozinha, t.lazer), MoveError.nameTaken);
    expect(s.canMoveCategory(t.eletro, t.lazer), isNull);
    expect(s.moveCategory(t.eletro, t.lazer), isNull);
    // a subárvore vai toda
    expect(s.depthOf(s.cat(t.frigo)!), 2);
    expect(s.rootOf(s.cat(t.frigo)!).id, t.lazer);
  });

  group('editor', () {
    testWidgets('cria uma sub-sub-sub-categoria (nível 4) a partir do nível 3', (
      tester,
    ) async {
      _bigScreen(tester);
      final s = AppState(Db.memory());
      final t = _Tree(s);
      int? result;
      await tester.pumpWidget(
        _editorApp(s, parentId: t.eletro, onResult: (v) => result = v),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Nova subcategoria'), findsOneWidget);
      // o caminho completo aparece no campo "Dentro de"
      expect(
        find.textContaining('Casa › Cozinha › Eletrodomésticos'),
        findsWidgets,
      );
      await tester.enterText(find.widgetWithText(TextField, 'Nome da subcategoria'), 'Máquina de lavar');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      final novo = s.cat(result)!;
      expect(novo.parentId, t.eletro);
      expect(s.depthOf(novo), 3);
      expect(s.path(novo.id), 'Casa › Cozinha › Eletrodomésticos › Máquina de lavar');

      // e uma quinta camada por baixo da que acabou de ser criada
      int? r2;
      await tester.pumpWidget(
        _editorApp(s, parentId: t.frigo, onResult: (v) => r2 = v),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Nome da subcategoria'), 'Gaveta');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(s.depthOf(s.cat(r2)!), 4);
    });

    testWidgets('editar uma categoria de nível 3 mostra as suas filhas e deixa acrescentar', (
      tester,
    ) async {
      _bigScreen(tester);
      final s = AppState(Db.memory());
      final t = _Tree(s);
      await tester.pumpWidget(_editorApp(s, edit: s.cat(t.eletro)));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Frigorífico'), findsOneWidget); // filha existente, editável
      await tester.ensureVisible(find.text('Adicionar subcategoria'));
      await tester.tap(find.text('Adicionar subcategoria'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(2), 'Micro-ondas');
      await tester.ensureVisible(find.text('Guardar'));
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      // a nova fica DENTRO da categoria editada (não ao lado)
      expect(s.childrenOf(t.eletro).map((c) => c.name).toSet(), {
        'Frigorífico',
        'Micro-ondas',
      });
    });

    testWidgets('mover pelo editor: o seletor esconde a própria e as descendentes e pede confirmação', (
      tester,
    ) async {
      _bigScreen(tester);
      final s = AppState(Db.memory());
      final t = _Tree(s);
      await tester.pumpWidget(_editorApp(s, edit: s.cat(t.cozinha)));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('parent-field')));
      await tester.pumpAndSettle();
      // não se pode escolher a própria nem nada do que tem dentro (evita ciclos)
      expect(find.byKey(ValueKey('tree-pick-${t.cozinha}')), findsNothing);
      expect(find.byKey(ValueKey('tree-pick-${t.eletro}')), findsNothing);
      expect(find.byKey(ValueKey('tree-pick-${t.frigo}')), findsNothing);
      expect(find.byKey(ValueKey('tree-pick-${t.casa}')), findsOneWidget);
      expect(find.byKey(const ValueKey('tree-pick-none')), findsOneWidget);
      await tester.tap(find.byKey(ValueKey('tree-pick-${t.lazer}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      // confirmação com o efeito
      expect(
        find.textContaining('“Cozinha” e as suas 2 subcategorias passam para dentro de “Lazer”'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Mover'));
      await tester.pumpAndSettle();
      expect(s.cat(t.cozinha)!.parentId, t.lazer);
      expect(s.rootOf(s.cat(t.frigo)!).id, t.lazer);
    });

    testWidgets('mover pelo editor para "Nenhuma (principal)"', (tester) async {
      _bigScreen(tester);
      final s = AppState(Db.memory());
      final t = _Tree(s);
      await tester.pumpWidget(_editorApp(s, edit: s.cat(t.eletro)));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('parent-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tree-pick-none')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Mover'));
      await tester.pumpAndSettle();
      expect(s.cat(t.eletro)!.parentId, isNull);
      expect(s.depthOf(s.cat(t.frigo)!), 1);
    });

    testWidgets('mover pelo editor para onde já existe o mesmo nome dá erro claro', (
      tester,
    ) async {
      _bigScreen(tester);
      final s = AppState(Db.memory());
      final t = _Tree(s);
      s.addCategory(Categoria(id: 0, name: 'Cozinha', parentId: t.lazer));
      await tester.pumpWidget(_editorApp(s, edit: s.cat(t.cozinha)));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('parent-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('tree-pick-${t.lazer}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Já existe esta subcategoria'), findsOneWidget);
      expect(s.cat(t.cozinha)!.parentId, t.casa); // nada mudou
    });
  });

  group('ecrã Categorias', () {
    testWidgets('mostra os 4 níveis, com contagem de filhas, e recolhe/expande ramos', (
      tester,
    ) async {
      _bigScreen(tester);
      final s = AppState(Db.memory());
      final t = _Tree(s);
      await tester.pumpWidget(_wrap(s, const CategoriesScreen()));
      await tester.pumpAndSettle();
      for (final n in ['Casa', 'Cozinha', 'Eletrodomésticos', 'Frigorífico', 'Lazer']) {
        expect(find.text(n), findsOneWidget);
      }
      // indentação cresce com o nível
      double x(String n) => tester.getTopLeft(find.text(n)).dx;
      expect(x('Cozinha'), greaterThan(x('Casa')));
      expect(x('Eletrodomésticos'), greaterThan(x('Cozinha')));
      expect(x('Frigorífico'), greaterThan(x('Eletrodomésticos')));
      expect(find.textContaining('1 subcategoria'), findsWidgets);

      await tester.tap(find.byKey(ValueKey('cat-toggle-${t.cozinha}')));
      await tester.pumpAndSettle();
      expect(find.text('Eletrodomésticos'), findsNothing);
      expect(find.text('Frigorífico'), findsNothing);
      expect(find.text('Cozinha'), findsOneWidget);
      await tester.tap(find.byKey(ValueKey('cat-toggle-${t.cozinha}')));
      await tester.pumpAndSettle();
      expect(find.text('Frigorífico'), findsOneWidget);
    });

    testWidgets('menu "Nova subcategoria" numa categoria de nível 4 cria uma filha dela', (
      tester,
    ) async {
      _bigScreen(tester);
      final s = AppState(Db.memory());
      final t = _Tree(s);
      await tester.pumpWidget(_wrap(s, const CategoriesScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('cat-menu-${t.frigo}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nova subcategoria'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Nome da subcategoria'), 'Congelador');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      final k = s.childrenOf(t.frigo).single;
      expect(k.name, 'Congelador');
      expect(s.depthOf(k), 4);
      expect(find.text('Congelador'), findsOneWidget);
    });

    testWidgets('menu "Mover para…" move o ramo todo depois de confirmar', (
      tester,
    ) async {
      _bigScreen(tester);
      final s = AppState(Db.memory());
      final t = _Tree(s);
      await tester.pumpWidget(_wrap(s, const CategoriesScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('cat-menu-${t.eletro}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mover para…'));
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('tree-pick-${t.eletro}')), findsNothing);
      expect(find.byKey(ValueKey('tree-pick-${t.frigo}')), findsNothing);
      await tester.tap(find.byKey(ValueKey('tree-pick-${t.lazer}')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('“Eletrodomésticos” e a sua subcategoria passam para dentro de “Lazer”'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Mover'));
      await tester.pumpAndSettle();
      expect(s.cat(t.eletro)!.parentId, t.lazer);
      expect(s.path(t.frigo), 'Lazer › Eletrodomésticos › Frigorífico');
    });

    testWidgets('menu "Mover para…" com nome repetido no destino mostra o erro e não move', (
      tester,
    ) async {
      _bigScreen(tester);
      final s = AppState(Db.memory());
      final t = _Tree(s);
      s.addCategory(Categoria(id: 0, name: 'Cozinha', parentId: t.lazer));
      await tester.pumpWidget(_wrap(s, const CategoriesScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('cat-menu-${t.cozinha}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mover para…'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('tree-pick-${t.lazer}')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Já existe “Cozinha” em “Lazer”'), findsOneWidget);
      expect(s.cat(t.cozinha)!.parentId, t.casa);
    });

    testWidgets('apagar um ramo avisa quantas subcategorias e movimentos e leva tudo', (
      tester,
    ) async {
      _bigScreen(tester);
      final s = AppState(Db.memory());
      final t = _Tree(s);
      for (final c in [t.cozinha, t.frigo, t.frigo]) {
        s.addManual(
          date: DateTime(2026, 5, 2),
          description: 'x$c',
          amount: -1000,
          categoryId: c,
        );
      }
      await tester.pumpWidget(_wrap(s, const CategoriesScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('cat-menu-${t.cozinha}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apagar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Apaga também as 2 subcategorias'), findsOneWidget);
      expect(find.textContaining('Os 3 movimentos ficam sem categoria'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Apagar'));
      await tester.pumpAndSettle();
      expect(s.cat(t.cozinha), isNull);
      expect(s.cat(t.eletro), isNull);
      expect(s.cat(t.frigo), isNull);
      expect(s.cat(t.casa), isNotNull);
      expect(s.transactions.every((x) => x.categoryId == null), isTrue);
    });
  });
}
