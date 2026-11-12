import '../import/parsers.dart' show parseDate;

/// Relatório da XTB (Excel com as folhas "Closed Positions", "Cash Operations" e "Open Positions"):
/// o que se leu dele e avisos para mostrar ao utilizador.
class XtbSummary {
  final int buys, sells, dividends;
  final int instruments;
  final int zeroDividends; // dividendos que ficam a 0,00 € depois da retenção (não se importam)
  final int unmatchedWithholdings; // retenções sem dividendo correspondente
  final int skippedPositions; // posições que não são compras de ações (ex.: CFD vendidos a descoberto)
  const XtbSummary({
    required this.buys,
    required this.sells,
    required this.dividends,
    required this.instruments,
    required this.zeroDividends,
    required this.unmatchedWithholdings,
    required this.skippedPositions,
  });
}

/// O ficheiro é um relatório da XTB? (tem as três folhas características)
bool isXtbReport(Map<String, List<List<String>>> sheets) =>
    sheets.containsKey('Closed Positions') &&
    sheets.containsKey('Cash Operations') &&
    sheets.containsKey('Open Positions');

/// Cabeçalho da tabela que o importador de operações reconhece sozinho.
const xtbTableHeader = [
  'Date',
  'Type',
  'Ticker',
  'Name',
  'Category',
  'Quantity',
  'Price',
  'Currency',
  'Exchange rate',
  'Total (EUR)',
  'Notes',
];

// Moeda de cada mercado da XTB pelo sufixo do ticker (sem sufixo ou desconhecido: euros).
const _currencies = {
  'US': 'USD',
  'UK': 'GBP',
  'CH': 'CHF',
  'PL': 'PLN',
  'CZ': 'CZK',
  'HU': 'HUF',
  'NO': 'NOK',
  'SE': 'SEK',
  'DK': 'DKK',
  'CA': 'CAD',
};

String _currencyOf(String ticker) => ticker.contains('.')
    ? (_currencies[ticker.split('.').last] ?? 'EUR')
    : 'EUR';

/// Linhas (como mapas) a partir da linha de cabeçalho cuja primeira célula é [first].
List<Map<String, String>> _table(List<List<String>> rows, String first) {
  for (var i = 0; i < rows.length; i++) {
    if (rows[i].isNotEmpty && rows[i][0].trim() == first) {
      final head = rows[i].map((c) => c.trim()).toList();
      return [
        for (final r in rows.skip(i + 1))
          {
            for (var c = 0; c < head.length; c++)
              if (head[c].isNotEmpty) head[c]: c < r.length ? r[c].trim() : '',
          },
      ];
    }
  }
  return const [];
}

double _num(String? s) {
  if (s == null || s.trim().isEmpty) return 0;
  return double.tryParse(s.trim().replaceAll(',', '.')) ?? 0;
}

/// Data e hora de uma célula: texto "2026-01-09 08:05" ou número de série do Excel (dias desde 1899-12-30).
DateTime? _dateTime(String? s) {
  final t = (s ?? '').trim();
  if (t.isEmpty) return null;
  final serial = double.tryParse(t);
  if (serial != null && serial > 20000 && !t.contains('-')) {
    final ms = (serial * 86400000).round();
    return DateTime.utc(1899, 12, 30).add(Duration(milliseconds: ms));
  }
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})(?:[ T](\d{2}):(\d{2}))?')
      .firstMatch(t);
  if (m != null) {
    return DateTime.utc(
      int.parse(m[1]!),
      int.parse(m[2]!),
      int.parse(m[3]!),
      int.parse(m[4] ?? '0'),
      int.parse(m[5] ?? '0'),
    );
  }
  return parseDate(t);
}

String _dt(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
}

/// Número com vírgula decimal (o que o importador lê sem ambiguidade) e sem zeros a mais.
String _f(double v, [int decimals = 4]) {
  var t = v.toStringAsFixed(decimals);
  if (t.contains('.'))
    t = t.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  return t.replaceAll('.', ',');
}

/// Converte o relatório da XTB numa tabela de operações (uma linha por compra, venda e dividendo),
/// no formato que o importador de operações reconhece sozinho:
/// - **Buy** por cada lote comprado, em carteira ou já fechado;
/// - **Sell** por cada lote (ou parte de lote) vendido, com a quantidade e o preço da venda;
/// - **Dividend** pelo valor líquido da retenção na fonte do mesmo título e momento.
/// O preço está na moeda do ativo e o câmbio (unidades dessa moeda por 1 EUR) sai do valor em euros que a
/// XTB regista, por isso a app reconstrói os euros ao cêntimo.
({List<List<String>> table, XtbSummary summary}) xtbReportToTable(
  Map<String, List<List<String>>> sheets,
) {
  final cash = _table(sheets['Cash Operations'] ?? const [], 'Type')
      .where(
        (r) => (r['Type'] ?? '').isNotEmpty && (r['Time'] ?? '').isNotEmpty,
      )
      .toList();
  final categories = <String, String>{};
  final names = <String, String>{};
  for (final r in cash) {
    final t = r['Ticker'] ?? '';
    if (t.isEmpty) continue;
    if ((r['Category'] ?? '').isNotEmpty) categories[t] = r['Category']!;
    if ((r['Instrument'] ?? '').isNotEmpty) names[t] = r['Instrument']!;
  }

  final ops = <(DateTime, String, List<String>)>[];
  final tickers = <String>{};
  var skipped = 0, buys = 0, sells = 0, divs = 0, zero = 0;

  void line(
    DateTime when,
    String type,
    String ticker,
    double? qty,
    double? price,
    double eur,
    String note, {
    String? currency,
  }) {
    final ccy = currency ?? _currencyOf(ticker);
    final rate = (ccy != 'EUR' && eur > 0 && (qty ?? 0) > 0 && (price ?? 0) > 0)
        ? qty! * price! / eur
        : null;
    tickers.add(ticker);
    ops.add((
      when,
      type,
      [
        _dt(when),
        type,
        ticker,
        names[ticker] ?? ticker,
        categories[ticker] ?? '',
        qty == null ? '' : _f(qty),
        price == null ? '' : _f(price),
        ccy,
        rate == null ? '' : _f(rate, 10),
        _f(eur, 2),
        note,
      ],
    ));
  }

  // lotes fechados: uma compra e uma venda
  for (final r in _table(sheets['Closed Positions']!, 'Instrument')) {
    final ticker = r['Ticker'] ?? '';
    if (ticker.isEmpty) continue; // a linha de totais
    if ((r['Type'] ?? 'BUY').toUpperCase() != 'BUY') {
      skipped++;
      continue;
    }
    names.putIfAbsent(ticker, () => r['Instrument'] ?? ticker);
    final qty = _num(r['Volume']);
    final open = _dateTime(r['Open Time (UTC)']),
        close = _dateTime(r['Close Time (UTC)']);
    if (open == null || close == null || qty <= 0) {
      skipped++;
      continue;
    }
    final pos = 'posição ${_num(r['Position ID']).round()}';
    line(
      open,
      'Buy',
      ticker,
      qty,
      _num(r['Open Price']),
      _num(r['Purchase Value']),
      pos,
    );
    line(
      close,
      'Sell',
      ticker,
      qty,
      _num(r['Close Price']),
      _num(r['Sale Value']),
      pos,
    );
    buys++;
    sells++;
  }

  // lotes em carteira: só a compra (custo em euros = valor atual - lucro, como a XTB)
  final open = sheets['Open Positions']!;
  final hi = open.indexWhere(
    (l) =>
        l.length > 1 &&
        l[0].trim() == 'Product' &&
        l[1].trim() == 'Instrument/Position',
  );
  if (hi >= 0) {
    final head = open[hi].map((c) => c.trim()).toList();
    for (final row in open.skip(hi + 1)) {
      final r = {
        for (var c = 0; c < head.length; c++)
          head[c]: c < row.length ? row[c].trim() : '',
      };
      final ticker = r['Ticker'] ?? '';
      if (r['Product'] != 'My Trades' || ticker.isEmpty) continue;
      if ((r['Type'] ?? '').isEmpty) {
        names[ticker] =
            r['Instrument/Position'] ?? ticker; // a linha do título dá o nome
        continue;
      }
      final when = _dateTime(r['Open time (UTC)']);
      final qty = _num(r['Volume']);
      if (when == null || qty <= 0) {
        skipped++;
        continue;
      }
      final cost = _num(r['Value']) - _num(r['Gross Profit']);
      line(
        when,
        'Buy',
        ticker,
        qty,
        _num(r['Open price']),
        cost,
        'posição ${r['Instrument/Position']}',
      );
      buys++;
    }
  }

  // dividendos, líquidos da retenção na fonte (mesmo título, mesmo momento)
  final withholdings = <String, List<Map<String, String>>>{};
  for (final r in cash) {
    if (r['Type'] == 'Withholding tax' && (r['Ticker'] ?? '').isNotEmpty) {
      (withholdings[r['Ticker']!] ??= []).add(r);
    }
  }
  for (final d in cash) {
    if (d['Type'] != 'Dividend' || (d['Ticker'] ?? '').isEmpty) continue;
    final when = _dateTime(d['Time']);
    if (when == null) continue;
    final list = withholdings[d['Ticker']] ?? [];
    final i = list.indexWhere((w) {
      final wt = _dateTime(w['Time']);
      return wt != null && wt.difference(when).inSeconds.abs() < 60;
    });
    final tax = i >= 0 ? _num(list.removeAt(i)['Amount']) : 0.0;
    final gross = _num(d['Amount']);
    final net = ((gross + tax) * 100).round() / 100;
    if (net <= 0) {
      zero++; // 0,00 € depois da retenção: a app não aceita dividendos sem valor
      continue;
    }
    // a XTB paga em euros (moeda da conta), mesmo nas ações em dólares
    line(
      when,
      'Dividend',
      d['Ticker']!,
      null,
      null,
      net,
      'bruto ${gross.toStringAsFixed(2)}, retenção ${(-tax).toStringAsFixed(2)}',
      currency: 'EUR',
    );
    divs++;
  }
  final unmatched = withholdings.values.fold(0, (a, l) => a + l.length);

  // por data; em caso de empate, tipo, título e quantidade (ordem estável e previsível)
  ops.sort((a, b) {
    var c = a.$1.compareTo(b.$1);
    if (c == 0) c = a.$2.compareTo(b.$2);
    if (c == 0) c = a.$3[2].compareTo(b.$3[2]);
    if (c == 0)
      c = (double.tryParse(a.$3[5].replaceAll(',', '.')) ?? 0).compareTo(
        double.tryParse(b.$3[5].replaceAll(',', '.')) ?? 0,
      );
    return c;
  });
  return (
    table: [xtbTableHeader, for (final o in ops) o.$3],
    summary: XtbSummary(
      buys: buys,
      sells: sells,
      dividends: divs,
      instruments: tickers.length,
      zeroDividends: zero,
      unmatchedWithholdings: unmatched,
      skippedPositions: skipped,
    ),
  );
}
