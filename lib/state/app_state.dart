import 'package:flutter/foundation.dart';

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
  Map<String, int> salaries = {};
  int defaultSalary = 0;

  void reload() {
    categories = db.categories();
    transactions = db.transactions();
    rules = db.rules();
    salaries = db.salaries();
    defaultSalary = int.tryParse(db.setting('default_salary') ?? '') ?? 0;
    notifyListeners();
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

  void wipe() {
    db.wipeAll();
    reload();
  }
}
