import 'package:financas/budget/budget_stats.dart';
import 'package:financas/db/database.dart';
import 'package:financas/l10n/app_localizations.dart';
import 'package:financas/models.dart';
import 'package:financas/screens/budget_screen.dart';
import 'package:financas/state/app_state.dart';
import 'package:financas/util/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'support/fonts.dart';

void main() {
  late AppState s;
  late String key;
  final now = DateTime.now();
  final day = DateTime(now.year, now.month, now.day);

  int cat(String n, int budget, {BudgetType t = BudgetType.limit, bool inv = false}) =>
      s.addCategory(
        Categoria(
          id: 0,
          name: n,
          budgetType: t,
          budgetValue: budget,
          hasBudget: budget > 0,
          isInvestment: inv,
        ),
      );
  void gasto(int c, int cents, {DateTime? when}) => s.addManual(
    date: when ?? day,
    description: 'mov $cents',
    amount: -cents,
    categoryId: c,
  );

  setUpAll(() async {
    await initializeDateFormatting('pt_PT');
    await loadRoboto();
  });
  setUp(() {
    s = AppState(Db.memory());
    s.setAppLanguage('pt');
    s.setDefaultSalary(180000);
    key = s.currentMonthKey;
  });

  test('estado: máximo excedido ou dentro, mínimo atingido ou em falta', () {
    expect(stateOf(BudgetType.limit, 35000, 30000), BudgetState.over);
    expect(stateOf(BudgetType.limit, 30000, 30000), BudgetState.ok);
    expect(stateOf(BudgetType.goal, 15000, 20000), BudgetState.below);
    expect(stateOf(BudgetType.goal, 20000, 20000), BudgetState.ok);
    expect(stateOf(BudgetType.limit, 100, 0), BudgetState.none);
    // mês que ainda não começou: o mínimo não conta como em falta
    expect(stateOf(BudgetType.goal, 0, 20000, started: false), BudgetState.ok);
  });

  test('linhas e resumo do mês: o exemplo do pedido (compras 350/300, investimentos 150/200)', () {
    final compras = cat('Compras', 30000);
    final alim = cat('Alimentação', 30000);
    final inv = cat('Investimentos', 20000, t: BudgetType.goal, inv: true);
    final trans = cat('Transportes', 0);
    gasto(compras, 35000);
    gasto(alim, 25000);
    gasto(inv, 15000);
    gasto(trans, 6000);
    final rows = budgetRows(s, key, 180000);
    CatBudget r(int id) => rows.firstWhere((x) => x.category.id == id);
    expect(r(compras).state, BudgetState.over);
    expect(r(alim).state, BudgetState.ok);
    expect(r(inv).state, BudgetState.below);
    expect(r(trans).state, BudgetState.none);
    final sum = summarize(s, rows);
    expect(sum.over, 1);
    expect(sum.below, 1);
    expect(sum.ok, 1);
    expect(sum.budgeted, 60000); // só os máximos
    expect(sum.spentBudgeted, 60000);
    expect(sum.left, 0);
    expect(sum.unbudgetedSpent, 6000);
  });

  test('sugestão: média dos 3 meses anteriores arredondada aos 5 €; sem histórico usa o mês', () {
    final c = cat('Transportes', 0);
    final y = int.parse(key.substring(0, 4)), m = int.parse(key.substring(5, 7));
    gasto(c, 6000, when: DateTime(y, m - 1, 10));
    gasto(c, 5000, when: DateTime(y, m - 2, 10));
    gasto(c, 5000, when: DateTime(y, m - 3, 10));
    expect(suggestBudget(s, s.cat(c)!, key, 0), 5500); // média 5333 → 55 €
    final novo = cat('Novo', 0);
    expect(suggestBudget(s, s.cat(novo)!, key, 1234), 1500);
    expect(suggestBudget(s, s.cat(novo)!, key, 0), isNull);
    final h = history(s, s.cat(c)!, key);
    expect(h.length, 6);
    expect(h.last.$1, key);
    expect(h[4].$2, 6000);
  });

  test('marca de hoje: fração do mês que já passou, ou nulo fora do mês', () {
    final p = Period(DateTime(2026, 11, 1), DateTime(2026, 12, 1));
    expect(paceOf(p, today: DateTime(2026, 11, 15)), closeTo(15 / 30, 1e-9));
    expect(paceOf(p, today: DateTime(2026, 12, 3)), isNull);
    expect(paceOf(p, today: DateTime(2026, 10, 20)), isNull);
  });

  Widget app() => ChangeNotifierProvider<AppState>.value(
    value: s,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('pt', 'PT'),
      home: const BudgetScreen(),
    ),
  );

  testWidgets('ecrã: grupos por estado, etiquetas e sugestão de orçamento', (tester) async {
    tester.view.physicalSize = const Size(400, 1800) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final compras = cat('Compras', 30000);
    final alim = cat('Alimentação', 30000);
    final trans = cat('Transportes', 0);
    gasto(compras, 35000);
    gasto(alim, 25000);
    gasto(trans, 6000);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Precisa de atenção · 1'), findsOneWidget);
    expect(find.text('Em ordem · 1'), findsOneWidget);
    expect(find.text('Sem orçamento · 1'), findsOneWidget);
    expect(find.text('+${fmtMoney(5000)} acima'), findsOneWidget);
    expect(find.text('restam ${fmtMoney(5000)}'), findsOneWidget);
    expect(find.text('1 excedido'), findsOneWidget);
    // sem histórico, a sugestão é o gasto do mês (60 € → 60 €)
    await tester.tap(find.text('Definir ${fmtMoney(6000)}'));
    await tester.pumpAndSettle();
    expect(s.cat(trans)!.hasBudget, isTrue);
    expect(s.cat(trans)!.budgetValue, 6000);
    expect(find.text('Sem orçamento · 1'), findsNothing);
  });

  testWidgets('tocar numa categoria abre o detalhe com 6 meses e muda máximo/mínimo', (tester) async {
    tester.view.physicalSize = const Size(400, 1800) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final compras = cat('Compras', 30000);
    gasto(compras, 35000);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compras'));
    await tester.pumpAndSettle();
    expect(find.text('Últimos 6 meses'), findsOneWidget);
    expect(find.textContaining('117% do máximo'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Mínimo'));
    await tester.pumpAndSettle();
    expect(s.cat(compras)!.budgetType, BudgetType.goal);
    expect(find.textContaining('117% do mínimo'), findsOneWidget);
  });
}
