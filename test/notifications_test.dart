import 'package:financas/db/database.dart';
import 'package:financas/invest/invest.dart';
import 'package:financas/notify/notifications.dart';
import 'package:financas/state/app_state.dart';
import 'package:financas/util/format.dart';
import 'package:flutter_test/flutter_test.dart';

/// Envio falso: guarda título e texto, sem chamar o plugin.
class _Envio {
  final List<({int id, String title, String body})> enviadas = [];
  final Set<String> falhaEm; // texto que faz o envio falhar
  _Envio({this.falhaEm = const {}});

  Future<void> call(int id, String title, String body) async {
    for (final f in falhaEm) {
      if (body.contains(f)) throw StateError('falhou');
    }
    enviadas.add((id: id, title: title, body: body));
  }
}

/// Estado com duas plataformas com plano e uma entrega cada, de hoje.
AppState _estado({bool comEntregas = true}) {
  final s = AppState(Db.memory());
  final banco = s.addAccount('Banco');
  final xtb = s.addInvestAccount('XTB');
  final trading = s.addInvestAccount('Trading 212');
  final vwce = s.addHolding(Holding(id: 0, accountId: xtb, name: 'VWCE'));
  final aapl = s.addHolding(Holding(id: 0, accountId: xtb, name: 'Apple'));
  final etf = s.addHolding(Holding(id: 0, accountId: trading, name: 'SPY'));
  s.setInvestPlan(xtb, {vwce: 7000, aapl: 3000});
  s.setInvestPlan(trading, {etf: 10000});
  if (comEntregas) {
    final hoje = DateTime.now();
    final meia = DateTime(hoje.year, hoje.month, hoje.day);
    s.addManual(
      date: meia,
      description: 'Entrega XTB',
      amount: -100000,
      accountId: banco,
      isTransfer: true,
      investAccountId: xtb,
    );
    s.addManual(
      date: meia,
      description: 'Entrega T212',
      amount: -50000,
      accountId: banco,
      isTransfer: true,
      investAccountId: trading,
    );
  }
  return s;
}

void main() {
  group('textos', () {
    test('movimentos recorrentes: singular e plural', () {
      expect(recurringBody(1), '1 movimento recorrente registado');
      expect(recurringBody(3), '3 movimentos recorrentes registados');
    });

    test('entrega: nome da plataforma, ativos e valores', () {
      final s = _estado();
      final alertas = allocationAlerts(
        s.pendingAllocations,
        {},
        nameOf: (id) => s.holding(id)?.name ?? 'Ativo',
      );
      final xtb = alertas.firstWhere((a) => a.accountName == 'XTB');
      expect(
        allocationBody(xtb),
        'XTB: VWCE ${fmtMoney(70000)}, Apple ${fmtMoney(30000)}',
      );
    });

    test('entregas por distribuir aparecem no texto', () {
      final s = AppState(Db.memory());
      final banco = s.addAccount('Banco');
      final xtb = s.addInvestAccount('XTB');
      final vwce = s.addHolding(Holding(id: 0, accountId: xtb, name: 'VWCE'));
      s.setInvestPlan(xtb, {vwce: 5000});
      s.addManual(
        date: DateTime.now(),
        description: 'Entrega',
        amount: -100000,
        accountId: banco,
        isTransfer: true,
        investAccountId: xtb,
      );
      final a = allocationAlerts(
        s.pendingAllocations,
        {},
        nameOf: (_) => 'VWCE',
      ).single;
      expect(
        allocationBody(a),
        'XTB: VWCE ${fmtMoney(50000)}, ${fmtMoney(50000)} por distribuir',
      );
    });
  });

  group('agrupamento', () {
    test('uma notificação por plataforma, com as entregas somadas', () {
      final s = _estado();
      final hoje = DateTime.now();
      final meia = DateTime(hoje.year, hoje.month, hoje.day);
      s.addManual(
        date: meia,
        description: 'Entrega XTB 2',
        amount: -20000,
        accountId: s.accounts.first.id,
        isTransfer: true,
        investAccountId: s.investAccounts.firstWhere((a) => a.name == 'XTB').id,
      );
      final alertas = allocationAlerts(
        s.pendingAllocations,
        {},
        nameOf: (id) => s.holding(id)?.name ?? 'Ativo',
      );
      expect(alertas.length, 2);
      final xtb = alertas.firstWhere((a) => a.accountName == 'XTB');
      expect(xtb.count, 2);
      expect(xtb.parts.firstWhere((p) => p.name == 'VWCE').cents, 84000);
    });

    test('movimentos já notificados ficam de fora', () {
      final s = _estado();
      final ids = s.pendingAllocations.map((p) => p.txn.id).toSet();
      final alertas = allocationAlerts(
        s.pendingAllocations,
        ids,
        nameOf: (_) => 'x',
      );
      expect(alertas, isEmpty);
    });
  });

  group('ids notificados', () {
    test('ida e volta; entradas inválidas são ignoradas', () {
      expect(parseNotifiedIds('3,10,7'), {3, 10, 7});
      expect(parseNotifiedIds(' 3 , abc ,, 10 '), {3, 10});
      expect(parseNotifiedIds(null), isEmpty);
      expect(parseNotifiedIds(''), isEmpty);
      expect(encodeNotifiedIds({10, 3, 7}), '3,7,10');
      expect(parseNotifiedIds(encodeNotifiedIds({5, 2})), {2, 5});
    });
  });

  group('arranque', () {
    test(
      'primeira execução: não envia avisos e marca as entregas existentes',
      () async {
        final s = _estado();
        final envio = _Envio();
        await notifyStartup(s, recurringCreated: 0, show: envio.call);
        expect(envio.enviadas, isEmpty);
        final guardados = parseNotifiedIds(
          s.db.setting(investAlertsNotifiedKey),
        );
        expect(guardados, s.pendingAllocations.map((p) => p.txn.id).toSet());
      },
    );

    test(
      'depois da primeira execução, só as entregas novas geram aviso',
      () async {
        final s = _estado();
        await notifyStartup(s, recurringCreated: 0, show: _Envio().call);

        final hoje = DateTime.now();
        final meia = DateTime(hoje.year, hoje.month, hoje.day);
        s.addManual(
          date: meia,
          description: 'Entrega nova',
          amount: -30000,
          accountId: s.accounts.first.id,
          isTransfer: true,
          investAccountId: s.investAccounts
              .firstWhere((a) => a.name == 'XTB')
              .id,
        );
        final envio = _Envio();
        await notifyStartup(s, recurringCreated: 0, show: envio.call);
        expect(envio.enviadas.length, 1);
        expect(envio.enviadas.single.title, allocationTitle);
        expect(envio.enviadas.single.body, contains('XTB'));
      },
    );

    test('ids já notificados não se repetem em execuções seguintes', () async {
      final s = _estado();
      s.db.putSetting(investAlertsNotifiedKey, '');
      final primeira = _Envio();
      await notifyStartup(s, recurringCreated: 0, show: primeira.call);
      expect(primeira.enviadas.length, 2); // XTB e Trading 212

      final segunda = _Envio();
      await notifyStartup(s, recurringCreated: 0, show: segunda.call);
      expect(segunda.enviadas, isEmpty);
    });

    test(
      'falha num envio não bloqueia os outros e essa plataforma repete-se',
      () async {
        final s = _estado();
        s.db.putSetting(investAlertsNotifiedKey, '');
        final falha = _Envio(falhaEm: {'XTB'});
        await notifyStartup(s, recurringCreated: 0, show: falha.call);
        expect(
          falha.enviadas.map((e) => e.body).join(),
          contains('Trading 212'),
        );
        expect(falha.enviadas.any((e) => e.body.contains('XTB')), isFalse);

        // a XTB não ficou marcada como notificada: sai na execução seguinte
        final depois = _Envio();
        await notifyStartup(s, recurringCreated: 0, show: depois.call);
        expect(depois.enviadas.length, 1);
        expect(depois.enviadas.single.body, contains('XTB'));
      },
    );

    test(
      'movimentos recorrentes criados geram um aviso; sem criados não há aviso',
      () async {
        final s = AppState(Db.memory());
        final envio = _Envio();
        await notifyStartup(s, recurringCreated: 0, show: envio.call);
        expect(envio.enviadas, isEmpty);
        await notifyStartup(s, recurringCreated: 2, show: envio.call);
        expect(envio.enviadas.single.title, recurringTitle);
        expect(envio.enviadas.single.body, recurringBody(2));
      },
    );
  });
}
