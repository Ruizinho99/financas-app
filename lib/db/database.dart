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
        category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
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
    if (_db.select('SELECT COUNT(*) c FROM categories').first['c'] == 0) _seedCategories();
  }

  void _seedCategories() {
    // categoria raiz -> (obrigatória, cor, subcategorias)
    final seed = <(String, bool, bool, int, List<String>)>[
      ('Habitação', true, false, 0xFF5C6BC0, ['Renda / Prestação', 'Condomínio', 'Água', 'Eletricidade', 'Gás', 'Internet / TV']),
      ('Alimentação', true, false, 0xFF66BB6A, ['Supermercado', 'Talho / Peixaria']),
      ('Transportes', true, false, 0xFF26A69A, ['Combustível', 'Transportes públicos', 'Seguro automóvel', 'Portagens']),
      ('Saúde', true, false, 0xFFEF5350, ['Farmácia', 'Consultas', 'Seguro de saúde']),
      ('Seguros e Impostos', true, false, 0xFF8D6E63, ['Seguros', 'Impostos', 'Bancárias / Comissões']),
      ('Lazer', false, false, 0xFFFFA726, ['Restaurantes', 'Cafés', 'Cinema / Eventos', 'Subscrições']),
      ('Compras', false, false, 0xFFAB47BC, ['Roupa', 'Eletrónica', 'Casa', 'Outros']),
      ('Viagens', false, false, 0xFF29B6F6, []),
      ('Poupança e Investimento', false, false, 0xFF9CCC65, ['Poupança', 'Investimento']),
      ('Rendimentos', false, true, 0xFF43A047, ['Salário', 'Outros rendimentos']),
    ];
    for (final (name, mand, inc, color, subs) in seed) {
      _db.execute(
          'INSERT INTO categories(name, mandatory, is_income, color) VALUES(?,?,?,?)',
          [name, mand ? 1 : 0, inc ? 1 : 0, color]);
      final pid = _db.lastInsertRowId;
      for (final s in subs) {
        _db.execute(
            'INSERT INTO categories(name, parent_id, mandatory, is_income, color) VALUES(?,?,?,?,?)',
            [s, pid, mand ? 1 : 0, inc ? 1 : 0, color]);
      }
    }
  }

  // ---------- Categorias ----------
  Categoria _cat(Row r) => Categoria(
        id: r['id'] as int,
        name: r['name'] as String,
        parentId: r['parent_id'] as int?,
        mandatory: r['mandatory'] == 1,
        isIncome: r['is_income'] == 1,
        color: r['color'] as int,
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
      c.name, c.parentId, c.mandatory ? 1 : 0, c.isIncome ? 1 : 0, c.color, c.description,
      c.budgetType == BudgetType.goal ? 'goal' : 'limit', c.budgetPercent ? 1 : 0,
      c.budgetValue, c.hasBudget ? 1 : 0, c.archived ? 1 : 0,
    ];
    if (id == null) {
      _db.execute(
          'INSERT INTO categories(name,parent_id,mandatory,is_income,color,description,budget_type,budget_percent,budget_value,has_budget,archived) VALUES(?,?,?,?,?,?,?,?,?,?,?)',
          vals);
      return _db.lastInsertRowId;
    }
    _db.execute(
        'UPDATE categories SET name=?,parent_id=?,mandatory=?,is_income=?,color=?,description=?,budget_type=?,budget_percent=?,budget_value=?,has_budget=?,archived=? WHERE id=?',
        [...vals, id]);
    return id;
  }

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
  }) {
    _db.execute(
        'INSERT INTO transactions(date,description,amount,balance,category_id,note,source,merchant_key,import_id,hash) VALUES(?,?,?,?,?,?,?,?,?,?)',
        [isoDate(date), description, amount, balance, categoryId, note, source, merchantKey, importId,
          hashOf(date, description, amount, balance)]);
    return _db.lastInsertRowId;
  }

  bool existsHash(String h) =>
      _db.select('SELECT 1 FROM transactions WHERE hash=? LIMIT 1', [h]).isNotEmpty;

  void updateTransaction(Txn t, {required String merchantKey}) => _db.execute(
      'UPDATE transactions SET date=?,description=?,amount=?,balance=?,category_id=?,note=?,merchant_key=?,hash=? WHERE id=?',
      [isoDate(t.date), t.description, t.amount, t.balance, t.categoryId, t.note, merchantKey,
        hashOf(t.date, t.description, t.amount, t.balance), t.id]);

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
  List<Rule> rules() => _db
      .select('SELECT * FROM rules ORDER BY id')
      .map((r) => Rule(
            id: r['id'] as int,
            pattern: r['pattern'] as String,
            exact: r['exact'] == 1,
            categoryId: r['category_id'] as int,
            label: r['label'] as String,
            note: r['note'] as String,
          ))
      .toList();

  void upsertRule(String pattern, int categoryId, {bool exact = true, String label = '', String note = ''}) {
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
    _db.execute('DELETE FROM transactions; DELETE FROM rules; DELETE FROM imports; DELETE FROM salaries;');
  }

  void close() => _db.close();

  static Future<File> dbFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'financas.db'));
  }
}
