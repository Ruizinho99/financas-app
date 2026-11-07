import 'package:financas/db/database.dart';
import 'package:financas/l10n/app_localizations.dart';
import 'package:financas/models.dart';
import 'package:financas/screens/more_screen.dart';
import 'package:financas/state/app_state.dart';
import 'package:financas/util/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget _wrap(AppState s) => ChangeNotifierProvider<AppState>.value(
  value: s,
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('pt', 'PT'),
    home: const CategoriesScreen(),
  ),
);

void main() {
  late AppState s;
  late int a, b;
  setUp(() {
    s = AppState(Db.memory());
    a = s.addCategory(const Categoria(id: 0, name: 'Restaurantes', budgetValue: 20000, hasBudget: true));
    b = s.addCategory(const Categoria(id: 0, name: 'Comer fora', budgetValue: 30000, hasBudget: true));
    s.addManual(date: DateTime(2026, 6, 1), description: 'Jantar', amount: -1500, categoryId: a);
  });

  Future<void> abrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1600) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_wrap(s));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('cat-menu-$a')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unificar com…'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('tree-pick-$b')));
    await tester.pumpAndSettle();
  }

  testWidgets('com dois orçamentos pergunta o que fazer e soma', (tester) async {
    await abrir(tester);
    expect(find.text('Unificar "Restaurantes" em "Comer fora"?'), findsOneWidget);
    expect(find.textContaining('1 movimento passa para "Comer fora"'), findsOneWidget);
    expect(find.text('As duas têm orçamento. O que fica?'), findsOneWidget);
    expect(
      find.text('Somar: ${fmtMoney(20000)} + ${fmtMoney(30000)} = ${fmtMoney(50000)}'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Unificar'));
    await tester.pumpAndSettle();
    expect(s.cat(a), isNull);
    expect(s.cat(b)!.budgetValue, 50000);
    expect(s.transactions.single.categoryId, b);
    expect(find.text('"Restaurantes" unificada em "Comer fora".'), findsOneWidget);
  });

  testWidgets('escolher manter o orçamento do destino', (tester) async {
    await abrir(tester);
    await tester.tap(find.textContaining('Manter o de "Comer fora"'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Unificar'));
    await tester.pumpAndSettle();
    expect(s.cat(b)!.budgetValue, 30000);
  });

  testWidgets('cancelar não muda nada', (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(s.cat(a), isNotNull);
    expect(s.transactions.single.categoryId, a);
  });

  testWidgets('sem conflito de orçamentos não pergunta', (tester) async {
    s.updateCategory(s.cat(b)!.copyWith(hasBudget: false, budgetValue: 0));
    await abrir(tester);
    expect(find.text('As duas têm orçamento. O que fica?'), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Unificar'));
    await tester.pumpAndSettle();
    expect(s.cat(b)!.budgetValue, 20000); // herda o da origem
  });
}
