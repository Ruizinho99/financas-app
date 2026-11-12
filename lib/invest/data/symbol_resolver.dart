/// Resolve o "símbolo de análise" de um ativo: o símbolo do Yahoo com que se pedem as demonstrações.
///
/// Regras (plano e `docs/metricas-fundamentais.md`, Parte 4):
///  - NUNCA se corta o sufixo à sorte (`APC.DE` não é `APC`: pode ser outra empresa).
///  - Ordem: (1) símbolo de análise já definido; (2) o símbolo da posição, se devolver demonstrações;
///    (3) pesquisa por ISIN e por nome, só aceitando resultados cujo nome corresponda ao do ativo;
///    (4) senão fica por resolver, com sugestões para o utilizador escolher.
///  - O que vem de uma pesquisa pede sempre confirmação do utilizador.
library;

import '../invest.dart';
import '../metrics/financials.dart';
import '../price_service.dart';
import 'yahoo_market_data.dart';

/// De onde veio o símbolo.
enum SymbolSource {
  explicit, // definido pelo utilizador (Holding.analysisSymbol)
  own, // o símbolo da própria posição
  searched, // encontrado por pesquisa (ISIN ou nome)
  none, // por resolver
}

class ResolvedSymbol {
  final String symbol; // vazio se por resolver
  final SymbolSource source;
  final bool needsConfirmation;

  /// Alternativas para o utilizador confirmar ou escolher (ordenadas: as melhores primeiro).
  final List<SymbolHit> alternatives;
  const ResolvedSymbol({
    required this.symbol,
    required this.source,
    this.needsConfirmation = false,
    this.alternatives = const [],
  });

  /// Nada encontrado: o utilizador tem de indicar o símbolo (as [alternatives] são só sugestões).
  const ResolvedSymbol.unresolved({this.alternatives = const []})
    : symbol = '',
      source = SymbolSource.none,
      needsConfirmation = true;

  bool get resolved => symbol.isNotEmpty;

  @override
  String toString() => 'ResolvedSymbol($symbol, ${source.name})';
}

/// Palavras que não distinguem uma empresa (formas jurídicas e tipos de ação).
const _ruido = {
  'inc',
  'incorporated',
  'corp',
  'corporation',
  'co',
  'com',
  'company',
  'ltd',
  'limited',
  'plc',
  'sa',
  'se',
  'ag',
  'nv',
  'bv',
  'spa',
  'ab',
  'asa',
  'oyj',
  'llc',
  'lp',
  'kgaa',
  'the',
  'adr',
  'ord',
  'ordinary',
  'shares',
  'share',
  'common',
  'stock',
  'registered',
  'reg',
  'r',
};

const _acentos = {
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'å': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ø': 'o',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ç': 'c',
  'ñ': 'n',
  'ß': 'ss',
};

/// Nome normalizado em palavras: minúsculas, sem acentos nem pontuação e sem sufixos como Inc, Corp, SE, AG.
List<String> normalizeName(String s) {
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    b.write(_acentos[ch] ?? ch);
  }
  final words = b
      .toString()
      .replaceAll('&', ' and ')
      // "S.A." e "N.V." passam a "SA" e "NV" (mas "Amazon.com" não é afetado)
      .replaceAll(
        RegExp(r'(?<=(^|[^a-z0-9])[a-z])\.(?=[a-z]([^a-z0-9]|$))'),
        '',
      )
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .split(' ')
      .where((w) => w.isNotEmpty)
      .toList();
  final out = <String>[];
  for (var i = 0; i < words.length; i++) {
    final w = words[i];
    if (w == 'class' && i + 1 < words.length && words[i + 1].length == 1) {
      i++; // "Class A"
      continue;
    }
    if (_ruido.contains(w)) continue;
    out.add(w);
  }
  return out;
}

/// 2 = nomes iguais; 1 = um é o início do outro (no máximo 2 palavras a mais); 0 = não correspondem.
/// "Apple" ~ "Apple Inc." dá 2. "APC" ~ "Apple" dá 0.
int nameMatch(String a, String b) {
  final x = normalizeName(a), y = normalizeName(b);
  if (x.isEmpty || y.isEmpty) return 0;
  if (x.join(' ') == y.join(' ')) return 2;
  final short = x.length <= y.length ? x : y;
  final long = x.length <= y.length ? y : x;
  if (long.length - short.length > 2) return 0;
  for (var i = 0; i < short.length; i++) {
    if (short[i] != long[i]) return 0;
  }
  return 1;
}

bool _temDados(Financials f) => f.annual.isNotEmpty || f.quarterly.isNotEmpty;

/// Resolve o símbolo de análise de um ativo.
///
/// Passa o [holding] (símbolo, nome e símbolo de análise) ou os campos soltos [symbol] e [name].
/// [requireFinancials] = falso para ETFs, fundos e cripto (só análise de mercado): o símbolo da posição
/// é aceite sem verificar demonstrações.
Future<ResolvedSymbol> resolveAnalysisSymbol({
  Holding? holding,
  String? name,
  String? isin,
  String? symbol,
  required YahooMarketData data,
  required PriceService prices,
  bool requireFinancials = true,
}) async {
  final explicit = holding?.analysisSymbol.trim() ?? '';
  if (explicit.isNotEmpty) {
    return ResolvedSymbol(symbol: explicit, source: SymbolSource.explicit);
  }
  final own = (symbol ?? holding?.symbol ?? '').trim();
  final nome = (name ?? holding?.name ?? '').trim();
  final isinTxt = (isin ?? '').trim();

  // (2) o símbolo da posição, se devolver dados
  if (own.isNotEmpty) {
    if (!requireFinancials) {
      return ResolvedSymbol(symbol: own, source: SymbolSource.own);
    }
    if (_temDados(await data.financials(own))) {
      return ResolvedSymbol(symbol: own, source: SymbolSource.own);
    }
  }

  // (3) pesquisa por ISIN e depois por nome
  final vistos = <String>{if (own.isNotEmpty) own};
  final sugestoes = <SymbolHit>[];
  final aceites = <(int, SymbolHit)>[];
  for (final q in [isinTxt, nome]) {
    if (q.isEmpty) continue;
    List<SymbolHit> hits;
    try {
      hits = await prices.search(PriceProvider.yahoo, q);
    } on PriceException {
      continue;
    }
    for (final h in hits) {
      if (!vistos.add(h.symbol)) continue;
      sugestoes.add(h);
      // só aceita se o nome devolvido corresponder ao do ativo
      // (só com o ISIN e sem nome, o resultado da pesquisa por ISIN vale, mas pede confirmação)
      final m = nome.isEmpty ? (q == isinTxt ? 1 : 0) : nameMatch(nome, h.name);
      if (m > 0) aceites.add((m, h));
    }
    // o ISIN deu um resultado coerente: não precisa de pesquisar pelo nome
    if (aceites.isNotEmpty) break;
  }
  // os mais parecidos primeiro (a ordem da pesquisa mantém-se em caso de empate)
  final ordenados = [
    ...aceites.where((e) => e.$1 == 2),
    ...aceites.where((e) => e.$1 == 1),
  ].map((e) => e.$2).toList();

  var verificados = 0;
  for (final h in ordenados) {
    if (verificados >= 3) break;
    if (requireFinancials) {
      verificados++;
      if (!_temDados(await data.financials(h.symbol))) continue;
    }
    return ResolvedSymbol(
      symbol: h.symbol,
      source: SymbolSource.searched,
      needsConfirmation: true,
      alternatives: [
        for (final o in sugestoes)
          if (o.symbol != h.symbol) o,
      ],
    );
  }

  // (4) por resolver, com sugestões
  return ResolvedSymbol.unresolved(alternatives: sugestoes);
}
