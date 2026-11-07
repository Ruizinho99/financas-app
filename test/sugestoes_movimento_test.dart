import 'package:financas/db/database.dart';
import 'package:financas/import/parsers.dart' show merchantKey;
import 'package:financas/models.dart';
import 'package:financas/state/app_state.dart';
import 'package:financas/widgets/category_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppState s;
  late int alim, trans, conta1, conta2;
  final hoje = DateTime(2026, 11, 5);

  void mov(String d, int cents, int? cat, {DateTime? when, int? conta}) =>
      s.addManual(
        date: when ?? hoje,
        description: d,
        amount: cents,
        categoryId: cat,
        accountId: conta,
      );

  setUp(() {
    s = AppState(Db.memory());
    alim = s.addCategory(const Categoria(id: 0, name: 'Alimentação'));
    trans = s.addCategory(const Categoria(id: 0, name: 'Transportes'));
    conta1 = s.addAccount('Conta Simples');
    conta2 = s.addAccount('Carteira');
  });

  group('sugestões de descrição', () {
    test('junta pelo nome, com a categoria mais usada e a contagem', () {
      mov('Pingo Doce', -1000, alim);
      mov('Pingo Doce', -2000, alim);
      mov('Pingo Doce', -500, trans); // engano, minoritário
      mov('Pingo Doce Vizela', -300, alim);
      mov('Galp', -4000, trans);
      final r = s.suggestDescriptions('ping');
      expect(r.map((x) => x.text), ['Pingo Doce', 'Pingo Doce Vizela']);
      expect(r.first.count, 3);
      expect(r.first.categoryId, alim);
    });

    test('não distingue maiúsculas nem acentos e pede 2 letras', () {
      mov('Pastelaria Café Ágata', -150, alim);
      expect(s.suggestDescriptions('agata').single.text, 'Pastelaria Café Ágata');
      expect(s.suggestDescriptions('CAFE'), hasLength(1));
      expect(s.suggestDescriptions('a'), isEmpty);
      expect(s.suggestDescriptions(''), isEmpty);
    });

    test('quem começa pelo texto vem primeiro; ignora transferências; filtra entradas/saídas', () {
      mov('Loja do Pingo', -100, alim);
      mov('Pingo Doce', -100, alim);
      mov('Pingo recebido', 5000, null);
      s.addManual(date: hoje, description: 'Pingo transf', amount: -999, isTransfer: true);
      expect(s.suggestDescriptions('pingo').first.text, anyOf('Pingo Doce', 'Pingo recebido'));
      expect(s.suggestDescriptions('pingo').map((x) => x.text), isNot(contains('Pingo transf')));
      expect(s.suggestDescriptions('pingo', income: true).map((x) => x.text), ['Pingo recebido']);
      expect(s.suggestDescriptions('pingo', income: false).map((x) => x.text), containsAll(['Pingo Doce', 'Loja do Pingo']));
    });

    test('respeita o limite', () {
      for (var i = 0; i < 8; i++) {
        mov('Loja $i', -100, alim);
      }
      expect(s.suggestDescriptions('loja', limit: 3), hasLength(3));
    });
  });

  group('categoria sugerida', () {
    test('a da regra memorizada ganha; senão, a mais usada com a mesma descrição', () {
      mov('Pingo Doce', -1000, alim);
      mov('Pingo Doce', -1000, alim);
      mov('Pingo Doce', -1000, trans);
      expect(s.suggestCategoryFor('Pingo Doce'), alim);
      s.db.upsertRule(merchantKey('Galp Porto'), trans);
      s.reload();
      expect(s.suggestCategoryFor('Galp Porto'), trans);
      expect(s.suggestCategoryFor('Desconhecido'), isNull);
      expect(s.suggestCategoryFor('  '), isNull);
    });
  });

  group('mais usadas e conta', () {
    test('mais usadas dos últimos meses, em saídas ou entradas', () {
      final sal = s.addCategory(const Categoria(id: 0, name: 'Salário'));
      for (var i = 0; i < 3; i++) {
        mov('a$i', -100, alim);
      }
      mov('b', -100, trans);
      mov('s', 100000, sal);
      mov('velho', -100, trans, when: DateTime(2025, 1, 1)); // fora dos 180 dias
      expect(s.mostUsedCategoryIds(today: hoje, income: false), [alim, trans]);
      expect(s.mostUsedCategoryIds(today: hoje, income: true), [sal]);
      expect(s.mostUsedCategoryIds(today: hoje, limit: 1), [alim]);
    });

    test('última conta usada é a do movimento mais recente com conta', () {
      expect(s.lastUsedAccountId, isNull);
      mov('x', -100, alim, when: DateTime(2026, 11, 1), conta: conta1);
      mov('y', -100, alim, when: DateTime(2026, 11, 4), conta: conta2);
      mov('z', -100, alim, when: DateTime(2026, 11, 5)); // sem conta
      expect(s.lastUsedAccountId, conta2);
    });
  });

  test('ícones por nome: palavras-chave, sem acentos, e um genérico se não souber', () {
    expect(categoryIconFor('Habitação'), Icons.home_outlined);
    expect(categoryIconFor('Supermercado'), Icons.shopping_basket_outlined);
    expect(categoryIconFor('RESTAURANTES'), Icons.restaurant_outlined);
    expect(categoryIconFor('Saúde'), Icons.medical_services_outlined);
    expect(categoryIconFor('Salário'), Icons.payments_outlined);
    expect(categoryIconFor('Zzz qualquer'), Icons.category_outlined);
  });
}
