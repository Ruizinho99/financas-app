import 'package:financas/analysis/analytics.dart';
import 'package:financas/db/database.dart';
import 'package:financas/models.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Categorias em árvore, sem limite de níveis: A > B > C > D.
void main() {
  late AppState s;
  late int a, b, c, d, outra;
  final dia = DateTime(2026, 6, 10);
  final period = Period.month(DateTime(2026, 6));

  int cat(String n, {int? parent, int budget = 0, bool inv = false}) =>
      s.addCategory(
        Categoria(
          id: 0,
          name: n,
          parentId: parent,
          budgetValue: budget,
          hasBudget: budget > 0,
          isInvestment: inv,
        ),
      );
  void gasto(int cid, int cents) => s.addManual(
    date: dia,
    description: 'mov $cents $cid',
    amount: -cents,
    categoryId: cid,
  );

  setUp(() {
    s = AppState(Db.memory());
    a = cat('A');
    b = cat('B', parent: a);
    c = cat('C', parent: b);
    d = cat('D', parent: c);
    outra = cat('Outra');
  });

  test('profundidade, antepassados, raiz, caminho e subárvore', () {
    final dd = s.cat(d)!;
    expect(s.depthOf(dd), 3);
    expect(s.ancestorsOf(dd).map((x) => x.name), ['C', 'B', 'A']);
    expect(s.rootOf(dd).id, a);
    expect(s.path(d), 'A › B › C › D');
    expect(s.descendantsOf(a).map((x) => x.name).toSet(), {'B', 'C', 'D'});
    expect(s.subtreeIds(b), {b, c, d});
    expect(s.inSubtree(d, a), isTrue);
    expect(s.inSubtree(a, d), isFalse);
    expect(s.childrenOf(c).map((x) => x.name), ['D']);
    expect(s.roots.map((x) => x.name), ['A', 'Outra']);
  });

  test('o gasto sobe por todos os níveis (rollup) e a análise junta na categoria principal', () {
    gasto(d, 1000);
    gasto(c, 500);
    gasto(b, 200);
    gasto(a, 100);
    final own = s.totalsByCategory(period);
    expect(s.rollup(s.cat(d)!, own), 1000);
    expect(s.rollup(s.cat(c)!, own), 1500);
    expect(s.rollup(s.cat(b)!, own), 1700);
    expect(s.rollup(s.cat(a)!, own), 1800);
    final an = Analytics(s, period, const AnalysisFilter());
    final slices = an.byCategory();
    expect(slices.single.categoryId, a); // tudo cai na raiz A
    expect(slices.single.amount, 1800);
    // filtrar por B inclui B, C e D mas não A
    final fb = Analytics(s, period, AnalysisFilter(categoryIds: {b}));
    expect(fb.spent, 1700);
  });

  test('orçamento: soma dos orçamentos das folhas e o do pai tem prioridade', () {
    final x = cat('X');
    final y = cat('Y', parent: x);
    cat('Z', parent: y, budget: 3000);
    cat('W', parent: y, budget: 2000);
    expect(s.effectiveMonthlyTarget(s.cat(x)!, 0), 5000);
    s.updateCategory(s.cat(y)!.copyWith(budgetValue: 4000, hasBudget: true));
    expect(s.effectiveMonthlyTarget(s.cat(x)!, 0), 4000);
  });

  test('obrigatória e datas herdam-se de qualquer antepassado', () {
    expect(s.isMandatory(s.cat(d)!, '2026-06'), isFalse);
    s.setMandatoryInMonth(a, '2026-06', true);
    expect(s.isMandatory(s.cat(d)!, '2026-06'), isTrue);
    expect(s.isMandatoryDirect(s.cat(d)!, '2026-06'), isFalse);
    s.updateCategory(s.cat(b)!.copyWith(activeFrom: '2026-07'));
    expect(s.isCategoryActive(s.cat(d)!, '2026-06'), isFalse); // B ainda não existe
    expect(s.isCategoryActive(s.cat(d)!, '2026-07'), isTrue);
  });

  group('mover', () {
    test('para dentro de outra categoria: leva a subárvore e os movimentos ficam', () {
      gasto(d, 700);
      expect(s.moveCategory(c, outra), isNull);
      expect(s.path(d), 'Outra › C › D');
      expect(s.rootOf(s.cat(d)!).id, outra);
      expect(s.rollup(s.cat(outra)!, s.totalsByCategory(period)), 700);
      expect(s.rollup(s.cat(a)!, s.totalsByCategory(period)), 0);
      expect(s.transactions.single.categoryId, d); // o movimento continua em D
      // persistiu na base de dados
      expect(s.db.categories().firstWhere((x) => x.id == c).parentId, outra);
    });

    test('para o topo (principal)', () {
      expect(s.moveCategory(c, null), isNull);
      expect(s.cat(c)!.parentId, isNull);
      expect(s.roots.map((x) => x.name), containsAll(['A', 'C', 'Outra']));
      expect(s.path(d), 'C › D');
    });

    test('não deixa mover para dentro de si nem de um descendente', () {
      expect(s.canMoveCategory(a, a), MoveError.self);
      expect(s.canMoveCategory(a, d), MoveError.intoDescendant);
      expect(s.canMoveCategory(b, c), MoveError.intoDescendant);
      expect(s.moveCategory(a, d), MoveError.intoDescendant);
      expect(s.path(d), 'A › B › C › D'); // nada mudou
    });

    test('nome repetido no destino é recusado; mover para onde já está não faz nada', () {
      cat('C', parent: outra);
      expect(s.moveCategory(c, outra), MoveError.nameTaken);
      expect(s.canMoveCategory(c, b), isNull); // já está em B
      expect(s.moveCategory(c, b), isNull);
    });

    test('dentro de uma categoria de investimento passam a ser de investimento', () {
      final inv = cat('Investimentos', inv: true);
      s.moveCategory(c, inv);
      expect(s.cat(c)!.isInvestment, isTrue);
      expect(s.cat(d)!.isInvestment, isTrue);
      expect(s.cat(b)!.isInvestment, isFalse);
    });
  });

  test('apagar uma categoria apaga tudo o que tem dentro e os movimentos ficam sem categoria', () {
    gasto(d, 300);
    s.deleteCategory(b);
    expect(s.cat(c), isNull);
    expect(s.cat(d), isNull);
    expect(s.cat(a), isNotNull);
    expect(s.transactions.single.categoryId, isNull);
  });

  test('duplicar para o ano seguinte copia a árvore toda', () {
    final y1 = cat('Férias 2026');
    final y2 = cat('Voos', parent: y1);
    cat('Ida', parent: y2, budget: 5000);
    final novo = s.duplicateForNextYear(s.cat(y1)!);
    expect(s.cat(novo)!.name, 'Férias 2027');
    final ds = s.descendantsOf(novo);
    expect(ds.map((x) => x.name).toSet(), {'Voos', 'Ida'});
    expect(ds.firstWhere((x) => x.name == 'Ida').budgetValue, 5000);
    expect(s.path(ds.firstWhere((x) => x.name == 'Ida').id), 'Férias 2027 › Voos › Ida');
  });
}
