import 'dart:convert';
import 'dart:typed_data';

import 'package:financas/cloud/apple_provider.dart';
import 'package:financas/cloud/cloud_provider.dart';
import 'package:financas/cloud/drive_appdata.dart';
import 'package:financas/db/database.dart';
import 'package:financas/screens/cloud_screen.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'support/fonts.dart';

/// Nuvem em memória, para testar a lógica sem rede.
class FakeCloud implements CloudProvider {
  Uint8List? stored;
  DateTime? at;
  String? _acc;
  @override
  String get id => 'fake';
  @override
  String get label => 'Nuvem de teste';
  @override
  String get accountHint => 'conta de teste';
  @override
  bool get available => true;
  @override
  String get unavailableReason => '';
  @override
  String? get account => _acc;
  @override
  Future<String> signIn() async => _acc = 'pessoa@exemplo.pt';
  @override
  Future<void> signOut() async => _acc = null;
  @override
  Future<String?> restoreSession() async => _acc;
  @override
  Future<CloudBackupInfo> upload(Uint8List data) async {
    stored = data;
    at = DateTime(2026, 10, 9);
    return CloudBackupInfo(id: '1', name: 'b', modified: at!, size: data.length);
  }

  @override
  Future<CloudBackupInfo?> latest() async => stored == null ? null : CloudBackupInfo(id: '1', name: 'b', modified: at!, size: stored!.length);
  @override
  Future<Uint8List> download(CloudBackupInfo info) async => stored!;
  @override
  Future<void> delete(CloudBackupInfo info) async => stored = null;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_PT');
    await loadRoboto();
  });

  group('Google Drive (pasta privada da app)', () {
    test('primeira cópia: cria o ficheiro na appDataFolder; seguintes: atualizam', () async {
      final calls = <String>[];
      String? created;
      var exists = false;
      final client = MockClient((r) async {
        calls.add('${r.method} ${r.url.path}');
        expect(r.headers['Authorization'], 'Bearer tok');
        if (r.method == 'GET' && r.url.path == '/drive/v3/files') {
          expect(r.url.queryParameters['spaces'], 'appDataFolder');
          return http.Response(jsonEncode({'files': exists ? [{'id': 'f1', 'name': DriveAppData.fileName, 'modifiedTime': '2026-10-09T10:00:00Z', 'size': '3'}] : []}), 200);
        }
        if (r.method == 'POST') {
          created = r.body;
          exists = true;
          expect(r.headers['Content-Type'], startsWith('multipart/related'));
          return http.Response(jsonEncode({'id': 'f1', 'name': DriveAppData.fileName, 'modifiedTime': '2026-10-09T10:00:00Z', 'size': '3'}), 200);
        }
        if (r.method == 'PATCH') {
          expect(r.url.path, '/upload/drive/v3/files/f1');
          return http.Response(jsonEncode({'id': 'f1', 'name': DriveAppData.fileName, 'modifiedTime': '2026-10-09T11:00:00Z', 'size': '3'}), 200);
        }
        if (r.method == 'GET' && r.url.queryParameters['alt'] == 'media') return http.Response.bytes([1, 2, 3], 200);
        return http.Response('', 404);
      });
      final d = DriveAppData(token: () async => 'tok', client: client);
      expect(await d.latest(), isNull);
      final a = await d.upload(Uint8List.fromList([1, 2, 3]));
      expect(a.id, 'f1');
      expect(created, contains('"parents":["appDataFolder"]'));
      final b = await d.upload(Uint8List.fromList([1, 2, 3]));
      expect(b.modified.toUtc().hour, 11);
      expect(calls.where((c) => c.startsWith('PATCH')).length, 1);
      expect(await d.download(a), [1, 2, 3]);
    });

    test('erros da Google viram mensagens em português', () async {
      final d = DriveAppData(token: () async => 't', client: MockClient((_) async => http.Response('', 403)));
      expect(() => d.latest(), throwsA(isA<CloudException>().having((e) => e.message, 'm', contains('recusou'))));
      final off = DriveAppData(token: () async => 't', client: MockClient((_) async => throw Exception('x')));
      expect(() => off.latest(), throwsA(isA<CloudException>().having((e) => e.message, 'm', contains('internet'))));
    });
  });

  group('cópia e restauro', () {
    test('guardar na nuvem e restaurar traz os dados de volta (e apaga o que veio depois)', () async {
      final cloud = FakeCloud();
      final s = AppState(Db.memory(), cloud: [cloud]);
      s.addManual(date: DateTime(2026, 1, 5), description: 'COMPRA TESTE', amount: -1234);
      final acc = s.addInvestAccount('XTB');
      await cloud.signIn();
      await s.backupToCloud(cloud);
      expect(s.lastCloudBackup, isNotNull);
      s.addManual(date: DateTime(2026, 1, 6), description: 'DEPOIS DA COPIA', amount: -99);
      s.deleteInvestAccount(acc);
      expect(s.transactions.length, 2);
      await s.restoreFromCloud(cloud);
      expect(s.transactions.map((t) => t.description), ['COMPRA TESTE']);
      expect(s.investAccounts.map((a) => a.name), ['XTB']);
    });

    test('ficheiro inválido não estraga os dados', () async {
      final cloud = FakeCloud()..stored = Uint8List.fromList(utf8.encode('isto não é uma base de dados'))..at = DateTime(2026, 1, 1);
      final s = AppState(Db.memory(), cloud: [cloud]);
      s.addManual(date: DateTime(2026, 1, 5), description: 'FICA', amount: -100);
      await expectLater(s.restoreFromCloud(cloud), throwsA(isA<CloudException>()));
      expect(s.transactions.single.description, 'FICA');
    });

    test('sem cópia na nuvem, o restauro explica porquê', () async {
      final s = AppState(Db.memory(), cloud: [FakeCloud()]);
      await expectLater(s.restoreFromCloud(s.cloud.first), throwsA(isA<CloudException>().having((e) => e.message, 'm', contains('nenhuma cópia'))));
    });

    test('o ID de cliente Google sobrevive ao restauro', () async {
      final cloud = FakeCloud();
      final s = AppState(Db.memory(), cloud: [cloud]);
      await cloud.signIn();
      await s.backupToCloud(cloud); // cópia sem ID
      s.setGoogleClientId('abc.apps.googleusercontent.com');
      await s.restoreFromCloud(cloud);
      expect(s.googleClientId, 'abc.apps.googleusercontent.com');
    });
  });

  group('ecrã', () {
    testWidgets('mostra Google e Apple (em preparação), liga a conta, guarda e restaura', (tester) async {
      final cloud = FakeCloud();
      final s = AppState(Db.memory(), cloud: [cloud, AppleProvider()]);
      s.addManual(date: DateTime(2026, 1, 5), description: 'COMPRA TESTE', amount: -1234);
      tester.view.physicalSize = const Size(360, 2400) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(value: s, child: MaterialApp(theme: ThemeData(useMaterial3: true), home: const CloudScreen())));
      await tester.pumpAndSettle();
      expect(find.text('iCloud (Apple)'), findsOneWidget);
      expect(find.textContaining('Em preparação'), findsOneWidget);
      await tester.tap(find.text('Ligar conta de teste'));
      await tester.pumpAndSettle();
      expect(find.text('pessoa@exemplo.pt'), findsOneWidget);
      await tester.tap(find.text('Guardar cópia agora'));
      await tester.pumpAndSettle(); // sem cópia anterior: não pede confirmação
      expect(cloud.stored, isNotNull);
      expect(find.textContaining('Cópia na nuvem'), findsOneWidget);
      // o restauro em si (assíncrono a sério) é testado acima, sem o ecrã
      expect(tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Restaurar')).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    });
  });
}
