import 'package:financas/l10n/app_localizations.dart';
import 'package:financas/models.dart';
import 'package:financas/screens/budget_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('máximo: dentro ou excedido; mínimo: atingido ou em falta', (
    tester,
  ) async {
    late AppLocalizations l;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'PT'),
        home: Builder(
          builder: (c) {
            l = AppLocalizations.of(c)!;
            return const SizedBox();
          },
        ),
      ),
    );
    String st(BudgetType t, int spent, int target) =>
        budgetStatus(l, t, spent, target);
    // compras: máximo 300
    expect(st(BudgetType.limit, 25000, 30000), contains('Dentro do máximo'));
    expect(st(BudgetType.limit, 35000, 30000), contains('Excedido em'));
    expect(st(BudgetType.limit, 30000, 30000), contains('Dentro do máximo'));
    // investimentos: mínimo 200
    expect(st(BudgetType.goal, 25000, 20000), contains('Mínimo atingido'));
    expect(st(BudgetType.goal, 15000, 20000), contains('Abaixo do mínimo'));
    expect(st(BudgetType.goal, 20000, 20000), contains('Mínimo atingido'));
  });
}
