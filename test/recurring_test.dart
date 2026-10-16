import 'package:financas/recurring/recurring.dart';
import 'package:flutter_test/flutter_test.dart';

RecurringRule _rule({
  RecurrenceFreq freq = RecurrenceFreq.monthly,
  required int day,
  required DateTime start,
  DateTime? end,
  DateTime? last,
  bool active = true,
}) => RecurringRule(
  description: 'Teste',
  amount: -10000,
  freq: freq,
  day: day,
  start: start,
  end: end,
  lastGenerated: last,
  active: active,
);

void main() {
  group('mensal', () {
    test('dia 31 em fevereiro passa para o último dia do mês', () {
      final r = _rule(day: 31, start: DateTime(2027, 1, 31));
      expect(dueOccurrences(r, DateTime(2027, 3, 31)), [
        DateTime(2027, 1, 31),
        DateTime(2027, 2, 28),
        DateTime(2027, 3, 31),
      ]);
    });

    test(
      'ano bissexto: dia 29 cai a 29 de fevereiro, e a 28 nos outros anos',
      () {
        final r = _rule(day: 29, start: DateTime(2027, 2, 1));
        final datas = dueOccurrences(r, DateTime(2028, 3, 1), limit: 100);
        expect(datas.contains(DateTime(2027, 2, 28)), isTrue);
        expect(datas.contains(DateTime(2028, 2, 29)), isTrue);
        expect(datas.contains(DateTime(2027, 2, 29)), isFalse);
      },
    );

    test('nada antes da data de início; o próprio início conta', () {
      final r = _rule(day: 5, start: DateTime(2026, 6, 5));
      expect(dueOccurrences(r, DateTime(2026, 6, 4)), isEmpty);
      expect(dueOccurrences(r, DateTime(2026, 6, 5)), [DateTime(2026, 6, 5)]);
    });

    test(
      'inicia no mês da data de início mesmo que o dia já tenha passado',
      () {
        // início a 10 de janeiro, dia 5: o primeiro é a 5 de fevereiro
        final r = _rule(day: 5, start: DateTime(2026, 1, 10));
        expect(dueOccurrences(r, DateTime(2026, 2, 5)), [DateTime(2026, 2, 5)]);
      },
    );
  });

  group('semanal', () {
    test('dia da semana 3 (quarta-feira) a partir de uma sexta', () {
      // 16/10/2026 é sexta-feira
      final r = _rule(
        freq: RecurrenceFreq.weekly,
        day: 3,
        start: DateTime(2026, 10, 16),
      );
      expect(dueOccurrences(r, DateTime(2026, 11, 4)), [
        DateTime(2026, 10, 21),
        DateTime(2026, 10, 28),
        DateTime(2026, 11, 4),
      ]);
    });

    test('atravessa a mudança de hora sem recuar um dia', () {
      // domingo (7) de 2026: a mudança de hora na Europa é a 25 de outubro
      final r = _rule(
        freq: RecurrenceFreq.weekly,
        day: 7,
        start: DateTime(2026, 10, 1),
      );
      expect(dueOccurrences(r, DateTime(2026, 11, 8)), [
        DateTime(2026, 10, 4),
        DateTime(2026, 10, 11),
        DateTime(2026, 10, 18),
        DateTime(2026, 10, 25),
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 8),
      ]);
    });
  });

  group('anual', () {
    test('repete no mês e dia da data de início', () {
      final r = _rule(
        freq: RecurrenceFreq.yearly,
        day: 15,
        start: DateTime(2024, 3, 15),
      );
      expect(dueOccurrences(r, DateTime(2026, 10, 16)), [
        DateTime(2024, 3, 15),
        DateTime(2025, 3, 15),
        DateTime(2026, 3, 15),
      ]);
    });

    test('29 de fevereiro nos anos não bissextos cai a 28', () {
      final r = _rule(
        freq: RecurrenceFreq.yearly,
        day: 29,
        start: DateTime(2027, 2, 28),
      );
      final datas = dueOccurrences(r, DateTime(2029, 3, 1));
      expect(datas, [
        DateTime(2027, 2, 28),
        DateTime(2028, 2, 29),
        DateTime(2029, 2, 28),
      ]);
    });
  });

  group('data de fim e última data gerada', () {
    test('não passa da data de fim (inclusive)', () {
      final r = _rule(
        day: 10,
        start: DateTime(2026, 1, 10),
        end: DateTime(2026, 3, 10),
      );
      expect(dueOccurrences(r, DateTime(2026, 12, 31)), [
        DateTime(2026, 1, 10),
        DateTime(2026, 2, 10),
        DateTime(2026, 3, 10),
      ]);
    });

    test('depois da última gerada: não repete o que já existe', () {
      final r = _rule(
        freq: RecurrenceFreq.yearly,
        day: 15,
        start: DateTime(2024, 3, 15),
        last: DateTime(2026, 3, 15),
      );
      expect(dueOccurrences(r, DateTime(2026, 10, 16)), isEmpty);
    });

    test('a última gerada ser o dia anterior a uma ocorrência não a salta', () {
      final r = _rule(
        day: 5,
        start: DateTime(2026, 1, 1),
        last: DateTime(2026, 2, 4),
      );
      expect(dueOccurrences(r, DateTime(2026, 2, 5)), [DateTime(2026, 2, 5)]);
    });

    test('fim anterior ao início: nada', () {
      final r = _rule(
        day: 5,
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 5, 1),
      );
      expect(dueOccurrences(r, DateTime(2026, 12, 1)), isEmpty);
    });
  });

  group('limite por execução', () {
    test('no máximo 24 ocorrências, as mais antigas primeiro', () {
      final r = _rule(day: 1, start: DateTime(2020, 1, 1));
      final datas = dueOccurrences(r, DateTime(2026, 10, 16));
      expect(datas.length, maxRecurringPerRun);
      expect(maxRecurringPerRun, 24);
      expect(datas.first, DateTime(2020, 1, 1));
      expect(datas.last, DateTime(2021, 12, 1));
    });

    test('a execução seguinte continua de onde a anterior parou', () {
      final r = _rule(day: 1, start: DateTime(2020, 1, 1));
      final primeira = dueOccurrences(r, DateTime(2026, 10, 16));
      final seguinte = dueOccurrences(
        r.withLastGenerated(primeira.last),
        DateTime(2026, 10, 16),
      );
      expect(seguinte.first, DateTime(2022, 1, 1));
    });
  });

  group('próxima data', () {
    test('a partir de hoje, sem contar datas já geradas', () {
      final r = _rule(day: 31, start: DateTime(2027, 1, 31));
      expect(nextOccurrence(r, DateTime(2027, 2, 1)), DateTime(2027, 2, 28));
    });

    test('nula depois da data de fim', () {
      final r = _rule(
        day: 5,
        start: DateTime(2026, 1, 5),
        end: DateTime(2026, 3, 5),
      );
      expect(nextOccurrence(r, DateTime(2026, 4, 1)), isNull);
    });

    test('antes do início, a primeira data é a de início', () {
      final r = _rule(day: 5, start: DateTime(2026, 6, 5));
      expect(nextOccurrence(r, DateTime(2026, 1, 1)), DateTime(2026, 6, 5));
    });
  });
}
