import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/common.dart';

const _accentColors = <int>[
  0xFF2E7D6B, 0xFF1E88E5, 0xFF3949AB, 0xFF8E24AA, 0xFFD81B60, 0xFFE53935,
  0xFFF4511E, 0xFFFB8C00, 0xFF7CB342, 0xFF00897B, 0xFF546E7A, 0xFF6D4C41,
];

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Aparência')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Tema', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(value: ThemeMode.system, label: Text('Sistema'), icon: Icon(Icons.brightness_auto)),
            ButtonSegment(value: ThemeMode.light, label: Text('Claro'), icon: Icon(Icons.light_mode)),
            ButtonSegment(value: ThemeMode.dark, label: Text('Escuro'), icon: Icon(Icons.dark_mode)),
          ],
          selected: {s.themeMode},
          onSelectionChanged: (v) => s.setAppearance(mode: v.first),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Preto total (AMOLED)'),
          subtitle: const Text('No modo escuro, fundo totalmente preto'),
          value: s.amoled,
          onChanged: (v) => s.setAppearance(amoledBlack: v),
        ),
        const Divider(height: 32),
        Text('Cor principal', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        const Text('Define a cor da barra de navegação, botões e gráficos.'),
        const SizedBox(height: 12),
        ColorChoice(color: s.seedColor, colors: _accentColors, onChanged: (c) => s.setAppearance(seed: c)),
        const Divider(height: 32),
        Text('Cor das receitas', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ColorChoice(color: s.incomeColor, colors: const [0xFF43A047, 0xFF00897B, 0xFF1E88E5, 0xFF7CB342, 0xFF00ACC1], onChanged: (c) => s.setAppearance(income: c)),
        const SizedBox(height: 20),
        Text('Cor das despesas', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ColorChoice(color: s.expenseColor, colors: const [0xFFE53935, 0xFFF4511E, 0xFFD81B60, 0xFF8E24AA, 0xFFFB8C00], onChanged: (c) => s.setAppearance(expense: c)),
        const Divider(height: 32),
        Text('Pré-visualização', style: Theme.of(context).textTheme.titleMedium),
        Card(
          child: ListTile(
            leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
            title: const Text('Supermercado'),
            subtitle: const Text('Categoria › Subcategoria'),
            trailing: const MoneyText(-4530),
          ),
        ),
        Card(child: ListTile(title: const Text('Salário'), trailing: const MoneyText(150000))),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: s.resetAppearance, icon: const Icon(Icons.restart_alt), label: const Text('Repor aparência original')),
        const SizedBox(height: 4),
        Text('Cada categoria e subcategoria tem um emoji próprio, que escolhes ao criar ou editar.', style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}
