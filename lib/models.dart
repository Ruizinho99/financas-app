enum BudgetType { limit, goal }

class Categoria {
  final int id;
  final String name;
  final int? parentId;
  final bool mandatory; // obrigatória (despesa mensal fixa/necessária) vs opcional
  final bool isIncome;
  final int color; // ARGB
  final String description;
  final BudgetType budgetType;
  final bool budgetPercent; // true: % do salário; false: valor em cêntimos
  final int budgetValue; // cêntimos ou percentagem*100 (ex.: 2500 = 25,00%)
  final bool hasBudget;
  final bool archived;

  const Categoria({
    required this.id,
    required this.name,
    this.parentId,
    this.mandatory = false,
    this.isIncome = false,
    this.color = 0xFF607D8B,
    this.description = '',
    this.budgetType = BudgetType.limit,
    this.budgetPercent = false,
    this.budgetValue = 0,
    this.hasBudget = false,
    this.archived = false,
  });

  /// Alocação mensal em cêntimos dado o salário líquido.
  int monthlyTarget(int salaryCents) =>
      !hasBudget ? 0 : (budgetPercent ? (salaryCents * budgetValue / 10000).round() : budgetValue);
}

class Txn {
  final int id;
  final DateTime date;
  final String description;
  final int amount; // cêntimos; negativo = saída
  final int? balance;
  final int? categoryId;
  final String note;
  final String source; // pdf | csv | xlsx | manual
  final String merchantKey;
  final int? importId;

  const Txn({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    this.balance,
    this.categoryId,
    this.note = '',
    this.source = 'manual',
    required this.merchantKey,
    this.importId,
  });
}

class Rule {
  final int id;
  final String pattern; // chave normalizada
  final bool exact; // exacta ou "contém"
  final int categoryId;
  final String label; // nome amigável
  final String note;
  const Rule({
    required this.id,
    required this.pattern,
    required this.exact,
    required this.categoryId,
    this.label = '',
    this.note = '',
  });
}

/// Movimento lido de um ficheiro, antes de ser guardado.
class ParsedRow {
  DateTime date;
  String description;
  int amount;
  int? balance;
  ParsedRow(this.date, this.description, this.amount, [this.balance]);
}

/// Grupo de movimentos com a mesma chave (cartão na aba Classificar).
class TxnGroup {
  final String key;
  final List<Txn> txns;
  TxnGroup(this.key, this.txns);
  int get total => txns.fold(0, (s, t) => s + t.amount);
  String get sampleDescription => txns.first.description;
}
