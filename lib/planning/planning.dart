/// Despesa planeada para um mês (AAAA-MM): um valor concreto numa categoria ou subcategoria,
/// marcada como obrigatória (renda, luz…) ou opcional (lazer, subscrições…).
class PlannedItem {
  final int id;
  final String month;
  final int categoryId;
  final int cents; // valor absoluto
  final bool mandatory;
  const PlannedItem({
    required this.id,
    required this.month,
    required this.categoryId,
    required this.cents,
    required this.mandatory,
  });
}

/// Totais de um mês: o que se planeou face ao salário.
class PlanTotals {
  final int salary;
  final int mandatory;
  final int optional;
  const PlanTotals(this.salary, this.mandatory, this.optional);

  int get planned => mandatory + optional;

  /// Por planear: salário menos o planeado. Negativo = o plano excede o salário.
  int get left => salary - planned;
}

PlanTotals planTotals(int salary, Iterable<PlannedItem> items) {
  var m = 0, o = 0;
  for (final i in items) {
    if (i.mandatory) {
      m += i.cents;
    } else {
      o += i.cents;
    }
  }
  return PlanTotals(salary, m, o);
}
