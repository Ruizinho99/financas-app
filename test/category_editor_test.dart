import 'package:financas/db/database.dart';
import 'package:financas/models.dart';
import 'package:financas/state/app_state.dart';
import 'package:financas/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget _app(AppState s, {Categoria? edit, int? parentId, void Function(int?)? onResult}) => ChangeNotifierProvider<AppState>.value(
      value: s,
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  final r = await showCategoryEditor(context, edit: edit, parentId: parentId);
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
      [(id: null, name: 'Restaurantes', emoji: '🍔'), (id: null, name: 'Supermercado', emoji: '🛒'), (id: null, name: 'Cafés', emoji: '☕')],
    );
    expect(s.cat(id)!.name, 'Alimentação');
    expect(s.childrenOf(id).map((c) => c.name).toList()..sort(), ['Cafés', 'Restaurantes', 'Supermercado']);
    expect(s.childrenOf(id).every((c) => c.parentId == id), isTrue);

    // editar: renomear uma, remover outra, acrescentar nova
    final sup = s.childrenOf(id).firstWhere((c) => c.name == 'Supermercado');
    final cafe = s.childrenOf(id).firstWhere((c) => c.name == 'Cafés');
    s.addManual(date: DateTime(2026, 1, 1), description: 'x', amount: -100, categoryId: cafe.id);
    s.saveCategoryWithSubs(
      s.cat(id)!.copyWith(name: 'Comida'),
      [(id: sup.id, name: 'Mercearia', emoji: '🧺'), (id: null, name: 'Takeaway', emoji: '🥡')],
      removedIds: [cafe.id],
    );
    expect(s.cat(id)!.name, 'Comida');
    expect(s.childrenOf(id).map((c) => c.name).toSet(), {'Restaurantes', 'Mercearia', 'Takeaway'});
    expect(s.cat(sup.id)!.emoji, '🧺');
    expect(s.transactions.first.categoryId, isNull); // apagar a subcategoria deixa os movimentos sem categoria
  });

  test('subcategorias ao lado de uma categoria-mãe existente + rendimento herdado', () {
    final s = AppState(Db.memory());
    final rend = s.saveCategoryWithSubs(const Categoria(id: 0, name: 'Rendimentos', isIncome: true), []);
    s.saveCategoryWithSubs(
      Categoria(id: 0, name: 'Salário', parentId: rend, isIncome: true),
      [(id: null, name: 'Extras', emoji: '')],
      subsAreSiblings: true,
    );
    final kids = s.childrenOf(rend);
    expect(kids.map((c) => c.name).toSet(), {'Salário', 'Extras'});
    expect(kids.every((c) => c.isIncome && c.parentId == rend), isTrue);
  });

  test('nomes duplicados só contam no mesmo nível', () {
    final s = AppState(Db.memory());
    final a = s.saveCategoryWithSubs(const Categoria(id: 0, name: 'Casa'), [(id: null, name: 'Água', emoji: '')]);
    expect(s.categoryNameTaken('  casa ', null), isTrue);
    expect(s.categoryNameTaken('Casa', null, excludeId: a), isFalse); // a própria, ao editar
    expect(s.categoryNameTaken('água', a), isTrue);
    expect(s.categoryNameTaken('Água', null), isFalse); // outro nível
  });

  testWidgets('modal: criar Alimentação com 3 subcategorias e guardar (ecrã pequeno)', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920); // 360×640 dp
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final s = AppState(Db.memory());
    int? result;
    await tester.pumpWidget(_app(s, onResult: (v) => result = v));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Nova categoria'), findsOneWidget);
    expect(find.text('Cria uma categoria e as suas subcategorias'), findsOneWidget);

    // nome vazio -> erro, nada é guardado
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Indica um nome'), findsOneWidget);
    expect(s.categories, isEmpty);

    await tester.enterText(find.widgetWithText(TextField, 'Nome'), '  Alimentação  ');
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
    expect(s.childrenOf(main.id).map((c) => c.name).toList()..sort(), ['Cafés', 'Restaurantes', 'Supermercado']); // linha vazia ignorada
  });

  testWidgets('modal: escolher categoria-mãe mostra que é uma subcategoria', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final s = AppState(Db.memory());
    final alim = s.addCategory(const Categoria(id: 0, name: 'Alimentação', emoji: '🍔'));
    await tester.pumpWidget(_app(s, parentId: alim));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Nova subcategoria'), findsOneWidget);
    expect(find.textContaining('A criar subcategoria de'), findsOneWidget);
    expect(find.text('Mais subcategorias de Alimentação'), findsOneWidget);
  });

  testWidgets('modal: editar mostra as subcategorias existentes e bloqueia a categoria-mãe', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final s = AppState(Db.memory());
    final id = s.saveCategoryWithSubs(const Categoria(id: 0, name: 'Casa'), [(id: null, name: 'Água', emoji: '💧'), (id: null, name: 'Luz', emoji: '💡')]);
    await tester.pumpWidget(_app(s, edit: s.cat(id)));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Editar categoria'), findsOneWidget);
    expect(find.text('Água'), findsOneWidget);
    expect(find.text('Luz'), findsOneWidget);
    expect(find.text('Tem subcategorias, por isso não pode ser uma subcategoria.'), findsOneWidget);
  });
}
