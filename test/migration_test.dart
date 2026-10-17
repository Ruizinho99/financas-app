import 'dart:io';
import 'dart:typed_data';

import 'package:financas/db/database.dart';
import 'package:financas/invest/invest.dart';
import 'package:financas/models.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// Base de dados atual com dados de todos os tipos (categorias, conta, movimentos, investimento).
Uint8List _copiaAtual() {
  final s = AppState(Db.memory());
  final alim = s.addCategory(const Categoria(id: 0, name: 'Alimentação'));
  s.addCategory(Categoria(id: 0, name: 'Supermercado', parentId: alim));
  final sal = s.addCategory(
    const Categoria(id: 0, name: 'Salário', isIncome: true),
  );
  final conta = s.addAccount('Conta à ordem', openingCents: 100000);
  s.addManual(
    date: DateTime(2026, 3, 2),
    description: 'Pingo Doce',
    amount: -2500,
    categoryId: alim,
    accountId: conta,
  );
  s.addManual(
    date: DateTime(2026, 3, 1),
    description: 'Empresa SA',
    amount: 150000,
    categoryId: sal,
    accountId: conta,
  );
  final xtb = s.addInvestAccount('XTB');
  final vwce = s.addHolding(
    Holding(
      id: 0,
      accountId: xtb,
      name: 'VWCE',
      symbol: 'VWCE.DE',
      provider: PriceProvider.yahoo,
      lastPrice: 120,
    ),
  );
  s.addOp(
    InvestOp(
      id: 0,
      accountId: xtb,
      holdingId: vwce,
      date: DateTime(2026, 2, 1),
      type: OpType.buy,
      quantity: 2,
      price: 100,
      amount: 20000,
    ),
  );
  return s.backupBytes();
}

/// Executa [fn] sobre uma cópia da base de dados aberta com o package sqlite3 (num ficheiro temporário).
T _comCopia<T>(Uint8List bytes, T Function(Database db) fn) {
  final dir = Directory.systemTemp.createTempSync('migracao');
  try {
    final f = File('${dir.path}/copia.db');
    f.writeAsBytesSync(bytes);
    final db = sqlite3.open(f.path);
    try {
      return fn(db);
    } finally {
      db.close();
    }
  } finally {
    dir.deleteSync(recursive: true);
  }
}

/// Devolve a cópia com as alterações feitas por [sql] (para simular bases antigas ou futuras).
Uint8List _alterar(Uint8List bytes, String sql) {
  final dir = Directory.systemTemp.createTempSync('migracao');
  try {
    final f = File('${dir.path}/copia.db');
    f.writeAsBytesSync(bytes);
    final db = sqlite3.open(f.path);
    db.execute(sql);
    db.close();
    return f.readAsBytesSync();
  } finally {
    dir.deleteSync(recursive: true);
  }
}

/// Desce uma cópia atual para o esquema da v13 (antes das migrações 14 a 20), como a v1.9.x.
Uint8List _descerParaV13(Uint8List bytes) => _alterar(bytes, '''
  DROP TABLE goals;
  DROP TABLE goal_targets;
  DROP TABLE goal_allocations;
  DROP TABLE planned_items;
  DROP TABLE invest_plan;
  DROP TABLE invest_plan_since;
  DROP TABLE invest_alerts_done;
  ALTER TABLE transactions DROP COLUMN reverses_id;
  ALTER TABLE transactions DROP COLUMN reversed_cents;
  ALTER TABLE accounts DROP COLUMN opening_cents;
  ALTER TABLE holdings DROP COLUMN logo;
  ALTER TABLE invest_ops DROP COLUMN allocate;
  PRAGMA user_version = 13;
''');

int _n(Database db, String sql) => db.select(sql).first.values.first as int;

/// Contagens das tabelas principais, para comparar antes e depois da migração.
Map<String, int> _contagens(Database db) => {
  for (final t in [
    'categories',
    'transactions',
    'accounts',
    'holdings',
    'invest_ops',
  ])
    t: _n(db, 'SELECT COUNT(*) FROM $t'),
};

void main() {
  test('base da v13 migra até à versão atual sem perder dados', () async {
    final atual = _copiaAtual();
    final antes = _comCopia(atual, _contagens);
    final antiga = _descerParaV13(atual);
    expect(_comCopia(antiga, (db) => _n(db, 'PRAGMA user_version')), 13);

    final db = Db.memory();
    await db.restoreBytes(antiga);
    final depois = db.snapshotBytes();

    _comCopia(depois, (raw) {
      expect(_n(raw, 'PRAGMA user_version'), greaterThanOrEqualTo(20));

      // tabelas criadas pelas migrações 17 a 20
      final tabelas = raw
          .select("SELECT name FROM sqlite_master WHERE type='table'")
          .map((r) => r['name'] as String)
          .toSet();
      expect(
        tabelas,
        containsAll([
          'goals',
          'goal_targets',
          'goal_allocations',
          'planned_items',
          'invest_plan',
          'invest_plan_since',
          'invest_alerts_done',
        ]),
      );

      // colunas novas com os valores por omissão
      expect(
        raw
            .select('SELECT allocate FROM invest_ops')
            .map((r) => r.values.first),
        everyElement(1),
      );
      expect(
        raw
            .select('SELECT reversed_cents FROM transactions')
            .map((r) => r.values.first),
        everyElement(0),
      );
      expect(
        raw
            .select('SELECT reverses_id FROM transactions')
            .map((r) => r.values.first),
        everyElement(isNull),
      );
      expect(
        raw
            .select('SELECT opening_cents FROM accounts')
            .map((r) => r.values.first),
        everyElement(0),
      );
      expect(
        raw.select('SELECT logo FROM holdings').map((r) => r.values.first),
        everyElement(isNull),
      );

      // dados originais continuam lá
      expect(_contagens(raw), antes);
      expect(
        _n(
          raw,
          "SELECT amount FROM transactions WHERE description = 'Pingo Doce'",
        ),
        -2500,
      );
      expect(
        _n(
          raw,
          "SELECT COUNT(*) FROM categories WHERE name = 'Supermercado' AND parent_id IS NOT NULL",
        ),
        1,
      );
    });

    final s = AppState(db);
    expect(() => s.reload(), returnsNormally);
    expect(s.transactions.length, antes['transactions']);
    expect(s.categories.length, antes['categories']);
    expect(s.accounts.first.name, 'Conta à ordem');
    expect(s.investOps.first.allocate, isTrue);
    db.close();
  });

  test('cópia com versão acima da atual é recusada', () async {
    final futura = _alterar(_copiaAtual(), 'PRAGMA user_version = 999');
    final db = Db.memory();
    await expectLater(
      db.restoreBytes(futura),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'mensagem',
          contains('versão mais recente'),
        ),
      ),
    );
    db.close();
  });
}
