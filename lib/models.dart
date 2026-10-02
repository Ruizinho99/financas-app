enum BudgetType { limit, goal }

class Categoria {
  final int id;
  final String name;
  final int? parentId;
  final bool isIncome;
  final String emoji; // ícone da categoria (um emoji); vazio = sem ícone
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
    this.isIncome = false,
    this.emoji = '',
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
  final int? accountId;
  final bool isTransfer; // transferência entre contas: fora das despesas/receitas
  final String? receiptPath; // nome do ficheiro do recibo (na pasta de recibos da app)

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
    this.accountId,
    this.isTransfer = false,
    this.receiptPath,
  });
}

/// Conta bancária / carteira onde o movimento aconteceu.
class Conta {
  final int id;
  final String name;
  final String emoji;
  const Conta({required this.id, required this.name, this.emoji = ''});
}

class Rule {
  final int id;
  final String pattern; // chave normalizada
  final bool exact; // exacta ou "contém"
  final int? categoryId; // pode ser nulo: regra só com nome amigável
  final String label; // nome amigável
  final String note;
  final int? groupId; // se pertence a um grupo, categoryId/label/note vêm do grupo
  const Rule({
    required this.id,
    required this.pattern,
    required this.exact,
    this.categoryId,
    this.label = '',
    this.note = '',
    this.groupId,
  });
}

/// Grupo: vários títulos de movimentos que representam a mesma coisa
/// (ex.: "TRANS RESTAURANTE ARMINDA" e "MB WAY RESTAURANTE ARMINDA" → "Restaurante Arminda").
class Grupo {
  final int id;
  final String name;
  final int? categoryId;
  final String note;
  const Grupo({required this.id, required this.name, this.categoryId, this.note = ''});
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
  final String key; // identificador do cartão (chave do título ou "g<id>" se for um grupo)
  final List<Txn> txns;
  final int? groupId;
  TxnGroup(this.key, this.txns, {this.groupId});
  /// Chave normalizada do primeiro título (para procurar a regra).
  String get rep => txns.first.merchantKey;
  Set<String> get keys => {for (final t in txns) t.merchantKey};
  int get total => txns.fold(0, (s, t) => s + t.amount);
  String get sampleDescription => txns.first.description;
}

/// Período em que uma categoria conta como "obrigatória" (despesa que existe nesses meses).
/// [end] nulo = sem fim. Meses no formato AAAA-MM.
class MandatoryRange {
  final int id;
  final int categoryId;
  final String start;
  final String? end;
  const MandatoryRange({required this.id, required this.categoryId, required this.start, this.end});
  bool covers(String month) => month.compareTo(start) >= 0 && (end == null || month.compareTo(end!) <= 0);
}
