import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models.dart';
import '../util/format.dart';

// ---------------------------------------------------------------------------
// Chave normalizada de um movimento (agrupa "o mesmo nome")
// ---------------------------------------------------------------------------
const _accents = {
  'Á': 'A', 'À': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A', 'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E',
  'Í': 'I', 'Ì': 'I', 'Î': 'I', 'Ï': 'I', 'Ó': 'O', 'Ò': 'O', 'Ô': 'O', 'Õ': 'O', 'Ö': 'O',
  'Ú': 'U', 'Ù': 'U', 'Û': 'U', 'Ü': 'U', 'Ç': 'C', 'Ñ': 'N',
};
const _stopPrefixes = {'COMPRA', 'COMPRAS', 'PAGAMENTO', 'PAG', 'PGTO', 'DEBITO', 'CREDITO', 'DD', 'POS'};

String merchantKey(String description) {
  var s = description.toUpperCase();
  s = s.split('').map((c) => _accents[c] ?? c).join();
  s = s.replaceAll(RegExp(r'[^A-Z0-9 ]'), ' ');
  final tokens = s
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty && !RegExp(r'\d').hasMatch(t))
      .toList();
  while (tokens.length > 1 && _stopPrefixes.contains(tokens.first)) {
    tokens.removeAt(0);
  }
  final key = tokens.take(6).join(' ');
  return key.isEmpty ? description.toUpperCase().trim() : key;
}

// ---------------------------------------------------------------------------
// Datas
// ---------------------------------------------------------------------------
const _months = {
  'JAN': 1, 'FEV': 2, 'FEB': 2, 'MAR': 3, 'ABR': 4, 'APR': 4, 'MAI': 5, 'MAY': 5, 'JUN': 6,
  'JUL': 7, 'AGO': 8, 'AUG': 8, 'SET': 9, 'SEP': 9, 'OUT': 10, 'OCT': 10, 'NOV': 11, 'DEZ': 12, 'DEC': 12,
};

DateTime? parseDate(String input, {int? defaultYear}) {
  final s = input.trim();
  if (s.isEmpty) return null;
  var m = RegExp(r'^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})').firstMatch(s);
  if (m != null) return _mk(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
  m = RegExp(r'^(\d{1,2})[-/.](\d{1,2})(?:[-/.](\d{2,4}))?').firstMatch(s);
  if (m != null) {
    var y = m[3] != null ? int.parse(m[3]!) : (defaultYear ?? DateTime.now().year);
    if (y < 100) y += 2000;
    return _mk(y, int.parse(m[2]!), int.parse(m[1]!));
  }
  m = RegExp(r'^(\d{1,2})\s+([A-Za-zçÇ]{3})\w*\.?\s+(\d{2,4})').firstMatch(s);
  if (m != null) {
    final mo = _months[m[2]!.toUpperCase()];
    if (mo != null) {
      var y = int.parse(m[3]!);
      if (y < 100) y += 2000;
      return _mk(y, mo, int.parse(m[1]!));
    }
  }
  return null;
}

DateTime? _mk(int y, int m, int d) {
  if (m < 1 || m > 12 || d < 1 || d > 31) return null;
  return DateTime(y, m, d);
}

// ---------------------------------------------------------------------------
// PDF
// ---------------------------------------------------------------------------
const _date = r'\d{1,2}[-/.]\d{1,2}(?:[-/.]\d{2,4})?';
const _amount = r'[-+]?\(?\d{1,3}(?:[. ]\d{3})*,\d{2}\)?(?:\s?[-+]|\s?[CD]R?)?|[-+]?\d+\.\d{2}';
final _lineRe = RegExp('^($_date)(?:\\s+($_date))?\\s+(.*?)\\s*($_amount)(?:\\s+($_amount))?\\s*\$');
final _onlyDateRe = RegExp('^($_date)(?:\\s+($_date))?\\s+(.+)\$');
final _dateOnlyRe = RegExp('^($_date)(?:\\s+($_date))?\$');
final _tailRe = RegExp('^(.*?)\\s*($_amount)(?:\\s+($_amount))?\\s*\$');
final _loneAmountRe = RegExp('^($_amount)\\s*\$');
final _loneAmountsRe = RegExp('^($_amount)(?:\\s+($_amount))?\\s*\$');
final _anchorRe = RegExp('^(SALDO INICIAL|SALDO ANTERIOR|TRANSPORTE)\\b\\s*($_amount)?\\s*\$', caseSensitive: false);
final _endAnchorRe = RegExp(r'^(A TRANSPORTAR|SALDO FINAL|SALDO DISPON[IÍ]VEL|SALDO CONTABIL[IÍ]STICO)\b', caseSensitive: false);
final _accountRe = RegExp(r'^CONTA(?: [A-ZÀ-Ú]+)+$');
final _noiseRe = RegExp(
    r'^(DATA|LANC\.?|VALOR|DESCRITIVO|D[ÉE]BITO|CR[ÉE]DITO|SALDO|P[ÁA]G\b|N\.|EXTRATO|MOEDA|BIC\b|EXT\.|MENSAGEM|RESUMO|IBAN|NIB)',
    caseSensitive: false);

int? _amt(String? s) {
  if (s == null) return null;
  final t = s.trim();
  final neg = t.startsWith('-') || t.endsWith('-') || t.startsWith('(') || RegExp(r'\bD(R)?$').hasMatch(t);
  final v = parseCents(t.replaceAll(RegExp(r'[-+()]|\s?[CD]R?$'), ''));
  return v == null ? null : (neg ? -v.abs() : v);
}

/// Texto do PDF, uma linha por linha visual, com espaços entre colunas.
/// (extractText(layoutText) cola colunas sem espaços e o parser deixava de reconhecer os movimentos.)
String pdfText(Uint8List bytes) {
  final doc = PdfDocument(inputBytes: bytes);
  try {
    final extractor = PdfTextExtractor(doc);
    final out = StringBuffer();
    for (var i = 0; i < doc.pages.count; i++) {
      for (final line in extractor.extractTextLines(startPageIndex: i, endPageIndex: i)) {
        final t = line.text.replaceAll(RegExp(r'\s+'), ' ').trim();
        if (t.isNotEmpty) out.writeln(t);
      }
    }
    final text = out.toString();
    // se por algum motivo não saiu nada, tenta o método antigo
    return text.trim().isEmpty ? extractor.extractText(layoutText: true) : text;
  } finally {
    doc.dispose();
  }
}

typedef StatementPeriod = ({DateTime start, DateTime end});

/// Período do extrato ("EXTRATO DE 2025/06/02 A 2025/06/30"), se existir.
StatementPeriod? detectPeriod(String text) {
  final m = RegExp(r'(\d{4})[/-](\d{2})[/-](\d{2})\s*(?:A|a|-|AT[ÉE]|até)\s*(\d{4})[/-](\d{2})[/-](\d{2})').firstMatch(text);
  if (m == null) return null;
  final a = _mk(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
  final b = _mk(int.parse(m[4]!), int.parse(m[5]!), int.parse(m[6]!));
  if (a == null || b == null) return null;
  return a.isAfter(b) ? (start: b, end: a) : (start: a, end: b);
}

/// Datas sem ano ("6.02") interpretam-se como dia.mês ou mês.dia conforme caiam dentro do período.
DateTime? _statementDate(String tok, StatementPeriod? per, int defaultYear) {
  final m2 = RegExp(r'^(\d{1,2})[-/.](\d{1,2})$').firstMatch(tok.trim());
  if (m2 == null || per == null) return parseDate(tok, defaultYear: defaultYear);
  final a = int.parse(m2[1]!), b = int.parse(m2[2]!);
  final lo = per.start.subtract(const Duration(days: 5)), hi = per.end.add(const Duration(days: 5));
  DateTime? pick(int month, int day) {
    for (final y in {per.end.year, per.start.year}) {
      final d = _mk(y, month, day);
      if (d != null && !d.isBefore(lo) && !d.isAfter(hi)) return d;
    }
    return null;
  }

  return pick(b, a) ?? pick(a, b);
}

bool _isNoise(String line) {
  if (_noiseRe.hasMatch(line)) return true;
  // texto com letras espaçadas ("B a n c o  A c t i v o") – rodapés/cabeçalhos
  final toks = line.split(' ');
  return toks.length >= 8 && toks.where((t) => t.length == 1).length >= toks.length * 0.6;
}

String _titleCase(String s) =>
    s.toLowerCase().split(' ').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');

/// Interpreta o texto de um extrato PDF. [text] vem de [pdfText].
List<ParsedRow> parseStatementText(String text, {int? defaultYear}) => parseStatementDetailed(text, defaultYear: defaultYear).rows;

/// Como [parseStatementText], mas devolve também as linhas que começam por uma data
/// e que não foram reconhecidas como movimento (para avisar o utilizador).
///
/// Percebe extratos com várias contas (secções "CONTA …"), movimentos partidos em várias linhas,
/// montantes sem sinal (deduz-o pela variação do saldo, a partir de "SALDO INICIAL"/"TRANSPORTE"),
/// datas "mês.dia" e ignora cabeçalhos/rodapés de página.
({List<ParsedRow> rows, List<String> skipped}) parseStatementDetailed(String text, {int? defaultYear}) {
  final period = detectPeriod(text);
  defaultYear ??= period?.end.year ??
      (RegExp(r'\b(20\d{2})\b').firstMatch(text) != null ? int.parse(RegExp(r'\b(20\d{2})\b').firstMatch(text)!.group(1)!) : DateTime.now().year);
  final lo = period?.start.subtract(const Duration(days: 5));
  final hi = period?.end.add(const Duration(days: 5));
  bool inWindow(DateTime d) => period == null || (!d.isBefore(lo!) && !d.isAfter(hi!));

  final rows = <ParsedRow>[];
  final skipped = <String>[];
  String? account;
  int? running; // saldo corrente da conta (para deduzir sinais)
  var expectAnchor = false;
  ParsedRow? pending; // movimento com data mas ainda sem montante
  var pendingDesc = <String>[];

  void dropPending() {
    final p = pending;
    if (p != null) skipped.add('${fmtDate(p.date)}  ${p.description}'.trim());
    pending = null;
  }

  void finalize(ParsedRow r) {
    if (r.balance != null) {
      if (running != null) {
        final delta = r.balance! - running!;
        if (delta.abs() == r.amount.abs()) r.amount = delta;
      }
      running = r.balance;
    } else if (running != null) {
      running = running! + r.amount;
    }
    r.account = account;
    rows.add(r);
  }

  for (final raw in const LineSplitter().convert(text)) {
    final line = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (line.isEmpty) continue;

    if (expectAnchor) {
      expectAnchor = false;
      final m = _loneAmountRe.firstMatch(line);
      if (m != null) {
        running = _amt(m[1]);
        continue;
      }
    }
    final anchor = _anchorRe.firstMatch(line);
    if (anchor != null) {
      dropPending();
      if (anchor[2] != null) {
        running = _amt(anchor[2]);
      } else {
        expectAnchor = true;
      }
      continue;
    }
    if (_endAnchorRe.hasMatch(line)) {
      dropPending();
      continue;
    }
    if (_accountRe.hasMatch(line) && !RegExp(r'\d').hasMatch(line)) {
      dropPending();
      account = _titleCase(line);
      running = null;
      continue;
    }

    final m = _lineRe.firstMatch(line);
    if (m != null && m[3]!.trim().isNotEmpty) {
      final d = _statementDate(m[1]!, period, defaultYear);
      final a = _amt(m[4]);
      if (d != null && a != null && inWindow(d)) {
        dropPending();
        finalize(ParsedRow(d, m[3]!.trim(), a, _amt(m[5])));
        continue;
      }
      if (d != null && !inWindow(d)) continue; // rodapé/cabeçalho com uma data fora do extrato
    }

    // linha só com valores ("3.60 53.44") a fechar um movimento pendente; parece duas datas, mas não cai no período
    final lone = _loneAmountsRe.firstMatch(line);
    final pend = pending;
    if (pend != null && lone != null) {
      final d0 = _statementDate(line.split(' ').first, period, defaultYear);
      final a = _amt(lone[1]);
      if ((d0 == null || !inWindow(d0)) && a != null) {
        pending = null;
        final desc = pendingDesc.join(' ').trim();
        finalize(ParsedRow(pend.date, desc.isEmpty ? '(sem descrição)' : desc, a, _amt(lone[2])));
        continue;
      }
    }

    // só data(s): a descrição e os valores vêm nas linhas seguintes
    final dOnly = _dateOnlyRe.firstMatch(line);
    if (dOnly != null) {
      final d = _statementDate(dOnly[1]!, period, defaultYear);
      if (d != null && inWindow(d)) {
        dropPending();
        pending = ParsedRow(d, '', 0);
        pendingDesc = [];
        continue;
      }
      // "3.60 53.44" parece duas datas mas é a linha de valores que fecha um movimento pendente
      if (pending == null) continue;
    }
    // data + descrição, o montante vem depois
    final od = _onlyDateRe.firstMatch(line);
    if (od != null) {
      final d = _statementDate(od[1]!, period, defaultYear);
      if (d != null && inWindow(d) && !_isNoise(od[3]!)) {
        dropPending();
        pending = ParsedRow(d, od[3]!.trim(), 0);
        pendingDesc = [od[3]!.trim()];
      }
      continue;
    }

    final p = pending;
    if (p != null) {
      final t = _tailRe.firstMatch(line);
      if (t != null) {
        if (t[1]!.trim().isNotEmpty) pendingDesc.add(t[1]!.trim());
        final a = _amt(t[2]);
        if (a != null) {
          p.description = pendingDesc.join(' ');
          pending = null;
          finalize(ParsedRow(p.date, p.description.isEmpty ? '(sem descrição)' : p.description, a, _amt(t[3])));
          continue;
        }
      }
      if (!_isNoise(line)) {
        pendingDesc.add(line);
        p.description = pendingDesc.join(' ');
      }
    }
  }
  dropPending();
  _inferSigns(rows);
  return (rows: rows, skipped: skipped);
}

/// Montantes sem sinal: inferir pela variação do saldo (linhas seguidas da mesma conta).
void _inferSigns(List<ParsedRow> rows) {
  for (var i = 1; i < rows.length; i++) {
    final p = rows[i - 1], c = rows[i];
    if (p.account == c.account && p.balance != null && c.balance != null) {
      final delta = c.balance! - p.balance!;
      if (delta.abs() == c.amount.abs()) c.amount = delta;
    }
  }
}

/// Marca como transferências os pares saída/entrada com o mesmo valor entre contas diferentes
/// (até 3 dias de diferença e "TRF"/"TRANSFER" na descrição). Devolve quantos pares encontrou.
int markTransfers(List<ParsedRow> rows) {
  for (final r in rows) {
    r.isTransfer = false;
  }
  bool looksTransfer(ParsedRow r) => RegExp(r'\bTRF\b|TRANSFER', caseSensitive: false).hasMatch(r.description);
  var pairs = 0;
  for (var i = 0; i < rows.length; i++) {
    final a = rows[i];
    if (a.isTransfer || a.account == null || a.amount == 0) continue;
    ParsedRow? best;
    var bestDiff = 99;
    for (var j = 0; j < rows.length; j++) {
      final b = rows[j];
      if (j == i || b.isTransfer || b.account == null || b.account == a.account || b.amount != -a.amount) continue;
      if (!looksTransfer(a) && !looksTransfer(b)) continue;
      final diff = a.date.difference(b.date).inDays.abs();
      if (diff <= 3 && diff < bestDiff) {
        best = b;
        bestDiff = diff;
      }
    }
    if (best != null) {
      a.isTransfer = true;
      best.isTransfer = true;
      pairs++;
    }
  }
  return pairs;
}

// ---------------------------------------------------------------------------
// CSV / Excel -> tabela de texto
// ---------------------------------------------------------------------------
List<List<String>> parseCsv(String text) {
  if (text.startsWith('﻿')) text = text.substring(1);
  final firstLine = text.split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
  final counts = {for (final d in [';', ',', '\t', '|']) d: d.allMatches(firstLine).length};
  final delim = (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
  final rows = <List<String>>[];
  var row = <String>[];
  final cur = StringBuffer();
  var inQ = false;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (inQ) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          cur.write('"');
          i++;
        } else {
          inQ = false;
        }
      } else {
        cur.write(c);
      }
    } else if (c == '"') {
      inQ = true;
    } else if (c == delim) {
      row.add(cur.toString());
      cur.clear();
    } else if (c == '\n' || c == '\r') {
      if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      row.add(cur.toString());
      cur.clear();
      if (row.any((e) => e.trim().isNotEmpty)) rows.add(row);
      row = <String>[];
    } else {
      cur.write(c);
    }
  }
  row.add(cur.toString());
  if (row.any((e) => e.trim().isNotEmpty)) rows.add(row);
  return rows;
}

String decodeText(Uint8List bytes) {
  try {
    return utf8.decode(bytes);
  } catch (_) {
    return latin1.decode(bytes);
  }
}

List<List<String>> parseXlsx(Uint8List bytes) {
  final excel = Excel.decodeBytes(bytes);
  Sheet? best;
  for (final s in excel.tables.values) {
    if (best == null || s.maxRows > best.maxRows) best = s;
  }
  if (best == null) return [];
  String cell(Data? d) {
    final v = d?.value;
    if (v == null) return '';
    if (v is TextCellValue) return v.value.text ?? '';
    if (v is IntCellValue) return v.value.toString();
    if (v is DoubleCellValue) return v.value.toString();
    if (v is DateCellValue) return '${v.year}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}';
    if (v is DateTimeCellValue) return '${v.year}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}';
    return v.toString();
  }

  return [
    for (final r in best.rows)
      if (r.any((c) => cell(c).trim().isNotEmpty)) [for (final c in r) cell(c)]
  ];
}

// ---------------------------------------------------------------------------
// Mapeamento de colunas
// ---------------------------------------------------------------------------
class ColumnMapping {
  int headerRow; // -1: sem cabeçalho
  int? date, description, amount, debit, credit, balance;
  ColumnMapping({this.headerRow = 0, this.date, this.description, this.amount, this.debit, this.credit, this.balance});
}

String _norm(String s) => s.toUpperCase().split('').map((c) => _accents[c] ?? c).join();

ColumnMapping guessMapping(List<List<String>> table) {
  final m = ColumnMapping();
  // Procura a linha de cabeçalho nas primeiras 15 linhas
  var best = -1, bestScore = 0;
  for (var i = 0; i < table.length && i < 15; i++) {
    final score = table[i].where((c) => _headerKind(c) != null).length;
    if (score > bestScore) {
      bestScore = score;
      best = i;
    }
  }
  if (bestScore >= 2) {
    m.headerRow = best;
    final used = <int>{};
    for (var c = 0; c < table[best].length; c++) {
      final k = _headerKind(table[best][c]);
      if (k == null) continue;
      switch (k) {
        case 'date':
          m.date ??= c;
        case 'desc':
          m.description ??= c;
        case 'amount':
          m.amount ??= c;
        case 'debit':
          m.debit ??= c;
        case 'credit':
          m.credit ??= c;
        case 'balance':
          m.balance ??= c;
      }
      used.add(c);
    }
    if (m.amount != null) {
      m.debit = null;
      m.credit = null;
    }
  } else {
    m.headerRow = -1;
    // Heurística por conteúdo
    final sample = table.take(20).toList();
    final cols = sample.fold(0, (a, r) => r.length > a ? r.length : a);
    for (var c = 0; c < cols; c++) {
      final vals = sample.map((r) => c < r.length ? r[c] : '').where((v) => v.trim().isNotEmpty).toList();
      if (vals.isEmpty) continue;
      final dates = vals.where((v) => parseDate(v) != null).length;
      final nums = vals.where((v) => parseCents(v) != null && RegExp(r'^[-+\s\d.,()€]+$').hasMatch(v.trim())).length;
      if (m.date == null && dates >= vals.length * 0.8) {
        m.date = c;
      } else if (nums >= vals.length * 0.8) {
        if (m.amount == null) {
          m.amount = c;
        } else {
          m.balance ??= c;
        }
      } else {
        m.description ??= c;
      }
    }
  }
  return m;
}

String? _headerKind(String h) {
  final s = _norm(h.trim());
  if (s.isEmpty) return null;
  if (RegExp(r'DATA.*VALOR|VALUE DATE').hasMatch(s)) return null;
  if (RegExp(r'^(DATA|DATE|DT|DATA MOV|DATA MOVIMENTO|DATA OPERACAO|DATA LANCAMENTO)').hasMatch(s)) return 'date';
  if (RegExp(r'DESCR|DESIGNACAO|MOVIMENTO|DETALHE|NARRATIVE|PAYEE|BENEFICIARIO|REFERENCIA|MEMO|DETAILS').hasMatch(s)) return 'desc';
  if (RegExp(r'SALDO|BALANCE').hasMatch(s)) return 'balance';
  if (RegExp(r'DEBITO|DEBIT|SAIDA|DEBITOS').hasMatch(s)) return 'debit';
  if (RegExp(r'CREDITO|CREDIT|ENTRADA|CREDITOS').hasMatch(s)) return 'credit';
  if (RegExp(r'MONTANTE|VALOR|IMPORTE|AMOUNT|QUANTIA').hasMatch(s)) return 'amount';
  return null;
}

List<ParsedRow> rowsFromTable(List<List<String>> table, ColumnMapping m, {int? defaultYear}) {
  final out = <ParsedRow>[];
  String at(List<String> r, int? c) => (c == null || c >= r.length) ? '' : r[c].trim();
  for (var i = m.headerRow + 1; i < table.length; i++) {
    final r = table[i];
    final d = parseDate(at(r, m.date), defaultYear: defaultYear);
    if (d == null) continue;
    int? amount;
    if (m.amount != null) {
      amount = _amt(at(r, m.amount));
    } else {
      final deb = parseCents(at(r, m.debit)), cred = parseCents(at(r, m.credit));
      if (deb != null || cred != null) amount = (cred ?? 0).abs() - (deb ?? 0).abs();
    }
    if (amount == null) continue;
    final desc = at(r, m.description);
    out.add(ParsedRow(d, desc.isEmpty ? '(sem descrição)' : desc, amount, parseCents(at(r, m.balance))));
  }
  return out;
}
