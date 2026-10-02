import 'package:financas/db/database.dart';
import 'package:financas/import/parsers.dart';
import 'package:financas/models.dart';
import 'package:financas/state/app_state.dart';
import 'package:financas/util/format.dart';
import 'package:flutter/material.dart' show ThemeMode;
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
    expect(s.categories, isEmpty); // nada vem pré-definido
    final food0 = s.addCategory(const Categoria(id: 0, name: 'Alimentação'));
    s.addCategory(Categoria(id: 0, name: 'Supermercado', parentId: food0, emoji: '🛒'));
    s.setDefaultSalary(200000);
    final (added, dup) = s.importRows('x.csv', 'csv', [
      ParsedRow(DateTime(2026, 1, 3), 'COMPRA CONTINENTE 1', -4000),
      ParsedRow(DateTime(2026, 1, 9), 'COMPRA CONTINENTE 2', -6000),
      ParsedRow(DateTime(2026, 1, 9), 'SALARIO ACME', 200000),
    ]);
    expect((added, dup), (3, 0));
    // classificar na importação, com memorização
    final mercado = s.categories.firstWhere((c) => c.name == 'Supermercado');
    s.importRows('z.csv', 'csv', [ParsedRow(DateTime(2026, 3, 1), 'LIDL 55', -500)],
        categories: {'LIDL': mercado.id}, remember: {'LIDL'});
    expect(s.transactions.firstWhere((t) => t.description == 'LIDL 55').categoryId, mercado.id);
    expect(s.ruleFor('LIDL')?.categoryId, mercado.id);
    s.importRows('w.csv', 'csv', [ParsedRow(DateTime(2026, 3, 2), 'LIDL 56', -700)], categories: {'LIDL': null});
    expect(s.transactions.firstWhere((t) => t.description == 'LIDL 56').categoryId, isNull);
    expect(s.importRows('x.csv', 'csv', [ParsedRow(DateTime(2026, 1, 3), 'COMPRA CONTINENTE 1', -4000)]).$2, 1);
    expect(s.cat(mercado.id)!.emoji, '🛒');
    final groups = s.unclassifiedGroups().where((g) => g.key == 'CONTINENTE').toList();
    expect(groups.first.txns.length, 2);
    final super_ = s.categories.firstWhere((c) => c.name == 'Supermercado');
    s.assign(groups.first.txns, super_.id, remember: true);
    expect(s.unclassifiedGroups().where((g) => g.key == 'CONTINENTE'), isEmpty);
    // futura importação usa a regra
    s.importRows('y.csv', 'csv', [ParsedRow(DateTime(2026, 2, 1), 'COMPRA CONTINENTE 77', -1000)]);
    expect(s.transactions.firstWhere((t) => t.description.endsWith('77')).categoryId, super_.id);
    // orçamento: limite de 25% do salário
    final food = s.categories.firstWhere((c) => c.name == 'Alimentação');
    s.updateCategory(Categoria(id: food.id, name: food.name, budgetPercent: true, budgetValue: 2500, hasBudget: true));
    final p = Period.month(DateTime(2026, 1));
    expect(s.effectiveMonthlyTarget(s.cat(food.id)!, 200000), 50000);
    expect(s.rollup(s.cat(food.id)!, s.totalsByCategory(p)), 10000);
    expect(s.targetIn(s.cat(food.id)!, Period.years(2026, 2026)), 600000);
    // YTD / intervalo: o último mês conta só os dias decorridos (15 de 28 em fevereiro)
    expect(s.targetIn(s.cat(food.id)!, Period.custom(DateTime(2026, 1, 1), DateTime(2026, 2, 15))), 50000 + 26786);
    expect(s.salaryIn(Period.custom(DateTime(2026, 1, 1), DateTime(2026, 1, 31))), 200000);
    expect(Period.ytd(DateTime(2026, 5, 20)).monthCount, 5);
    expect(Period.ytd(DateTime(2026, 5, 20)).contains(DateTime(2026, 5, 20)), isTrue);
    expect(Period.ytd(DateTime(2026, 5, 20)).contains(DateTime(2026, 5, 21)), isFalse);
  });
  test('nome amigável aplica-se a movimentos com o mesmo nome', () {
    final s = AppState(Db.memory());
    final desp = s.addCategory(const Categoria(id: 0, name: 'Desporto'));
    final gym = s.addCategory(Categoria(id: 0, name: 'Ginásio', parentId: desp));
    const weird = 'XPTO*GYM 99887 HLM';
    s.importRows('a.csv', 'csv', [ParsedRow(DateTime(2026, 1, 5), weird, -3990)],
        categories: {merchantKey(weird): gym}, remember: {merchantKey(weird)}, names: {merchantKey(weird): 'Ginásio Holmes'});
    final t1 = s.transactions.first;
    expect(s.displayName(t1), 'Ginásio Holmes');
    expect(t1.categoryId, gym);
    // importação seguinte com o mesmo nome: nome e categoria vêm automaticamente
    s.importRows('b.csv', 'csv', [ParsedRow(DateTime(2026, 2, 5), 'XPTO*GYM 11223 HLM', -3990)]);
    final t2 = s.transactions.firstWhere((t) => t.date == DateTime(2026, 2, 5));
    expect(s.displayName(t2), 'Ginásio Holmes');
    expect(t2.categoryId, gym);
    // só nome, sem categoria
    s.importRows('c.csv', 'csv', [ParsedRow(DateTime(2026, 3, 1), 'TRF 123 JOAO', -1000)], names: {merchantKey('TRF 123 JOAO'): 'Mesada'});
    final t3 = s.transactions.firstWhere((t) => t.date == DateTime(2026, 3, 1));
    expect(s.displayName(t3), 'Mesada');
    expect(t3.categoryId, isNull);
  });

  test('obrigatória varia de mês para mês', () {
    final s = AppState(Db.memory());
    final casa = s.addCategory(const Categoria(id: 0, name: 'Casa'));
    final sub = s.addCategory(Categoria(id: 0, name: 'Condomínio', parentId: casa));
    final c = s.cat(casa)!, k = s.cat(sub)!;
    expect(s.isMandatory(c, '2026-03'), isFalse);
    s.addRange(casa, '2026-01', '2026-06');
    expect(s.isMandatory(c, '2026-03'), isTrue);
    expect(s.isMandatory(c, '2026-07'), isFalse);
    expect(s.isMandatory(k, '2026-03'), isTrue); // herdada
    // desmarcar só março parte o período em dois
    s.setMandatoryInMonth(casa, '2026-03', false);
    expect(s.isMandatory(c, '2026-02'), isTrue);
    expect(s.isMandatory(c, '2026-03'), isFalse);
    expect(s.isMandatory(c, '2026-04'), isTrue);
    expect(s.rangesOf(casa).length, 2);
    // período sem fim
    s.setMandatoryInMonth(casa, '2026-09', true);
    s.addRange(sub, '2027-01', null);
    expect(s.isMandatory(k, '2030-05'), isTrue);
    // divisão por mês dos movimentos
    s.addManual(date: DateTime(2026, 2, 5), description: 'Condominio', amount: -3000, categoryId: sub);
    s.addManual(date: DateTime(2026, 3, 5), description: 'Condominio', amount: -3000, categoryId: sub);
    final split = s.mandatorySplit(Period.years(2026, 2026));
    expect(split.mandatory[sub], 3000);
    expect(split.optional[sub], 3000);
  });

  test('definições de aparência persistem', () {
    final db = Db.memory();
    final s = AppState(db);
    s.setAppearance(mode: ThemeMode.dark, seed: 0xFF123456, amoledBlack: true);
    final s2 = AppState(db);
    expect(s2.themeMode, ThemeMode.dark);
    expect(s2.seedColor, 0xFF123456);
    expect(s2.amoled, isTrue);
    s2.resetAppearance();
    expect(s2.themeMode, ThemeMode.system);
  });

  test('grupos: vários títulos, um nome e uma categoria', () {
    final s = AppState(Db.memory());
    final rest = s.addCategory(const Categoria(id: 0, name: 'Restaurantes'));
    final bar = s.addCategory(const Categoria(id: 0, name: 'Bar'));
    const t1 = 'TRANS RESTAURANTE ARMINDA', t2 = 'MB WAY RESTAURANTE ARMINDA 123';
    s.importRows('a.csv', 'csv', [
      ParsedRow(DateTime(2026, 1, 5), t1, -1500),
      ParsedRow(DateTime(2026, 1, 9), t2, -2000),
      ParsedRow(DateTime(2026, 1, 10), 'LIDL', -500),
    ]);
    expect(s.unclassifiedGroups().length, 3);

    // juntar dois títulos num grupo com categoria: os movimentos existentes ficam classificados
    final gid = s.createGroup('Restaurante Arminda', categoryId: rest, keys: {merchantKey(t1), merchantKey(t2)});
    expect(s.transactions.where((t) => t.categoryId == rest).length, 2);
    expect(s.displayName(s.transactions.firstWhere((t) => t.description == t1)), 'Restaurante Arminda');
    expect(s.unclassifiedGroups().length, 1); // só o LIDL

    // título do grupo numa importação futura: nome e categoria automáticos
    s.importRows('b.csv', 'csv', [ParsedRow(DateTime(2026, 2, 5), 'MB WAY RESTAURANTE ARMINDA 999', -1000)]);
    expect(s.transactions.firstWhere((t) => t.date == DateTime(2026, 2, 5)).categoryId, rest);

    // um terceiro título junta-se ao grupo escrevendo o mesmo nome na importação
    const t3 = 'PAG ARMINDA TAKEAWAY 77';
    s.importRows('c.csv', 'csv', [ParsedRow(DateTime(2026, 3, 1), t3, -900)],
        names: {merchantKey(t3): 'restaurante arminda'}, remember: {merchantKey(t3)}, categories: {merchantKey(t3): rest});
    expect(s.rulesOfGroup(gid).length, 3);
    expect(s.displayName(s.transactions.firstWhere((t) => t.date == DateTime(2026, 3, 1))), 'Restaurante Arminda');

    // no Classificar, os três títulos aparecem num único cartão
    final cards = s.allGroups().where((c) => c.groupId == gid).toList();
    expect(cards.length, 1);
    expect(cards.first.keys.length, 3);
    expect(cards.first.txns.length, 4);

    // mudar a categoria do grupo move os movimentos que estavam na antiga
    s.updateGroup(Grupo(id: gid, name: 'Restaurante Arminda', categoryId: bar));
    expect(s.transactions.where((t) => t.categoryId == bar).length, 4);

    // tirar um título do grupo: mantém nome e categoria, mas deixa de acompanhar o grupo
    final r1 = s.rulesOfGroup(gid).firstWhere((r) => r.pattern == merchantKey(t1));
    s.removeFromGroup(r1.id);
    expect(s.ruleFor(merchantKey(t1))!.groupId, isNull);
    expect(s.ruleFor(merchantKey(t1))!.label, 'Restaurante Arminda');
    expect(s.ruleFor(merchantKey(t1))!.categoryId, bar);
    expect(s.rulesOfGroup(gid).length, 2);

    // apagar o grupo dissolve-o sem perder nomes
    s.deleteGroup(gid);
    expect(s.groups, isEmpty);
    expect(s.ruleFor(merchantKey(t2))!.label, 'Restaurante Arminda');
    expect(s.ruleFor(merchantKey(t2))!.groupId, isNull);
  });
}
