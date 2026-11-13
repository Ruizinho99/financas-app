import 'dart:io';
import 'dart:typed_data';

import 'package:financas/analysis/analytics.dart';
import 'package:financas/db/database.dart';
import 'package:financas/models.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late AppState s;
  late int jogo, ganhos;
  final period = Period.month(DateTime(2026, 10));

  setUp(() {
    s = AppState(Db.memory());
    jogo = s.addCategory(const Categoria(id: 0, name: 'Jogo'));
    ganhos = s.addCategory(
      const Categoria(id: 0, name: 'Ganhos', isIncome: true),
    );
  });

  int idOf(String d) => s.transactions.firstWhere((t) => t.description == d).id;
  Txn txn(String d) => s.transactions.firstWhere((t) => t.description == d);

  void betclic({int recebido = 1100}) {
    s.addManual(
      date: DateTime(2026, 10, 3),
      description: 'Betclic envio',
      amount: -1000,
      categoryId: jogo,
    );
    s.addManual(
      date: DateTime(2026, 10, 9),
      description: 'Levantamento XYZ',
      amount: recebido,
      categoryId: ganhos,
    );
  }

  test('sem ligação: 10 de despesa e 11 de receita (comportamento antigo)', () {
    betclic();
    final a = Analytics(s, period, const AnalysisFilter());
    expect(a.spent, 1000);
    expect(a.incomeReceived, 1100);
  });

  test('ligados: 10 -> 11 dá líquido +1, sem despesa nem receita de 10/11', () {
    betclic();
    expect(s.linkTxns(idOf('Betclic envio'), idOf('Levantamento XYZ')), isTrue);
    final a = Analytics(s, period, const AnalysisFilter());
    expect(a.spent, 0);
    expect(a.incomeReceived, 100); // só o líquido conta como receita
    expect(s.linkNet(txn('Betclic envio').linkGroup!), 100);
    expect(s.isSpend(txn('Betclic envio')), isFalse);
    expect(s.isSpend(txn('Levantamento XYZ')), isFalse);
    expect(s.isIncomeTxn(txn('Levantamento XYZ')), isFalse);
    // o saldo do banco não muda: -10 + 11
    expect(s.transactions.fold(0, (x, t) => x + t.amount), 100);
  });

  test('líquido negativo: despesa de 1 na categoria da saída', () {
    betclic(recebido: 900);
    s.linkTxns(idOf('Betclic envio'), idOf('Levantamento XYZ'));
    final a = Analytics(s, period, const AnalysisFilter());
    expect(a.spent, 100);
    expect(a.incomeReceived, 0);
    expect(s.totalsByCategory(period)[jogo], 100);
  });

  test('líquido zero: neutro', () {
    betclic(recebido: 1000);
    s.linkTxns(idOf('Betclic envio'), idOf('Levantamento XYZ'));
    final a = Analytics(s, period, const AnalysisFilter());
    expect(a.spent, 0);
    expect(a.incomeReceived, 0);
    expect(s.totalsByCategory(period), isEmpty);
  });

  test('líquido positivo: receita de 1 se o representante tem categoria', () {
    s.addManual(
      date: DateTime(2026, 10, 3),
      description: 'Envio',
      amount: -1000,
      categoryId: ganhos, // categoria partilhada: o sinal do líquido decide
    );
    s.addManual(
      date: DateTime(2026, 10, 9),
      description: 'Recebi',
      amount: 1100,
    );
    s.linkTxns(idOf('Envio'), idOf('Recebi'));
    final a = Analytics(s, period, const AnalysisFilter());
    expect(a.incomeReceived, 100);
    expect(a.spent, 0);
  });

  test('desligar repõe o comportamento antigo', () {
    betclic();
    s.linkTxns(idOf('Betclic envio'), idOf('Levantamento XYZ'));
    s.unlinkTxn(idOf('Levantamento XYZ'));
    expect(txn('Betclic envio').linkGroup, isNull); // o grupo ficou com um só
    expect(txn('Levantamento XYZ').linkGroup, isNull);
    final a = Analytics(s, period, const AnalysisFilter());
    expect(a.spent, 1000);
    expect(a.incomeReceived, 1100);
  });

  test('grupo de três; apagar um deixa o par; apagar outro desfaz o grupo', () {
    betclic();
    s.addManual(
      date: DateTime(2026, 10, 12),
      description: 'Outro envio',
      amount: -300,
      categoryId: jogo,
    );
    s.linkTxns(idOf('Betclic envio'), idOf('Levantamento XYZ'));
    s.linkTxns(idOf('Outro envio'), idOf('Levantamento XYZ'));
    final g = txn('Outro envio').linkGroup!;
    expect(s.linkGroups[g]!.length, 3);
    expect(s.linkNet(g), -1000 - 300 + 1100);
    expect(Analytics(s, period, const AnalysisFilter()).spent, 200);
    s.deleteTxns([idOf('Outro envio')]);
    expect(s.linkNet(txn('Betclic envio').linkGroup!), 100);
    s.deleteTxns([idOf('Levantamento XYZ')]);
    expect(txn('Betclic envio').linkGroup, isNull);
    expect(Analytics(s, period, const AnalysisFilter()).spent, 1000);
  });

  test('não liga transferências nem o mesmo movimento; ligar 2x não duplica', () {
    betclic();
    s.addTransfer(
      date: DateTime(2026, 10, 4),
      description: 'Entre contas',
      amount: 500,
    );
    final tr = s.transactions.firstWhere((t) => t.isTransfer).id;
    expect(s.linkTxns(idOf('Betclic envio'), tr), isFalse);
    expect(s.linkTxns(idOf('Betclic envio'), idOf('Betclic envio')), isFalse);
    expect(s.linkTxns(idOf('Betclic envio'), idOf('Levantamento XYZ')), isTrue);
    expect(
      s.linkTxns(idOf('Levantamento XYZ'), idOf('Betclic envio')),
      isFalse,
    );
    expect(s.linkGroups.length, 1);
  });

  test('editar um movimento ligado não perde a ligação', () {
    betclic();
    s.linkTxns(idOf('Betclic envio'), idOf('Levantamento XYZ'));
    final t = txn('Levantamento XYZ');
    s.updateTxn(
      Txn(
        id: t.id,
        date: t.date,
        description: t.description,
        amount: 1200,
        categoryId: t.categoryId,
        merchantKey: t.merchantKey,
      ),
    );
    expect(txn('Levantamento XYZ').linkGroup, isNotNull);
    expect(s.linkNet(txn('Levantamento XYZ').linkGroup!), 200);
  });

  // ---------- migração ----------
  test('migração v21 -> v22 acrescenta link_group sem perder dados', () async {
    betclic();
    final bytes = s.backupBytes();
    // simula uma base v21: sem a coluna
    final dir = Directory.systemTemp.createTempSync('lnk');
    late Uint8List antiga;
    try {
      final f = File('${dir.path}/c.db')..writeAsBytesSync(bytes);
      final raw = sqlite3.open(f.path);
      raw.execute('ALTER TABLE transactions DROP COLUMN link_group');
      raw.execute('PRAGMA user_version = 21');
      raw.close();
      antiga = f.readAsBytesSync();
    } finally {
      dir.deleteSync(recursive: true);
    }
    final db = Db.memory();
    await db.restoreBytes(antiga);
    final s2 = AppState(db);
    expect(s2.transactions.length, 2);
    expect(s2.transactions.every((t) => t.linkGroup == null), isTrue);
    expect(s2.transactions.map((t) => t.amount).toSet(), {-1000, 1100});
    expect(s2.linkTxns(s2.transactions[0].id, s2.transactions[1].id), isTrue);
    // a cópia gravada leva a versão atual (23)
    final dir2 = Directory.systemTemp.createTempSync('lnk');
    try {
      final f = File('${dir2.path}/d.db')..writeAsBytesSync(db.snapshotBytes());
      final raw = sqlite3.open(f.path);
      expect(raw.select('PRAGMA user_version').first.values.first, 25);
      raw.close();
    } finally {
      dir2.deleteSync(recursive: true);
    }
    db.close();
  });
}
