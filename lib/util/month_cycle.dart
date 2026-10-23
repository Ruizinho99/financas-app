/// Como se define o "mês" da app: o calendário (dia 1), um dia fixo (ex.: 25) ou os dias em que se recebe o salário.
enum CycleMode { calendar, fixedDay, salary }

/// Um mês da app, com início e fim (exclusivo) e o nome AAAA-MM do mês em que termina.
/// Exemplo (dia 25): 25 ago – 24 set (fim exclusivo: 25 set) chama-se 2026-09.
class CycleSpan {
  final String key;
  final DateTime start;
  final DateTime end;
  const CycleSpan(this.key, this.start, this.end);
}

String _key(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

DateTime _clampDay(int y, int m, int day) {
  final last = DateTime(y, m + 1, 0).day;
  return DateTime(y, m, day > last ? last : day);
}

DateTime _addMonth(DateTime d, int n) => _clampDay(d.year, d.month + n, d.day);

/// Define onde começa e acaba cada mês e a que mês pertence cada data.
/// Os meses são sempre nomeados pelo mês em que terminam (ex.: 25 ago–24 set é setembro).
class MonthCycle {
  final CycleMode mode;
  final int startDay; // 1–31; só conta no dia fixo
  final List<DateTime>
  boundaries; // início de cada mês, por ordem (modo salário)

  MonthCycle.calendar()
    : mode = CycleMode.calendar,
      startDay = 1,
      boundaries = const [];

  MonthCycle.fixed(int day)
    : mode = CycleMode.fixedDay,
      startDay = day,
      boundaries = const [];

  MonthCycle.salary(this.boundaries) : mode = CycleMode.salary, startDay = 1;

  bool get _calendar =>
      mode == CycleMode.calendar ||
      (mode == CycleMode.fixedDay && startDay <= 1) ||
      (mode == CycleMode.salary && boundaries.isEmpty);

  // ---- dia fixo (e extrapolação do modo salário) ----
  static CycleSpan _fixedSpan(String key, int day) {
    final y = int.parse(key.substring(0, 4)),
        m = int.parse(key.substring(5, 7));
    if (day <= 1) return CycleSpan(key, DateTime(y, m), DateTime(y, m + 1));
    return CycleSpan(key, _clampDay(y, m - 1, day), _clampDay(y, m, day));
  }

  static String _fixedKeyOf(DateTime d, int day) {
    if (day <= 1) return _key(d);
    final startThis = _clampDay(d.year, d.month, day);
    final dd = DateTime(d.year, d.month, d.day);
    return !dd.isBefore(startThis)
        ? _key(DateTime(d.year, d.month + 1))
        : _key(d);
  }

  // ---- modo salário: meses pelos dias de recebimento ----
  late final List<CycleSpan> _spans = _buildSpans();

  List<CycleSpan> _buildSpans() {
    final out = <CycleSpan>[];
    for (var i = 0; i < boundaries.length; i++) {
      final start = boundaries[i];
      // o último mês ainda não acabou: assume-se um mês depois do início
      final end = i + 1 < boundaries.length
          ? boundaries[i + 1]
          : _addMonth(start, 1);
      var name = _key(end.subtract(const Duration(days: 1)));
      if (out.isNotEmpty && name.compareTo(out.last.key) <= 0) {
        final p = out.last.key;
        name = _key(
          DateTime(
            int.parse(p.substring(0, 4)),
            int.parse(p.substring(5, 7)) + 1,
          ),
        );
      }
      out.add(CycleSpan(name, start, end));
    }
    return out;
  }

  /// O mês [key] (AAAA-MM). [today] estende o último mês se o salário ainda não chegou.
  CycleSpan span(String key, {DateTime? today}) {
    if (_calendar) return _fixedSpan(key, 1);
    if (mode == CycleMode.fixedDay) return _fixedSpan(key, startDay);
    final t = today ?? DateTime.now();
    final first = _spans.first, last = _spans.last;
    if (key.compareTo(first.key) < 0) return _fixedSpan(key, first.start.day);
    if (key.compareTo(last.key) > 0) {
      final f = _fixedSpan(key, last.start.day);
      final lastEnd = _openEnd(last, t);
      return f.start.isBefore(lastEnd)
          ? CycleSpan(
              key,
              lastEnd,
              f.end.isAfter(lastEnd) ? f.end : _addMonth(lastEnd, 1),
            )
          : f;
    }
    for (final s in _spans) {
      if (s.key == key) {
        return s == last ? CycleSpan(s.key, s.start, _openEnd(s, t)) : s;
      }
    }
    // mês sem salário detetado entre outros: usa o dia do anterior
    CycleSpan prev = first;
    for (final s in _spans) {
      if (s.key.compareTo(key) < 0) prev = s;
    }
    return _fixedSpan(key, prev.start.day);
  }

  DateTime _openEnd(CycleSpan last, DateTime today) {
    final t = DateTime(today.year, today.month, today.day + 1);
    return t.isAfter(last.end) && today.difference(last.end).inDays < 45
        ? t
        : last.end;
  }

  /// O mês (AAAA-MM) a que a data [d] pertence.
  String keyOf(DateTime d, {DateTime? today}) {
    if (_calendar) return _key(d);
    if (mode == CycleMode.fixedDay) return _fixedKeyOf(d, startDay);
    final day = DateTime(d.year, d.month, d.day);
    if (day.isBefore(_spans.first.start)) {
      return _fixedKeyOf(d, _spans.first.start.day);
    }
    for (var i = _spans.length - 1; i >= 0; i--) {
      if (!day.isBefore(_spans[i].start)) {
        if (i == _spans.length - 1 && !day.isBefore(_spans[i].end)) {
          // depois do fim esperado do último mês, sem novo salário
          final end = _openEnd(_spans[i], today ?? DateTime.now());
          if (!day.isBefore(end)) return _fixedKeyOf(d, _spans[i].start.day);
        }
        return _spans[i].key;
      }
    }
    return _key(d);
  }
}

/// Dias de recebimento do salário: datas de movimentos positivos, uma por mês (as seguintes dentro de 15 dias
/// da primeira são o mesmo salário). [dates] não precisa de vir ordenada.
List<DateTime> salaryBoundaries(Iterable<DateTime> dates) {
  final ds = [for (final d in dates) DateTime(d.year, d.month, d.day)]..sort();
  final out = <DateTime>[];
  for (final d in ds) {
    if (out.isEmpty || d.difference(out.last).inDays >= 15) out.add(d);
  }
  return out;
}
