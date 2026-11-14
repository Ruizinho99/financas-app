import 'package:financas/budget/distribute.dart';
import 'package:financas/db/database.dart';
import 'package:financas/l10n/app_localizations.dart';
import 'package:financas/models.dart';
import 'package:financas/screens/budget_screen.dart';
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

  group('splitEqually', () {
    test('a soma é exatamente o total, com o resto nas primeiras', () {
      expect(splitEqually(100, 3), [34, 33, 33]);
      expect(splitEqually(100, 3).fold(0, (a, b) => a + b), 100);
      expect(splitEqually(10, 4), [3, 3, 2, 2]);
      expect(splitEqually(2, 5), [1, 1, 0, 0, 0]);
      expect(splitEqually(0, 3), [0, 0, 0]);
      expect(splitEqually(100, 0), isEmpty);
    });
  });

  group('distributionWrites', () {
    test('só grava as editadas; vazias e percentuais ficam intactas', () {
      final kids = [
        const DistKid(1),
        const DistKid(2),
        const DistKid(3, percent: true),
        const DistKid(4),
      ];
      final w = distributionWrites(kids, {1: 5000, 2: null, 3: 9999});
      expect(w, {1: 5000}); // 2 vazio, 3 percentual, 4 não editada
    });
  });

  testWidgets('distribuir numa árvore de 3 níveis', (tester) async {
    final s = AppState(Db.memory());
    final inv = s.addCategory(Categoria(id: 0, name: 'Investimento',
        isInvestment: true, hasBudget: true, budgetValue: 30001));
    final xtb = s.addCategory(Categoria(id: 0, name: 'XTB', parentId: inv,
        isInvestment: true, hasBudget: true, budgetValue: 20000));
    final nvda = s.addCategory(Categoria(id: 0, name: 'NVDA', parentId: xtb, isInvestment: true));
    final vwce = s.addCategory(Categoria(id: 0, name: 'VWCE', parentId: xtb, isInvestment: true));
    final pct = s.addCategory(Categoria(id: 0, name: 'Cripto', parentId: inv,
        isInvestment: true, hasBudget: true, budgetPercent: true, budgetValue: 500));
    s.setSalary(s.currentMonthKey, 100000); // 5% = 5000

    tester.view.physicalSize = const Size(400, 1400) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    Future<void> open(int catId, int total) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: s,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('pt', 'PT'),
            home: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => showDistributeDialog(ctx, s, s.cat(catId)!, total),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    // 1.º nível: a filha percentual é só leitura e fica intacta
    await open(inv, 30001);
    expect(find.textContaining('permanentes'), findsOneWidget);
    expect(find.byKey(ValueKey('dist-pct-$pct')), findsOneWidget);
    expect(find.byKey(ValueKey('dist-field-$pct')), findsNothing);
    await tester.tap(find.text('Dividir por igual'));
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(s.cat(pct)!.budgetPercent, isTrue);
    expect(s.cat(pct)!.budgetValue, 500);
    expect(s.cat(xtb)!.budgetValue, 25001); // 30001 - 5000 (percentual)

    // 2.º nível (corretora -> ativos): resto de cêntimos distribuído e total exato
    await open(xtb, 25001);
    await tester.tap(find.text('Dividir por igual'));
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(s.cat(nvda)!.budgetValue + s.cat(vwce)!.budgetValue, 25001);
    expect(s.cat(nvda)!.budgetValue, 12501);

    // campo vazio não apaga: só edito o NVDA, o VWCE mantém o valor
    await open(xtb, 25001);
    await tester.enterText(find.byKey(ValueKey('dist-field-$nvda')), '100,00');
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(s.cat(nvda)!.budgetValue, 10000);
    expect(s.cat(vwce)!.budgetValue, 12500);
    expect(s.cat(vwce)!.hasBudget, isTrue);
  });
}
