import 'package:financas/analysis/analytics.dart';
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

/// Movimentos sem categoria caem em "Por classificar": contam como movimento (saída = despesa,
/// entrada = receita) e aparecem igual na Análise, no Mês e no Orçamento.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_PT');
    await loadRoboto();
  });

  late AppState s;
  final jun = DateTime(2026, 6, 10);
  final period = Period.month(DateTime(2026, 6));
  Analytics an() => Analytics(s, period, const AnalysisFilter());

  setUp(() {
    setFormatLocale('pt');
    s = AppState(Db.memory());
  });

  void mov(int cents, int? cat, {bool transfer = false, DateTime? date}) =>
      s.addManual(
        date: date ?? jun,
        description: 'mov $cents',
        amount: cents,
        categoryId: cat,
        isTransfer: transfer,
      );

  test('entrada sem categoria conta na receita da Análise e do Orçamento', () {
    mov(70000, null);
    expect(an().incomeReceived, 70000);
    expect(an().income, 70000);
    expect(s.incomeIn(period), 70000);
  });

  test('saída sem categoria aparece em "Por classificar" na Análise e no Orçamento', () {
    mov(-1200, null);
    expect(an().spent, 1200);
    expect(an().unclassifiedTotal, 1200);
    expect(an().byCategory().single.label, 'Por classificar');
    expect(s.unclassifiedSpent(period), 1200);
    expect(s.mandatorySplit(period).unclassified, 1200);
  });

  test('Análise == Mês == Orçamento para o mesmo período', () {
    final casa = s.addCategory(const Categoria(id: 0, name: 'Casa'));
    mov(-3000, casa);
    mov(-1200, null);
    mov(-300, null);
    mov(2500, casa);
    mov(70000, null);
    mov(900, null, transfer: true);
    mov(-901, null, transfer: true);
    final a = an();
    // despesa total: categorizada + por classificar
    expect(a.spent, 4500);
    expect(a.unclassifiedTotal, 1500);
    expect(s.unclassifiedSpent(period), a.unclassifiedTotal);
    expect(s.totalsByCategory(period)[casa], 3000);
    expect(
      s.totalsByCategory(period).values.fold(0, (x, y) => x + y) +
          s.unclassifiedSpent(period),
      a.spent,
    );
    // receita: a mesma no Orçamento e na Análise
    expect(a.incomeReceived, 72500);
    expect(s.incomeIn(period), a.incomeReceived);
    // as transferências reais continuam fora
    expect(
      s.isSpend(s.transactions.firstWhere((t) => t.amount == -901)),
      false,
    );
    expect(
      s.isIncomeTxn(s.transactions.firstWhere((t) => t.amount == 900)),
      false,
    );
  });

  test('salário definido continua a ser o mínimo da receita', () {
    s.setDefaultSalary(150000);
    mov(5000, null); // reembolso pequeno sem categoria
    Analytics fechado() => Analytics(
      s,
      period,
      const AnalysisFilter(),
      today: DateTime(2026, 8, 1),
    );
    expect(fechado().incomeReceived, 5000);
    expect(fechado().income, 150000);
    expect(fechado().incomeFromSalary, isTrue);
    mov(200000, null); // recebido acima do salário
    expect(fechado().income, 205000);
    expect(fechado().incomeFromSalary, isFalse);
  });

  testWidgets('Orçamento mostra a linha "Por classificar" e a receita sem categoria', (
    tester,
  ) async {
    final now = DateTime.now();
    final key = s.currentMonthKey;
    s.setDefaultSalary(100000);
    mov(-2500, null, date: now);
    mov(40000, null, date: now);
    expect(s.unclassifiedSpent(s.periodOfMonth(key)), 2500);
    tester.view.physicalSize = const Size(400, 1400) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: s,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('pt', 'PT'),
          home: const BudgetScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Por classificar'), findsOneWidget);
    expect(find.textContaining(fmtMoney(40000)), findsWidgets); // receita do mês
    expect(find.textContaining(fmtMoney(2500)), findsWidgets);
  });
}
