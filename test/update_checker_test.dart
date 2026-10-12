import 'package:financas/db/database.dart';
import 'package:financas/update/update_checker.dart';
import 'package:financas/update/update_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _redirect(String tag) => http.Response(
  '',
  302,
  headers: {
    'location': 'https://github.com/Ruizinho99/financas-app/releases/tag/$tag',
  },
);

void main() {
  late Db db;
  late int calls;
  late String latestTag;
  late bool offline;
  late DateTime clock;
  late List<String> notified;

  UpdateChecker make({String current = '1.9.0'}) => UpdateChecker(
    db: db,
    currentVersion: current,
    service: UpdateService(
      client: MockClient((_) async {
        calls++;
        if (offline) throw Exception('sem rede');
        return _redirect(latestTag);
      }),
    ),
    notify: (tag) async => notified.add(tag),
    now: () => clock,
  );

  setUp(() {
    db = Db.memory();
    calls = 0;
    latestTag = 'v1.9.1';
    offline = false;
    clock = DateTime(2026, 10, 13, 9);
    notified = [];
  });

  test('versão nova: avisa uma vez', () async {
    final c = make();
    final r = await c.check();
    expect(r, 'v1.9.1');
    expect(notified, ['v1.9.1']);
  });

  test('a mesma versão nova não volta a avisar', () async {
    final c = make();
    await c.check();
    await c.check(force: true);
    expect(notified, ['v1.9.1']);
  });

  test('sem versão nova, não avisa', () async {
    latestTag = 'v1.9.0';
    expect(await make().check(), isNull);
    expect(notified, isEmpty);
  });

  test('só pergunta ao GitHub uma vez por dia', () async {
    final c = make();
    await c.check();
    clock = clock.add(const Duration(hours: 5));
    await c.check();
    expect(calls, 1);
    clock = clock.add(const Duration(hours: 20));
    await c.check();
    expect(calls, 2);
  });

  test(
    'sem internet não gasta a verificação do dia: tenta na próxima abertura',
    () async {
      offline = true;
      expect(await make().check(), isNull);
      offline = false;
      final r = await make().check();
      expect(r, 'v1.9.1');
      expect(notified, ['v1.9.1']);
    },
  );
}
