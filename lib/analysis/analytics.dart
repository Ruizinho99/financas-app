import 'dart:math' as math;

import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';

const Object _k = Object();

enum SpendType { all, mandatory, optional }

/// Filtros da Análise. Aplicam-se às despesas (as transferências entre contas nunca contam).
class AnalysisFilter {
  final SpendType type;
  final Set<int> categoryIds; // categorias e/ou subcategorias; uma categoria inclui as suas subcategorias
  final Set<int> accountIds;
  final String query;
  final int? minCents; // valor absoluto do movimento
  final int? maxCents;
  const AnalysisFilter({
    this.type = SpendType.all,
    this.categoryIds = const {},
    this.accountIds = const {},
    this.query = '',
    this.minCents,
    this.maxCents,
  });

  int get activeCount =>
      (type != SpendType.all ? 1 : 0) +
      (categoryIds.isNotEmpty ? 1 : 0) +
      (accountIds.isNotEmpty ? 1 : 0) +
      (query.trim().isNotEmpty ? 1 : 0) +
      (minCents != null || maxCents != null ? 1 : 0);
  bool get isActive => activeCount > 0;

  AnalysisFilter copyWith({
    SpendType? type,
    Set<int>? categoryIds,
    Set<int>? accountIds,
    String? query,
    Object? minCents = _k,
    Object? maxCents = _k,
  }) =>
      AnalysisFilter(
        type: type ?? this.type,
        categoryIds: categoryIds ?? this.categoryIds,
        accountIds: accountIds ?? this.accountIds,
        query: query ?? this.query,
        minCents: identical(minCents, _k) ? this.minCents : minCents as int?,
        maxCents: identical(maxCents, _k) ? this.maxCents : maxCents as int?,
      );
}

/// Despesa enriquecida (valor positivo).
class Spend {
  final Txn t;
  final Categoria? cat;
  final bool mandatory;
  const Spend(this.t, this.cat, this.mandatory);
  int get amount => -t.amount;
  String get month => monthKey(t.date);
}

/// Uma fatia de gastos (categoria, subcategoria, comerciante ou conta).
class Slice {
  final String key;
  final String label;
  final String? subtitle;
  final String emoji;
  final int amount;
  final int prev; // mesmo item no período anterior
  final List<Spend> items;
  final int? categoryId; // para filtrar/abrir a categoria
  const Slice({required this.key, required this.label, this.subtitle, this.emoji = '', required this.amount, required this.prev, required this.items, this.categoryId});
  int get count => items.length;
  int get avg => items.isEmpty ? 0 : (amount / items.length).round();
}

class MonthPoint {
  final DateTime month;
  final int spent, mandatory, optional, unclassified, income;
  const MonthPoint(this.month, this.spent, this.mandatory, this.optional, this.unclassified, this.income);
  int get balance => income - spent;
  double? get savingsRate => income > 0 ? balance / income : null;
}

class Recurring {
  final String label;
  final String emoji;
  final int monthly; // valor típico (mediana)
  final int months; // em quantos meses apareceu
  final DateTime last;
  final bool mandatory; // despesa obrigatória (renda, luz…): não se corta, ao contrário de uma subscrição
  const Recurring(this.label, this.emoji, this.monthly, this.months, this.last, {this.mandatory = false});
  int get yearly => monthly * 12;
}

enum InsightKind { overBudget, increase, topOptional, smallFrequent, recurring, unclassified }

class Insight {
  final InsightKind kind;
  final String title;
  final String detail;
  final int? monthlySaving; // poupança potencial por mês (null = informativo)
  final int? categoryId; // para o botão "ver categoria"
  const Insight(this.kind, this.title, this.detail, {this.monthlySaving, this.categoryId});
}

class Projection {
  final int elapsedDays, totalDays, spent, projected;
  final int? budget;
  const Projection(this.elapsedDays, this.totalDays, this.spent, this.projected, this.budget);
}

/// Período imediatamente anterior, para comparar (mês → mês anterior; ano/YTD → mesmo intervalo
/// do ano anterior; intervalo livre → o intervalo anterior com a mesma duração).
/// Se o período ainda está a decorrer (ex.: estamos no dia 2 do mês), compara só os mesmos dias do
/// período anterior, para não comparar 2 dias com um mês inteiro.
Period previousPeriod(Period p, {DateTime? today}) {
  Period prev;
  final wholeMonths = p.start.day == 1 && p.end.day == 1;
  if (wholeMonths) {
    final n = p.monthCount;
    prev = Period(DateTime(p.start.year, p.start.month - n), DateTime(p.end.year, p.end.month - n));
  } else if (p.start.month == 1 && p.start.day == 1) {
    prev = Period(DateTime(p.start.year - 1), DateTime(p.end.year - 1, p.end.month, p.end.day));
  } else {
    final days = DateTime.utc(p.end.year, p.end.month, p.end.day).difference(DateTime.utc(p.start.year, p.start.month, p.start.day)).inDays;
    prev = Period(DateTime(p.start.year, p.start.month, p.start.day - days), DateTime(p.start.year, p.start.month, p.start.day));
  }
  final t = today ?? DateTime.now();
  final ongoing = p.contains(t) && DateTime(t.year, t.month, t.day + 1).isBefore(p.end);
  if (ongoing) {
    final elapsed = DateTime.utc(t.year, t.month, t.day).difference(DateTime.utc(p.start.year, p.start.month, p.start.day)).inDays + 1;
    final cut = DateTime(prev.start.year, prev.start.month, prev.start.day + elapsed);
    if (cut.isBefore(prev.end)) return Period(prev.start, cut);
  }
  return prev;
}

/// Cálculos da Análise para um período, com filtros. Sem Flutter: só dados.
class Analytics {
  final AppState s;
  final Period period;
  final AnalysisFilter filter;
  final Period? previous;
  final DateTime today;
  Analytics(this.s, this.period, this.filter, {this.previous, DateTime? today}) : today = today ?? DateTime.now();

  // ---------- base ----------
  List<Spend> _spends(Period p) {
    final out = <Spend>[];
    for (final t in s.transactions) {
      if (!p.contains(t.date) || t.isTransfer || t.amount >= 0) continue;
      final c = s.cat(t.categoryId);
      if (c != null && c.isIncome) continue;
      final mand = c != null && s.isMandatory(c, monthKey(t.date));
      if (_matches(t, c, mand)) out.add(Spend(t, c, mand));
    }
    return out;
  }

  bool _matches(Txn t, Categoria? c, bool mand) {
    final f = filter;
    if (f.type == SpendType.mandatory && !mand) return false;
    if (f.type == SpendType.optional && (mand || c == null)) return false;
    if (f.categoryIds.isNotEmpty) {
      if (c == null) return false;
      if (!f.categoryIds.contains(c.id) && !(c.parentId != null && f.categoryIds.contains(c.parentId))) return false;
    }
    if (f.accountIds.isNotEmpty && (t.accountId == null || !f.accountIds.contains(t.accountId))) return false;
    final a = -t.amount;
    if (f.minCents != null && a < f.minCents!) return false;
    if (f.maxCents != null && a > f.maxCents!) return false;
    final q = f.query.trim().toLowerCase();
    if (q.isNotEmpty) {
      final hay = '${s.displayName(t)} ${t.description} ${t.note} ${s.path(t.categoryId)} ${s.account(t.accountId)?.name ?? ''}'.toLowerCase();
      if (!hay.contains(q)) return false;
    }
    return true;
  }

  late final List<Spend> spends = _spends(period);
  late final List<Spend> prevSpends = previous == null ? const [] : _spends(previous!);

  int _sum(Iterable<Spend> l) => l.fold(0, (a, e) => a + e.amount);

  late final int spent = _sum(spends);
  late final int prevSpent = _sum(prevSpends);

  /// Dinheiro enviado para plataformas de investimento no período (entregas menos levantamentos).
  late final int invested = s.investedIn(period);
  int get count => spends.length;
  int get avgTicket => spends.isEmpty ? 0 : (spent / spends.length).round();
  late final int mandatoryTotal = _sum(spends.where((e) => e.mandatory));
  late final int optionalTotal = _sum(spends.where((e) => !e.mandatory && e.cat != null));
  late final int unclassifiedTotal = _sum(spends.where((e) => e.cat == null));
  late final int prevMandatory = _sum(prevSpends.where((e) => e.mandatory));
  late final int prevOptional = _sum(prevSpends.where((e) => !e.mandatory && e.cat != null));

  /// Quantos meses (fracionados) o período tem – base das médias mensais.
  late final double monthsFactor = math.max(0.05, period.monthWeights.fold(0.0, (a, w) => a + w.$2));

  int perMonth(int cents) => (cents / monthsFactor).round();

  /// O período ainda está a decorrer (faltam dias até ao fim)?
  bool get ongoing => period.contains(today) && DateTime(today.year, today.month, today.day + 1).isBefore(period.end);

  int get daysElapsed {
    final end = DateTime.utc(period.end.year, period.end.month, period.end.day);
    final t = DateTime.utc(today.year, today.month, today.day + 1);
    final stop = end.isBefore(t) ? end : t;
    return math.max(1, stop.difference(DateTime.utc(period.start.year, period.start.month, period.start.day)).inDays);
  }

  int get dailyAvg => (spent / daysElapsed).round();

  // ---------- rendimentos / saldo ----------
  int _income(Period p) {
    var total = 0;
    for (final t in s.transactions) {
      if (!p.contains(t.date) || t.isTransfer || t.amount <= 0) continue;
      if (!(s.cat(t.categoryId)?.isIncome ?? false)) continue;
      if (filter.accountIds.isNotEmpty && (t.accountId == null || !filter.accountIds.contains(t.accountId))) continue;
      total += t.amount;
    }
    return total;
  }

  /// Rendimento do período:
  ///  - período terminado: o recebido; se não houver nenhum categorizado, o salário líquido definido;
  ///  - período em curso: o salário esperado do mês inteiro (se definido), senão o recebido até hoje —
  ///    assim a taxa de poupança não parece enorme só porque o salário ainda não entrou.
  int _incomeFor(Period shown, Period full) {
    final received = _income(shown);
    final salary = s.salaryIn(full);
    if (ongoing) return salary > 0 ? (received > salary ? received : salary) : received;
    return received > 0 ? received : salary;
  }

  /// Período anterior completo (sem o corte dos "mesmos dias"), para o salário esperado.
  late final Period? _previousFull = previous == null ? null : previousPeriod(period, today: DateTime(1900));

  late final int incomeReceived = _income(period);
  late final bool incomeFromSalary = incomeReceived == 0 && s.salaryIn(period) > 0;
  late final int income = _incomeFor(period, period);
  late final int prevIncome = previous == null ? 0 : _incomeFor(previous!, _previousFull!);
  int get balance => income - spent;
  int get prevBalance => prevIncome - prevSpent;
  double? get savingsRate => income > 0 ? balance / income : null;
  double? get prevSavingsRate => prevIncome > 0 ? prevBalance / prevIncome : null;

  // ---------- onde gasto ----------
  static const _none = '-';

  List<Slice> _slices(String Function(Spend) keyOf, Slice Function(String key, List<Spend> cur, int prev) build) {
    final cur = <String, List<Spend>>{};
    for (final e in spends) {
      cur.putIfAbsent(keyOf(e), () => []).add(e);
    }
    final prev = <String, int>{};
    for (final e in prevSpends) {
      final k = keyOf(e);
      prev[k] = (prev[k] ?? 0) + e.amount;
    }
    final out = [for (final en in cur.entries) build(en.key, en.value, prev[en.key] ?? 0)];
    out.sort((a, b) => b.amount.compareTo(a.amount));
    return out;
  }

  /// Por categoria principal (inclui as subcategorias).
  List<Slice> byCategory() => _slices(
        (e) => e.cat == null ? _none : '${e.cat!.parentId ?? e.cat!.id}',
        (k, l, prev) {
          final root = k == _none ? null : s.cat(int.parse(k));
          return Slice(
            key: k,
            label: root?.name ?? 'Sem categoria',
            emoji: root?.emoji ?? '',
            amount: _sum(l),
            prev: prev,
            items: l,
            categoryId: root?.id,
          );
        },
      );

  /// Por subcategoria (ou categoria, quando o movimento não tem subcategoria).
  List<Slice> bySubcategory() => _slices(
        (e) => e.cat == null ? _none : '${e.cat!.id}',
        (k, l, prev) {
          final c = k == _none ? null : s.cat(int.parse(k));
          final parent = s.cat(c?.parentId);
          return Slice(
            key: k,
            label: c?.name ?? 'Sem categoria',
            subtitle: parent?.name,
            emoji: c?.emoji.isNotEmpty == true ? c!.emoji : (parent?.emoji ?? ''),
            amount: _sum(l),
            prev: prev,
            items: l,
            categoryId: c?.id,
          );
        },
      );

  String _merchantKey(Txn t) {
    final r = s.ruleFor(t.merchantKey);
    return r?.groupId != null ? 'g${r!.groupId}' : t.merchantKey;
  }

  /// Por comerciante / título (os grupos de títulos contam como um só).
  List<Slice> byMerchant() => _slices(
        (e) => _merchantKey(e.t),
        (k, l, prev) => Slice(
          key: k,
          label: s.displayName(l.first.t),
          subtitle: l.first.cat == null ? null : s.path(l.first.cat!.id),
          emoji: l.first.cat?.emoji ?? '',
          amount: _sum(l),
          prev: prev,
          items: l,
          categoryId: l.first.cat?.id,
        ),
      );

  List<Slice> byAccount() => _slices(
        (e) => '${e.t.accountId ?? _none}',
        (k, l, prev) {
          final a = k == _none ? null : s.account(int.parse(k));
          return Slice(key: k, label: a?.name ?? 'Sem conta', emoji: a?.emoji ?? '', amount: _sum(l), prev: prev, items: l);
        },
      );

  /// Total e número de movimentos por dia da semana (0 = segunda … 6 = domingo).
  ({List<int> totals, List<int> counts}) byWeekday() {
    final totals = List<int>.filled(7, 0), counts = List<int>.filled(7, 0);
    for (final e in spends) {
      final i = e.t.date.weekday - 1;
      totals[i] += e.amount;
      counts[i]++;
    }
    return (totals: totals, counts: counts);
  }

  List<Spend> largest([int n = 5]) => ([...spends]..sort((a, b) => b.amount.compareTo(a.amount))).take(n).toList();

  // ---------- evolução ----------
  /// Pontos mensais dos últimos [n] meses até ao fim do período, com os mesmos filtros.
  List<MonthPoint> monthly(int n) {
    final last = DateTime(period.end.year, period.end.month, period.end.day - 1);
    final first = DateTime(last.year, last.month - (n - 1));
    final all = _spends(Period(DateTime(first.year, first.month), DateTime(last.year, last.month + 1)));
    final out = <MonthPoint>[];
    for (var i = 0; i < n; i++) {
      final m = DateTime(first.year, first.month + i);
      final mk = monthKey(m);
      final l = all.where((e) => e.month == mk);
      final inc = _income(Period.month(m));
      out.add(MonthPoint(
        m,
        _sum(l),
        _sum(l.where((e) => e.mandatory)),
        _sum(l.where((e) => !e.mandatory && e.cat != null)),
        _sum(l.where((e) => e.cat == null)),
        inc > 0 ? inc : s.salaryFor(mk),
      ));
    }
    return out;
  }

  // ---------- poupar ----------
  /// Pagamentos que se repetem todos os meses (assinaturas, rendas, tarifários…): aparecem em pelo
  /// menos 3 dos últimos 6 meses com valor parecido.
  List<Recurring> recurring() {
    final end = period.end;
    final from = DateTime(end.year, end.month - 6, end.day);
    final hist = _spends(Period(from, end));
    final groups = <String, List<Spend>>{};
    for (final e in hist) {
      groups.putIfAbsent(_merchantKey(e.t), () => []).add(e);
    }
    final out = <Recurring>[];
    for (final l in groups.values) {
      final months = l.map((e) => e.month).toSet();
      if (months.length < 3 || l.length > months.length * 1.5) continue;
      final vals = l.map((e) => e.amount).toList()..sort();
      final median = vals[vals.length ~/ 2];
      final close = vals.where((v) => (v - median).abs() <= median * 0.25).length;
      if (close < vals.length * 0.7) continue;
      final last = l.map((e) => e.t.date).reduce((a, b) => a.isAfter(b) ? a : b);
      final latest = l.reduce((a, b) => a.t.date.isAfter(b.t.date) ? a : b);
      out.add(Recurring(s.displayName(l.first.t), l.first.cat?.emoji ?? '', median, months.length, last, mandatory: latest.mandatory));
    }
    // opcionais primeiro (são os que se podem cancelar), depois por valor
    out.sort((a, b) {
      if (a.mandatory != b.mandatory) return a.mandatory ? 1 : -1;
      return b.monthly.compareTo(a.monthly);
    });
    return out;
  }

  /// Pequenas compras que se repetem muito (cafés, snacks…).
  List<Slice> frequentSmall() => byMerchant().where((e) => e.count >= 6 && e.avg <= 2500).toList();

  /// Sugestões concretas, da maior para a menor poupança potencial.
  List<Insight> insights() {
    final out = <Insight>[];
    final usedCategories = <int>{};

    // 1) orçamentos de limite ultrapassados
    final own = s.totalsByCategory(period);
    for (final c in s.roots.where((c) => !c.isIncome)) {
      final target = s.targetIn(c, period);
      final spentC = s.rollup(c, own);
      final limitLike = c.budgetType == BudgetType.limit;
      if (target > 0 && limitLike && spentC > target) {
        usedCategories.add(c.id);
        out.add(Insight(
          InsightKind.overBudget,
          '${c.emoji.isEmpty ? '' : '${c.emoji} '}${c.name} acima do limite',
          'Gastaste ${fmtMoney(spentC)} para um limite de ${fmtMoney(target)}.',
          monthlySaving: perMonth(spentC - target),
          categoryId: c.id,
        ));
      }
    }

    // 2) categorias que subiram muito face ao período anterior
    if (previous != null) {
      for (final sl in byCategory()) {
        if (sl.categoryId == null || usedCategories.contains(sl.categoryId)) continue;
        final delta = sl.amount - sl.prev;
        if (sl.prev > 0 && delta >= 2000 && delta >= sl.prev * 0.25) {
          usedCategories.add(sl.categoryId!);
          out.add(Insight(
            InsightKind.increase,
            '${sl.emoji.isEmpty ? '' : '${sl.emoji} '}${sl.label} subiu ${fmtPercent(delta / sl.prev)}',
            'Mais ${fmtMoney(delta)} do que no período anterior (${fmtMoney(sl.prev)} → ${fmtMoney(sl.amount)}).',
            monthlySaving: perMonth(delta),
            categoryId: sl.categoryId,
          ));
        }
      }
    }

    // 3) as maiores despesas opcionais: cortar 10% já se nota
    final opt = byCategory().where((e) => e.categoryId != null && !usedCategories.contains(e.categoryId) && e.items.every((x) => !x.mandatory)).take(3);
    for (final sl in opt) {
      if (spent == 0 || sl.amount < spent * 0.05) continue;
      usedCategories.add(sl.categoryId!);
      out.add(Insight(
        InsightKind.topOptional,
        '${sl.emoji.isEmpty ? '' : '${sl.emoji} '}${sl.label}: ${fmtPercent(sl.amount / spent)} das despesas',
        'É uma despesa opcional. Cortar 10% poupava ${fmtMoney(perMonth((sl.amount * 0.1).round()))} por mês.',
        monthlySaving: perMonth((sl.amount * 0.1).round()),
        categoryId: sl.categoryId,
      ));
    }

    // 4) pequenas compras frequentes
    final small = frequentSmall();
    if (small.isNotEmpty) {
      final total = small.fold(0, (a, e) => a + e.amount);
      final n = small.fold(0, (a, e) => a + e.count);
      out.add(Insight(
        InsightKind.smallFrequent,
        'Pequenas compras frequentes',
        '$n compras em ${small.length} ${small.length == 1 ? 'sítio' : 'sítios'} somam ${fmtMoney(total)} (${small.take(3).map((e) => e.label).join(', ')}). Reduzir um terço poupava ${fmtMoney(perMonth((total / 3).round()))} por mês.',
        monthlySaving: perMonth((total / 3).round()),
      ));
    }

    // 5) pagamentos recorrentes opcionais (subscrições, ginásio…) – informativo
    final rec = recurring().where((e) => !e.mandatory).toList();
    if (rec.isNotEmpty) {
      final monthly = rec.fold(0, (a, e) => a + e.monthly);
      out.add(Insight(
        InsightKind.recurring,
        '${rec.length} ${rec.length == 1 ? 'pagamento recorrente opcional' : 'pagamentos recorrentes opcionais'}',
        'Somam ${fmtMoney(monthly)} por mês (${fmtMoney(monthly * 12)} por ano). Vê se ainda precisas de todos.',
      ));
    }

    // 6) sem categoria
    if (unclassifiedTotal > 0) {
      out.add(Insight(
        InsightKind.unclassified,
        'Despesas sem categoria',
        '${fmtMoney(unclassifiedTotal)} por classificar. Quanto mais classificado, mais certeiras são as sugestões.',
      ));
    }

    out.sort((a, b) => (b.monthlySaving ?? -1).compareTo(a.monthlySaving ?? -1));
    return out;
  }

  /// Poupança potencial por mês (soma das sugestões com valor, sem repetir categorias).
  int get potentialMonthly => insights().fold(0, (a, e) => a + (e.monthlySaving ?? 0));

  /// Simulador: e se cortasse [percent] (0–1) das despesas opcionais?
  ({int monthly, int yearly, int total, double? newRate}) simulate(double percent) {
    final cut = (optionalTotal * percent).round();
    final base = income;
    return (
      monthly: perMonth(cut),
      yearly: perMonth(cut) * 12,
      total: cut,
      newRate: base > 0 ? (balance + cut) / base : null,
    );
  }

  /// Projeção até ao fim do mês corrente (só faz sentido quando o período é o mês atual).
  Projection? projection() {
    final start = period.start, end = period.end;
    final isMonth = start.day == 1 && end.day == 1 && period.monthCount == 1;
    if (!isMonth || !period.contains(today)) return null;
    final totalDays = DateTime.utc(end.year, end.month, end.day).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
    final elapsed = math.min(totalDays, math.max(1, today.day));
    final projected = (spent / elapsed * totalDays).round();
    final salary = s.salaryFor(monthKey(start));
    final budget = s.totalAllocated(salary, monthKey(start));
    return Projection(elapsed, totalDays, spent, projected, budget > 0 ? budget : null);
  }

  /// Estado do orçamento (não depende dos filtros).
  List<CategoryStat> budgetStats() {
    final own = s.totalsByCategory(period);
    final out = <CategoryStat>[];
    for (final c in s.roots.where((c) => !c.isIncome)) {
      final t = s.targetIn(c, period);
      if (t <= 0) continue;
      out.add(CategoryStat(c, s.rollup(c, own), t));
    }
    out.sort((a, b) => b.ratio.compareTo(a.ratio));
    return out;
  }
}
