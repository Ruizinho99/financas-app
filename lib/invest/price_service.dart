import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'invest.dart';

/// Preço obtido, já convertido para euros.
class PriceQuote {
  final double eur;
  final String currency; // moeda original do ativo
  final double original; // preço na moeda original
  final DateTime at;
  const PriceQuote(this.eur, this.currency, this.original, this.at);
}

class SymbolHit {
  final String symbol; // Yahoo: VWCE.DE · CoinGecko: id (bitcoin)
  final String name;
  final String exchange;
  final PriceProvider provider;
  const SymbolHit(this.symbol, this.name, this.exchange, this.provider);
}

class PriceException implements Exception {
  final String message;
  const PriceException(this.message);
  @override
  String toString() => message;
}

/// Preços através de APIs gratuitas e sem chave: Yahoo Finance (ETFs, ações, câmbios) e CoinGecko
/// (criptomoedas). Só é usado quando o utilizador pede para atualizar; envia apenas o símbolo do ativo.
class PriceService {
  PriceService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  final Map<String, double> _fx = {};

  static const _headers = {'User-Agent': 'Mozilla/5.0 (Linux; Android 14) FinancasApp/1.0', 'Accept': 'application/json'};

  Future<dynamic> _getJson(Uri uri) async {
    final http.Response r;
    try {
      r = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 12));
    } on TimeoutException {
      throw const PriceException('O serviço demorou demasiado a responder.');
    } catch (_) {
      throw const PriceException('Sem ligação à internet.');
    }
    if (r.statusCode == 429) throw const PriceException('Limite do serviço atingido. Tenta daqui a um minuto.');
    if (r.statusCode == 404) throw const PriceException('Símbolo não encontrado.');
    if (r.statusCode != 200) throw PriceException('Erro do serviço (${r.statusCode}).');
    try {
      return jsonDecode(utf8.decode(r.bodyBytes));
    } catch (_) {
      throw const PriceException('Resposta inesperada do serviço.');
    }
  }

  /// Preço atual em euros.
  Future<PriceQuote> quote(PriceProvider provider, String symbol) {
    final s = symbol.trim();
    if (s.isEmpty) throw const PriceException('Falta o símbolo.');
    return switch (provider) {
      PriceProvider.yahoo => _yahoo(s),
      PriceProvider.coingecko => _gecko(s),
      PriceProvider.manual => throw const PriceException('Preço manual: não há nada para atualizar.'),
    };
  }

  Future<({double price, String currency})> _yahooRaw(String symbol) async {
    // pathSegments codifica uma só vez (encodeComponent + Uri.https dava %253D em "USDEUR=X" e o Yahoo respondia 404)
    final uri = Uri(scheme: 'https', host: 'query1.finance.yahoo.com', pathSegments: ['v8', 'finance', 'chart', symbol], queryParameters: {'range': '1d', 'interval': '1d'});
    final j = await _getJson(uri);
    final chart = j is Map ? j['chart'] : null;
    final result = chart is Map ? chart['result'] : null;
    if (result is! List || result.isEmpty) throw const PriceException('Símbolo não encontrado.');
    final meta = result.first['meta'];
    final price = meta is Map ? meta['regularMarketPrice'] : null;
    if (price is! num) throw const PriceException('Sem preço disponível para este símbolo.');
    return (price: price.toDouble(), currency: (meta['currency'] as String?) ?? 'EUR');
  }

  Future<double> _fxToEur(String ccy) async {
    if (_fx.containsKey(ccy)) return _fx[ccy]!;
    final r = await _yahooRaw('${ccy}EUR=X');
    return _fx[ccy] = r.price;
  }

  Future<PriceQuote> _yahoo(String symbol) async {
    final raw = await _yahooRaw(symbol);
    var price = raw.price;
    var ccy = raw.currency;
    if (ccy == 'GBp' || ccy == 'GBX') {
      price /= 100; // libras em pence
      ccy = 'GBP';
    }
    final original = price;
    if (ccy != 'EUR') price *= await _fxToEur(ccy);
    return PriceQuote(price, ccy, original, DateTime.now());
  }

  Future<PriceQuote> _gecko(String id) async {
    final key = id.toLowerCase();
    final j = await _getJson(Uri.https('api.coingecko.com', '/api/v3/simple/price', {'ids': key, 'vs_currencies': 'eur'}));
    final v = j is Map ? j[key] : null;
    final eur = v is Map ? v['eur'] : null;
    if (eur is! num) throw const PriceException('Id não encontrado no CoinGecko (usa o id, ex.: bitcoin).');
    return PriceQuote(eur.toDouble(), 'EUR', eur.toDouble(), DateTime.now());
  }

  /// Procura ativos pelo nome ou símbolo.
  Future<List<SymbolHit>> search(PriceProvider provider, String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    switch (provider) {
      case PriceProvider.yahoo:
        final j = await _getJson(Uri.https('query2.finance.yahoo.com', '/v1/finance/search', {'q': q, 'quotesCount': '10', 'newsCount': '0'}));
        final quotes = j is Map ? j['quotes'] : null;
        if (quotes is! List) return [];
        return [
          for (final e in quotes)
            if (e is Map && e['symbol'] is String)
              SymbolHit(e['symbol'] as String, (e['shortname'] ?? e['longname'] ?? e['symbol']) as String, (e['exchDisp'] ?? e['exchange'] ?? '') as String, provider),
        ];
      case PriceProvider.coingecko:
        final j = await _getJson(Uri.https('api.coingecko.com', '/api/v3/search', {'query': q}));
        final coins = j is Map ? j['coins'] : null;
        if (coins is! List) return [];
        return [
          for (final e in coins.take(10))
            if (e is Map && e['id'] is String) SymbolHit(e['id'] as String, '${e['name']} (${(e['symbol'] as String?)?.toUpperCase() ?? ''})', 'CoinGecko', provider),
        ];
      case PriceProvider.manual:
        return [];
    }
  }

  void close() => _client.close();
}
