import 'package:financas/analysis/analytics.dart';
import 'package:financas/db/database.dart';
import 'package:financas/models.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppState s;
  late int subs, reembolsos;
  final day = DateTime(2026, 10, 5);
  final period = Period.month(DateTime(2026, 10));

  setUp(() {
    s = AppState(Db.memory());
    subs = s.addCategory(const Categoria(id: 0, name: 'Subscrições'));
    reembolsos = s.addCategory(
      const Categoria(id: 0, name: 'Reembolsos', isIncome: true),
    );
  });

  int idOf(String desc) =>
      s.transactions.firstWhere((t) => t.description == desc).id;

  test('reembolso total: a despesa e a receita saem da análise, o extrato não muda', () {
    s.addManual(
      date: day,
      description: 'Claude',
      amount: -2200,
      categoryId: subs,
    );
    s.addManual(
      date: day,
      description: 'Reembolso empresa',
      amount: 2200,
      categoryId: reembolsos,
      reversesId: idOf('Claude'),
      reversedCents: 2200,
    );
    final a = Analytics(s, period, const AnalysisFilter());
    expect(a.spent, 0);
    expect(a.income, 0);
    // o saldo do banco continua a ser -22 + 22
    expect(s.transactions.fold(0, (x, t) => x + t.amount), 0);
  });

  test('devolução parcial: 20 € de compra, 5 € devolvidos, conta 15 €', () {
    s.addManual(
      date: day,
      description: 'Produtos',
      amount: -2000,
      categoryId: subs,
    );
    final id = idOf('Produtos');
    s.addManual(
      date: day,
      description: 'Devolução defeito',
      amount: 500,
      categoryId: reembolsos,
      reversesId: id,
      reversedCents: 500,
    );
    final a = Analytics(s, period, const AnalysisFilter());
    expect(a.spent, 1500);
    expect(a.income, 0);
    expect(
      s.reversibleLeft(s.transactions.firstWhere((t) => t.id == id)),
      1500,
    );
  });

  test('não se pode anular mais do que a despesa tem por anular', () {
    s.addManual(
      date: day,
      description: 'Jantar',
      amount: -3000,
      categoryId: subs,
    );
    final exp = s.transactions.firstWhere((t) => t.description == 'Jantar');
    s.addManual(
      date: day,
      description: 'Reembolso 1',
      amount: 2000,
      categoryId: reembolsos,
      reversesId: exp.id,
      reversedCents: 2000,
    );
    expect(s.reversibleLeft(exp), 1000);
    // editar a própria receita não conta como já anulada
    final r1 = s.transactions.firstWhere((t) => t.description == 'Reembolso 1');
    expect(s.reversibleLeft(exp, exceptTxnId: r1.id), 3000);
  });

  test(
    'apagar a despesa transforma a receita de anulação numa receita normal',
    () {
      s.addManual(
        date: day,
        description: 'Hotel',
        amount: -10000,
        categoryId: subs,
      );
      final hotel = idOf('Hotel');
      s.addManual(
        date: day,
        description: 'Reembolso hotel',
        amount: 10000,
        categoryId: reembolsos,
        reversesId: hotel,
        reversedCents: 10000,
      );
      s.deleteTxns([hotel]);
      final r = s.transactions.firstWhere(
        (t) => t.description == 'Reembolso hotel',
      );
      expect(r.reversesId, isNull);
      expect(r.reversedCents, 0);
      final a = Analytics(s, period, const AnalysisFilter());
      expect(a.income, 10000);
    },
  );
}
