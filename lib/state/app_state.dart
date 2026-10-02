import 'package:flutter/material.dart';

import '../db/database.dart';
import '../import/parsers.dart';
import '../models.dart';
import '../util/format.dart';

/// Período de análise: um mês, um ano, o ano até hoje (YTD) ou um intervalo de datas.
class Period {
  final DateTime start; // inclusivo
  final DateTime end; // exclusivo
  const Period(this.start, this.end);

  static DateTime _u(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  /// Número de meses que o período toca (um mês parcial conta como um).
  int get monthCount {
    final last = _u(end).subtract(const Duration(days: 1));
    return (last.year - start.year) * 12 + last.month - start.month + 1;
  }

  /// Cada mês tocado com o peso (fração dos dias do mês que estão dentro do período).
  /// Meses completos pesam 1; num intervalo/YTD o último mês pesa só os dias decorridos.
  List<(DateTime, double)> get monthWeights {
    final out = <(DateTime, double)>[];
    for (var i = 0; i < monthCount; i++) {
      final m = DateTime(start.year, start.month + i);
      final next = DateTime(m.year, m.month + 1);
      final from = _u(start).isAfter(_u(m)) ? _u(start) : _u(m);
      final to = _u(end).isBefore(_u(next)) ? _u(end) : _u(next);
      final days = to.difference(from).inDays;
      final inMonth = _u(next).difference(_u(m)).inDays;
      out.add((m, days <= 0 ? 0 : days / inMonth));
    }
    return out;
  }

  bool contains(DateTime d) => !d.isBefore(start) && d.isBefore(end);

  static Period month(DateTime d) => Period(DateTime(d.year, d.month), DateTime(d.year, d.month + 1));
  static Period year(int y) => Period(DateTime(y), DateTime(y + 1));
  static Period years(int from, int to) => Period(DateTime(from), DateTime(to + 1));

  /// 1 de janeiro até hoje (inclusive).
  static Period ytd([DateTime? today]) {
    final t = today ?? DateTime.now();
    return Period(DateTime(t.year), DateTime(t.year, t.month, t.day + 1));
  }

  /// Intervalo de dias, ambos inclusivos.
  static Period custom(DateTime from, DateTime to) {
    final a = from.isBefore(to) ? from : to, b = from.isBefore(to) ? to : from;
    return Period(DateTime(a.year, a.month, a.day), DateTime(b.year, b.month, b.day + 1));
  }
}

class CategoryStat {
  final Categoria category;
  final int spent; // cêntimos, valor positivo (despesa) ou entrada (rendimentos)
  final int target; // alocação no período
  const CategoryStat(this.category, this.spent, this.target);

  double get ratio => target <= 0 ? 0 : spent / target;
}

class AppState extends ChangeNotifier {
  final Db db;
  AppState(this.db) {
    reload();
  }

  List<Categoria> categories = [];
  List<Txn> transactions = [];
  List<Rule> rules = [];
  List<Grupo> groups = [];
  List<MandatoryRange> mandatoryRanges = [];
  Map<String, int> salaries = {};
  int defaultSalary = 0;

  void reload() {
    categories = db.categories();
    transactions = db.transactions();
    rules = db.rules();
    groups = db.ruleGroups();
    mandatoryRanges = db.mandatoryRanges();
    salaries = db.salaries();
    defaultSalary = int.tryParse(db.setting('default_salary') ?? '') ?? 0;
    themeMode = ThemeMode.values.firstWhere((m) => m.name == db.setting('theme_mode'), orElse: () => ThemeMode.system);
    seedColor = int.tryParse(db.setting('seed_color') ?? '') ?? 0xFF2E7D6B;
    amoled = db.setting('amoled') == '1';
    incomeColor = int.tryParse(db.setting('income_color') ?? '') ?? 0xFF43A047;
    expenseColor = int.tryParse(db.setting('expense_color') ?? '') ?? 0xFFE53935;
    notifyListeners();
  }

  // ---------- Aparência ----------
  ThemeMode themeMode = ThemeMode.system;
  int seedColor = 0xFF2E7D6B;
  bool amoled = false;
  int incomeColor = 0xFF43A047;
  int expenseColor = 0xFFE53935;

  void setAppearance({ThemeMode? mode, int? seed, bool? amoledBlack, int? income, int? expense}) {
    if (mode != null) db.putSetting('theme_mode', mode.name);
    if (seed != null) db.putSetting('seed_color', seed.toString());
    if (amoledBlack != null) db.putSetting('amoled', amoledBlack ? '1' : '0');
    if (income != null) db.putSetting('income_color', income.toString());
    if (expense != null) db.putSetting('expense_color', expense.toString());
    reload();
  }

  void resetAppearance() {
    for (final k in ['theme_mode', 'seed_color', 'amoled', 'income_color', 'expense_color']) {
      db.deleteSetting(k);
    }
    reload();
  }

  // ---------- Obrigatoriedade por mês ----------
  /// Uma categoria é obrigatória num mês se ela (ou a mãe) tiver um período que o cobre.
  bool isMandatory(Categoria c, String month, {bool inherit = true}) {
    bool own(int id) => mandatoryRanges.any((r) => r.categoryId == id && r.covers(month));
    if (own(c.id)) return true;
    return inherit && c.parentId != null && own(c.parentId!);
  }

  bool isMandatoryDirect(Categoria c, String month) => isMandatory(c, month, inherit: false);

  List<MandatoryRange> rangesOf(int categoryId) => mandatoryRanges.where((r) => r.categoryId == categoryId).toList();

  void addRange(int categoryId, String start, String? end) {
    db.addMandatoryRange(categoryId, start, end);
    reload();
  }

  void removeRange(int id) {
    db.deleteMandatoryRange(id);
    reload();
  }

  static String _shift(String month, int delta) {
    final y = int.parse(month.substring(0, 4)), m = int.parse(month.substring(5, 7));
    return monthKey(DateTime(y, m + delta));
  }

  /// Marca/desmarca a categoria como obrigatória só num mês, dividindo períodos existentes.
  void setMandatoryInMonth(int categoryId, String month, bool value) {
    final own = rangesOf(categoryId);
    if (value) {
      if (!own.any((r) => r.covers(month))) db.addMandatoryRange(categoryId, month, month);
    } else {
      for (final r in own.where((r) => r.covers(month))) {
        db.deleteMandatoryRange(r.id);
        if (r.start.compareTo(month) < 0) db.addMandatoryRange(categoryId, r.start, _shift(month, -1));
        if (r.end == null || r.end!.compareTo(month) > 0) db.addMandatoryRange(categoryId, _shift(month, 1), r.end);
      }
    }
    reload();
  }

  /// Despesa por categoria dividida em obrigatória / opcional, conforme o mês de cada movimento.
  ({Map<int, int> mandatory, Map<int, int> optional, int unclassified}) mandatorySplit(Period p) {
    final mand = <int, int>{}, opt = <int, int>{};
    var unclassified = 0;
    for (final t in txnsIn(p)) {
      if (t.amount >= 0) continue;
      final c = cat(t.categoryId);
      if (c == null) {
        unclassified += -t.amount;
        continue;
      }
      if (c.isIncome) continue;
      final target = isMandatory(c, monthKey(t.date)) ? mand : opt;
      target[c.id] = (target[c.id] ?? 0) - t.amount;
    }
    return (mandatory: mand, optional: opt, unclassified: unclassified);
  }

  // ---------- Consultas ----------
  Categoria? cat(int? id) {
    if (id == null) return null;
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  List<Categoria> get roots => categories.where((c) => c.parentId == null && !c.archived).toList();
  List<Categoria> childrenOf(int id) => categories.where((c) => c.parentId == id && !c.archived).toList();
  Categoria? parentOf(Categoria c) => cat(c.parentId);

  /// "Pai › Filha" – permite distinguir categorias com o mesmo nome.
  String path(int? id) {
    final c = cat(id);
    if (c == null) return 'Sem categoria';
    final p = cat(c.parentId);
    return p == null ? c.name : '${p.name} › ${c.name}';
  }

  Rule? ruleFor(String key) {
    Rule? contains;
    for (final r in rules) {
      if (r.exact && r.pattern == key) return r;
      if (!r.exact && key.contains(r.pattern)) contains ??= r;
    }
    return contains;
  }

  String displayName(Txn t) {
    final r = ruleFor(t.merchantKey);
    return (r != null && r.label.isNotEmpty) ? r.label : t.description;
  }

  int salaryFor(String month) => salaries[month] ?? defaultSalary;

  /// Salário acumulado num período (soma mês a mês).
  int salaryIn(Period p) {
    var total = 0;
    for (final (m, w) in p.monthWeights) {
      total += (salaryFor(monthKey(m)) * w).round();
    }
    return total;
  }

  List<Txn> txnsIn(Period p) => transactions.where((t) => p.contains(t.date)).toList();

  List<TxnGroup> _cards(Iterable<Txn> txns) {
    final map = <String, List<Txn>>{};
    final gid = <String, int?>{};
    for (final t in txns) {
      final r = ruleFor(t.merchantKey);
      final id = r?.groupId;
      final k = id != null ? 'g$id' : t.merchantKey;
      map.putIfAbsent(k, () => []).add(t);
      gid[k] = id;
    }
    return map.entries.map((e) => TxnGroup(e.key, e.value, groupId: gid[e.key])).toList()
      ..sort((a, b) => b.txns.length.compareTo(a.txns.length));
  }

  /// Cartões da aba Classificar: um por título, ou um por grupo quando o título pertence a um.
  List<TxnGroup> unclassifiedGroups() => _cards(transactions.where((t) => t.categoryId == null));

  List<TxnGroup> allGroups() => _cards(transactions);

  Grupo? groupById(int? id) {
    if (id == null) return null;
    for (final g in groups) {
      if (g.id == id) return g;
    }
    return null;
  }

  Grupo? groupByName(String name) {
    final n = name.trim().toLowerCase();
    if (n.isEmpty) return null;
    for (final g in groups) {
      if (g.name.toLowerCase() == n) return g;
    }
    return null;
  }

  List<Rule> rulesOfGroup(int id) => rules.where((r) => r.groupId == id).toList();

  /// Títulos distintos dos movimentos, com a contagem (para escolher o que juntar num grupo).
  Map<String, int> titleCounts() {
    final m = <String, int>{};
    for (final t in transactions) {
      m[t.merchantKey] = (m[t.merchantKey] ?? 0) + 1;
    }
    return m;
  }

  // ---------- Estatísticas ----------
  /// Gasto por categoria (inclui subcategorias nas categorias-pai).
  /// Despesas contam como valor positivo; rendimentos também.
  Map<int, int> totalsByCategory(Period p) {
    final own = <int, int>{};
    for (final t in txnsIn(p)) {
      final id = t.categoryId;
      if (id == null) continue;
      final c = cat(id);
      if (c == null) continue;
      own[id] = (own[id] ?? 0) + (c.isIncome ? t.amount : -t.amount);
    }
    return own;
  }

  /// Total de uma categoria incluindo descendentes directos.
  int rollup(Categoria c, Map<int, int> own) {
    var total = own[c.id] ?? 0;
    for (final ch in categories.where((x) => x.parentId == c.id)) {
      total += own[ch.id] ?? 0;
    }
    return total;
  }

  /// Alocação mensal efectiva: valor próprio, ou soma das filhas se a mãe não tiver.
  int effectiveMonthlyTarget(Categoria c, int salary) {
    if (c.hasBudget) return c.monthlyTarget(salary);
    return childrenOf(c.id).fold(0, (s, ch) => s + ch.monthlyTarget(salary));
  }

  int totalAllocated(int salary) =>
      roots.where((c) => !c.isIncome).fold(0, (s, c) => s + effectiveMonthlyTarget(c, salary));

  /// Alocação de [c] no período: soma mês a mês (suporta % e salários diferentes).
  int targetIn(Categoria c, Period p) {
    var t = 0;
    for (final (m, w) in p.monthWeights) {
      t += (effectiveMonthlyTarget(c, salaryFor(monthKey(m))) * w).round();
    }
    return t;
  }

  // ---------- Escrita ----------
  int addCategory(Categoria c) {
    final id = db.saveCategory(c);
    reload();
    return id;
  }

  void updateCategory(Categoria c) {
    db.saveCategory(c, id: c.id);
    reload();
  }

  void deleteCategory(int id) {
    db.deleteCategory(id);
    reload();
  }

  void addManual({
    required DateTime date,
    required String description,
    required int amount,
    int? categoryId,
    String note = '',
  }) {
    final key = merchantKey(description);
    var cid = categoryId;
    final r = ruleFor(key);
    cid ??= r?.categoryId;
    db.insertTransaction(
        date: date, description: description, amount: amount, categoryId: cid, note: note, source: 'manual', merchantKey: key);
    reload();
  }

  void updateTxn(Txn t) {
    db.updateTransaction(t, merchantKey: merchantKey(t.description));
    reload();
  }

  void deleteTxns(List<int> ids) {
    db.deleteTransactions(ids);
    reload();
  }

  /// Move movimentos para uma categoria. Se [remember], cria/actualiza regra para o futuro
  /// e aplica-a a todos os movimentos sem categoria com a mesma chave.
  void assign(List<Txn> txns, int? categoryId, {bool remember = false, String label = '', String note = ''}) {
    db.setCategory(txns.map((t) => t.id).toList(), categoryId);
    if (remember && categoryId != null && txns.isNotEmpty) {
      for (final key in {for (final t in txns) t.merchantKey}) {
        final r = ruleFor(key);
        if (r?.groupId != null) {
          // o título pertence a um grupo: a categoria é a do grupo
          final g = groupById(r!.groupId)!;
          db.saveRuleGroup(id: g.id, name: g.name, categoryId: categoryId, note: g.note);
          rules = db.rules();
          groups = db.ruleGroups();
        } else {
          db.upsertRule(key, categoryId, label: label, note: note);
        }
        final others = transactions.where((t) => t.merchantKey == key && t.categoryId == null).map((t) => t.id).toList();
        db.setCategory(others, categoryId);
      }
      // movimentos de outros títulos do mesmo grupo
      for (final t in transactions.where((t) => t.categoryId == null)) {
        final r = ruleFor(t.merchantKey);
        if (r?.groupId != null && r!.categoryId != null) db.setCategory([t.id], r.categoryId);
      }
    }
    reload();
  }

  void setNote(List<int> ids, String note) {
    db.setNote(ids, note);
    reload();
  }

  void saveRule(String pattern, int? categoryId, {bool exact = true, String label = '', String note = ''}) {
    db.upsertRule(pattern, categoryId, exact: exact, label: label, note: note);
    reload();
  }

  void deleteRule(int id) {
    db.deleteRule(id);
    reload();
  }

  /// Aplica todas as regras a movimentos sem categoria. Devolve quantos foram classificados.
  int applyRules() {
    var n = 0;
    for (final t in transactions.where((t) => t.categoryId == null)) {
      final r = ruleFor(t.merchantKey);
      if (r != null && r.categoryId != null) {
        db.setCategory([t.id], r.categoryId);
        n++;
      }
    }
    reload();
    return n;
  }

  // ---------- Grupos ----------
  /// Cria um grupo e (opcionalmente) junta-lhe títulos. Devolve o id.
  int createGroup(String name, {int? categoryId, String note = '', Iterable<String> keys = const []}) {
    final id = db.saveRuleGroup(name: name.trim(), categoryId: categoryId, note: note);
    for (final k in keys) {
      db.setRuleGroup(db.ensureRule(k), id);
    }
    _afterGroupChange(id, null);
    return id;
  }

  /// Altera nome/categoria/nota. Os movimentos dos títulos do grupo que estavam sem categoria
  /// (ou na categoria antiga do grupo) passam para a nova.
  void updateGroup(Grupo g) {
    final old = groupById(g.id)?.categoryId;
    db.saveRuleGroup(id: g.id, name: g.name.trim(), categoryId: g.categoryId, note: g.note);
    _afterGroupChange(g.id, old);
  }

  void addKeysToGroup(int groupId, Iterable<String> keys, {bool exact = true}) {
    for (final k in keys) {
      db.setRuleGroup(db.ensureRule(k, exact: exact), groupId);
    }
    _afterGroupChange(groupId, null);
  }

  void removeFromGroup(int ruleId) {
    db.detachRule(ruleId);
    reload();
  }

  void deleteGroup(int id) {
    db.deleteRuleGroup(id);
    reload();
  }

  void _afterGroupChange(int groupId, int? oldCategory) {
    rules = db.rules();
    groups = db.ruleGroups();
    final g = groupById(groupId);
    final cid = g?.categoryId;
    if (cid != null) {
      final ids = [
        for (final t in transactions)
          if (ruleFor(t.merchantKey)?.groupId == groupId && (t.categoryId == null || t.categoryId == oldCategory)) t.id
      ];
      db.setCategory(ids, cid);
    }
    reload();
  }

  /// Importa linhas; ignora duplicados. Devolve (novos, duplicados).
  (int, int) importRows(String filename, String source, List<ParsedRow> rows,
      {Map<String, int?> categories = const {},
      Set<String> remember = const {},
      Map<String, String> names = const {}}) {
    // Regras: categoria memorizada e/ou nome amigável. Aplicam-se a esta e às próximas importações.
    for (final k in {...remember, ...names.keys}) {
      // se o nome escrito é o de um grupo existente, o título junta-se a esse grupo
      final named = names[k]?.trim() ?? '';
      final grp = groupByName(named);
      if (grp != null) {
        db.setRuleGroup(db.ensureRule(k), grp.id);
        final c = remember.contains(k) ? categories[k] : null;
        if (c != null && c != grp.categoryId) db.saveRuleGroup(id: grp.id, name: grp.name, categoryId: c, note: grp.note);
        rules = db.rules();
        groups = db.ruleGroups();
        continue;
      }
      final ex = ruleFor(k);
      final c = remember.contains(k) ? categories[k] : ex?.categoryId;
      final label = names.containsKey(k) ? names[k]!.trim() : (ex?.label ?? '');
      if (c == null && label.isEmpty) continue;
      db.upsertRule(k, c, label: label, note: ex?.note ?? '');
    }
    rules = db.rules();
    final importId = db.createImport(filename, 0);
    var added = 0, dup = 0;
    final seen = <String>{};
    for (final r in rows) {
      final h = Db.hashOf(r.date, r.description, r.amount, r.balance);
      // Linhas iguais dentro do mesmo ficheiro são legítimas (2 cafés iguais); só se
      // comparam com o que já existia antes da importação.
      if (db.existsHash(h) && !seen.contains(h)) {
        dup++;
        continue;
      }
      seen.add(h);
      final key = merchantKey(r.description);
      db.insertTransaction(
        date: r.date,
        description: r.description,
        amount: r.amount,
        balance: r.balance,
        categoryId: categories.containsKey(key) ? categories[key] : ruleFor(key)?.categoryId,
        source: source,
        merchantKey: key,
        importId: importId,
      );
      added++;
    }
    db.updateImportCount(importId, added);
    reload();
    return (added, dup);
  }

  void setSalary(String month, int? amount) {
    db.setSalary(month, amount);
    reload();
  }

  void setDefaultSalary(int cents) {
    db.putSetting('default_salary', cents.toString());
    reload();
  }

  void deleteImport(int id) {
    db.deleteImport(id);
    reload();
  }

  void wipe({bool categories = false}) {
    db.wipeAll();
    if (categories) db.wipeCategories();
    reload();
  }
}
