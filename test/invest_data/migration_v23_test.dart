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
        expect(r.select('PRAGMA user_version').first.values.first, 23);
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
}
