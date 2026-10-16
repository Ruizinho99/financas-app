import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../goals/goals.dart';
import '../invest/allocation_plan.dart';
import '../planning/planning.dart';
import '../invest/invest.dart';
import '../recurring/recurring.dart';
import '../models.dart';
import '../util/format.dart';

/// Acesso à base de dados SQLite local (sem rede).
class Db {
  late Database _db;

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
      final used =
          _db.select('SELECT 1 FROM transactions LIMIT 1').isNotEmpty ||
          _db
              .select('SELECT 1 FROM categories WHERE has_budget=1 LIMIT 1')
              .isNotEmpty;
      if (!used) _db.execute('DELETE FROM categories');
    }
    if (v < 3) {
      // v3: emoji em vez de cor. Em bases novas a coluna já existe.
      try {
        _db.execute(
          "ALTER TABLE categories ADD COLUMN emoji TEXT NOT NULL DEFAULT ''",
        );
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
        _db.execute(
          'ALTER TABLE rules ADD COLUMN group_id INTEGER REFERENCES rule_groups(id) ON DELETE SET NULL',
        );
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
    if (v < 7) {
      // v7: categorias com período de validade (ex.: "Férias 2027").
      for (final sql in [
        'ALTER TABLE categories ADD COLUMN active_from TEXT',
        'ALTER TABLE categories ADD COLUMN active_to TEXT',
      ]) {
        try {
          _db.execute(sql);
        } catch (_) {}
      }
      _db.execute('PRAGMA user_version = 7');
    }
    if (v < 8) {
      // v8: investimentos (plataformas, ativos, operações, títulos que são entregas a plataformas).
      _db.execute('''
        CREATE TABLE IF NOT EXISTS invest_accounts(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          emoji TEXT NOT NULL DEFAULT '',
          note TEXT NOT NULL DEFAULT '',
          archived INTEGER NOT NULL DEFAULT 0
        );
        CREATE TABLE IF NOT EXISTS holdings(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          account_id INTEGER NOT NULL REFERENCES invest_accounts(id) ON DELETE CASCADE,
          name TEXT NOT NULL,
          symbol TEXT NOT NULL DEFAULT '',
          provider TEXT NOT NULL DEFAULT 'manual',
          kind TEXT NOT NULL DEFAULT 'etf',
          last_price REAL,
          last_price_at TEXT,
          archived INTEGER NOT NULL DEFAULT 0
        );
        CREATE TABLE IF NOT EXISTS invest_ops(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          account_id INTEGER NOT NULL REFERENCES invest_accounts(id) ON DELETE CASCADE,
          holding_id INTEGER REFERENCES holdings(id) ON DELETE CASCADE,
          date TEXT NOT NULL,
          type TEXT NOT NULL,
          quantity REAL NOT NULL DEFAULT 0,
          price REAL NOT NULL DEFAULT 0,
          amount INTEGER NOT NULL DEFAULT 0,
          fee INTEGER NOT NULL DEFAULT 0,
          note TEXT NOT NULL DEFAULT ''
        );
        CREATE TABLE IF NOT EXISTS invest_patterns(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          pattern TEXT NOT NULL,
          account_id INTEGER NOT NULL REFERENCES invest_accounts(id) ON DELETE CASCADE
        );
      ''');
      try {
        _db.execute(
          'ALTER TABLE transactions ADD COLUMN invest_account_id INTEGER REFERENCES invest_accounts(id) ON DELETE SET NULL',
        );
      } catch (_) {}
      _db.execute('PRAGMA user_version = 8');
    }
    if (v < 9) {
      // v9: moeda por ativo (EUR, USD…) e câmbio de cada operação.
      for (final sql in [
        "ALTER TABLE holdings ADD COLUMN currency TEXT NOT NULL DEFAULT 'EUR'",
        'ALTER TABLE holdings ADD COLUMN last_price_orig REAL',
        'ALTER TABLE holdings ADD COLUMN last_fx REAL',
        'ALTER TABLE invest_ops ADD COLUMN fx REAL',
      ]) {
        try {
          _db.execute(sql);
        } catch (_) {}
      }
      _db.execute('PRAGMA user_version = 9');
    }
    if (v < 10) {
      try {
        _db.execute(
          'ALTER TABLE holdings ADD COLUMN currency_manual INTEGER NOT NULL DEFAULT 0',
        );
      } catch (_) {}
      _db.execute('PRAGMA user_version = 10');
    }
    if (v < 11) {
      // v11: compra ligada à transferência do banco que a financiou
      try {
        _db.execute('ALTER TABLE invest_ops ADD COLUMN txn_id INTEGER');
      } catch (_) {}
      _db.execute('PRAGMA user_version = 11');
    }
    if (v < 12) {
      // v12: categorias de investimento (dinheiro investido, não é gasto)
      try {
        _db.execute(
          'ALTER TABLE categories ADD COLUMN is_investment INTEGER NOT NULL DEFAULT 0',
        );
      } catch (_) {}
      _db.execute('PRAGMA user_version = 12');
    }
    if (v < 13) {
      // v13: categorias que aceitam despesas e receitas
      try {
        _db.execute(
          'ALTER TABLE categories ADD COLUMN is_both INTEGER NOT NULL DEFAULT 0',
        );
      } catch (_) {}
      _db.execute('PRAGMA user_version = 13');
    }
    if (v < 14) {
      // v14: compra sem alocação (não desconta do dinheiro por alocar da plataforma)
      try {
        _db.execute(
          'ALTER TABLE invest_ops ADD COLUMN allocate INTEGER NOT NULL DEFAULT 1',
        );
      } catch (_) {}
      _db.execute('PRAGMA user_version = 14');
    }
    if (v < 15) {
      // v15: logótipo do ativo (imagem guardada na base de dados)
      try {
        _db.execute('ALTER TABLE holdings ADD COLUMN logo BLOB');
      } catch (_) {}
      _db.execute('PRAGMA user_version = 15');
    }
    if (v < 16) {
      // v16: anulação de despesas (reembolsos e devoluções ligados à despesa original)
      try {
        _db.execute('ALTER TABLE transactions ADD COLUMN reverses_id INTEGER');
      } catch (_) {}
      try {
        _db.execute(
          'ALTER TABLE transactions ADD COLUMN reversed_cents INTEGER NOT NULL DEFAULT 0',
        );
      } catch (_) {}
      _db.execute('PRAGMA user_version = 16');
    }
    if (v < 17) {
      // v17: objetivos de poupança, histórico do valor e movimentos associados
      _db.execute('''
        CREATE TABLE IF NOT EXISTS goals(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT NOT NULL DEFAULT '',
          category_id INTEGER NOT NULL,
          target_cents INTEGER NOT NULL,
          end_date TEXT,
          archived INTEGER NOT NULL DEFAULT 0
        )''');
      _db.execute('''
        CREATE TABLE IF NOT EXISTS goal_targets(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          goal_id INTEGER NOT NULL,
          date TEXT NOT NULL,
          cents INTEGER NOT NULL
        )''');
      _db.execute('''
        CREATE TABLE IF NOT EXISTS goal_allocations(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          txn_id INTEGER NOT NULL,
          goal_id INTEGER NOT NULL,
          cents INTEGER NOT NULL
        )''');
      _db.execute('PRAGMA user_version = 17');
    }
    if (v < 18) {
      // v18: despesas planeadas por mês (planeamento mensal)
      _db.execute('''
        CREATE TABLE IF NOT EXISTS planned_items(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          month TEXT NOT NULL,
          category_id INTEGER NOT NULL,
          cents INTEGER NOT NULL,
          mandatory INTEGER NOT NULL DEFAULT 0
        )''');
      _db.execute('PRAGMA user_version = 18');
    }
    if (v < 19) {
      // v19: plano de distribuição das entregas por plataforma e entregas já vistas
      _db.execute('''
        CREATE TABLE IF NOT EXISTS invest_plan(
          account_id INTEGER NOT NULL,
          holding_id INTEGER NOT NULL,
          bp INTEGER NOT NULL,
          PRIMARY KEY(account_id, holding_id)
        )''');
      _db.execute('''
        CREATE TABLE IF NOT EXISTS invest_plan_since(
          account_id INTEGER PRIMARY KEY,
          since TEXT NOT NULL
        )''');
      _db.execute('''
        CREATE TABLE IF NOT EXISTS invest_alerts_done(
          txn_id INTEGER PRIMARY KEY
        )''');
      _db.execute('PRAGMA user_version = 19');
    }
    if (v < 20) {
      // v20: saldo inicial de cada conta bancária
      try {
        _db.execute(
          'ALTER TABLE accounts ADD COLUMN opening_cents INTEGER NOT NULL DEFAULT 0',
        );
      } catch (_) {}
      _db.execute('PRAGMA user_version = 20');
    }
    if (v < 21) {
      // v21: movimentos recorrentes (salário, renda, subscrições)
      _db.execute('''
        CREATE TABLE IF NOT EXISTS recurring_rules(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          description TEXT NOT NULL,
          amount INTEGER NOT NULL,
          category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
          account_id INTEGER REFERENCES accounts(id) ON DELETE SET NULL,
          freq TEXT NOT NULL,
          day INTEGER NOT NULL,
          start_date TEXT NOT NULL,
          end_date TEXT,
          last_date TEXT,
          active INTEGER NOT NULL DEFAULT 1
        )''');
      _db.execute('PRAGMA user_version = 21');
    }
  }

  /// Corre [body] numa transação: ou grava tudo ou nada.
  void inTransaction(void Function() body) {
    _db.execute('BEGIN');
    try {
      body();
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  // ---------- Categorias ----------
  Categoria _cat(Row r) => Categoria(
    id: r['id'] as int,
    name: r['name'] as String,
    parentId: r['parent_id'] as int?,
    isIncome: r['is_income'] == 1,
    isInvestment: r['is_investment'] == 1,
    both: r['is_both'] == 1,
    emoji: r['emoji'] as String,
    description: r['description'] as String,
    budgetType: r['budget_type'] == 'goal' ? BudgetType.goal : BudgetType.limit,
    budgetPercent: r['budget_percent'] == 1,
    budgetValue: r['budget_value'] as int,
    hasBudget: r['has_budget'] == 1,
    archived: r['archived'] == 1,
    activeFrom: r['active_from'] as String?,
    activeTo: r['active_to'] as String?,
  );

  List<Categoria> categories() => _db
      .select(
        'SELECT * FROM categories ORDER BY COALESCE(parent_id, id), parent_id IS NOT NULL, name',
      )
      .map(_cat)
      .toList();

  int saveCategory(Categoria c, {int? id}) {
    final vals = [
      c.name,
      c.parentId,
      c.isIncome ? 1 : 0,
      c.emoji,
      c.description,
      c.budgetType == BudgetType.goal ? 'goal' : 'limit',
      c.budgetPercent ? 1 : 0,
      c.budgetValue,
      c.hasBudget ? 1 : 0,
      c.archived ? 1 : 0,
      c.activeFrom,
      c.activeTo,
      c.isInvestment ? 1 : 0,
      c.both ? 1 : 0,
    ];
    if (id == null) {
      _db.execute(
        'INSERT INTO categories(name,parent_id,is_income,emoji,description,budget_type,budget_percent,budget_value,has_budget,archived,active_from,active_to,is_investment,is_both) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
        vals,
      );
      return _db.lastInsertRowId;
    }
    _db.execute(
      'UPDATE categories SET name=?,parent_id=?,is_income=?,emoji=?,description=?,budget_type=?,budget_percent=?,budget_value=?,has_budget=?,archived=?,active_from=?,active_to=?,is_investment=?,is_both=? WHERE id=?',
      [...vals, id],
    );
    return id;
  }

  // ---------- Períodos de obrigatoriedade ----------
  List<MandatoryRange> mandatoryRanges() => _db
      .select(
        'SELECT * FROM mandatory_ranges ORDER BY category_id, start_month',
      )
      .map(
        (r) => MandatoryRange(
          id: r['id'] as int,
          categoryId: r['category_id'] as int,
          start: r['start_month'] as String,
          end: r['end_month'] as String?,
        ),
      )
      .toList();

  void addMandatoryRange(int categoryId, String start, String? end) =>
      _db.execute(
        'INSERT INTO mandatory_ranges(category_id,start_month,end_month) VALUES(?,?,?)',
        [categoryId, start, end],
      );

  void deleteMandatoryRange(int id) =>
      _db.execute('DELETE FROM mandatory_ranges WHERE id=?', [id]);

  void deleteCategory(int id) =>
      _db.execute('DELETE FROM categories WHERE id=?', [id]);

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
    investAccountId: r['invest_account_id'] as int?,
    reversesId: r['reverses_id'] as int?,
    reversedCents: (r['reversed_cents'] as int?) ?? 0,
  );

  List<Txn> transactions() => _db
      .select('SELECT * FROM transactions ORDER BY date DESC, id DESC')
      .map(_tx)
      .toList();

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
    int? investAccountId,
    int? reversesId,
    int reversedCents = 0,
  }) {
    _db.execute(
      'INSERT INTO transactions(date,description,amount,balance,category_id,note,source,merchant_key,import_id,hash,account_id,is_transfer,receipt_path,invest_account_id,reverses_id,reversed_cents) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
      [
        isoDate(date),
        description,
        amount,
        balance,
        categoryId,
        note,
        source,
        merchantKey,
        importId,
        hashOf(date, description, amount, balance),
        accountId,
        isTransfer ? 1 : 0,
        receiptPath,
        investAccountId,
        reversesId,
        reversedCents,
      ],
    );
    return _db.lastInsertRowId;
  }

  bool existsHash(String h) => _db.select(
    'SELECT 1 FROM transactions WHERE hash=? LIMIT 1',
    [h],
  ).isNotEmpty;

  void updateTransaction(Txn t, {required String merchantKey}) => _db.execute(
    'UPDATE transactions SET date=?,description=?,amount=?,balance=?,category_id=?,note=?,merchant_key=?,hash=?,account_id=?,is_transfer=?,receipt_path=?,invest_account_id=?,reverses_id=?,reversed_cents=? WHERE id=?',
    [
      isoDate(t.date),
      t.description,
      t.amount,
      t.balance,
      t.categoryId,
      t.note,
      merchantKey,
      hashOf(t.date, t.description, t.amount, t.balance),
      t.accountId,
      t.isTransfer ? 1 : 0,
      t.receiptPath,
      t.investAccountId,
      t.reversesId,
      t.reversedCents,
      t.id,
    ],
  );

  /// Nomes dos ficheiros de recibo dos movimentos indicados.
  List<String> receiptsOf(List<int> ids) => [
    for (final id in ids)
      for (final r in _db.select(
        'SELECT receipt_path FROM transactions WHERE id=? AND receipt_path IS NOT NULL',
        [id],
      ))
        r['receipt_path'] as String,
  ];

  // ---------- Objetivos ----------
  List<Goal> goals() => _db
      .select('SELECT * FROM goals ORDER BY archived, name COLLATE NOCASE')
      .map(
        (r) => Goal(
          id: r['id'] as int,
          name: r['name'] as String,
          description: r['description'] as String,
          categoryId: r['category_id'] as int,
          targetCents: r['target_cents'] as int,
          endDate: r['end_date'] == null
              ? null
              : DateTime.parse(r['end_date'] as String),
          archived: r['archived'] == 1,
        ),
      )
      .toList();

  int saveGoal({
    int? id,
    required String name,
    required String description,
    required int categoryId,
    required int targetCents,
    DateTime? endDate,
    bool archived = false,
  }) {
    final vals = [
      name,
      description,
      categoryId,
      targetCents,
      endDate == null ? null : isoDate(endDate),
      archived ? 1 : 0,
    ];
    if (id == null) {
      _db.execute(
        'INSERT INTO goals(name,description,category_id,target_cents,end_date,archived) VALUES(?,?,?,?,?,?)',
        vals,
      );
      return _db.lastInsertRowId;
    }
    _db.execute(
      'UPDATE goals SET name=?,description=?,category_id=?,target_cents=?,end_date=?,archived=? WHERE id=?',
      [...vals, id],
    );
    return id;
  }

  List<GoalTargetChange> goalTargets(int goalId) => _db
      .select('SELECT * FROM goal_targets WHERE goal_id=? ORDER BY id', [
        goalId,
      ])
      .map(
        (r) => GoalTargetChange(
          DateTime.parse(r['date'] as String),
          r['cents'] as int,
        ),
      )
      .toList();

  void addGoalTarget(int goalId, DateTime date, int cents) => _db.execute(
    'INSERT INTO goal_targets(goal_id,date,cents) VALUES(?,?,?)',
    [goalId, isoDate(date), cents],
  );

  List<GoalAllocation> goalAllocations() => _db
      .select('SELECT * FROM goal_allocations ORDER BY id')
      .map(
        (r) => GoalAllocation(
          id: r['id'] as int,
          txnId: r['txn_id'] as int,
          goalId: r['goal_id'] as int,
          cents: r['cents'] as int,
        ),
      )
      .toList();

  /// Associa [cents] do movimento [txnId] ao objetivo [goalId] (substitui a associação anterior).
  void setGoalAllocation(int txnId, int goalId, int cents) {
    _db.execute('DELETE FROM goal_allocations WHERE txn_id=? AND goal_id=?', [
      txnId,
      goalId,
    ]);
    _db.execute(
      'INSERT INTO goal_allocations(txn_id,goal_id,cents) VALUES(?,?,?)',
      [txnId, goalId, cents],
    );
  }

  void deleteGoalAllocation(int id) =>
      _db.execute('DELETE FROM goal_allocations WHERE id=?', [id]);

  void deleteGoal(int id) {
    _db.execute('DELETE FROM goal_allocations WHERE goal_id=?', [id]);
    _db.execute('DELETE FROM goal_targets WHERE goal_id=?', [id]);
    _db.execute('DELETE FROM goals WHERE id=?', [id]);
  }

  // ---------- Planeamento mensal ----------
  List<PlannedItem> plannedItems() => _db
      .select('SELECT * FROM planned_items ORDER BY month, mandatory DESC, id')
      .map(
        (r) => PlannedItem(
          id: r['id'] as int,
          month: r['month'] as String,
          categoryId: r['category_id'] as int,
          cents: r['cents'] as int,
          mandatory: r['mandatory'] == 1,
        ),
      )
      .toList();

  int savePlannedItem({
    int? id,
    required String month,
    required int categoryId,
    required int cents,
    required bool mandatory,
  }) {
    if (id == null) {
      _db.execute(
        'INSERT INTO planned_items(month,category_id,cents,mandatory) VALUES(?,?,?,?)',
        [month, categoryId, cents, mandatory ? 1 : 0],
      );
      return _db.lastInsertRowId;
    }
    _db.execute(
      'UPDATE planned_items SET month=?,category_id=?,cents=?,mandatory=? WHERE id=?',
      [month, categoryId, cents, mandatory ? 1 : 0, id],
    );
    return id;
  }

  void deletePlannedItem(int id) =>
      _db.execute('DELETE FROM planned_items WHERE id=?', [id]);

  // ---------- Plano de distribuição das entregas ----------
  Map<int, List<PlanLine>> investPlan() {
    final out = <int, List<PlanLine>>{};
    for (final r in _db.select(
      'SELECT * FROM invest_plan ORDER BY account_id, bp DESC',
    )) {
      out
          .putIfAbsent(r['account_id'] as int, () => [])
          .add(PlanLine(r['holding_id'] as int, r['bp'] as int));
    }
    return out;
  }

  Map<int, DateTime> investPlanSince() => {
    for (final r in _db.select('SELECT * FROM invest_plan_since'))
      r['account_id'] as int: DateTime.parse(r['since'] as String),
  };

  /// Grava o plano de uma plataforma (substitui o anterior). A data de início fica a da primeira vez.
  void saveInvestPlan(int accountId, List<PlanLine> lines) {
    _db.execute('DELETE FROM invest_plan WHERE account_id=?', [accountId]);
    for (final l in lines) {
      _db.execute(
        'INSERT INTO invest_plan(account_id,holding_id,bp) VALUES(?,?,?)',
        [accountId, l.holdingId, l.bp],
      );
    }
    if (lines.isEmpty) {
      _db.execute('DELETE FROM invest_plan_since WHERE account_id=?', [
        accountId,
      ]);
    } else {
      _db.execute(
        'INSERT OR IGNORE INTO invest_plan_since(account_id,since) VALUES(?,?)',
        [accountId, isoDate(DateTime.now())],
      );
    }
  }

  Set<int> investAlertsDone() => {
    for (final r in _db.select('SELECT txn_id FROM invest_alerts_done'))
      r['txn_id'] as int,
  };

  void markInvestAlertDone(int txnId) => _db.execute(
    'INSERT OR IGNORE INTO invest_alerts_done(txn_id) VALUES(?)',
    [txnId],
  );

  // ---------- Contas ----------
  List<Conta> accounts() => _db
      .select('SELECT * FROM accounts ORDER BY name COLLATE NOCASE')
      .map(
        (r) => Conta(
          id: r['id'] as int,
          name: r['name'] as String,
          emoji: r['emoji'] as String,
          openingCents: (r['opening_cents'] as int?) ?? 0,
        ),
      )
      .toList();

  int saveAccount({
    int? id,
    required String name,
    String emoji = '',
    int openingCents = 0,
  }) {
    if (id == null) {
      _db.execute(
        'INSERT INTO accounts(name,emoji,opening_cents) VALUES(?,?,?)',
        [name, emoji, openingCents],
      );
      return _db.lastInsertRowId;
    }
    _db.execute(
      'UPDATE accounts SET name=?,emoji=?,opening_cents=? WHERE id=?',
      [name, emoji, openingCents, id],
    );
    return id;
  }

  void deleteAccount(int id) =>
      _db.execute('DELETE FROM accounts WHERE id=?', [id]);

  void setAccount(List<int> ids, int? accountId) {
    for (final id in ids) {
      _db.execute('UPDATE transactions SET account_id=? WHERE id=?', [
        accountId,
        id,
      ]);
    }
  }

  void deleteTransactions(List<int> ids) {
    for (final id in ids) {
      _db.execute('DELETE FROM goal_allocations WHERE txn_id=?', [id]);
      // as receitas que anulavam esta despesa passam a ser receitas normais
      _db.execute(
        'UPDATE transactions SET reverses_id=NULL, reversed_cents=0 WHERE reverses_id=?',
        [id],
      );
      _db.execute('DELETE FROM transactions WHERE id=?', [id]);
    }
  }

  void setCategory(List<int> ids, int? categoryId) {
    for (final id in ids) {
      _db.execute('UPDATE transactions SET category_id=? WHERE id=?', [
        categoryId,
        id,
      ]);
    }
  }

  void setNote(List<int> ids, String note) {
    for (final id in ids) {
      _db.execute('UPDATE transactions SET note=? WHERE id=?', [note, id]);
    }
  }

  int createImport(String filename, int count) {
    _db.execute(
      'INSERT INTO imports(filename,created_at,count) VALUES(?,?,?)',
      [filename, DateTime.now().toIso8601String(), count],
    );
    return _db.lastInsertRowId;
  }

  void updateImportCount(int id, int count) =>
      _db.execute('UPDATE imports SET count=? WHERE id=?', [count, id]);

  List<({int id, String filename, DateTime createdAt, int count})> imports() =>
      _db
          .select('SELECT * FROM imports ORDER BY id DESC')
          .map(
            (r) => (
              id: r['id'] as int,
              filename: r['filename'] as String,
              createdAt: DateTime.parse(r['created_at'] as String),
              count: r['count'] as int,
            ),
          )
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
      .map(
        (r) => Rule(
          id: r['id'] as int,
          pattern: r['pattern'] as String,
          exact: r['exact'] == 1,
          categoryId: r['category_id'] as int?,
          label: r['label'] as String,
          note: r['note'] as String,
          groupId: r['group_id'] as int?,
        ),
      )
      .toList();

  // ---------- Grupos ----------
  List<Grupo> ruleGroups() => _db
      .select('SELECT * FROM rule_groups ORDER BY name COLLATE NOCASE')
      .map(
        (r) => Grupo(
          id: r['id'] as int,
          name: r['name'] as String,
          categoryId: r['category_id'] as int?,
          note: r['note'] as String,
        ),
      )
      .toList();

  int saveRuleGroup({
    int? id,
    required String name,
    int? categoryId,
    String note = '',
  }) {
    if (id == null) {
      _db.execute(
        'INSERT INTO rule_groups(name,category_id,note) VALUES(?,?,?)',
        [name, categoryId, note],
      );
      return _db.lastInsertRowId;
    }
    _db.execute(
      'UPDATE rule_groups SET name=?,category_id=?,note=? WHERE id=?',
      [name, categoryId, note, id],
    );
    return id;
  }

  /// Garante que existe uma regra para o título e devolve o seu id.
  int ensureRule(String pattern, {bool exact = true}) {
    final ex = _db.select('SELECT id FROM rules WHERE pattern=? AND exact=?', [
      pattern,
      exact ? 1 : 0,
    ]);
    if (ex.isNotEmpty) return ex.first['id'] as int;
    _db.execute('INSERT INTO rules(pattern,exact) VALUES(?,?)', [
      pattern,
      exact ? 1 : 0,
    ]);
    return _db.lastInsertRowId;
  }

  void setRuleGroup(int ruleId, int? groupId) =>
      _db.execute('UPDATE rules SET group_id=? WHERE id=?', [groupId, ruleId]);

  /// Copia os dados do grupo para as regras e tira-as do grupo (mantêm nome e categoria).
  void detachRule(int ruleId) {
    _db.execute(
      '''
      UPDATE rules SET
        category_id = (SELECT category_id FROM rule_groups WHERE id = rules.group_id),
        label = COALESCE((SELECT name FROM rule_groups WHERE id = rules.group_id), label),
        note = COALESCE((SELECT note FROM rule_groups WHERE id = rules.group_id), note),
        group_id = NULL
      WHERE id = ? AND group_id IS NOT NULL
    ''',
      [ruleId],
    );
  }

  void deleteRuleGroup(int id) {
    for (final r in _db.select('SELECT id FROM rules WHERE group_id=?', [id])) {
      detachRule(r['id'] as int);
    }
    _db.execute('DELETE FROM rule_groups WHERE id=?', [id]);
  }

  void upsertRule(
    String pattern,
    int? categoryId, {
    bool exact = true,
    String label = '',
    String note = '',
  }) {
    final ex = _db.select('SELECT id FROM rules WHERE pattern=? AND exact=?', [
      pattern,
      exact ? 1 : 0,
    ]);
    if (ex.isEmpty) {
      _db.execute(
        'INSERT INTO rules(pattern,exact,category_id,label,note) VALUES(?,?,?,?,?)',
        [pattern, exact ? 1 : 0, categoryId, label, note],
      );
    } else {
      _db.execute('UPDATE rules SET category_id=?,label=?,note=? WHERE id=?', [
        categoryId,
        label,
        note,
        ex.first['id'],
      ]);
    }
  }

  void deleteRule(int id) => _db.execute('DELETE FROM rules WHERE id=?', [id]);

  // ---------- Salários e definições ----------
  Map<String, int> salaries() => {
    for (final r in _db.select('SELECT * FROM salaries'))
      r['month'] as String: r['amount'] as int,
  };

  void setSalary(String month, int? amount) {
    if (amount == null) {
      _db.execute('DELETE FROM salaries WHERE month=?', [month]);
    } else {
      _db.execute('INSERT OR REPLACE INTO salaries(month,amount) VALUES(?,?)', [
        month,
        amount,
      ]);
    }
  }

  String? setting(String key) {
    final r = _db.select('SELECT value FROM settings WHERE key=?', [key]);
    return r.isEmpty ? null : r.first['value'] as String;
  }

  void putSetting(String key, String value) => _db.execute(
    'INSERT OR REPLACE INTO settings(key,value) VALUES(?,?)',
    [key, value],
  );

  // ---------- Investimentos ----------
  List<InvestAccount> investAccounts() => _db
      .select('SELECT * FROM invest_accounts ORDER BY name COLLATE NOCASE')
      .map(
        (r) => InvestAccount(
          id: r['id'] as int,
          name: r['name'] as String,
          emoji: r['emoji'] as String,
          note: r['note'] as String,
          archived: r['archived'] == 1,
        ),
      )
      .toList();

  int saveInvestAccount({
    int? id,
    required String name,
    String emoji = '',
    String note = '',
    bool archived = false,
  }) {
    if (id == null) {
      _db.execute(
        'INSERT INTO invest_accounts(name,emoji,note,archived) VALUES(?,?,?,?)',
        [name, emoji, note, archived ? 1 : 0],
      );
      return _db.lastInsertRowId;
    }
    _db.execute(
      'UPDATE invest_accounts SET name=?,emoji=?,note=?,archived=? WHERE id=?',
      [name, emoji, note, archived ? 1 : 0, id],
    );
    return id;
  }

  void deleteInvestAccount(int id) {
    // os movimentos do banco associados deixam de apontar para a plataforma (continuam transferências)
    _db.execute('DELETE FROM invest_accounts WHERE id=?', [id]);
  }

  List<Holding> holdings() => _db
      .select('SELECT * FROM holdings ORDER BY name COLLATE NOCASE')
      .map((r) {
        final at = r['last_price_at'] as String?;
        return Holding(
          id: r['id'] as int,
          accountId: r['account_id'] as int,
          name: r['name'] as String,
          symbol: r['symbol'] as String,
          provider: PriceProvider.values.firstWhere(
            (p) => p.name == r['provider'],
            orElse: () => PriceProvider.manual,
          ),
          kind: HoldingKind.values.firstWhere(
            (k) => k.name == r['kind'],
            orElse: () => HoldingKind.other,
          ),
          lastPrice: (r['last_price'] as num?)?.toDouble(),
          lastPriceAt: at == null ? null : DateTime.tryParse(at),
          archived: r['archived'] == 1,
          currency: (r['currency'] as String?) ?? 'EUR',
          currencyManual: r['currency_manual'] == 1,
          lastPriceOrig: (r['last_price_orig'] as num?)?.toDouble(),
          lastFx: (r['last_fx'] as num?)?.toDouble(),
          logo: r['logo'] as Uint8List?,
        );
      })
      .toList();

  int saveHolding(Holding h, {bool isNew = false}) {
    final vals = [
      h.accountId,
      h.name,
      h.symbol,
      h.provider.name,
      h.kind.name,
      h.lastPrice,
      h.lastPriceAt?.toIso8601String(),
      h.archived ? 1 : 0,
      h.currency,
      h.lastPriceOrig,
      h.lastFx,
      h.currencyManual ? 1 : 0,
      h.logo,
    ];
    if (isNew) {
      _db.execute(
        'INSERT INTO holdings(account_id,name,symbol,provider,kind,last_price,last_price_at,archived,currency,last_price_orig,last_fx,currency_manual,logo) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?)',
        vals,
      );
      return _db.lastInsertRowId;
    }
    _db.execute(
      'UPDATE holdings SET account_id=?,name=?,symbol=?,provider=?,kind=?,last_price=?,last_price_at=?,archived=?,currency=?,last_price_orig=?,last_fx=?,currency_manual=?,logo=? WHERE id=?',
      [...vals, h.id],
    );
    return h.id;
  }

  void deleteHolding(int id) =>
      _db.execute('DELETE FROM holdings WHERE id=?', [id]);

  List<InvestOp> investOps() => _db
      .select('SELECT * FROM invest_ops ORDER BY date, id')
      .map(
        (r) => InvestOp(
          id: r['id'] as int,
          accountId: r['account_id'] as int,
          holdingId: r['holding_id'] as int?,
          date: DateTime.parse(r['date'] as String),
          type: OpType.values.firstWhere(
            (t) => t.name == r['type'],
            orElse: () => OpType.cash,
          ),
          quantity: (r['quantity'] as num).toDouble(),
          price: (r['price'] as num).toDouble(),
          fx: (r['fx'] as num?)?.toDouble(),
          amount: r['amount'] as int,
          fee: r['fee'] as int,
          note: r['note'] as String,
          txnId: r['txn_id'] as int?,
          allocate: (r['allocate'] as int? ?? 1) == 1,
        ),
      )
      .toList();

  int saveInvestOp(InvestOp o, {bool isNew = false}) {
    final vals = [
      o.accountId,
      o.holdingId,
      isoDate(o.date),
      o.type.name,
      o.quantity,
      o.price,
      o.amount,
      o.fee,
      o.note,
      o.fx,
      o.txnId,
      o.allocate ? 1 : 0,
    ];
    if (isNew) {
      _db.execute(
        'INSERT INTO invest_ops(account_id,holding_id,date,type,quantity,price,amount,fee,note,fx,txn_id,allocate) VALUES(?,?,?,?,?,?,?,?,?,?,?,?)',
        vals,
      );
      return _db.lastInsertRowId;
    }
    _db.execute(
      'UPDATE invest_ops SET account_id=?,holding_id=?,date=?,type=?,quantity=?,price=?,amount=?,fee=?,note=?,fx=?,txn_id=?,allocate=? WHERE id=?',
      [...vals, o.id],
    );
    return o.id;
  }

  /// Liga [opIds] à transferência [txnId] e desliga as que estavam ligadas a ela e não estão na lista.
  void setOpsTransfer(int txnId, Iterable<int> opIds) {
    _db.execute('UPDATE invest_ops SET txn_id=NULL WHERE txn_id=?', [txnId]);
    for (final id in opIds) {
      _db.execute('UPDATE invest_ops SET txn_id=? WHERE id=?', [txnId, id]);
    }
  }

  void deleteInvestOp(int id) =>
      _db.execute('DELETE FROM invest_ops WHERE id=?', [id]);

  List<({int id, String pattern, int accountId})> investPatterns() => _db
      .select('SELECT * FROM invest_patterns ORDER BY id')
      .map(
        (r) => (
          id: r['id'] as int,
          pattern: r['pattern'] as String,
          accountId: r['account_id'] as int,
        ),
      )
      .toList();

  void addInvestPattern(String pattern, int accountId) {
    final ex = _db.select('SELECT id FROM invest_patterns WHERE pattern=?', [
      pattern,
    ]);
    if (ex.isEmpty) {
      _db.execute(
        'INSERT INTO invest_patterns(pattern,account_id) VALUES(?,?)',
        [pattern, accountId],
      );
    } else {
      _db.execute('UPDATE invest_patterns SET account_id=? WHERE id=?', [
        accountId,
        ex.first['id'],
      ]);
    }
  }

  void deleteInvestPattern(int id) =>
      _db.execute('DELETE FROM invest_patterns WHERE id=?', [id]);

  /// Marca movimentos como entregas/levantamentos de uma plataforma (ou desmarca com [accountId] nulo).
  void setInvestAccount(List<int> txnIds, int? accountId) {
    for (final id in txnIds) {
      if (accountId == null) {
        _db.execute(
          'UPDATE transactions SET invest_account_id=NULL, is_transfer=0 WHERE id=?',
          [id],
        );
      } else {
        _db.execute(
          'UPDATE transactions SET invest_account_id=?, is_transfer=1, category_id=NULL WHERE id=?',
          [accountId, id],
        );
      }
    }
  }

  void wipeInvestments() => _db.execute(
    'DELETE FROM invest_ops; DELETE FROM holdings; DELETE FROM invest_patterns; DELETE FROM invest_accounts;',
  );

  void wipeAll() {
    _db.execute(
      'DELETE FROM transactions; DELETE FROM rules; DELETE FROM rule_groups; DELETE FROM imports; DELETE FROM salaries; DELETE FROM recurring_rules;',
    );
  }

  void wipeCategories() {
    _db.execute('DELETE FROM categories; DELETE FROM accounts;');
  }

  void deleteSetting(String key) =>
      _db.execute('DELETE FROM settings WHERE key=?', [key]);

  // ---------- Movimentos recorrentes ----------
  RecurringRule _rec(Row r) => RecurringRule(
    id: r['id'] as int,
    description: r['description'] as String,
    amount: r['amount'] as int,
    categoryId: r['category_id'] as int?,
    accountId: r['account_id'] as int?,
    freq: RecurrenceFreq.values.byName(r['freq'] as String),
    day: r['day'] as int,
    start: DateTime.parse(r['start_date'] as String),
    end: r['end_date'] == null ? null : DateTime.parse(r['end_date'] as String),
    lastGenerated: r['last_date'] == null
        ? null
        : DateTime.parse(r['last_date'] as String),
    active: r['active'] == 1,
  );

  List<RecurringRule> recurringRules() => _db
      .select(
        'SELECT * FROM recurring_rules ORDER BY description COLLATE NOCASE, id',
      )
      .map(_rec)
      .toList();

  int insertRecurring(RecurringRule r) {
    _db.execute(
      'INSERT INTO recurring_rules(description,amount,category_id,account_id,freq,day,start_date,end_date,last_date,active) VALUES(?,?,?,?,?,?,?,?,?,?)',
      _recValues(r),
    );
    return _db.lastInsertRowId;
  }

  /// Grava todos os campos da regra (inclui a última data gerada).
  void updateRecurring(RecurringRule r) => _db.execute(
    'UPDATE recurring_rules SET description=?,amount=?,category_id=?,account_id=?,freq=?,day=?,start_date=?,end_date=?,last_date=?,active=? WHERE id=?',
    [..._recValues(r), r.id],
  );

  void setRecurringLast(int id, DateTime d) => _db.execute(
    'UPDATE recurring_rules SET last_date=? WHERE id=?',
    [isoDate(d), id],
  );

  /// Apagar a regra não apaga os movimentos que já criou.
  void deleteRecurring(int id) =>
      _db.execute('DELETE FROM recurring_rules WHERE id=?', [id]);

  List<Object?> _recValues(RecurringRule r) => [
    r.description,
    r.amount,
    r.categoryId,
    r.accountId,
    r.freq.name,
    r.day,
    isoDate(r.start),
    r.end == null ? null : isoDate(r.end!),
    r.lastGenerated == null ? null : isoDate(r.lastGenerated!),
    r.active ? 1 : 0,
  ];

  void close() => _db.close();

  /// Cópia consistente de toda a base de dados (um ficheiro SQLite), para cópias de segurança.
  Uint8List snapshotBytes() {
    final dir = Directory.systemTemp.createTempSync('financas');
    try {
      final f = File(p.join(dir.path, 'copia.db'));
      _db.execute('VACUUM INTO ?', [f.path]);
      return f.readAsBytesSync();
    } finally {
      dir.deleteSync(recursive: true);
    }
  }

  /// Substitui todos os dados pelos de uma cópia (ficheiro SQLite). Lança [FormatException] se não for válida.
  Future<void> restoreBytes(Uint8List bytes) async {
    final dir = Directory.systemTemp.createTempSync('financas');
    try {
      final f = File(p.join(dir.path, 'restauro.db'));
      f.writeAsBytesSync(bytes);
      final Database src;
      try {
        src = sqlite3.open(f.path, mode: OpenMode.readOnly);
      } catch (_) {
        throw const FormatException('O ficheiro não é uma cópia válida.');
      }
      try {
        final bool ok;
        final int v;
        try {
          ok =
              src
                  .select(
                    "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('transactions','categories')",
                  )
                  .length ==
              2;
          v = src.select('PRAGMA user_version').first.values.first as int;
        } on SqliteException {
          throw const FormatException('O ficheiro não é uma cópia válida.');
        }
        if (!ok)
          throw const FormatException('O ficheiro não é uma cópia desta app.');
        if (v > _schemaVersion)
          throw const FormatException(
            'A cópia é de uma versão mais recente da app. Atualiza a app primeiro.',
          );
        await src.backup(_db).drain<void>();
      } finally {
        src.dispose();
      }
      _migrate(); // cópias antigas sobem para o esquema atual
    } finally {
      dir.deleteSync(recursive: true);
    }
  }

  static const _schemaVersion = 21;

  static Future<File> dbFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'financas.db'));
  }
}
