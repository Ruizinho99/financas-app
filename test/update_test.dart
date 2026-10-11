import 'dart:convert';
import 'dart:io';

import 'package:financas/screens/update_screen.dart';
import 'package:financas/update/update_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'support/fonts.dart';

String _release(
  String tag, {
  String body = 'Notes here',
  List<Map<String, Object>>? assets,
}) => jsonEncode({
  'tag_name': tag,
  'name': 'Release $tag',
  'body': body,
  'html_url': 'https://github.com/Ruizinho99/financas-app/releases/tag/$tag',
  'assets':
      assets ??
      [
        {
          'name': 'financas-$tag-debug.apk',
          'browser_download_url': 'https://dl/debug.apk',
          'size': 100,
        },
        {
          'name': 'financas-$tag-release.apk',
          'browser_download_url': 'https://dl/release.apk',
          'size': 6,
        },
      ],
});

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_PT');
    await loadRoboto();
  });

  test('comparação de versões', () {
    expect(UpdateService.isNewer('v1.9.0', '1.8.0'), isTrue);
    expect(UpdateService.isNewer('1.8.0', '1.8.0'), isFalse);
    expect(UpdateService.isNewer('v1.8.0', '1.9.0+9'), isFalse);
    expect(UpdateService.isNewer('v1.10.0', '1.9.5'), isTrue);
    expect(UpdateService.isNewer('v2.0', '1.99.99'), isTrue);
    expect(UpdateService.isNewer('v1.8.1', '1.8.0+3'), isTrue);
  });

  group('GitHub', () {
    test(
      'lê a última versão e escolhe o APK de release (não o de debug)',
      () async {
        final c = MockClient((r) async {
          expect(
            r.url.toString(),
            'https://api.github.com/repos/Ruizinho99/financas-app/releases/latest',
          );
          return http.Response(_release('v1.9.0'), 200);
        });
        final r = await UpdateService(client: c).latest();
        expect(
          (r.tag, r.version, r.apkName, r.apkUrl, r.apkSize),
          (
            'v1.9.0',
            '1.9.0',
            'financas-v1.9.0-release.apk',
            'https://dl/release.apk',
            6,
          ),
        );
      },
    );

    test('erros viram mensagens em português', () async {
      Future<String> err(MockClient c) async {
        try {
          await UpdateService(client: c).latest();
        } on UpdateException catch (e) {
          return e.message;
        }
        return '';
      }

      expect(
        await err(MockClient((_) async => http.Response('', 404))),
        contains('nenhuma versão'),
      );
      expect(
        await err(MockClient((_) async => http.Response('', 403))),
        contains('Limite'),
      );
      expect(
        await err(MockClient((_) async => throw Exception('x'))),
        contains('internet'),
      );
      expect(
        await err(MockClient((_) async => http.Response('não é json', 200))),
        contains('inesperada'),
      );
    });

    test(
      'descarrega o APK com progresso e rejeita transferências incompletas',
      () async {
        final dir = Directory.systemTemp.createTempSync('upd');
        addTearDown(() => dir.deleteSync(recursive: true));
        final ok = MockClient.streaming(
          (req, _) async => http.StreamedResponse(
            Stream.fromIterable([
              [1, 2, 3],
              [4, 5, 6],
            ]),
            200,
            contentLength: 6,
          ),
        );
        final svc = UpdateService(client: ok, tempDir: dir);
        final info = ReleaseInfo(
          tag: 'v1.9.0',
          name: 'x',
          notes: '',
          pageUrl: 'p',
          apkName: 'a.apk',
          apkUrl: 'https://dl/release.apk',
          apkSize: 6,
        );
        final seen = <double>[];
        final f = await svc.download(info, onProgress: seen.add);
        expect(f.readAsBytesSync(), [1, 2, 3, 4, 5, 6]);
        expect(seen.last, 1.0);

        final short = MockClient.streaming(
          (req, _) async => http.StreamedResponse(
            Stream.fromIterable([
              [1, 2],
            ]),
            200,
            contentLength: 6,
          ),
        );
        await expectLater(
          UpdateService(client: short, tempDir: dir).download(info),
          throwsA(isA<UpdateException>()),
        );
      },
    );
  });

  group('ecrã', () {
    Future<void> pump(WidgetTester tester, String tag, String current) async {
      tester.view.physicalSize = const Size(360, 1400) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final svc = UpdateService(
        client: MockClient(
          (_) async => http.Response(
            _release(tag, body: '## Highlights\n- **New** thing'),
            200,
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: UpdateScreen(service: svc, currentVersion: current),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Procurar atualizações'));
      await tester.pumpAndSettle();
    }

    testWidgets('há versão nova: mostra as notas e o botão de instalar', (
      tester,
    ) async {
      await pump(tester, 'v1.9.0', '1.8.0');
      expect(find.text('Há uma versão nova: 1.9.0'), findsOneWidget);
      expect(find.textContaining('Descarregar e instalar'), findsOneWidget);
      await tester.tap(find.text('O que mudou'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Highlights'), findsOneWidget);
      expect(find.textContaining('##'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('já na última versão: avisa e não oferece instalar', (
      tester,
    ) async {
      await pump(tester, 'v1.9.0', '1.9.0');
      expect(find.text('Já tens a versão mais recente'), findsOneWidget);
      expect(find.textContaining('Descarregar e instalar'), findsNothing);
    });
  });
}
