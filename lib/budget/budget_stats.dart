import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';

/// Em que ponto está um orçamento no mês.
/// - [over]: passou o máximo; [below]: ficou abaixo do mínimo;
/// - [ok]: dentro do máximo ou mínimo atingido; [none]: sem orçamento definido.
enum BudgetState { over, below, ok, none }

/// Uma categoria principal com o seu gasto e orçamento no mês.
class CatBudget {
  final Categoria category;
  final int spent; // cêntimos gastos (com subcategorias), nunca negativo
  final int target; // orçamento do mês (0 = sem orçamento)
  final BudgetType type;
  final BudgetState state;
  const CatBudget(
    this.category,
    this.spent,
    this.target,
    this.type,
    this.state,
  );

  double get ratio => target <= 0 ? 0 : spent / target;
  bool get isMax => type == BudgetType.limit;

  /// Máximo quase esgotado (mas ainda dentro).
  bool get nearLimit => isMax && state == BudgetState.ok && ratio >= 0.85;
}

/// Resumo do mês: o que se gastou face ao que se orçamentou em máximos.
class BudgetSummary {
  final int spentBudgeted; // gasto nas categorias com máximo
  final int budgeted; // soma dos máximos
  final int
  unbudgetedSpent; // gasto em categorias sem orçamento (investimentos à parte)
  final int over, below, ok;
  const BudgetSummary({
    required this.spentBudgeted,
    required this.budgeted,
    required this.unbudgetedSpent,
    required this.over,
    required this.below,
    required this.ok,
  });
  int get left => budgeted - spentBudgeted;
}

/// Estado de um orçamento. O mínimo só conta como "em falta" a partir do início do mês.
BudgetState stateOf(
  BudgetType type,
  int spent,
  int target, {
  bool started = true,
}) {
  if (target <= 0) return BudgetState.none;
  if (type == BudgetType.limit) {
    return spent > target ? BudgetState.over : BudgetState.ok;
  }
  return started && spent < target ? BudgetState.below : BudgetState.ok;
}

/// Linhas do orçamento do mês [key] (só categorias que existem nele ou que tiveram movimentos).
List<CatBudget> budgetRows(
  AppState s,
  String key,
  int salary, {
  DateTime? today,
}) {
  final period = s.periodOfMonth(key);
  final own = s.totalsByCategory(period);
  final started = !(today ?? DateTime.now()).isBefore(period.start);
  final out = <CatBudget>[];
  for (final c in s.roots) {
    final spentRaw = s.rollup(c, own);
    if ((c.isIncome && !c.hasBudget && spentRaw == 0) ||
        (!s.isCategoryActive(c, key) && spentRaw == 0)) {
      continue;
    }
    final spent = spentRaw < 0 ? 0 : spentRaw;
    final target = s.effectiveMonthlyTarget(c, salary, key);
    final type = c.hasBudget
        ? c.budgetType
        : s
              .descendantsOf(c.id)
              .firstWhere((k) => k.hasBudget, orElse: () => c)
              .budgetType;
    out.add(
      CatBudget(
        c,
        spent,
        target,
        type,
        stateOf(type, spent, target, started: started),
      ),
    );
  }
  return out;
}

BudgetSummary summarize(AppState s, List<CatBudget> rows) {
  var spentB = 0, budgeted = 0, unb = 0, over = 0, below = 0, ok = 0;
  for (final r in rows) {
    switch (r.state) {
      case BudgetState.over:
        over++;
      case BudgetState.below:
        below++;
      case BudgetState.ok:
        ok++;
      case BudgetState.none:
    }
    if (r.target > 0 && r.isMax) {
      spentB += r.spent;
      budgeted += r.target;
    } else if (r.target == 0 && !r.category.isSetAside) {
      unb += r.spent;
    }
  }
  return BudgetSummary(
    spentBudgeted: spentB,
    budgeted: budgeted,
    unbudgetedSpent: unb,
    over: over,
    below: below,
    ok: ok,
  );
}

/// Fração do mês que já passou (0 a 1), ou nulo se o mês não está a decorrer.
double? paceOf(Period p, {DateTime? today}) {
  final t = today ?? DateTime.now();
  final d = DateTime(t.year, t.month, t.day);
  if (d.isBefore(p.start) || !d.isBefore(p.end)) return null;
  final total = p.end.difference(p.start).inDays;
  if (total <= 0) return null;
  return (d.difference(p.start).inDays + 1) / total;
}

/// Gasto da categoria nos [n] meses até [key] (inclusive), do mais antigo para o mais recente.
List<(String, int)> history(AppState s, Categoria c, String key, {int n = 6}) {
  final y = int.parse(key.substring(0, 4)), m = int.parse(key.substring(5, 7));
  final out = <(String, int)>[];
  for (var i = n - 1; i >= 0; i--) {
    final k = monthKey(DateTime(y, m - i));
    final v = s.rollup(c, s.totalsByCategory(s.periodOfMonth(k)));
    out.add((k, v < 0 ? 0 : v));
  }
  return out;
}

List<Map<int, int>>? _memoMonths;
Object? _memoTxns;
String? _memoKey;

/// Gasto de cada categoria nos [n] meses até [key]; guarda o resultado enquanto os movimentos
/// forem os mesmos (a lista do orçamento pede isto uma vez por linha).
List<Map<int, int>> monthTotals(AppState s, String key, {int n = 6}) {
  if (_memoMonths != null &&
      identical(_memoTxns, s.transactions) &&
      _memoKey == '$key|$n') {
    return _memoMonths!;
  }
  final y = int.parse(key.substring(0, 4)), m = int.parse(key.substring(5, 7));
  final out = [
    for (var i = n - 1; i >= 0; i--)
      s.totalsByCategory(s.periodOfMonth(monthKey(DateTime(y, m - i)))),
  ];
  _memoMonths = out;
  _memoTxns = s.transactions;
  _memoKey = '$key|$n';
  return out;
}

/// Gasto da categoria [c] em cada um dos meses de [monthTotals].
List<int> trendOf(AppState s, Categoria c, String key, {int n = 6}) => [
  for (final t in monthTotals(s, key, n: n)) () {
    final v = s.rollup(c, t);
    return v < 0 ? 0 : v;
  }(),
];

/// Previsão do gasto no fim do mês ao ritmo atual: gasto / fração do mês já passada.
/// Nulo se o mês não está a decorrer ou ainda não há gasto.
int? forecastEnd(int spent, double? pace) {
  if (pace == null || pace <= 0 || spent <= 0) return null;
  return (spent / pace).round();
}

/// Orçamento sugerido: média dos 3 meses anteriores, arredondada para cima aos 5 €;
/// se não houver histórico, o gasto deste mês. Nulo se não há nada a sugerir.
int? suggestBudget(AppState s, Categoria c, String key, int spentNow) {
  final y = int.parse(key.substring(0, 4)), m = int.parse(key.substring(5, 7));
  var total = 0;
  for (var i = 1; i <= 3; i++) {
    final k = monthKey(DateTime(y, m - i));
    final v = s.rollup(c, s.totalsByCategory(s.periodOfMonth(k)));
    total += v < 0 ? 0 : v;
  }
  var avg = (total / 3).round();
  if (avg <= 0) avg = spentNow;
  if (avg <= 0) return null;
  const step = 500;
  return ((avg + step - 1) ~/ step) * step;
}
