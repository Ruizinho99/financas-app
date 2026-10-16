import 'package:financas/db/database.dart';
import 'package:financas/recurring/recurring.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

RecurringRule _rule({
  int? id,
  String description = 'Renda',
  int amount = -80000,
  RecurrenceFreq freq = RecurrenceFreq.monthly,
  int day = 10,
  required DateTime start,
  DateTime? end,
  bool active = true,
  int? accountId,
}) => RecurringRule(
  id: id,
  description: description,
  amount: amount,
  freq: freq,
  day: day,
  start: start,
  end: end,
  active: active,
  accountId: accountId,
);

void main() {
  test('despesa fica negativa e receita positiva, com source recurring', () {
    final s = AppState(Db.memory());
    s.saveRecurring(
      _rule(description: 'Renda', amount: -80000, start: DateTime(2026, 1, 10)),
    );
    s.saveRecurring(
      _rule(
        description: 'Salário',
        amount: 150000,
        start: DateTime(2026, 1, 10),
      ),
    );

    final criados = s.generateRecurring(today: DateTime(2026, 2, 10));
    expect(criados, 4); // renda e salário, em 10/01 e 10/02

    final renda = s.transactions.where((t) => t.description == 'Renda');
    final salario = s.transactions.where((t) => t.description == 'Salário');
    expect(renda.every((t) => t.amount == -80000), isTrue);
    expect(salario.every((t) => t.amount == 150000), isTrue);
    expect(s.transactions.every((t) => t.source == 'recurring'), isTrue);
  });

  test('movimento fica ligado à conta da regra', () {
    final s = AppState(Db.memory());
    final conta = s.addAccount('Banco');
    s.saveRecurring(_rule(start: DateTime(2026, 1, 10), accountId: conta));
    s.generateRecurring(today: DateTime(2026, 1, 10));
    expect(s.transactions.single.accountId, conta);
  });

  test('idempotente: duas execuções no mesmo dia não duplicam nada', () {
    final s = AppState(Db.memory());
    s.saveRecurring(_rule(start: DateTime(2026, 1, 10)));
    final hoje = DateTime(2026, 3, 15);

    expect(s.generateRecurring(today: hoje), 3);
    expect(s.transactions.length, 3);
    expect(s.generateRecurring(today: hoje), 0);
    expect(s.transactions.length, 3);
  });

  test('a execução seguinte só cria as datas novas', () {
    final s = AppState(Db.memory());
    s.saveRecurring(_rule(start: DateTime(2026, 1, 10)));
    s.generateRecurring(today: DateTime(2026, 2, 10));
    expect(s.generateRecurring(today: DateTime(2026, 3, 9)), 0);
    expect(s.generateRecurring(today: DateTime(2026, 3, 10)), 1);
    expect(s.transactions.length, 3);
  });

  test(
    'a última data gerada fica gravada e volta a ler-se da base de dados',
    () {
      final db = Db.memory();
      final s = AppState(db);
      s.saveRecurring(_rule(start: DateTime(2026, 1, 10)));
      s.generateRecurring(today: DateTime(2026, 2, 10));
      final reaberta = AppState(db);
      expect(
        reaberta.recurringRules.single.lastGenerated,
        DateTime(2026, 2, 10),
      );
    },
  );

  test('regra pausada não gera; ao reativar não recria os meses parados', () {
    final s = AppState(Db.memory());
    s.saveRecurring(_rule(start: DateTime(2026, 1, 10), active: false));
    expect(s.generateRecurring(today: DateTime(2026, 3, 20)), 0);
    expect(s.transactions, isEmpty);

    final parada = s.recurringRules.single;
    s.saveRecurring(
      _rule(id: parada.id, start: parada.start, active: true),
      today: DateTime(2026, 3, 20),
    );
    // jan, fev e mar ficaram para trás: só abril em diante
    expect(s.generateRecurring(today: DateTime(2026, 3, 20)), 0);
    expect(s.generateRecurring(today: DateTime(2026, 4, 10)), 1);
    expect(s.transactions.single.date, DateTime(2026, 4, 10));
  });

  test('apagar a regra mantém os movimentos já criados', () {
    final s = AppState(Db.memory());
    s.saveRecurring(_rule(start: DateTime(2026, 1, 10)));
    s.generateRecurring(today: DateTime(2026, 2, 10));
    s.deleteRecurring(s.recurringRules.single.id!);
    expect(s.recurringRules, isEmpty);
    expect(s.transactions.length, 2);
    expect(s.transactions.every((t) => t.source == 'recurring'), isTrue);
  });

  test('no máximo 24 movimentos por execução; as seguintes continuam', () {
    final s = AppState(Db.memory());
    s.saveRecurring(_rule(day: 1, start: DateTime(2020, 1, 1)));
    final hoje = DateTime(2026, 10, 16);
    expect(s.generateRecurring(today: hoje), maxRecurringPerRun);
    expect(s.transactions.length, 24);
    expect(s.generateRecurring(today: hoje), maxRecurringPerRun);
    expect(s.transactions.length, 48);
  });
}
