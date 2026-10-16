import 'dart:math';

/// Movimentos recorrentes (salário, renda, subscrições): modelo e regras de datas.
/// Funções puras, sem base de dados. Todas as datas são dias sem hora.

/// Quantos movimentos se criam, no máximo, por execução (os mais antigos primeiro).
const maxRecurringPerRun = 24;

enum RecurrenceFreq { monthly, weekly, yearly }

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

int _daysIn(int year, int month) => DateTime(year, month + 1, 0).day;

/// Dia válido para a frequência: 1 a 31 no mensal e no anual, 1 (segunda) a 7 (domingo) no semanal.
bool diaValido(RecurrenceFreq f, int dia) =>
    f == RecurrenceFreq.weekly ? dia >= 1 && dia <= 7 : dia >= 1 && dia <= 31;

class RecurringRule {
  final int? id; // nulo = regra ainda não guardada
  final String description;
  final int amount; // cêntimos com sinal: negativo = despesa
  final int? categoryId;
  final int? accountId;
  final RecurrenceFreq freq;
  // mensal e anual: dia do mês (1–31; no anual o mês é o da data de início);
  // semanal: dia da semana (1 = segunda … 7 = domingo, como DateTime.weekday)
  final int day;
  final DateTime start;
  final DateTime? end; // nulo = sem data de fim
  final DateTime?
  lastGenerated; // última data já gerada (nula = nada gerado ainda)
  final bool active;

  RecurringRule({
    this.id,
    required this.description,
    required this.amount,
    this.categoryId,
    this.accountId,
    required this.freq,
    required this.day,
    required DateTime start,
    DateTime? end,
    DateTime? lastGenerated,
    this.active = true,
  }) : start = dateOnly(start),
       end = end == null ? null : dateOnly(end),
       lastGenerated = lastGenerated == null ? null : dateOnly(lastGenerated);

  /// Cópia com outra última data gerada (a data é normalizada).
  RecurringRule withLastGenerated(DateTime? d) => RecurringRule(
    id: id,
    description: description,
    amount: amount,
    categoryId: categoryId,
    accountId: accountId,
    freq: freq,
    day: day,
    start: start,
    end: end,
    lastGenerated: d,
    active: active,
  );
}

/// Datas em que a regra cai, a partir de [from] (inclusive), por ordem e sem fim.
Iterable<DateTime> _schedule(RecurringRule r, DateTime from) sync* {
  switch (r.freq) {
    case RecurrenceFreq.monthly:
      {
        var y = from.year, m = from.month;
        while (true) {
          // dia 31 em meses curtos passa para o último dia do mês (29 de fevereiro em anos bissextos)
          final d = DateTime(y, m, min(r.day, _daysIn(y, m)));
          if (!d.isBefore(from)) yield d;
          m++;
          if (m > 12) {
            m = 1;
            y++;
          }
        }
      }
    case RecurrenceFreq.yearly:
      {
        final mes = r.start.month;
        for (var y = from.year; ; y++) {
          final d = DateTime(y, mes, min(r.day, _daysIn(y, mes)));
          if (!d.isBefore(from)) yield d;
        }
      }
    case RecurrenceFreq.weekly:
      {
        // aritmética de calendário (não de 7 × 24 h), para não recuar um dia com a mudança de hora
        var d = DateTime(
          from.year,
          from.month,
          from.day + (r.day - from.weekday + 7) % 7,
        );
        while (true) {
          yield d;
          d = DateTime(d.year, d.month, d.day + 7);
        }
      }
  }
}

/// Primeira data que a regra pode gerar: a data de início, ou o dia a seguir à última gerada.
DateTime _lowerBound(RecurringRule r) {
  final last = r.lastGenerated;
  if (last == null) return r.start;
  final depois = DateTime(last.year, last.month, last.day + 1);
  return depois.isAfter(r.start) ? depois : r.start;
}

/// Ocorrências por gerar até [today] (inclusive), da mais antiga para a mais recente.
/// Começa depois da última gerada (ou na data de início, inclusive), nunca antes do início e
/// não passa da data de fim. Devolve no máximo [limit] datas.
List<DateTime> dueOccurrences(
  RecurringRule r,
  DateTime today, {
  int limit = maxRecurringPerRun,
}) {
  var ate = dateOnly(today);
  if (r.end != null && r.end!.isBefore(ate)) ate = r.end!;
  final out = <DateTime>[];
  if (limit <= 0) return out;
  for (final d in _schedule(r, _lowerBound(r))) {
    if (d.isAfter(ate) || out.length >= limit) break;
    out.add(d);
  }
  return out;
}

/// Próxima data por gerar a partir de [today], ou nula se a regra já acabou.
DateTime? nextOccurrence(RecurringRule r, DateTime today) {
  var from = _lowerBound(r);
  final hoje = dateOnly(today);
  if (hoje.isAfter(from)) from = hoje;
  final d = _schedule(r, from).first;
  if (r.end != null && d.isAfter(r.end!)) return null;
  return d;
}
