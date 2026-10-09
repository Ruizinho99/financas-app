import '../import/parsers.dart' show parseDate;
import 'invest.dart';

/// Compra, venda ou dividendo lido de um ficheiro (PDF, CSV ou Excel) de uma corretora.
class ParsedTrade {
  DateTime date;
  String kind; // 'buy' | 'sell' | 'dividend'
  String name;
  String symbol;
  String isin;
  double quantity; // sempre positiva
  double price; // por unidade, na moeda [currency]
  String currency; // vazio = não indicada no ficheiro
  double fee; // comissão, na mesma moeda (positiva)
  double? total; // valor total da linha, na mesma moeda (positivo), se indicado
  double? rate; // unidades da moeda por 1 unidade da moeda de base, se o ficheiro indicar
  String note;
  ParsedTrade({
    required this.date,
    required this.kind,
    this.name = '',
    this.symbol = '',
    this.isin = '',
    this.quantity = 0,
    this.price = 0,
    this.currency = '',
    this.fee = 0,
    this.total,
    this.rate,
    this.note = '',
  });

  /// Valor sem comissão, na moeda da linha.
  double get gross => kind == 'dividend' ? (total ?? 0) : quantity * price;

  /// Chave que identifica o instrumento: ISIN, símbolo ou nome.
  String get key {
    if (isin.isNotEmpty) return isin.toUpperCase();
    if (symbol.isNotEmpty) return symbol.toUpperCase();
    return name.toUpperCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

/// Número escrito em formato português ou inglês ("1.234,56", "1,234.56", "12.5", "(3,00)", "US$ 10").
double? parseDecimal(String input) {
  var s = input.trim();
  if (s.isEmpty) return null;
  final neg = s.startsWith('-') || s.endsWith('-') || (s.startsWith('(') && s.endsWith(')'));
  s = s.replaceAll(RegExp(r'[^\d,.]'), '');
  if (s.isEmpty) return null;
  final lc = s.lastIndexOf(','), ld = s.lastIndexOf('.');
  if (lc >= 0 && ld >= 0) {
    s = lc > ld ? s.replaceAll('.', '').replaceAll(',', '.') : s.replaceAll(',', '');
  } else if (lc >= 0) {
    // só vírgulas: decimal ("12,5"), ou milhares se houver várias ("1,234,567")
    s = s.indexOf(',') != lc ? s.replaceAll(',', '') : s.replaceAll(',', '.');
  } else if (ld >= 0 && s.indexOf('.') != ld) {
    s = s.replaceAll('.', ''); // "1.234.567"
  }
  final v = double.tryParse(s);
  if (v == null) return null;
  return neg ? -v : v;
}

// ---------------------------------------------------------------------------
// Tabelas (CSV / Excel)
// ---------------------------------------------------------------------------
class TradeMapping {
  int headerRow; // -1: sem cabeçalho
  int? date, type, name, symbol, isin, quantity, price, currency, fee, total, rate;
  TradeMapping({this.headerRow = 0, this.date, this.type, this.name, this.symbol, this.isin, this.quantity, this.price, this.currency, this.fee, this.total, this.rate});

  bool get usable => date != null && quantity != null && (price != null || total != null);

  /// Colunas, na ordem em que aparecem no ecrã de mapeamento.
  static const fields = <(String, String)>[
    ('date', 'Data'),
    ('type', 'Tipo (compra / venda)'),
    ('name', 'Nome do ativo'),
    ('symbol', 'Símbolo'),
    ('isin', 'ISIN'),
    ('quantity', 'Quantidade'),
    ('price', 'Preço por unidade'),
    ('total', 'Valor total'),
    ('fee', 'Comissão'),
    ('currency', 'Moeda'),
    ('rate', 'Câmbio (unidades da moeda por 1 da moeda de base)'),
  ];

  int? get_(String f) => switch (f) {
        'date' => date,
        'type' => type,
        'name' => name,
        'symbol' => symbol,
        'isin' => isin,
        'quantity' => quantity,
        'price' => price,
        'total' => total,
        'fee' => fee,
        'currency' => currency,
        'rate' => rate,
        _ => null,
      };

  void set_(String f, int? v) {
    switch (f) {
      case 'date':
        date = v;
      case 'type':
        type = v;
      case 'name':
        name = v;
      case 'symbol':
        symbol = v;
      case 'isin':
        isin = v;
      case 'quantity':
        quantity = v;
      case 'price':
        price = v;
      case 'total':
        total = v;
      case 'fee':
        fee = v;
      case 'currency':
        currency = v;
      case 'rate':
        rate = v;
    }
  }
}

String _norm(String s) {
  const from = 'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ';
  const to = 'AAAAAEEEEIIIIOOOOOUUUUCN';
  final b = StringBuffer();
  for (final c in s.toUpperCase().split('')) {
    final i = from.indexOf(c);
    b.write(i >= 0 ? to[i] : c);
  }
  return b.toString().trim();
}

String? _tradeHeader(String h) {
  final s = _norm(h);
  if (s.isEmpty) return null;
  if (RegExp(r'^ISIN').hasMatch(s)) return 'isin';
  if (RegExp(r'CAMBIO|EXCHANGE RATE|^FX|FX RATE|TAXA DE CAMBIO').hasMatch(s)) return 'rate';
  if (RegExp(r'COMISS|COMMISSION|^FEES?$|FEE\b|CUSTOS|CHARGES|TAXAS? DE TRANS|TRANSACTION COST').hasMatch(s)) return 'fee';
  if (RegExp(r'^(MOEDA|CURRENCY|DIVISA)').hasMatch(s)) return 'currency';
  if (RegExp(r'QUANTIDADE|^QTD|QUANTITY|^SHARES|^UNITS|^VOLUME|NO\. OF SHARES|N[O°] DE ACOES|ACOES|UNIDADES').hasMatch(s)) return 'quantity';
  if (RegExp(r'^(PRECO|PRICE|COTACAO|COTACAO|OPEN PRICE|PRECO MEDIO|PRECO UNIT|UNIT PRICE|PRICE PER SHARE)').hasMatch(s)) return 'price';
  if (RegExp(r'^SIMBOLO|^SYMBOL|^TICKER').hasMatch(s)) return 'symbol';
  if (RegExp(r'^(TIPO|TYPE|SIDE|ACTION|ACAO|OPERACAO|DIRECAO|DIRECTION|BUY/SELL|COMPRA/VENDA)').hasMatch(s)) return 'type';
  if (RegExp(r'^(NOME|NAME|PRODUTO|PRODUCT|INSTRUMENT|INSTRUMENTO|ATIVO|ASSET|SECURITY|TITULO|DESCRI)').hasMatch(s)) return 'name';
  if (RegExp(r'^(DATA|DATE|TIME|HORA DE|EXECUTION|OPEN TIME|TRADE DATE|DATA DA ORDEM|DATA OPERACAO)').hasMatch(s) && !RegExp(r'VALOR|VALUE').hasMatch(s)) return 'date';
  if (RegExp(r'^(TOTAL|VALOR|AMOUNT|MONTANTE|VALUE|PROCEEDS|NET|VALOR LOCAL|VALOR EUR|GROSS)').hasMatch(s)) return 'total';
  return null;
}

TradeMapping guessTradeMapping(List<List<String>> table) {
  final m = TradeMapping();
  var best = -1, bestScore = 0;
  for (var i = 0; i < table.length && i < 20; i++) {
    final kinds = {for (final c in table[i]) _tradeHeader(c)}..remove(null);
    if (kinds.length > bestScore) {
      bestScore = kinds.length;
      best = i;
    }
  }
  if (best < 0 || bestScore < 3) {
    m.headerRow = -1;
    return m;
  }
  m.headerRow = best;
  for (var c = 0; c < table[best].length; c++) {
    final k = _tradeHeader(table[best][c]);
    if (k != null && m.get_(k) == null) m.set_(k, c);
  }
  return m;
}

String _kindOf(String raw, double? qty) {
  final s = _norm(raw);
  if (s.isEmpty) return qty != null && qty < 0 ? 'sell' : 'buy';
  if (RegExp(r'DIVID|JURO|INTEREST|COUPON|CUPAO').hasMatch(s)) return 'dividend';
  if (RegExp(r'SELL|VEND|SALE|^V$|^S$|SOLD|LIQUID').hasMatch(s)) return 'sell';
  if (RegExp(r'BUY|COMPR|PURCHASE|^C$|^B$|BOUGHT|SUBSCR').hasMatch(s)) return 'buy';
  return ''; // outra coisa (depósito, taxa, impostos…): ignorar
}

/// Compras, vendas e dividendos de uma tabela. As linhas que não são operações são ignoradas.
List<ParsedTrade> tradesFromTable(List<List<String>> table, TradeMapping m, {int? defaultYear}) {
  final out = <ParsedTrade>[];
  String at(List<String> r, int? c) => (c == null || c >= r.length) ? '' : r[c].trim();
  for (var i = m.headerRow + 1; i < table.length; i++) {
    final r = table[i];
    final d = parseDate(at(r, m.date), defaultYear: defaultYear);
    if (d == null) continue;
    final q = parseDecimal(at(r, m.quantity));
    var kind = _kindOf(at(r, m.type), q);
    if (kind.isEmpty) continue;
    var qty = q?.abs() ?? 0;
    var price = parseDecimal(at(r, m.price))?.abs() ?? 0;
    final total = parseDecimal(at(r, m.total))?.abs();
    if (kind != 'dividend') {
      if (qty <= 0) continue;
      if (price <= 0 && total != null) price = total / qty;
      if (price <= 0) continue;
    } else if (total == null || total <= 0) {
      continue;
    }
    final fx = parseDecimal(at(r, m.rate));
    out.add(ParsedTrade(
      date: d,
      kind: kind,
      name: at(r, m.name),
      symbol: at(r, m.symbol),
      isin: at(r, m.isin),
      quantity: kind == 'dividend' ? 0 : qty,
      price: kind == 'dividend' ? 0 : price,
      currency: at(r, m.currency).toUpperCase(),
      fee: parseDecimal(at(r, m.fee))?.abs() ?? 0,
      total: total,
      rate: fx != null && fx > 0 ? fx : null,
    ));
  }
  return out;
}

// ---------------------------------------------------------------------------
// PDF (texto): tenta reconhecer linhas do tipo "05/01/2025 Compra Apple Inc 2 150,00 USD 300,00"
// ---------------------------------------------------------------------------
final _isinRe = RegExp(r'\b[A-Z]{2}[A-Z0-9]{9}\d\b');
final _dateTok = RegExp(r'\b(\d{4}[-/.]\d{1,2}[-/.]\d{1,2}|\d{1,2}[-/.]\d{1,2}[-/.]\d{2,4})\b');
final _kindTok = RegExp(r'\b(COMPRA|COMPRAS|BUY|BOUGHT|PURCHASE|VENDA|VENDAS|SELL|SOLD|SALE|DIVIDENDO|DIVIDEND|DIVIDENDOS|JUROS)\b', caseSensitive: false);
final _numTok = RegExp(r'(?<![\w.,])[-+]?\(?\d{1,3}(?:\.\d{3})+(?:,\d+)?\)?(?![\w])|(?<![\w.,])[-+]?\(?\d+(?:[.,]\d+)?\)?(?![\w])');
const _knownCcy = {'EUR', 'USD', 'GBP', 'CHF', 'CAD', 'AUD', 'JPY', 'SEK', 'NOK', 'DKK', 'PLN', 'BRL'};

List<ParsedTrade> tradesFromText(String text, {int? defaultYear}) {
  final out = <ParsedTrade>[];
  for (final raw in text.split('\n')) {
    final line = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (line.isEmpty) continue;
    final dm = _dateTok.firstMatch(line);
    final km = _kindTok.firstMatch(line);
    if (dm == null || km == null) continue;
    final date = parseDate(dm[1]!, defaultYear: defaultYear);
    if (date == null) continue;
    final w = km[1]!.toUpperCase();
    final kind = RegExp(r'^(VEND|SELL|SOLD|SALE)').hasMatch(w)
        ? 'sell'
        : RegExp(r'^(DIV|JUROS)').hasMatch(w)
            ? 'dividend'
            : 'buy';
    final isin = _isinRe.firstMatch(line)?[0] ?? '';
    // tudo o que vem depois da palavra do tipo (ou depois da data, se vier antes)
    final from = km.end > dm.end ? km.end : dm.end;
    var rest = line.substring(from);
    var ccy = '';
    for (final t in rest.split(' ')) {
      if (_knownCcy.contains(t.toUpperCase()) && t == t.toUpperCase()) {
        ccy = t;
        break;
      }
    }
    final nums = <double>[];
    var firstNum = rest.length;
    for (final m in _numTok.allMatches(rest)) {
      final tok = m[0]!;
      if (isin.isNotEmpty && isin.contains(tok)) continue;
      final v = parseDecimal(tok);
      if (v == null) continue;
      if (nums.isEmpty) firstNum = m.start;
      nums.add(v);
    }
    var name = rest.substring(0, firstNum).replaceAll(isin, '').replaceAll(RegExp(r'\b(EUR|USD|GBP|CHF)\b'), '').trim();
    name = name.replaceAll(RegExp(r'^[-–:|\s]+|[-–:|\s]+$'), '');
    if (kind == 'dividend') {
      if (nums.isEmpty) continue;
      out.add(ParsedTrade(date: date, kind: kind, name: name, isin: isin, currency: ccy, total: nums.last.abs()));
      continue;
    }
    if (nums.length < 2) continue;
    final qty = nums[0].abs();
    final price = nums[1].abs();
    if (qty <= 0 || price <= 0) continue;
    double? total;
    var fee = 0.0;
    if (nums.length >= 3) {
      total = nums[2].abs();
      // total = qty × preço ± comissão; se houver um quarto valor, é a comissão
      if (nums.length >= 4) {
        fee = nums[2].abs();
        total = nums[3].abs();
      } else {
        final gross = qty * price;
        if ((total - gross).abs() > 0.02 && total > 0) fee = (total - gross).abs();
      }
    }
    out.add(ParsedTrade(date: date, kind: kind, name: name, isin: isin, quantity: qty, price: price, currency: ccy, fee: fee, total: total));
  }
  return out;
}

// ---------------------------------------------------------------------------
// De uma linha lida para uma operação da Carteira
// ---------------------------------------------------------------------------

/// Cria a operação correspondente. Devolve nulo se faltar o câmbio de alguma moeda.
///
/// [rates]: unidades de cada moeda por 1 unidade da moeda de base (ex.: USD 1,08).
/// [holdingCcy]: moeda do ativo; o preço da operação fica nessa moeda.
InvestOp? tradeToOp(
  ParsedTrade t, {
  required int accountId,
  required int? holdingId,
  required String base,
  required String defaultCcy,
  required Map<String, double> rates,
  required String holdingCcy,
}) {
  double? eurPer(String ccy, [double? rowRate]) {
    if (ccy == base) return 1;
    final r = rowRate ?? rates[ccy];
    return r != null && r > 0 ? 1 / r : null;
  }

  final ccy = t.currency.isEmpty ? defaultCcy : t.currency;
  final e = eurPer(ccy, t.rate);
  if (e == null) return null;
  int cents(double v) => (v * e * 100).round();

  if (t.kind == 'dividend') {
    return InvestOp(id: 0, accountId: accountId, holdingId: holdingId, date: t.date, type: OpType.dividend, amount: cents(t.total ?? 0), note: t.note);
  }
  final gross = t.quantity * t.price;
  final amount = t.kind == 'buy' ? cents(gross + t.fee) : cents(gross - t.fee);
  // preço na moeda do ativo (se a linha estiver noutra moeda, passa pelo valor na moeda de base)
  final eh = eurPer(holdingCcy, holdingCcy == ccy ? t.rate : null);
  if (eh == null) return null;
  final price = holdingCcy == ccy ? t.price : gross * e / eh / t.quantity;
  return InvestOp(
    id: 0,
    accountId: accountId,
    holdingId: holdingId,
    date: t.date,
    type: t.kind == 'buy' ? OpType.buy : OpType.sell,
    quantity: t.quantity,
    price: price,
    fx: holdingCcy == base ? null : eh,
    amount: amount,
    fee: cents(t.fee),
    note: t.note,
  );
}

/// Duas operações são a mesma se tiverem o mesmo ativo, dia, tipo e quantidade
/// (nos dividendos, o mesmo ativo e dia).
String opSignature(InvestOp o) => _sig(o.holdingId, o.date, o.type.name, o.quantity);

/// Assinatura de uma linha lida (para detetar o que já foi importado, mesmo sem câmbio).
String tradeSignature(int? holdingId, ParsedTrade t) => _sig(holdingId, t.date, t.kind == 'buy' ? 'buy' : (t.kind == 'sell' ? 'sell' : 'dividend'), t.quantity);

String _sig(int? holdingId, DateTime d, String type, double qty) => '$holdingId|${d.year}-${d.month}-${d.day}|$type|${type == 'dividend' ? '' : qty.toStringAsFixed(6)}';
