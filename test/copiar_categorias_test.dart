import 'package:financas/db/database.dart';
import 'package:financas/l10n/app_localizations.dart';
import 'package:financas/models.dart';
import 'package:financas/screens/more_screen.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

AppState _arvore() {
  final s = AppState(Db.memory());
  int c(String n, [int? p]) =>
      s.addCategory(Categoria(id: 0, name: n, parentId: p));
  final c1 = c('cat1');
  c('cat1.1', c1);
  final c12 = c('cat1.2', c1);
  final c121 = c('cat1.2.1', c12);
  c('cat1.2.1.1', c121);
  c('cat2');
  return s;
}

void main() {
  test('texto em árvore: um "-" por nível', () {
    expect(
      _arvore().categoryTreeText(),
      'cat1\n-cat1.1\n-cat1.2\n--cat1.2.1\n---cat1.2.1.1\ncat2',
    );
    expect(AppState(Db.memory()).categoryTreeText(), '');
  });

  testWidgets('o botão copia a árvore para o clipboard', (tester) async {
    final s = _arvore();
    String? copiado;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiado = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: s,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('pt', 'PT'),
          home: const CategoriesScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Copiar categorias'));
    await tester.pump();
    expect(copiado, 'cat1\n-cat1.1\n-cat1.2\n--cat1.2.1\n---cat1.2.1.1\ncat2');
    expect(find.text('6 categorias copiadas'), findsOneWidget);
  });
}
