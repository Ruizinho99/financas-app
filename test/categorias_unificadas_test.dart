import 'package:financas/analysis/analytics.dart';
import 'package:financas/db/database.dart';
import 'package:financas/l10n/app_localizations.dart';
import 'package:financas/models.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Qualquer categoria serve para despesas e receitas: quem decide é o sinal do movimento.
void main() {
  late AppState s;
  final jun = DateTime(2026, 6, 10);
  final period = Period.month(DateTime(2026, 6));
  Analytics an() => Analytics(s, period, const AnalysisFilter());

  setUp(() => s = AppState(Db.memory()));

  void mov(int cents, int? cat, {bool transfer = false}) => s.addManual(
    date: jun,
    description: 'mov $cents',
    amount: cents,
    categoryId: cat,
    isTransfer: transfer,
  );

  test(
    'uma categoria nos dois sentidos: gasto 20, receita 50, orçamento 20',
    () {
      final saude = s.addCategory(const Categoria(id: 0, name: 'Saúde'));
      mov(-2000, saude);
      mov(5000, saude);
      expect(an().spent, 2000);
      expect(an().incomeReceived, 5000);
      // no orçamento a entrada não abate ao gasto da categoria (o reembolso explícito faz-se com a anulação)
      expect(s.totalsByCategory(period)[saude], 2000);
    },
  );

  test('uma categoria antiga só de receita também aceita despesas', () {
    final sal = s.addCategory(
      const Categoria(id: 0, name: 'Salário', isIncome: true),
    );
    mov(100000, sal);
    mov(-1500, sal);
    expect(an().incomeReceived, 100000);
    expect(an().spent, 1500);
  });

  test(
    'uma categoria antiga "despesas e receitas" comporta-se como as outras',
    () {
      final olx = s.addCategory(
        const Categoria(id: 0, name: 'OLX', both: true),
      );
      final plain = s.addCategory(const Categoria(id: 0, name: 'Vendas'));
      for (final c in [olx, plain]) {
        mov(-4000, c);
        mov(15000, c);
      }
      expect(an().spent, 8000);
      expect(an().incomeReceived, 30000);
    },
  );

  test('investimento continua a não ser gasto nem receita', () {
    final etf = s.addCategory(
      const Categoria(id: 0, name: 'ETFs', isInvestment: true),
    );
    mov(-3000, etf);
    mov(500, etf);
    expect(an().spent, 0);
    expect(an().incomeReceived, 0);
    expect(an().invested, 3000);
  });

  test('entradas sem categoria e transferências não são receita', () {
    final c = s.addCategory(const Categoria(id: 0, name: 'Casa'));
    mov(700, null);
    mov(900, c, transfer: true);
    expect(an().incomeReceived, 0);
    expect(
      s.isIncomeTxn(s.transactions.firstWhere((t) => t.amount == 900)),
      isFalse,
    );
    expect(
      s.isSpend(s.transactions.firstWhere((t) => t.amount == 900)),
      isFalse,
    );
  });

  test('o mesmo ajudante serve para despesa e receita (sem categoria conta como despesa)', () {
    mov(-1200, null);
    expect(an().spent, 1200);
  });

  test('insights() e insightsL() dão o mesmo resultado em português', () async {
    final casa = s.addCategory(
      const Categoria(id: 0, name: 'Casa', hasBudget: true, budgetValue: 1000),
    );
    mov(-3000, casa);
    mov(-800, null);
    mov(2500, casa);
    final l = await AppLocalizations.delegate.load(const Locale('pt', 'PT'));
    final a = an();
    final plain = a.insights().map((i) => i.title).toList();
    final loc = a.insightsL(l).map((i) => i.title).toList();
    expect(loc, plain);
  });
}
