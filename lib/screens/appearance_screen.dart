import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../invest/invest.dart' show kCurrencies;
import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import '../widgets/common.dart';

const _accentColors = <int>[
  0xFF2E7D6B,
  0xFF1E88E5,
  0xFF3949AB,
  0xFF8E24AA,
  0xFFD81B60,
  0xFFE53935,
  0xFFF4511E,
  0xFFFB8C00,
  0xFF7CB342,
  0xFF00897B,
  0xFF546E7A,
  0xFF6D4C41,
];

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.appearanceTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.languageTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'system', label: Text(l.languageSystem)),
              ButtonSegment(value: 'pt', label: Text(l.languagePortuguese)),
              ButtonSegment(value: 'en', label: Text(l.languageEnglish)),
            ],
            selected: {s.appLanguage},
            onSelectionChanged: (v) => s.setAppLanguage(v.first),
          ),
          const SizedBox(height: 24),
          Text(l.morThemeTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(l.morThemeSystem),
                icon: Icon(Icons.brightness_auto),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(l.morThemeLight),
                icon: Icon(Icons.light_mode),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(l.morThemeDark),
                icon: Icon(Icons.dark_mode),
              ),
            ],
            selected: {s.themeMode},
            onSelectionChanged: (v) => s.setAppearance(mode: v.first),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.morAmoledTitle),
            subtitle: Text(l.morAmoledSubtitle),
            value: s.amoled,
            onChanged: (v) => s.setAppearance(amoledBlack: v),
          ),
          const Divider(height: 32),
          Text(
            l.morBaseCurrencyTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(l.morBaseCurrencyHint),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: kCurrencies.contains(s.baseCurrency)
                ? s.baseCurrency
                : null,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.payments_outlined),
            ),
            items: [
              for (final c in kCurrencies)
                DropdownMenuItem(value: c, child: Text('$c · ${ccySymbol(c)}')),
            ],
            onChanged: (c) {
              if (c == null) return;
              s.setBaseCurrency(c);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.morBaseCurrencyChanged(c))),
              );
            },
          ),
          const Divider(height: 32),
          Text(l.morMainColor, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(l.morMainColorHint),
          const SizedBox(height: 12),
          ColorChoice(
            color: s.seedColor,
            colors: _accentColors,
            onChanged: (c) => s.setAppearance(seed: c),
          ),
          const Divider(height: 32),
          Text(
            l.morIncomeColor,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ColorChoice(
            color: s.incomeColor,
            colors: const [
              0xFF43A047,
              0xFF00897B,
              0xFF1E88E5,
              0xFF7CB342,
              0xFF00ACC1,
            ],
            onChanged: (c) => s.setAppearance(income: c),
          ),
          const SizedBox(height: 20),
          Text(
            l.morExpenseColor,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ColorChoice(
            color: s.expenseColor,
            colors: const [
              0xFFE53935,
              0xFFF4511E,
              0xFFD81B60,
              0xFF8E24AA,
              0xFFFB8C00,
            ],
            onChanged: (c) => s.setAppearance(expense: c),
          ),
          const Divider(height: 32),
          Text(l.morPreview, style: Theme.of(context).textTheme.titleMedium),
          Card(
            child: ListTile(
              leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
              title: Text(l.morSamplePlace),
              subtitle: Text(l.morSampleCategory),
              trailing: const MoneyText(-4530),
            ),
          ),
          Card(
            child: ListTile(
              title: Text(l.morSampleSalary),
              trailing: const MoneyText(150000),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: s.resetAppearance,
            icon: const Icon(Icons.restart_alt),
            label: Text(l.morResetAppearance),
          ),
          const SizedBox(height: 4),
          Text(l.morEmojiHint, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
