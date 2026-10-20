import 'package:financas/db/database.dart';
import 'package:financas/l10n/app_localizations.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('idioma por omissão é o do telemóvel e fica guardado', () {
    final db = Db.memory();
    final s = AppState(db);
    expect(s.appLanguage, 'system');
    s.setAppLanguage('en');
    expect(s.appLanguage, 'en');
    // uma nova instância lê a mesma definição
    expect(AppState(db).appLanguage, 'en');
  });

  test('as traduções carregam em inglês e em português', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final pt = await AppLocalizations.delegate.load(const Locale('pt', 'PT'));
    expect(en.onboardingStart, 'Get started');
    expect(pt.onboardingStart, 'Começar');
    expect(en.appearanceTitle, 'Appearance');
    expect(pt.appearanceTitle, 'Aparência');
  });
}
