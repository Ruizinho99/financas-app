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

  testWidgets('picker: navega em profundidade e escolhe uma sub-sub-categoria', (
    tester,
  ) async {
    int? res;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (ctx) => TextButton(
            onPressed: () async => res = await chooseCategory(ctx),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ChoiceChip, 'A ›'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Outra'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'A ›'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'B ›'));
    await tester.pumpAndSettle();
    // caminho clicável: Principais › A › B, e "Só B" para escolher o próprio B
    expect(find.byKey(ValueKey('crumb-$a')), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Só B'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'C ›'));
    await tester.pumpAndSettle();
    // no último nível, D é folha: escolhe-se de imediato
    await tester.tap(find.widgetWithText(ChoiceChip, 'D'));
    await tester.pumpAndSettle();
    expect(res, d);
  });

  testWidgets('picker: o caminho do topo volta a um nível anterior e "Só A" escolhe A', (
    tester,
  ) async {
    int? res;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (ctx) => TextButton(
            onPressed: () async => res = await chooseCategory(ctx, selected: d),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    // abre já no nível da seleção (filhas de C), com D marcado
    expect(find.widgetWithText(ChoiceChip, 'D'), findsOneWidget);
    expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'D')).selected, isTrue);
    await tester.tap(find.byKey(ValueKey('crumb-$a')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ChoiceChip, 'B ›'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cat-back')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ChoiceChip, 'A ›'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'A ›'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Só A'));
    await tester.pumpAndSettle();
    expect(res, a);
  });

  testWidgets('picker: a pesquisa procura em todos os níveis e mostra o caminho', (
    tester,
  ) async {
    int? res;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (ctx) => TextButton(
            onPressed: () async => res = await chooseCategory(ctx),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'd');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ChoiceChip, 'A › B › C › D'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'A › B › C › D'));
    await tester.pumpAndSettle();
    expect(res, d);
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
    await tester.tap(find.text('A › B › C › D'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('crumb-root')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Outra'));
    await tester.pumpAndSettle();
    expect(value, outra);
    expect(find.text('Outra'), findsOneWidget);
    // "Sem categoria" limpa
    await tester.tap(find.text('Outra'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sem categoria'));
    await tester.pumpAndSettle();
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
    await tester.tap(find.text('🏷️  A'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🏷️  B'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('tree-check-$b')));
    await tester.pumpAndSettle();
    bool? val(int id) =>
        tester.widget<Checkbox>(find.byKey(ValueKey('tree-check-$id'))).value;
    expect(val(b), isTrue);
    expect(val(a), isNull); // meio marcada
    await tester.tap(find.text('🏷️  C'));
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
