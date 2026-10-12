import 'dart:convert';
import 'dart:typed_data';

import 'package:financas/cloud/cloud_provider.dart';
import 'package:financas/cloud/microsoft_auth.dart';
import 'package:financas/cloud/onedrive_provider.dart';
import 'package:financas/db/database.dart';
import 'package:financas/screens/cloud_screen.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Autenticação sem login real: devolve sempre um token de teste.
class _FakeAuth extends MicrosoftAuth {
  _FakeAuth(Db db) : super(db: db, clientId: () => 'abc-123');
  @override
  Future<String> accessToken() async => 'tok';
}

/// Nuvem em memória, para testar a cópia e o restauro da app.
class FakeCloud implements CloudProvider {
  Uint8List? stored;
  DateTime? at;
  String? _acc;
  @override
  String get label => 'OneDrive de teste';
  @override
  String? get account => _acc;
  @override
  Future<String> signIn() async => _acc = 'pessoa@exemplo.pt';
  @override
  Future<void> signOut() async => _acc = null;
  @override
  Future<CloudBackupInfo> upload(Uint8List data) async {
    stored = data;
    at = DateTime(2026, 10, 12);
    return CloudBackupInfo(
      id: '1',
      name: 'b',
      modified: at!,
      size: data.length,
    );
  }

  @override
  Future<CloudBackupInfo?> latest() async => stored == null
      ? null
      : CloudBackupInfo(
          id: '1',
          name: 'b',
          modified: at!,
          size: stored!.length,
        );
  @override
  Future<Uint8List> download(CloudBackupInfo info) async => stored!;
  @override
  Future<void> delete(CloudBackupInfo info) async => stored = null;
}

Map<String, Object?> _item(String id) => {
  'id': id,
  'name': 'financas-backup.db',
  'lastModifiedDateTime': '2026-10-12T10:00:00Z',
  'size': 3,
};

void main() {
  group('OneDrive (Graph, pasta privada da app)', () {
    test('sem cópia, latest devolve nulo', () async {
      final p = OneDriveProvider(
        auth: _FakeAuth(Db.memory()),
        client: MockClient((_) async => http.Response('', 404)),
      );
      expect(await p.latest(), isNull);
    });

    test('lê a cópia mais recente da pasta approot', () async {
      final c = MockClient((r) async {
        expect(
          r.url.toString(),
          'https://graph.microsoft.com/v1.0/me/drive/special/approot:/financas-backup.db',
        );
        expect(r.headers['Authorization'], 'Bearer tok');
        return http.Response(jsonEncode(_item('f1')), 200);
      });
      final i = await OneDriveProvider(
        auth: _FakeAuth(Db.memory()),
        client: c,
      ).latest();
      expect((i!.id, i.size, i.modified.toUtc().hour), ('f1', 3, 10));
    });

    test(
      'ficheiro pequeno: um só PUT no conteúdo, a substituir o anterior',
      () async {
        var puts = 0;
        final c = MockClient((r) async {
          expect(r.method, 'PUT');
          expect(
            r.url.path,
            '/v1.0/me/drive/special/approot:/financas-backup.db:/content',
          );
          puts++;
          return http.Response(jsonEncode(_item('f1')), 200);
        });
        final p = OneDriveProvider(auth: _FakeAuth(Db.memory()), client: c);
        final i = await p.upload(Uint8List.fromList([1, 2, 3]));
        expect((puts, i.id), (1, 'f1'));
      },
    );

    test(
      'ficheiro grande: sessão de carregamento e partes com Content-Range',
      () async {
        final sent = <String>[];
        final bodies = <List<int>>[];
        final c = MockClient((r) async {
          if (r.url.path.endsWith(':/createUploadSession')) {
            expect(r.body, contains('"replace"'));
            return http.Response(
              jsonEncode({'uploadUrl': 'https://upload.example/session'}),
              200,
            );
          }
          expect(r.url.host, 'upload.example');
          sent.add(r.headers['Content-Range']!);
          bodies.add(r.bodyBytes);
          return sent.length == 3
              ? http.Response(jsonEncode(_item('big')), 201)
              : http.Response('', 202);
        });
        final p = OneDriveProvider(
          auth: _FakeAuth(Db.memory()),
          client: c,
          simpleLimit: 4,
          chunkSize: 4,
        );
        final data = Uint8List.fromList(List.generate(10, (i) => i));
        final i = await p.upload(data);
        expect(sent, ['bytes 0-3/10', 'bytes 4-7/10', 'bytes 8-9/10']);
        expect(bodies.expand((b) => b).toList(), data);
        expect(i.id, 'big');
      },
    );

    test('download devolve os bytes da cópia', () async {
      final c = MockClient((r) async {
        expect(r.url.path.endsWith(':/content'), isTrue);
        return http.Response.bytes([9, 8, 7], 200);
      });
      final p = OneDriveProvider(auth: _FakeAuth(Db.memory()), client: c);
      expect(
        await p.download(
          CloudBackupInfo(
            id: 'f1',
            name: 'x',
            modified: DateTime(2026),
            size: 3,
          ),
        ),
        [9, 8, 7],
      );
    });

    test('erros do Graph viram mensagens em português', () async {
      Future<String> err(int code) async {
        final p = OneDriveProvider(
          auth: _FakeAuth(Db.memory()),
          client: MockClient((_) async => http.Response('', code)),
        );
        try {
          await p.latest();
        } on CloudException catch (e) {
          return e.message;
        }
        return '';
      }

      expect(await err(403), contains('recusou'));
      expect(await err(429), contains('ocupado'));
      expect(await err(500), contains('Erro do OneDrive (500)'));
      final off = OneDriveProvider(
        auth: _FakeAuth(Db.memory()),
        client: MockClient((_) async => throw Exception('x')),
      );
      await expectLater(
        off.latest(),
        throwsA(
          isA<CloudException>().having(
            (e) => e.message,
            'm',
            contains('internet'),
          ),
        ),
      );
    });

    test(
      'sem ID da aplicação, o login diz o que falta antes de abrir o browser',
      () async {
        final db = Db.memory();
        final auth = MicrosoftAuth(db: db, clientId: () => '  ');
        await expectLater(
          auth.signIn(),
          throwsA(
            isA<CloudException>().having(
              (e) => e.message,
              'm',
              contains('ID da aplicação'),
            ),
          ),
        );
        await expectLater(
          auth.accessToken(),
          throwsA(
            isA<CloudException>().having(
              (e) => e.message,
              'm',
              contains('Liga primeiro'),
            ),
          ),
        );
      },
    );
  });

  group('cópia e restauro', () {
    test('guardar no OneDrive e restaurar traz os dados de volta', () async {
      final cloud = FakeCloud();
      final s = AppState(Db.memory(), cloud: cloud);
      s.addManual(
        date: DateTime(2026, 1, 5),
        description: 'COMPRA TESTE',
        amount: -1234,
      );
      final acc = s.addInvestAccount('XTB');
      await cloud.signIn();
      await s.backupToCloud(cloud);
      expect(s.lastCloudBackup, isNotNull);
      s.addManual(
        date: DateTime(2026, 1, 6),
        description: 'DEPOIS DA COPIA',
        amount: -99,
      );
      s.deleteInvestAccount(acc);
      expect(s.transactions.length, 2);
      await s.restoreFromCloud(cloud);
      expect(s.transactions.map((t) => t.description), ['COMPRA TESTE']);
      expect(s.investAccounts.map((a) => a.name), ['XTB']);
    });

    test('ficheiro inválido não estraga os dados', () async {
      final cloud = FakeCloud()
        ..stored = Uint8List.fromList(
          utf8.encode('isto não é uma base de dados'),
        )
        ..at = DateTime(2026, 1, 1);
      final s = AppState(Db.memory(), cloud: cloud);
      s.addManual(
        date: DateTime(2026, 1, 5),
        description: 'FICA',
        amount: -100,
      );
      await expectLater(
        s.restoreFromCloud(cloud),
        throwsA(isA<CloudException>()),
      );
      expect(s.transactions.single.description, 'FICA');
    });

    test('sem cópia, o restauro explica porquê', () async {
      final s = AppState(Db.memory(), cloud: FakeCloud());
      await expectLater(
        s.restoreFromCloud(s.cloud),
        throwsA(
          isA<CloudException>().having(
            (e) => e.message,
            'm',
            contains('nenhuma cópia'),
          ),
        ),
      );
    });

    test(
      'o ID da aplicação e a sessão deste telemóvel sobrevivem ao restauro',
      () async {
        final cloud = FakeCloud();
        final s = AppState(Db.memory(), cloud: cloud);
        await cloud.signIn();
        await s.backupToCloud(cloud); // cópia sem ID
        s.setOneDriveClientId('abc-123');
        s.db.putSetting('onedrive_refresh', 'token-deste-telemovel');
        await s.restoreFromCloud(cloud);
        expect(s.oneDriveClientId, 'abc-123');
        expect(s.db.setting('onedrive_refresh'), 'token-deste-telemovel');
      },
    );
  });

  testWidgets(
    'ecrã do OneDrive: sem ligação pede o ID e mostra o passo a passo',
    (tester) async {
      tester.view.physicalSize = const Size(360, 1400) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final s = AppState(Db.memory(), cloud: FakeCloud());
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: s,
          child: MaterialApp(home: const CloudScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ligar conta Microsoft'), findsOneWidget);
      expect(find.text('Configuração (uma vez)'), findsOneWidget);
      expect(find.text('ID da aplicação (cliente)'), findsOneWidget);
      await tester.tap(find.text('Como criar o registo no Azure'));
      await tester.pumpAndSettle();
      expect(find.text('pt.financas.financas:/oauth'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
