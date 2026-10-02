import 'package:financas/db/database.dart';
import 'package:financas/import/parsers.dart';
import 'package:financas/models.dart';
import 'package:financas/state/app_state.dart';
import 'package:financas/util/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseCents', () {
    expect(parseCents('1.234,56'), 123456);
    expect(parseCents('-45,30'), -4530);
    expect(parseCents('12,50-'), -1250);
    expect(parseCents('1,234.56'), 123456);
    expect(parseCents('45.30'), 4530);
    expect(parseCents('abc'), isNull);
  });

  test('merchantKey agrupa o mesmo nome', () {
    expect(merchantKey('COMPRA CONTINENTE 1234 LISBOA'), merchantKey('Compra Continente 9876 Lisboa'));
    expect(merchantKey('PAG SERVIÇOS EDP 123'), 'SERVICOS EDP');
  });

  test('PDF texto com descrição em duas linhas e sinais por saldo', () {
    const text = '''
BANCO EXEMPLO - Extrato 2026
02-01-2026 02-01-2026 SALDO INICIAL 1.000,00
03-01-2026 03-01-2026 COMPRA CONTINENTE LISBOA -45,30 954,70
05-01-2026 05-01-2026 TRF DE JOAO SILVA
RENDA JANEIRO 500,00 1.454,70
10-01-2026 10-01-2026 PAG SERVICOS EDP 72,15 1.382,55
''';
    final rows = parseStatementText(text);
    expect(rows.length, 4);
    expect(rows[2].description, 'TRF DE JOAO SILVA RENDA JANEIRO');
    expect(rows[2].amount, 50000);
    expect(rows[3].amount, -7215); // sinal inferido pelo saldo
  });

  test('CSV com mapeamento automático', () {
    final t = parseCsv('Data;Descrição;Débito;Crédito;Saldo\n01/02/2026;LIDL;25,00;;975,00\n02/02/2026;SALARIO;;1.500,00;2.475,00\n');
    final m = guessMapping(t);
    final rows = rowsFromTable(t, m);
    expect(rows.length, 2);
    expect(rows[0].amount, -2500);
    expect(rows[1].amount, 150000);
  });

  test('classificar, memorizar regra e orçamento', () {
    final s = AppState(Db.memory());
    s.setDefaultSalary(200000);
    final (added, dup) = s.importRows('x.csv', 'csv', [
      ParsedRow(DateTime(2026, 1, 3), 'COMPRA CONTINENTE 1', -4000),
      ParsedRow(DateTime(2026, 1, 9), 'COMPRA CONTINENTE 2', -6000),
      ParsedRow(DateTime(2026, 1, 9), 'SALARIO ACME', 200000),
    ]);
    expect((added, dup), (3, 0));
    expect(s.importRows('x.csv', 'csv', [ParsedRow(DateTime(2026, 1, 3), 'COMPRA CONTINENTE 1', -4000)]).$2, 1);
    final groups = s.unclassifiedGroups();
    expect(groups.first.txns.length, 2);
    final super_ = s.categories.firstWhere((c) => c.name == 'Supermercado');
    s.assign(groups.first.txns, super_.id, remember: true);
    expect(s.unclassifiedGroups().length, 1);
    // futura importação usa a regra
    s.importRows('y.csv', 'csv', [ParsedRow(DateTime(2026, 2, 1), 'COMPRA CONTINENTE 77', -1000)]);
    expect(s.transactions.firstWhere((t) => t.description.endsWith('77')).categoryId, super_.id);
    // orçamento: limite de 25% do salário
    final food = s.categories.firstWhere((c) => c.name == 'Alimentação');
    s.updateCategory(Categoria(id: food.id, name: food.name, mandatory: true, color: food.color, budgetPercent: true, budgetValue: 2500, hasBudget: true));
    final p = Period.month(DateTime(2026, 1));
    expect(s.effectiveMonthlyTarget(s.cat(food.id)!, 200000), 50000);
    expect(s.rollup(s.cat(food.id)!, s.totalsByCategory(p)), 10000);
    expect(s.targetIn(s.cat(food.id)!, Period.years(2026, 2026)), 600000);
  });
}
