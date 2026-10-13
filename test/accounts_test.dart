import 'package:financas/db/database.dart';
import 'package:financas/models.dart';
import 'package:financas/screens/accounts_screen.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'support/fonts.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_PT');
    await loadRoboto();
  });

  test('saldo = saldo inicial + movimentos da conta (cada conta separada)', () {
    final s = AppState(Db.memory());
    final a = s.addAccount('Conta à ordem', openingCents: 100000);
    final b = s.addAccount('Poupança', openingCents: -5000);
    final day = DateTime(2026, 10, 3);
    s.addManual(
      date: day,
      description: 'Supermercado',
      amount: -4550,
      accountId: a,
    );
    s.addManual(
      date: day,
      description: 'Salário',
      amount: 250000,
      accountId: a,
    );
    s.addManual(date: day, description: 'Juros', amount: 1200, accountId: b);
    expect(s.accountBalance(a), 100000 - 4550 + 250000);
    expect(s.accountBalance(b), -5000 + 1200);
    // a conta sem movimentos fica no saldo inicial
    final c = s.addAccount('Vazia', openingCents: 777);
    expect(s.accountBalance(c), 777);
  });

  test('objetivos alimentados por uma conta: só o que veio dessa conta', () {
    final s = AppState(Db.memory());
    final bank1 = s.addAccount('Banco 1');
    final bank2 = s.addAccount('Banco 2');
    final lazer = s.addCategory(const Categoria(id: 0, name: 'Lazer'));
    final gid = s.addGoal(
      name: 'Férias',
      parentCategoryId: lazer,
      targetCents: 100000,
    );
    final goalCat = s.goals.first.categoryId;
    final day = DateTime.now();
    s.addManual(
      date: day,
      description: 'Poupança 1',
      amount: -30000,
      accountId: bank1,
      categoryId: goalCat,
    );
    s.addManual(
      date: day,
      description: 'Poupança 2',
      amount: -20000,
      accountId: bank2,
      categoryId: goalCat,
    );
    expect(s.goalContributionsFrom(bank1), {gid: 30000});
    expect(s.goalContributionsFrom(bank2), {gid: 20000});
  });

  testWidgets('detalhe da conta: saldo, este mês e movimentos da conta', (
    tester,
  ) async {
    final s = AppState(Db.memory());
    final a = s.addAccount('Conta à ordem', openingCents: 100000);
    final now = DateTime.now();
    s.addManual(
      date: now,
      description: 'Supermercado',
      amount: -4550,
      accountId: a,
    );
    tester.view.physicalSize = const Size(400, 1400) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: s,
        child: MaterialApp(home: AccountDetailScreen(accountId: a)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Saldo'), findsOneWidget);
    expect(find.textContaining('Supermercado'), findsOneWidget);
    expect(find.text('Ver todos'), findsOneWidget);
  });
}
