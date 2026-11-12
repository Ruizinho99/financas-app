import 'dart:io';
import 'dart:typed_data';

import 'package:financas/db/database.dart';
import 'package:financas/invest/data/market_cache.dart';
import 'package:financas/invest/invest.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

T _comCopia<T>(Uint8List bytes, T Function(Database db) fn) {
  final dir = Directory.systemTemp.createTempSync('mig23');
  try {
    final f = File('${dir.path}/c.db')..writeAsBytesSync(bytes);
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

Uint8List _alterar(Uint8List bytes, String sql) {
  final dir = Directory.systemTemp.createTempSync('mig23');
  try {
    final f = File('${dir.path}/c.db')..writeAsBytesSync(bytes);
    final db = sqlite3.open(f.path);
    db.execute(sql);
    db.close();
    return f.readAsBytesSync();
  } finally {
    dir.deleteSync(recursive: true);
  }
}

void main() {
  test(
    'base v22 migra para v23: dados preservados, tabela e coluna criadas',
    () async {
      final s = AppState(Db.memory());
      final conta = s.addInvestAccount('XTB');
      s.addHolding(
        Holding(
          id: 0,
          accountId: conta,
          name: 'Apple',
          symbol: 'APC.DE',
          provider: PriceProvider.yahoo,
          lastPrice: 150,
          analysisSymbol: 'AAPL',
        ),
      );
      s.addHolding(
        Holding(id: 0, accountId: conta, name: 'VWCE', symbol: 'VWCE.DE'),
      );
      // desce para a v22: sem a tabela nem a coluna
      final v22 = _alterar(s.backupBytes(), '''
      DROP TABLE market_cache;
      ALTER TABLE holdings DROP COLUMN analysis_symbol;
      PRAGMA user_version = 22;
    ''');
      _comCopia(v22, (raw) {
        expect(raw.select('PRAGMA user_version').first.values.first, 22);
        final cols = raw
            .select('PRAGMA table_info(holdings)')
            .map((r) => r['name'])
            .toList();
        expect(cols, isNot(contains('analysis_symbol')));
      });

      final db = Db.memory();
      await db.restoreBytes(v22);

      final raw = db.snapshotBytes();
      _comCopia(raw, (r) {
        expect(r.select('PRAGMA user_version').first.values.first, 24);
        final tabelas = r
            .select("SELECT name FROM sqlite_master WHERE type='table'")
            .map((x) => x['name'])
            .toSet();
        expect(tabelas, contains('market_cache'));
        final cols = r
            .select('PRAGMA table_info(market_cache)')
            .map((x) => x['name'])
            .toList();
        expect(cols, ['key', 'json', 'fetched_at']);
        expect(
          r
              .select('SELECT analysis_symbol FROM holdings')
              .map((x) => x.values.first),
          everyElement(''), // valor por omissão
        );
      });

      // dados preservados
      final hs = db.holdings();
      expect(hs.length, 2);
      final apple = hs.firstWhere((h) => h.name == 'Apple');
      expect(apple.symbol, 'APC.DE');
      expect(apple.lastPrice, 150);
      expect(apple.analysisSymbol, '');
      expect(hs.every((h) => h.analysisSymbol == ''), isTrue);

      // leitura e escrita do símbolo de análise
      db.saveHolding(apple.copyWith(analysisSymbol: 'AAPL'));
      expect(
        db.holdings().firstWhere((h) => h.name == 'Apple').analysisSymbol,
        'AAPL',
      );
      // copyWith sem o campo mantém-no
      expect(apple.copyWith(name: 'X').analysisSymbol, '');
      db.close();
    },
  );

  test('símbolo de análise sobrevive a uma cópia de segurança', () async {
    final s = AppState(Db.memory());
    final conta = s.addInvestAccount('XTB');
    s.addHolding(
      Holding(
        id: 0,
        accountId: conta,
        name: 'Apple',
        symbol: 'APC.DE',
        analysisSymbol: 'AAPL',
      ),
    );
    final db = Db.memory();
    await db.restoreBytes(s.backupBytes());
    expect(db.holdings().single.analysisSymbol, 'AAPL');
    db.close();
  });

  test('MarketCache sobre a base de dados: guarda, lê e expira', () {
    final db = Db.memory();
    var agora = DateTime(2026, 5, 1, 10);
    final c = MarketCache.db(db, now: () => agora);
    expect(c.get('k', MarketCache.priceTtl), isNull);
    c.put('k', {'a': 1});
    expect(c.get('k', MarketCache.priceTtl), {'a': 1});
    c.put('k', {'a': 2}); // substitui
    expect(c.get('k', MarketCache.priceTtl), {'a': 2});
    agora = agora.add(const Duration(minutes: 16));
    expect(c.get('k', MarketCache.priceTtl), isNull);
    expect(c.get('k', MarketCache.fundamentalsTtl), {'a': 2});
    db.close();
  });

  group('Correções F3', () {
    test('R3: a purga apaga entradas com mais de 7 dias e mantém as recentes', () {
      final db = Db.memory();
      final agora = DateTime(2026, 11, 12, 10);
      db.marketCacheWrite('velha', '{}', agora.subtract(const Duration(days: 8)));
      db.marketCacheWrite('limite', '{}', agora.subtract(const Duration(days: 6)));
      db.marketCacheWrite('nova', '{}', agora);
      db.purgeMarketCache(now: agora);
      expect(db.marketCacheRead('velha'), isNull);
      expect(db.marketCacheRead('limite'), isNotNull);
      expect(db.marketCacheRead('nova'), isNotNull);
      db.close();
    });

    test('R3: abrir uma base (migração) purga a cache antiga', () async {
      final s = AppState(Db.memory());
      s.addInvestAccount('XTB');
      final com = _alterar(s.backupBytes(), '''
        INSERT INTO market_cache VALUES('velha','{}','2020-01-01T00:00:00');
        INSERT INTO market_cache VALUES('nova','{}','${DateTime.now().toIso8601String()}');
      ''');
      final db = Db.memory();
      await db.restoreBytes(com);
      expect(db.marketCacheRead('velha'), isNull);
      expect(db.marketCacheRead('nova'), isNotNull);
      db.close();
    });

    test('R3: a cópia de segurança não leva a market_cache (mas a tabela existe)', () {
      final db = Db.memory();
      db.marketCacheWrite('k', '{"a":1}', DateTime.now());
      final raw = db.snapshotBytes();
      _comCopia(raw, (r) {
        expect(r.select('SELECT count(*) c FROM market_cache').first['c'], 0);
        expect(r.select('PRAGMA user_version').first.values.first, 24);
      });
      // a base original mantém a cache
      expect(db.marketCacheRead('k'), isNotNull);
      db.close();
    });

    test('R3: apagar investimentos esvazia a cache de mercado', () {
      final s = AppState(Db.memory());
      s.db.marketCacheWrite('k', '{}', DateTime.now());
      s.wipe(categories: true);
      expect(s.db.marketCacheRead('k'), isNull);
      s.db.marketCacheWrite('k', '{}', DateTime.now());
      s.db.wipeInvestments();
      expect(s.db.marketCacheRead('k'), isNull);
    });

    test('R9: base v22 com a coluna já criada migra sem erro', () async {
      final s = AppState(Db.memory());
      final conta = s.addInvestAccount('XTB');
      s.addHolding(
        Holding(
          id: 0,
          accountId: conta,
          name: 'Apple',
          symbol: 'AAPL',
          analysisSymbol: 'AAPL',
        ),
      );
      // v22 "a meio": coluna já existe, sem tabela
      final meio = _alterar(
        s.backupBytes(),
        'DROP TABLE market_cache; PRAGMA user_version = 22;',
      );
      final db = Db.memory();
      await db.restoreBytes(meio);
      expect(db.holdings().single.analysisSymbol, 'AAPL'); // intacto
      _comCopia(db.snapshotBytes(), (r) {
        expect(r.select('PRAGMA user_version').first.values.first, 24);
      });
      db.close();
    });

    test('R9: erro real na migração propaga e desfaz tudo (nada de v23 a meio)', () async {
      final s = AppState(Db.memory());
      s.addInvestAccount('XTB');
      // v22 sem a tabela holdings: o ALTER falha de verdade
      final estragada = _alterar(
        s.backupBytes(),
        'DROP TABLE market_cache; DROP TABLE holdings; PRAGMA user_version = 22;',
      );
      final db = Db.memory();
      await expectLater(db.restoreBytes(estragada), throwsA(anything));
      _comCopia(db.snapshotBytes(), (r) {
        // a transação foi desfeita: sem market_cache e ainda v22
        final tabelas = r
            .select("SELECT name FROM sqlite_master WHERE type='table'")
            .map((x) => x['name'])
            .toSet();
        expect(tabelas, isNot(contains('market_cache')));
        expect(r.select('PRAGMA user_version').first.values.first, 22);
      });
      db.close();
    });
  });
}
