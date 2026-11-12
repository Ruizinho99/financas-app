/// Resolve o "símbolo de análise" de um ativo: o símbolo do Yahoo com que se pedem as demonstrações.
///
/// Regras (plano e `docs/metricas-fundamentais.md`, Parte 4):
///  - NUNCA se corta o sufixo à sorte (`APC.DE` não é `APC`: pode ser outra empresa).
///  - Ordem: (1) símbolo de análise já definido; (2) o símbolo da posição, se devolver demonstrações;
///    (3) pesquisa por ISIN e por nome, só aceitando resultados cujo nome corresponda ao do ativo;
///    (4) senão fica por resolver, com sugestões para o utilizador escolher.
///  - O que vem de uma pesquisa pede sempre confirmação do utilizador.
///  - Erro de rede, limite do serviço ou timeout NÃO é "sem dados": propaga-se [PriceException] em vez de
///    seguir para a pesquisa por nome (que daria um símbolo errado só porque o primeiro pedido falhou).
///  - Futuros, opções e índices nunca são candidatos; ETFs só se aceitam com o nome igual.
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
  // ETFs e fundos: tipo de unidade e política de rendimentos
  'ucits',
  'etf',
  'acc',
  'dist',
  '1c',
  '1d',
  '2c',
  '2d',
  'accumulating',
  'distributing',
  'capitalisation',
  'capitalization',
};

/// Palavras a mais num nome que NÃO mudam a empresa (Ford ~ Ford Motor). Qualquer outra (Otosan,
/// Hospitality, Consolidated, Information Technology...) indica outra entidade: o prefixo não basta.
const _extrasGenericos = {
  'motor',
  'motors',
  'group',
  'holding',
  'holdings',
  'international',
  'intl',
  'global',
  'worldwide',
  'technologies',
  'technology',
  'systems',
  'industries',
  'enterprises',
  'class',
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
      i++; // "Class A": sai do nome (a letra compara-se à parte em nameMatch)
      continue;
    }
    if (_ruido.contains(w)) continue;
    out.add(w);
  }
  return out;
}

/// Letra da classe de ação ("Class B" -> "b"), se o nome tiver uma.
String? _classe(String s) {
  final m = RegExp(r'\bclass\s+([a-z])\b').firstMatch(s.toLowerCase());
  return m?.group(1);
}

/// Variantes de um nome para comparar: o nome inteiro e, se tiver um travessão com espaços
/// ("EDP - Energias de Portugal"), cada um dos lados.
List<String> _variantes(String s) => [
  s,
  ...s.split(RegExp(r'\s[-–—]\s')).where((p) => p.trim().isNotEmpty),
];

int _match1(List<String> x, List<String> y) {
  if (x.isEmpty || y.isEmpty) return 0;
  // "TOTAL ENERGIES" ~ "TotalEnergies": mesmas letras com as palavras juntas
  if (x.join('') == y.join('')) return 2;
  final short = x.length <= y.length ? x : y;
  final long = x.length <= y.length ? y : x;
  if (long.length - short.length > 2) return 0;
  for (var i = 0; i < short.length; i++) {
    if (short[i] != long[i]) return 0;
  }
  if (long.length == short.length) return 2;
  // as palavras a mais têm de ser genéricas: "Apple" não é "Apple Hospitality REIT"
  for (var i = short.length; i < long.length; i++) {
    final w = long[i];
    if (!_extrasGenericos.contains(w) && w.length > 1) return 0;
  }
  return 1;
}

/// 2 = nomes iguais; 1 = um é o início do outro, só com palavras a mais genéricas (no máximo 2); 0 = não
/// correspondem. "Apple" ~ "Apple Inc." dá 2; "Ford" ~ "Ford Motor" dá 1; "Ford" ~ "Ford Otosan" e
/// "APC" ~ "Apple" dão 0. Classes de ação diferentes (BRK Class A / Class B) não correspondem.
int nameMatch(String a, String b) {
  final ca = _classe(a), cb = _classe(b);
  if (ca != null && cb != null && ca != cb) return 0;
  var best = 0;
  for (final va in _variantes(a)) {
    for (final vb in _variantes(b)) {
      final m = _match1(normalizeName(va), normalizeName(vb));
      if (m > best) best = m;
      if (best == 2) return 2;
    }
  }
  return best;
}

/// Demonstrações do símbolo; se o pedido falhou (rede, 429, timeout) lança em vez de parecer "sem dados".
Future<Financials> _financials(YahooMarketData data, String symbol) async {
  final f = await data.financials(symbol);
  if (f.failed && !_temDados(f)) {
    throw const PriceException(
      'Não foi possível obter os dados (sem ligação ou limite do serviço). Tenta mais tarde.',
    );
  }
  return f;
}

/// Futuros, opções e índices (e símbolos como `TSLA=F`) não são empresas analisáveis.
bool _naoAnalisavel(SymbolHit h) {
  const tipos = {'FUTURE', 'OPTION', 'INDEX'};
  return tipos.contains(h.quoteType.toUpperCase()) || h.symbol.contains('=F');
}

bool _eFundo(SymbolHit h) {
  final t = h.quoteType.toUpperCase();
  return t == 'ETF' || t == 'MUTUALFUND';
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
    if (_temDados(await _financials(data, own))) {
      return ResolvedSymbol(symbol: own, source: SymbolSource.own);
    }
  }

  // (3) pesquisa por ISIN e depois por nome
  final vistos = <String>{if (own.isNotEmpty) own};
  final sugestoes = <SymbolHit>[];
  final aceites = <(int, SymbolHit)>[];
  PriceException? erroPesquisa;
  for (final q in [isinTxt, nome]) {
    if (q.isEmpty) continue;
    List<SymbolHit> hits;
    try {
      hits = await prices.search(PriceProvider.yahoo, q);
    } on PriceException catch (e) {
      erroPesquisa ??= e; // tenta a outra pesquisa; se nada resolver, o erro propaga-se no fim
      continue;
    }
    for (final h in hits) {
      if (_naoAnalisavel(h)) continue; // futuros, opções e índices não têm demonstrações
      if (!vistos.add(h.symbol)) continue;
      sugestoes.add(h);
      // só aceita se o nome devolvido corresponder ao do ativo
      // (só com o ISIN e sem nome, o resultado da pesquisa por ISIN vale, mas pede confirmação)
      final m = nome.isEmpty ? (q == isinTxt ? 1 : 0) : nameMatch(nome, h.name);
      // um ETF/fundo só vale com o nome igual: o prefixo apanha outros produtos da mesma casa
      if (m == 1 && _eFundo(h)) continue;
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
      if (!_temDados(await _financials(data, h.symbol))) continue;
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

  // (4) por resolver, com sugestões; se a pesquisa falhou (e não deu nada), não se diz "sem dados"
  if (erroPesquisa != null && sugestoes.isEmpty) throw erroPesquisa;
  return ResolvedSymbol.unresolved(alternatives: sugestoes);
}
