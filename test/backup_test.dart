import 'dart:typed_data';

import 'package:financas/db/database.dart';
import 'package:financas/screens/backup_screen.dart';
import 'package:financas/state/app_state.dart';
import 'package:financas/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  test('cópia e restauro: os dados voltam tal como estavam', () async {
    final s = AppState(Db.memory());
    s.addManual(
      date: DateTime(2026, 1, 5),
      description: 'COMPRA TESTE',
      amount: -1234,
    );
    final bytes = s.backupBytes();
    s.addManual(date: DateTime(2026, 1, 6), description: 'DEPOIS', amount: -99);
    expect(s.transactions.length, 2);
    await s.restoreBackup(bytes);
    expect(s.transactions.map((t) => t.description), ['COMPRA TESTE']);
  });

  test('um ficheiro que não é uma cópia não estraga os dados', () async {
    final s = AppState(Db.memory());
    s.addManual(date: DateTime(2026, 1, 5), description: 'FICA', amount: -100);
    await expectLater(
      s.restoreBackup(Uint8List.fromList('não é uma base'.codeUnits)),
      throwsA(isA<FormatException>()),
    );
    expect(s.transactions.single.description, 'FICA');
  });

  testWidgets('ecrã de cópia mostra guardar e restaurar', (tester) async {
    tester.view.physicalSize = const Size(360, 900) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: AppState(Db.memory()),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('pt', 'PT'),
          home: const BackupScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Guardar cópia'), findsOneWidget);
    expect(find.text('Restaurar de um ficheiro'), findsOneWidget);
    expect(find.textContaining('Google Drive'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
