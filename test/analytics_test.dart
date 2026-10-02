import 'package:financas/analysis/analytics.dart';
import 'package:financas/models.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/analysis_data.dart';

Analytics june(AppState s, {AnalysisFilter f = const AnalysisFilter()}) {
  final p = Period.month(DateTime(2026, 6));
  return Analytics(s, p, f, previous: previousPeriod(p, today: DateTime(2026, 6, 15)), today: DateTime(2026, 6, 15));
}

void main() {
  test('período anterior', () {
    final jun = previousPeriod(Period.month(DateTime(2026, 6)), today: DateTime(2027, 1, 5));
    expect((jun.start, jun.end), (DateTime(2026, 5), DateTime(2026, 6)));
    final year = previousPeriod(Period.year(2026), today: DateTime(2027, 1, 5));
    expect((year.start, year.end), (DateTime(2025), DateTime(2026)));
    final ytd = previousPeriod(Period.ytd(DateTime(2026, 6, 15)), today: DateTime(2026, 6, 15));
    expect((ytd.start, ytd.end), (DateTime(2025), DateTime(2025, 6, 16)));
    final custom = previousPeriod(Period.custom(DateTime(2026, 6, 10), DateTime(2026, 6, 19)), today: DateTime(2026, 12, 1));
    expect((custom.start, custom.end), (DateTime(2026, 5, 31), DateTime(2026, 6, 10)));
    // mês em curso (dia 2): compara só os mesmos 2 dias do mês anterior
    final oct = previousPeriod(Period.month(DateTime(2026, 10)), today: DateTime(2026, 10, 2));
    expect((oct.start, oct.end), (DateTime(2026, 9), DateTime(2026, 9, 3)));
    // mês completo no passado: mês anterior inteiro
    final sep = previousPeriod(Period.month(DateTime(2026, 9)), today: DateTime(2026, 10, 2));
    expect((sep.start, sep.end), (DateTime(2026, 8), DateTime(2026, 9)));
    // ano em curso: até ao mesmo dia do ano anterior
    final y = previousPeriod(Period.year(2026), today: DateTime(2026, 10, 2));
    expect(y.start, DateTime(2025));
    expect(y.end, DateTime(2025, 10, 3));
  });

  test('totais, obrigatórias/opcionais, rendimentos, saldo e comparação', () {
    final d = buildAnalysisData();
    final a = june(d.s);
    expect(a.spent, 97558);
    expect(a.mandatoryTotal, 50000);
    expect(a.optionalTotal, 46558);
    expect(a.unclassifiedTotal, 1000);
    expect(a.income, 150000);
    expect(a.balance, 52442);
    expect(a.savingsRate, closeTo(0.3496, 0.001));
    expect(a.prevSpent, 77098); // maio
    expect(a.spent - a.prevSpent, 20460);
    // a transferência de 300 € não conta nem como despesa nem como rendimento
    expect(a.count, 14);
  });

  test('filtros: tipo, categoria (com subs), conta, texto e valor', () {
    final d = buildAnalysisData();
    expect(june(d.s, f: const AnalysisFilter(type: SpendType.mandatory)).spent, 50000);
    expect(june(d.s, f: const AnalysisFilter(type: SpendType.optional)).spent, 46558); // sem o não classificado
    expect(june(d.s, f: AnalysisFilter(categoryIds: {d.alim})).spent, 43500); // Alimentação inclui subcategorias
    expect(june(d.s, f: AnalysisFilter(categoryIds: {d.rest})).spent, 3500);
    expect(june(d.s, f: AnalysisFilter(accountIds: {d.poup})).spent, 1000);
    expect(june(d.s, f: const AnalysisFilter(query: 'netflix')).spent, 1299);
    expect(june(d.s, f: const AnalysisFilter(minCents: 5000)).spent, 90000);
    expect(june(d.s, f: const AnalysisFilter(maxCents: 200)).spent, 960);
    expect(const AnalysisFilter().isActive, isFalse);
    expect(const AnalysisFilter(type: SpendType.optional, query: 'x').activeCount, 2);
  });

  test('onde gasto: categorias, subcategorias, comerciantes, dias da semana', () {
    final d = buildAnalysisData();
    final a = june(d.s);
    final cats = a.byCategory();
    expect(cats.map((e) => e.label).toList(), ['Casa', 'Alimentação', 'Lazer', 'Sem categoria']);
    expect(cats[1].amount, 43500);
    expect(cats[1].prev, 25000); // maio
    final subs = a.bySubcategory();
    expect(subs.first.label, 'Casa');
    final sup = subs.firstWhere((e) => e.label == 'Supermercado');
    expect(sup.amount, 40000);
    expect(sup.subtitle, 'Alimentação');
    final merchants = a.byMerchant();
    expect(merchants.first.label, 'RENDA CASA');
    final cafe = merchants.firstWhere((e) => e.label == 'CAFE CENTRAL');
    expect((cafe.count, cafe.amount, cafe.avg), (8, 960, 120));
    final w = a.byWeekday();
    expect(w.totals.fold(0, (x, y) => x + y), a.spent);
    expect(w.counts.fold(0, (x, y) => x + y), a.count);
    expect(a.largest(2).map((e) => e.amount).toList(), [50000, 40000]);
    expect(a.byAccount().map((e) => e.label).toSet(), {'Ordem', 'Poupança'});
  });

  test('pagamentos recorrentes e pequenas compras frequentes', () {
    final d = buildAnalysisData();
    final a = june(d.s);
    final rec = a.recurring();
    // opcionais primeiro (os que se podem cancelar); supermercado varia demasiado e os cafés só aparecem num mês
    expect(rec.map((e) => e.label).toList(), ['NETFLIX', 'SPOTIFY', 'RENDA CASA']);
    expect(rec.map((e) => e.mandatory).toList(), [false, false, true]);
    expect(rec[0].monthly, 1299);
    expect(rec[0].yearly, 1299 * 12);
    expect(rec[0].months, 3);
    final small = a.frequentSmall();
    expect(small.length, 1);
    expect(small.first.label, 'CAFE CENTRAL');
  });

  test('sugestões de poupança e simulador', () {
    final d = buildAnalysisData();
    final a = june(d.s);
    final ins = a.insights();
    // Alimentação subiu 74% (+185 €), as pequenas compras, os recorrentes e o que está sem categoria
    expect(ins.map((e) => e.kind).toList(), [InsightKind.increase, InsightKind.smallFrequent, InsightKind.recurring, InsightKind.unclassified]);
    expect(ins.first.monthlySaving, 18500);
    expect(ins.first.categoryId, d.alim);
    expect(ins[1].monthlySaving, 320);
    expect(ins[2].monthlySaving, isNull);
    expect(a.potentialMonthly, 18820);

    final sim = a.simulate(0.1);
    expect(sim.total, 4656);
    expect(sim.monthly, 4656);
    expect(sim.yearly, 4656 * 12);
    expect(sim.newRate, closeTo((52442 + 4656) / 150000, 0.0001));
  });

  test('orçamento ultrapassado vira sugestão', () {
    final d = buildAnalysisData();
    final lazer = d.s.cat(d.lazer)!;
    d.s.updateCategory(lazer.copyWith(hasBudget: true, budgetValue: 2000, budgetType: BudgetType.limit));
    final a = june(d.s);
    final over = a.insights().firstWhere((e) => e.kind == InsightKind.overBudget);
    expect(over.monthlySaving, 3058 - 2000);
    expect(a.budgetStats().first.category.id, d.lazer);
  });

  test('projeção do mês e evolução mensal', () {
    final d = buildAnalysisData();
    final a = june(d.s);
    final pr = a.projection()!;
    expect((pr.elapsedDays, pr.totalDays), (15, 30));
    expect(pr.projected, 97558 * 2);
    expect(pr.budget, isNull);
    // período que já acabou não tem projeção
    final may = Period.month(DateTime(2026, 5));
    expect(Analytics(d.s, may, const AnalysisFilter(), today: DateTime(2026, 6, 15)).projection(), isNull);

    final m = a.monthly(3);
    expect(m.map((e) => e.spent).toList(), [72098, 77098, 97558]);
    expect(m.map((e) => e.income).toList(), [150000, 150000, 150000]);
    expect(m.last.balance, 52442);
    expect(m.first.month, DateTime(2026, 4));
  });
}
