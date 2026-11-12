/// Cache de dados de mercado (respostas JSON do Yahoo) em SQLite, com validade por tipo de dado.
/// Funciona também sem base de dados (memória ou "objeto nulo") para testes.
library;

import 'dart:convert';

import '../../db/database.dart';

/// Onde a cache guarda as entradas.
abstract class MarketCacheStore {
  ({String json, DateTime fetchedAt})? read(String key);
  void write(String key, String json, DateTime at);
}

/// Guarda na tabela `market_cache` da base de dados da app (migração v23).
class DbMarketCacheStore implements MarketCacheStore {
  DbMarketCacheStore(this._db);
  final Db _db;
  @override
  ({String json, DateTime fetchedAt})? read(String key) =>
      _db.marketCacheRead(key);
  @override
  void write(String key, String json, DateTime at) =>
      _db.marketCacheWrite(key, json, at);
}

/// Guarda em memória (testes e utilização sem base de dados).
class MemoryMarketCacheStore implements MarketCacheStore {
  final Map<String, ({String json, DateTime fetchedAt})> entries = {};
  @override
  ({String json, DateTime fetchedAt})? read(String key) => entries[key];
  @override
  void write(String key, String json, DateTime at) =>
      entries[key] = (json: json, fetchedAt: at);
}

/// Objeto nulo: nunca guarda nada (cada pedido vai à rede).
class _NoStore implements MarketCacheStore {
  const _NoStore();
  @override
  ({String json, DateTime fetchedAt})? read(String key) => null;
  @override
  void write(String key, String json, DateTime at) {}
}

class MarketCache {
  MarketCache({MarketCacheStore? store, DateTime Function()? now})
    : _store = store ?? const _NoStore(),
      _now = now ?? DateTime.now;

  /// Sem cache: tudo vai à rede.
  MarketCache.none() : this();

  /// Só em memória (válida enquanto a app estiver aberta).
  MarketCache.memory({DateTime Function()? now})
    : this(store: MemoryMarketCacheStore(), now: now);

  /// Sobre a base de dados da app.
  MarketCache.db(Db db, {DateTime Function()? now})
    : this(store: DbMarketCacheStore(db), now: now);

  final MarketCacheStore _store;
  final DateTime Function() _now;

  /// Validade por tipo de dado. O crumb do Yahoo não se guarda aqui (só em memória).
  static const priceTtl = Duration(minutes: 15); // preços e histórico
  static const fundamentalsTtl = Duration(hours: 24); // demonstrações
  static const profileTtl = Duration(hours: 24); // perfil e estatísticas

  /// Valor guardado se ainda for válido (idade <= [ttl]); senão `null`.
  Object? get(String key, Duration ttl) {
    final e = _store.read(key);
    if (e == null) return null;
    final age = _now().difference(e.fetchedAt);
    if (age.isNegative || age > ttl) return null;
    try {
      return jsonDecode(e.json);
    } catch (_) {
      return null;
    }
  }

  void put(String key, Object? value) =>
      _store.write(key, jsonEncode(value), _now());

  /// Devolve o valor da cache se válido; senão corre [fetch], guarda o resultado (se não for nulo e se
  /// [worthCaching], quando dado, o aceitar) e devolve-o. Assim uma resposta vazia não fica em cache 24 h.
  Future<Object?> cachedOr(
    String key,
    Duration ttl,
    Future<Object?> Function() fetch, {
    bool Function(Object? value)? worthCaching,
  }) async {
    final hit = get(key, ttl);
    if (hit != null) return hit;
    final v = await fetch();
    if (v != null && (worthCaching == null || worthCaching(v))) put(key, v);
    return v;
  }
}
