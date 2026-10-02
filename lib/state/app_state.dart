import 'package:flutter/material.dart';

import '../db/database.dart';
import '../import/parsers.dart';
import '../models.dart';
import '../util/format.dart';

enum PeriodKind { month, months, year, years, all }

/// Período de análise: um mês, vários meses, um ano, vários anos ou tudo.
class Period {
  final DateTime start; // inclusivo
  final DateTime end; // exclusivo
  const Period(this.start, this.end);

  int get monthCount => (end.year - start.year) * 12 + end.month - start.month;
  bool contains(DateTime d) => !d.isBefore(start) && d.isBefore(end);

  static Period month(DateTime d) => Period(DateTime(d.year, d.month), DateTime(d.year, d.month + 1));
  static Period months(DateTime from, DateTime to) =>
      Period(DateTime(from.year, from.month), DateTime(to.year, to.month + 1));
  static Period years(int from, int to) => Period(DateTime(from), DateTime(to + 1));
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
  List<MandatoryRange> mandatoryRanges = [];
  Map<String, int> salaries = {};
  int defaultSalary = 0;

  void reload() {
    categories = db.categories();
    transactions = db.transactions();
    rules = db.rules();
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
    for (var i = 0; i < p.monthCount; i++) {
      total += salaryFor(monthKey(DateTime(p.start.year, p.start.month + i)));
    }
    return total;
  }

  List<Txn> txnsIn(Period p) => transactions.where((t) => p.contains(t.date)).toList();

  List<TxnGroup> unclassifiedGroups() {
    final map = <String, List<Txn>>{};
    for (final t in transactions) {
      if (t.categoryId == null) map.putIfAbsent(t.merchantKey, () => []).add(t);
    }
    return map.entries.map((e) => TxnGroup(e.key, e.value)).toList()
      ..sort((a, b) => b.txns.length.compareTo(a.txns.length));
  }

  List<TxnGroup> allGroups() {
    final map = <String, List<Txn>>{};
    for (final t in transactions) {
      map.putIfAbsent(t.merchantKey, () => []).add(t);
    }
    return map.entries.map((e) => TxnGroup(e.key, e.value)).toList()
      ..sort((a, b) => b.txns.length.compareTo(a.txns.length));
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
    for (var i = 0; i < p.monthCount; i++) {
      t += effectiveMonthlyTarget(c, salaryFor(monthKey(DateTime(p.start.year, p.start.month + i))));
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
      final key = txns.first.merchantKey;
      db.upsertRule(key, categoryId, label: label, note: note);
      final others = transactions
          .where((t) => t.merchantKey == key && t.categoryId == null)
          .map((t) => t.id)
          .toList();
      db.setCategory(others, categoryId);
    }
    reload();
  }

  void setNote(List<int> ids, String note) {
    db.setNote(ids, note);
    reload();
  }

  void saveRule(String pattern, int categoryId, {bool exact = true, String label = '', String note = ''}) {
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
      if (r != null) {
        db.setCategory([t.id], r.categoryId);
        n++;
      }
    }
    reload();
    return n;
  }

  /// Importa linhas; ignora duplicados. Devolve (novos, duplicados).
  (int, int) importRows(String filename, String source, List<ParsedRow> rows) {
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
        categoryId: ruleFor(key)?.categoryId,
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
