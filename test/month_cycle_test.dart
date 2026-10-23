import 'package:financas/util/month_cycle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dia fixo', () {
    final c = MonthCycle.fixed(25);

    test('25 de agosto a 24 de setembro é setembro', () {
      final s = c.span('2026-09');
      expect(s.start, DateTime(2026, 8, 25));
      expect(s.end, DateTime(2026, 9, 25)); // exclusivo
    });

    test('a que mês pertence cada data', () {
      expect(c.keyOf(DateTime(2026, 8, 24)), '2026-08');
      expect(c.keyOf(DateTime(2026, 8, 25)), '2026-09');
      expect(c.keyOf(DateTime(2026, 9, 24)), '2026-09');
      expect(c.keyOf(DateTime(2026, 9, 25)), '2026-10');
      expect(c.keyOf(DateTime(2026, 12, 31)), '2027-01');
    });

    test('dia 31 usa o último dia dos meses mais curtos', () {
      final s = MonthCycle.fixed(31).span('2027-03');
      expect(s.start, DateTime(2027, 2, 28));
      expect(s.end, DateTime(2027, 3, 31));
      expect(MonthCycle.fixed(31).keyOf(DateTime(2027, 2, 28)), '2027-03');
    });

    test('cada data cai no mês cujo intervalo a contém', () {
      for (
        var d = DateTime(2026, 1, 1);
        d.year < 2027;
        d = d.add(const Duration(days: 1))
      ) {
        final s = c.span(c.keyOf(d));
        expect(!d.isBefore(s.start) && d.isBefore(s.end), isTrue, reason: '$d');
      }
    });
  });

  test('calendário: o mês é o mês do calendário', () {
    final c = MonthCycle.calendar();
    final s = c.span('2026-02');
    expect(s.start, DateTime(2026, 2, 1));
    expect(s.end, DateTime(2026, 3, 1));
    expect(c.keyOf(DateTime(2026, 2, 28)), '2026-02');
    // dia fixo 1 é o mesmo que calendário
    expect(MonthCycle.fixed(1).span('2026-02').start, DateTime(2026, 2, 1));
  });

  group('pelo salário', () {
    // salário recebido a 24 fev, 26 mar, 25 abr, 25 mai
    final c = MonthCycle.salary([
      DateTime(2026, 1, 24),
      DateTime(2026, 2, 24),
      DateTime(2026, 3, 26),
      DateTime(2026, 4, 25),
      DateTime(2026, 5, 25),
    ]);
    final hoje = DateTime(2026, 5, 30);

    test('março vai de 24 de fevereiro ao dia antes do salário de março', () {
      final s = c.span('2026-03', today: hoje);
      expect(s.start, DateTime(2026, 2, 24));
      expect(s.end, DateTime(2026, 3, 26));
    });

    test('abril começa no dia em que o salário de abril chegou', () {
      final s = c.span('2026-04', today: hoje);
      expect(s.start, DateTime(2026, 3, 26));
      expect(s.end, DateTime(2026, 4, 25));
    });

    test('a que mês pertence cada data', () {
      expect(c.keyOf(DateTime(2026, 3, 25), today: hoje), '2026-03');
      expect(c.keyOf(DateTime(2026, 3, 26), today: hoje), '2026-04');
      expect(c.keyOf(DateTime(2026, 4, 24), today: hoje), '2026-04');
      expect(c.keyOf(DateTime(2026, 4, 25), today: hoje), '2026-05');
    });

    test(
      'o último mês acaba um mês depois, ou mais tarde se o salário atrasar',
      () {
        final normal = c.span('2026-06', today: DateTime(2026, 6, 10));
        expect(normal.start, DateTime(2026, 5, 25));
        expect(normal.end, DateTime(2026, 6, 25));
        // 3 dias de atraso: o mês continua aberto até hoje
        final atrasado = c.span('2026-06', today: DateTime(2026, 6, 28));
        expect(atrasado.end.isAfter(DateTime(2026, 6, 28)), isTrue);
        expect(
          c.keyOf(DateTime(2026, 6, 27), today: DateTime(2026, 6, 28)),
          '2026-06',
        );
      },
    );

    test('sem salários detetados comporta-se como o calendário', () {
      final vazio = MonthCycle.salary(const []);
      expect(vazio.span('2026-02').start, DateTime(2026, 2, 1));
      expect(vazio.keyOf(DateTime(2026, 2, 20)), '2026-02');
    });
  });

  group('dias de salário', () {
    test('movimentos próximos contam como o mesmo salário', () {
      final b = salaryBoundaries([
        DateTime(2026, 3, 26),
        DateTime(2026, 3, 28), // complemento do mesmo mês
        DateTime(2026, 2, 24),
        DateTime(2026, 4, 25),
      ]);
      expect(b, [
        DateTime(2026, 2, 24),
        DateTime(2026, 3, 26),
        DateTime(2026, 4, 25),
      ]);
    });
  });
}
