import 'package:financas/db/database.dart';
import 'package:financas/models.dart';
import 'package:financas/state/app_state.dart';

/// 3 meses (abril–junho de 2026) com renda obrigatória, subscrições, cafés, supermercado a subir,
/// uma transferência entre contas e um movimento sem categoria.
({AppState s, int casa, int alim, int rest, int sup, int lazer, int ordem, int poup}) buildAnalysisData() {
  final s = AppState(Db.memory());
  final casa = s.addCategory(const Categoria(id: 0, name: 'Casa', emoji: '🏠'));
  final alim = s.addCategory(const Categoria(id: 0, name: 'Alimentação', emoji: '🍔'));
  final rest = s.addCategory(Categoria(id: 0, name: 'Restaurantes', parentId: alim));
  final sup = s.addCategory(Categoria(id: 0, name: 'Supermercado', parentId: alim));
  final lazer = s.addCategory(const Categoria(id: 0, name: 'Lazer', emoji: '🎬'));
  final sal = s.addCategory(const Categoria(id: 0, name: 'Salário', isIncome: true));
  s.addRange(casa, '2026-01', '2026-12'); // Casa é obrigatória
  final ordem = s.addAccount('Ordem');
  final poup = s.addAccount('Poupança');
  void tx(DateTime d, String desc, int cents, {int? cat, int? acc}) =>
      s.addManual(date: d, description: desc, amount: cents, categoryId: cat, accountId: acc);
  for (final m in [4, 5, 6]) {
    tx(DateTime(2026, m, 1), 'RENDA CASA', -50000, cat: casa, acc: ordem);
    tx(DateTime(2026, m, 3), 'NETFLIX', -1299, cat: lazer, acc: ordem);
    tx(DateTime(2026, m, 4), 'SPOTIFY', -799, cat: lazer, acc: ordem);
    tx(DateTime(2026, m, 25), 'SALARIO ACME', 150000, cat: sal, acc: ordem);
  }
  tx(DateTime(2026, 4, 10), 'CONTINENTE', -20000, cat: sup, acc: ordem);
  tx(DateTime(2026, 5, 10), 'CONTINENTE', -25000, cat: sup, acc: ordem);
  tx(DateTime(2026, 6, 10), 'CONTINENTE', -40000, cat: sup, acc: ordem);
  tx(DateTime(2026, 6, 12), 'RESTAURANTE ARMINDA', -3500, cat: rest, acc: ordem);
  for (var i = 0; i < 8; i++) {
    tx(DateTime(2026, 6, 2 + i), 'CAFE CENTRAL', -120, cat: lazer, acc: ordem);
  }
  tx(DateTime(2026, 6, 20), 'COMPRA X', -1000, acc: poup); // sem categoria
  s.addTransfer(date: DateTime(2026, 6, 26), description: 'Para poupança', amount: 30000, fromAccount: ordem, toAccount: poup);
  return (s: s, casa: casa, alim: alim, rest: rest, sup: sup, lazer: lazer, ordem: ordem, poup: poup);
}

