import 'package:financas/invest/metrics/financials.dart';
import 'package:financas/invest/metrics/shared.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fim = DateTime(2026, 6, 30);
  test('capitalização: marketCap ou preço × ações', () {
    expect(mcapOf(const MarketSnapshot(symbol: 'X', marketCap: 100)), 100);
    expect(
      mcapOf(
        const MarketSnapshot(symbol: 'X', price: 10, sharesOutstanding: 5),
      ),
      50,
    );
    expect(mcapOf(const MarketSnapshot(symbol: 'X', price: 10)), isNull);
  });

  test('EBITDA = resultado operacional + D&A (e não o EBITDA do Yahoo)', () {
    final p = FinPeriod(
      end: fim,
      annual: true,
      operatingIncome: 100,
      ebit: 130,
      depreciationAmortization: 10,
      ebitda: 140,
    );
    expect(ebitdaOf(p), 110);
    // sem D&A: último recurso, o campo da fonte
    expect(
      ebitdaOf(
        FinPeriod(end: fim, annual: true, operatingIncome: 100, ebitda: 140),
      ),
      140,
    );
    expect(ebitdaOf(FinPeriod(end: fim, annual: true)), isNull);
  });

  test(
    'período anterior: anual vs anual; TTM pela janela de 320 a 410 dias',
    () {
      final a0 = FinPeriod(end: DateTime(2024, 6, 30), annual: true);
      final a1 = FinPeriod(end: DateTime(2025, 6, 30), annual: true);
      final f = Financials(symbol: 'X', annual: [a0, a1]);
      expect(previousPeriodFor(f, a1), same(a0));
      expect(previousPeriodFor(f, a0), isNull);
      final ttm = FinPeriod(end: DateTime(2026, 6, 30), annual: true);
      final f2 = Financials(symbol: 'X', annual: [a0, a1], ttm: ttm);
      expect(
        previousPeriodFor(f2, ttm),
        same(a1),
      ); // sem trimestrais: cai no anual
      final q = FinPeriod(end: DateTime(2025, 6, 30), annual: false);
      final f3 = Financials(
        symbol: 'X',
        annual: [a0],
        quarterly: [q],
        ttm: ttm,
      );
      expect(previousPeriodFor(f3, ttm), same(q));
    },
  );

  test(
    'financeira: sem custo das vendas, resultado operacional e ativo corrente',
    () {
      expect(
        isFinancialLike(FinPeriod(end: fim, annual: true, netIncome: 1)),
        isTrue,
      );
      expect(
        isFinancialLike(FinPeriod(end: fim, annual: true, currentAssets: 5)),
        isFalse,
      );
      expect(isFinancialLike(null), isFalse);
    },
  );

  test('base de ações: ADR com 5 ações por recibo', () {
    final f = Financials(
      symbol: 'X',
      annual: [FinPeriod(end: fim, annual: true, sharesOutstanding: 25.9)],
    );
    expect(
      sharesBasisMismatch(
        f,
        const MarketSnapshot(symbol: 'X', sharesOutstanding: 5.19),
      ),
      isTrue,
    );
    expect(
      sharesBasisMismatch(
        f,
        const MarketSnapshot(symbol: 'X', sharesOutstanding: 25.9),
      ),
      isFalse,
    );
    expect(sharesBasisMismatch(f, const MarketSnapshot(symbol: 'X')), isFalse);
  });
}
