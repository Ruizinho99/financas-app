import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../models.dart';
import '../util/format.dart';

/// Acesso à base de dados SQLite local (sem rede).
class Db {
  late final Database _db;

  static Future<Db> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final d = Db();
    d._db = sqlite3.open(p.join(dir.path, 'financas.db'));
    d._migrate();
    return d;
  }

  static Db memory() {
    final d = Db();
    d._db = sqlite3.openInMemory();
    d._migrate();
    return d;
  }

  void _migrate() {
    _db.execute('PRAGMA foreign_keys = ON');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        parent_id INTEGER REFERENCES categories(id) ON DELETE CASCADE,
        mandatory INTEGER NOT NULL DEFAULT 0,
        is_income INTEGER NOT NULL DEFAULT 0,
        color INTEGER NOT NULL DEFAULT 4284955319,
        emoji TEXT NOT NULL DEFAULT '',
        description TEXT NOT NULL DEFAULT '',
        budget_type TEXT NOT NULL DEFAULT 'limit',
        budget_percent INTEGER NOT NULL DEFAULT 0,
        budget_value INTEGER NOT NULL DEFAULT 0,
        has_budget INTEGER NOT NULL DEFAULT 0,
        archived INTEGER NOT NULL DEFAULT 0
      );
      CREATE TABLE IF NOT EXISTS imports(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        filename TEXT NOT NULL,
        created_at TEXT NOT NULL,
        count INTEGER NOT NULL
      );
      CREATE TABLE IF NOT EXISTS transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        description TEXT NOT NULL,
        amount INTEGER NOT NULL,
        balance INTEGER,
        category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
        note TEXT NOT NULL DEFAULT '',
        source TEXT NOT NULL DEFAULT 'manual',
        merchant_key TEXT NOT NULL,
        import_id INTEGER REFERENCES imports(id) ON DELETE SET NULL,
        hash TEXT
      );
      CREATE INDEX IF NOT EXISTS idx_tx_date ON transactions(date);
      CREATE INDEX IF NOT EXISTS idx_tx_cat ON transactions(category_id);
      CREATE INDEX IF NOT EXISTS idx_tx_key ON transactions(merchant_key);
      CREATE TABLE IF NOT EXISTS rules(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pattern TEXT NOT NULL,
        exact INTEGER NOT NULL DEFAULT 1,
        category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
        label TEXT NOT NULL DEFAULT '',
        note TEXT NOT NULL DEFAULT ''
      );
      CREATE TABLE IF NOT EXISTS salaries(
        month TEXT PRIMARY KEY,
        amount INTEGER NOT NULL
      );
      CREATE TABLE IF NOT EXISTS settings(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS mandatory_ranges(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
        start_month TEXT NOT NULL,
        end_month TEXT
      );
    ''');
    final v = _db.select('PRAGMA user_version').first.values.first as int;
    if (v < 2) {
      // v1 trazia categorias de exemplo. Se nunca foram usadas, removê-las: nada vem pré-definido.
      final used = _db.select('SELECT 1 FROM transactions LIMIT 1').isNotEmpty ||
          _db.select('SELECT 1 FROM categories WHERE has_budget=1 LIMIT 1').isNotEmpty;
      if (!used) _db.execute('DELETE FROM categories');
    }
    if (v < 3) {
      // v3: emoji em vez de cor. Em bases novas a coluna já existe.
      try {
        _db.execute("ALTER TABLE categories ADD COLUMN emoji TEXT NOT NULL DEFAULT ''");
      } catch (_) {}
      _db.execute('PRAGMA user_version = 3');
    }
    if (v < 4) {
      // v4: uma regra pode ter só nome amigável (sem categoria).
      _db.execute('''
        CREATE TABLE rules_new(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          pattern TEXT NOT NULL,
          exact INTEGER NOT NULL DEFAULT 1,
          category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
          label TEXT NOT NULL DEFAULT '',
          note TEXT NOT NULL DEFAULT ''
        );
        INSERT INTO rules_new(id,pattern,exact,category_id,label,note)
          SELECT id,pattern,exact,category_id,label,note FROM rules;
        DROP TABLE rules;
        ALTER TABLE rules_new RENAME TO rules;
      ''');
      _db.execute('PRAGMA user_version = 4');
    }
    if (v < 5) {
      // v5: grupos de títulos (vários títulos → um nome e uma categoria).
      _db.execute('''
        CREATE TABLE IF NOT EXISTS rule_groups(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
          note TEXT NOT NULL DEFAULT ''
        );
      ''');
      try {
        _db.execute('ALTER TABLE rules ADD COLUMN group_id INTEGER REFERENCES rule_groups(id) ON DELETE SET NULL');
      } catch (_) {}
      _db.execute('PRAGMA user_version = 5');
    }
    if (v < 6) {
      // v6: contas, transferências e recibos.
      _db.execute('''
        CREATE TABLE IF NOT EXISTS accounts(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          emoji TEXT NOT NULL DEFAULT ''
        );
      ''');
      for (final sql in [
        'ALTER TABLE transactions ADD COLUMN account_id INTEGER REFERENCES accounts(id) ON DELETE SET NULL',
        'ALTER TABLE transactions ADD COLUMN is_transfer INTEGER NOT NULL DEFAULT 0',
        'ALTER TABLE transactions ADD COLUMN receipt_path TEXT',
      ]) {
        try {
          _db.execute(sql);
        } catch (_) {}
      }
      _db.execute('PRAGMA user_version = 6');
    }
  }

  // ---------- Categorias ----------
  Categoria _cat(Row r) => Categoria(
        id: r['id'] as int,
        name: r['name'] as String,
        parentId: r['parent_id'] as int?,
        isIncome: r['is_income'] == 1,
        emoji: r['emoji'] as String,
        description: r['description'] as String,
        budgetType: r['budget_type'] == 'goal' ? BudgetType.goal : BudgetType.limit,
        budgetPercent: r['budget_percent'] == 1,
        budgetValue: r['budget_value'] as int,
        hasBudget: r['has_budget'] == 1,
        archived: r['archived'] == 1,
      );

  List<Categoria> categories() =>
      _db.select('SELECT * FROM categories ORDER BY COALESCE(parent_id, id), parent_id IS NOT NULL, name').map(_cat).toList();

  int saveCategory(Categoria c, {int? id}) {
    final vals = [
      c.name, c.parentId, c.isIncome ? 1 : 0, c.emoji, c.description,
      c.budgetType == BudgetType.goal ? 'goal' : 'limit', c.budgetPercent ? 1 : 0,
      c.budgetValue, c.hasBudget ? 1 : 0, c.archived ? 1 : 0,
    ];
    if (id == null) {
      _db.execute(
          'INSERT INTO categories(name,parent_id,is_income,emoji,description,budget_type,budget_percent,budget_value,has_budget,archived) VALUES(?,?,?,?,?,?,?,?,?,?)',
          vals);
      return _db.lastInsertRowId;
    }
    _db.execute(
        'UPDATE categories SET name=?,parent_id=?,is_income=?,emoji=?,description=?,budget_type=?,budget_percent=?,budget_value=?,has_budget=?,archived=? WHERE id=?',
        [...vals, id]);
    return id;
  }

  // ---------- Períodos de obrigatoriedade ----------
  List<MandatoryRange> mandatoryRanges() => _db
      .select('SELECT * FROM mandatory_ranges ORDER BY category_id, start_month')
      .map((r) => MandatoryRange(
          id: r['id'] as int,
          categoryId: r['category_id'] as int,
          start: r['start_month'] as String,
          end: r['end_month'] as String?))
      .toList();

  void addMandatoryRange(int categoryId, String start, String? end) => _db.execute(
      'INSERT INTO mandatory_ranges(category_id,start_month,end_month) VALUES(?,?,?)', [categoryId, start, end]);

  void deleteMandatoryRange(int id) => _db.execute('DELETE FROM mandatory_ranges WHERE id=?', [id]);

  void deleteCategory(int id) => _db.execute('DELETE FROM categories WHERE id=?', [id]);

  // ---------- Movimentos ----------
  Txn _tx(Row r) => Txn(
        id: r['id'] as int,
        date: DateTime.parse(r['date'] as String),
        description: r['description'] as String,
        amount: r['amount'] as int,
        balance: r['balance'] as int?,
        categoryId: r['category_id'] as int?,
        note: r['note'] as String,
        source: r['source'] as String,
        merchantKey: r['merchant_key'] as String,
        importId: r['import_id'] as int?,
        accountId: r['account_id'] as int?,
        isTransfer: r['is_transfer'] == 1,
        receiptPath: r['receipt_path'] as String?,
      );

  List<Txn> transactions() =>
      _db.select('SELECT * FROM transactions ORDER BY date DESC, id DESC').map(_tx).toList();

  static String hashOf(DateTime d, String desc, int amount, int? bal) =>
      '${isoDate(d)}|${desc.trim().toUpperCase()}|$amount|${bal ?? ''}';

  int insertTransaction({
    required DateTime date,
    required String description,
    required int amount,
    int? balance,
    int? categoryId,
    String note = '',
    String source = 'manual',
    required String merchantKey,
    int? importId,
    int? accountId,
    bool isTransfer = false,
    String? receiptPath,
  }) {
    _db.execute(
        'INSERT INTO transactions(date,description,amount,balance,category_id,note,source,merchant_key,import_id,hash,account_id,is_transfer,receipt_path) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?)',
        [isoDate(date), description, amount, balance, categoryId, note, source, merchantKey, importId,
          hashOf(date, description, amount, balance), accountId, isTransfer ? 1 : 0, receiptPath]);
    return _db.lastInsertRowId;
  }

  bool existsHash(String h) =>
      _db.select('SELECT 1 FROM transactions WHERE hash=? LIMIT 1', [h]).isNotEmpty;

  void updateTransaction(Txn t, {required String merchantKey}) => _db.execute(
      'UPDATE transactions SET date=?,description=?,amount=?,balance=?,category_id=?,note=?,merchant_key=?,hash=?,account_id=?,is_transfer=?,receipt_path=? WHERE id=?',
      [isoDate(t.date), t.description, t.amount, t.balance, t.categoryId, t.note, merchantKey,
        hashOf(t.date, t.description, t.amount, t.balance), t.accountId, t.isTransfer ? 1 : 0, t.receiptPath, t.id]);

  /// Nomes dos ficheiros de recibo dos movimentos indicados.
  List<String> receiptsOf(List<int> ids) => [
        for (final id in ids)
          for (final r in _db.select('SELECT receipt_path FROM transactions WHERE id=? AND receipt_path IS NOT NULL', [id]))
            r['receipt_path'] as String
      ];

  // ---------- Contas ----------
  List<Conta> accounts() => _db
      .select('SELECT * FROM accounts ORDER BY name COLLATE NOCASE')
      .map((r) => Conta(id: r['id'] as int, name: r['name'] as String, emoji: r['emoji'] as String))
      .toList();

  int saveAccount({int? id, required String name, String emoji = ''}) {
    if (id == null) {
      _db.execute('INSERT INTO accounts(name,emoji) VALUES(?,?)', [name, emoji]);
      return _db.lastInsertRowId;
    }
    _db.execute('UPDATE accounts SET name=?,emoji=? WHERE id=?', [name, emoji, id]);
    return id;
  }

  void deleteAccount(int id) => _db.execute('DELETE FROM accounts WHERE id=?', [id]);

  void setAccount(List<int> ids, int? accountId) {
    for (final id in ids) {
      _db.execute('UPDATE transactions SET account_id=? WHERE id=?', [accountId, id]);
    }
  }

  void deleteTransactions(List<int> ids) {
    for (final id in ids) {
      _db.execute('DELETE FROM transactions WHERE id=?', [id]);
    }
  }

  void setCategory(List<int> ids, int? categoryId) {
    for (final id in ids) {
      _db.execute('UPDATE transactions SET category_id=? WHERE id=?', [categoryId, id]);
    }
  }

  void setNote(List<int> ids, String note) {
    for (final id in ids) {
      _db.execute('UPDATE transactions SET note=? WHERE id=?', [note, id]);
    }
  }

  int createImport(String filename, int count) {
    _db.execute('INSERT INTO imports(filename,created_at,count) VALUES(?,?,?)',
        [filename, DateTime.now().toIso8601String(), count]);
    return _db.lastInsertRowId;
  }

  void updateImportCount(int id, int count) =>
      _db.execute('UPDATE imports SET count=? WHERE id=?', [count, id]);

  List<({int id, String filename, DateTime createdAt, int count})> imports() => _db
      .select('SELECT * FROM imports ORDER BY id DESC')
      .map((r) => (
            id: r['id'] as int,
            filename: r['filename'] as String,
            createdAt: DateTime.parse(r['created_at'] as String),
            count: r['count'] as int
          ))
      .toList();

  void deleteImport(int id) {
    _db.execute('DELETE FROM transactions WHERE import_id=?', [id]);
    _db.execute('DELETE FROM imports WHERE id=?', [id]);
  }

  // ---------- Regras ----------
  /// Regras já com nome/categoria/nota resolvidos (os do grupo, se pertencerem a um).
  List<Rule> rules() => _db
      .select('''
        SELECT r.id, r.pattern, r.exact, r.group_id,
          CASE WHEN r.group_id IS NULL THEN r.category_id ELSE g.category_id END AS category_id,
          CASE WHEN r.group_id IS NULL THEN r.label ELSE g.name END AS label,
          CASE WHEN r.group_id IS NULL THEN r.note ELSE g.note END AS note
        FROM rules r LEFT JOIN rule_groups g ON g.id = r.group_id ORDER BY r.id
      ''')
      .map((r) => Rule(
            id: r['id'] as int,
            pattern: r['pattern'] as String,
            exact: r['exact'] == 1,
            categoryId: r['category_id'] as int?,
            label: r['label'] as String,
            note: r['note'] as String,
            groupId: r['group_id'] as int?,
          ))
      .toList();

  // ---------- Grupos ----------
  List<Grupo> ruleGroups() => _db
      .select('SELECT * FROM rule_groups ORDER BY name COLLATE NOCASE')
      .map((r) => Grupo(id: r['id'] as int, name: r['name'] as String, categoryId: r['category_id'] as int?, note: r['note'] as String))
      .toList();

  int saveRuleGroup({int? id, required String name, int? categoryId, String note = ''}) {
    if (id == null) {
      _db.execute('INSERT INTO rule_groups(name,category_id,note) VALUES(?,?,?)', [name, categoryId, note]);
      return _db.lastInsertRowId;
    }
    _db.execute('UPDATE rule_groups SET name=?,category_id=?,note=? WHERE id=?', [name, categoryId, note, id]);
    return id;
  }

  /// Garante que existe uma regra para o título e devolve o seu id.
  int ensureRule(String pattern, {bool exact = true}) {
    final ex = _db.select('SELECT id FROM rules WHERE pattern=? AND exact=?', [pattern, exact ? 1 : 0]);
    if (ex.isNotEmpty) return ex.first['id'] as int;
    _db.execute('INSERT INTO rules(pattern,exact) VALUES(?,?)', [pattern, exact ? 1 : 0]);
    return _db.lastInsertRowId;
  }

  void setRuleGroup(int ruleId, int? groupId) =>
      _db.execute('UPDATE rules SET group_id=? WHERE id=?', [groupId, ruleId]);

  /// Copia os dados do grupo para as regras e tira-as do grupo (mantêm nome e categoria).
  void detachRule(int ruleId) {
    _db.execute('''
      UPDATE rules SET
        category_id = (SELECT category_id FROM rule_groups WHERE id = rules.group_id),
        label = COALESCE((SELECT name FROM rule_groups WHERE id = rules.group_id), label),
        note = COALESCE((SELECT note FROM rule_groups WHERE id = rules.group_id), note),
        group_id = NULL
      WHERE id = ? AND group_id IS NOT NULL
    ''', [ruleId]);
  }

  void deleteRuleGroup(int id) {
    for (final r in _db.select('SELECT id FROM rules WHERE group_id=?', [id])) {
      detachRule(r['id'] as int);
    }
    _db.execute('DELETE FROM rule_groups WHERE id=?', [id]);
  }

  void upsertRule(String pattern, int? categoryId, {bool exact = true, String label = '', String note = ''}) {
    final ex = _db.select('SELECT id FROM rules WHERE pattern=? AND exact=?', [pattern, exact ? 1 : 0]);
    if (ex.isEmpty) {
      _db.execute('INSERT INTO rules(pattern,exact,category_id,label,note) VALUES(?,?,?,?,?)',
          [pattern, exact ? 1 : 0, categoryId, label, note]);
    } else {
      _db.execute('UPDATE rules SET category_id=?,label=?,note=? WHERE id=?',
          [categoryId, label, note, ex.first['id']]);
    }
  }

  void deleteRule(int id) => _db.execute('DELETE FROM rules WHERE id=?', [id]);

  // ---------- Salários e definições ----------
  Map<String, int> salaries() => {
        for (final r in _db.select('SELECT * FROM salaries')) r['month'] as String: r['amount'] as int
      };

  void setSalary(String month, int? amount) {
    if (amount == null) {
      _db.execute('DELETE FROM salaries WHERE month=?', [month]);
    } else {
      _db.execute('INSERT OR REPLACE INTO salaries(month,amount) VALUES(?,?)', [month, amount]);
    }
  }

  String? setting(String key) {
    final r = _db.select('SELECT value FROM settings WHERE key=?', [key]);
    return r.isEmpty ? null : r.first['value'] as String;
  }

  void putSetting(String key, String value) =>
      _db.execute('INSERT OR REPLACE INTO settings(key,value) VALUES(?,?)', [key, value]);

  void wipeAll() {
    _db.execute('DELETE FROM transactions; DELETE FROM rules; DELETE FROM rule_groups; DELETE FROM imports; DELETE FROM salaries;');
  }

  void wipeCategories() {
    _db.execute('DELETE FROM categories; DELETE FROM accounts;');
  }

  void deleteSetting(String key) => _db.execute('DELETE FROM settings WHERE key=?', [key]);

  void close() => _db.close();

  static Future<File> dbFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'financas.db'));
  }
}
