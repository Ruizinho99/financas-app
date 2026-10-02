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
final _tailRe = RegExp('^(.*?)\\s*($_amount)(?:\\s+($_amount))?\\s*\$');

int? _amt(String? s) {
  if (s == null) return null;
  final t = s.trim();
  final neg = t.startsWith('-') || t.endsWith('-') || t.startsWith('(') || RegExp(r'\bD(R)?$').hasMatch(t);
  final v = parseCents(t.replaceAll(RegExp(r'[-+()]|\s?[CD]R?$'), ''));
  return v == null ? null : (neg ? -v.abs() : v);
}

String pdfText(Uint8List bytes) {
  final doc = PdfDocument(inputBytes: bytes);
  try {
    return PdfTextExtractor(doc).extractText(layoutText: true);
  } finally {
    doc.dispose();
  }
}

/// Interpreta o texto de um extrato PDF. [text] vem de [pdfText].
List<ParsedRow> parseStatementText(String text, {int? defaultYear}) {
  defaultYear ??= RegExp(r'\b(20\d{2})\b').firstMatch(text)?.group(1) != null
      ? int.parse(RegExp(r'\b(20\d{2})\b').firstMatch(text)!.group(1)!)
      : DateTime.now().year;
  final rows = <ParsedRow>[];
  ParsedRow? pending;
  bool pendingOpen = false; // a linha pendente ainda não tem montante
  for (final raw in const LineSplitter().convert(text)) {
    final line = raw.trim().replaceAll(RegExp(r'\s{2,}'), '  ').replaceAll('  ', ' ');
    if (line.isEmpty) continue;
    final m = _lineRe.firstMatch(line);
    if (m != null && m[3]!.trim().isNotEmpty) {
      final d = parseDate(m[1]!, defaultYear: defaultYear);
      final a = _amt(m[4]);
      if (d != null && a != null) {
        rows.add(ParsedRow(d, m[3]!.trim(), a, _amt(m[5])));
        pendingOpen = false;
        continue;
      }
    }
    final od = _onlyDateRe.firstMatch(line);
    if (od != null) {
      final d = parseDate(od[1]!, defaultYear: defaultYear);
      if (d != null) {
        pending = ParsedRow(d, od[3]!.trim(), 0);
        rows.add(pending);
        pendingOpen = true;
        continue;
      }
    }
    final t = _tailRe.firstMatch(line);
    if (pendingOpen && pending != null && t != null) {
      if (t[1]!.trim().isNotEmpty) pending.description += ' ${t[1]!.trim()}';
      pending.amount = _amt(t[2]) ?? 0;
      pending.balance = _amt(t[3]);
      pendingOpen = false;
    } else if (rows.isNotEmpty && t == null) {
      rows.last.description += ' $line';
    }
  }
  rows.removeWhere((r) => r.amount == 0 && r.balance == null);
  _inferSigns(rows);
  return rows;
}

/// Montantes sem sinal: inferir pela variação do saldo.
void _inferSigns(List<ParsedRow> rows) {
  for (var i = 1; i < rows.length; i++) {
    final p = rows[i - 1], c = rows[i];
    if (p.balance != null && c.balance != null) {
      final delta = c.balance! - p.balance!;
      if (delta.abs() == c.amount.abs()) c.amount = delta;
    }
  }
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
