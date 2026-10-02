import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import '../widgets/common.dart';
import 'transactions_screen.dart' show confirm;

/// Cria ou edita uma conta. Devolve o id.
Future<int?> showAccountEditor(BuildContext context, {Conta? edit}) {
  final s = context.read<AppState>();
  final name = TextEditingController(text: edit?.name ?? '');
  var emoji = edit?.emoji ?? '';
  return showDialog<int>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        title: Text(edit == null ? 'Nova conta' : 'Editar conta'),
        content: Row(children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final e = await pickEmoji(ctx, emoji);
              if (e != null) set(() => emoji = e);
            },
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(border: Border.all(color: Theme.of(ctx).colorScheme.outlineVariant), borderRadius: BorderRadius.circular(14)),
              child: Text(emoji.isEmpty ? '🏦' : emoji, style: TextStyle(fontSize: 28, color: emoji.isEmpty ? Colors.grey : null)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: name, autofocus: true, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Nome', hintText: 'Ex.: Conta à ordem'))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final n = name.text.trim();
              if (n.isEmpty) return;
              if (edit == null) {
                Navigator.pop(ctx, s.addAccount(n, emoji: emoji));
              } else {
                s.updateAccount(Conta(id: edit.id, name: n, emoji: emoji));
                Navigator.pop(ctx, edit.id);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );
}

/// Escolher uma conta (folha inferior). Devolve o id, -1 para "sem conta" ou null se cancelado.
Future<int?> pickAccount(BuildContext context, {int? selected, int? exclude, String title = 'Conta'}) {
  return showModalBottomSheet<int>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (ctx) {
      final s = ctx.watch<AppState>();
      return SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 8), child: Align(alignment: Alignment.centerLeft, child: Text(title, style: Theme.of(ctx).textTheme.titleLarge))),
          for (final a in s.accounts.where((a) => a.id != exclude))
            ListTile(
              leading: Text(a.emoji.isEmpty ? '🏦' : a.emoji, style: const TextStyle(fontSize: 24)),
              title: Text(a.name),
              selected: a.id == selected,
              trailing: a.id == selected ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(ctx, a.id),
            ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Nova conta…'),
            onTap: () async {
              final id = await showAccountEditor(ctx);
              if (id != null && ctx.mounted) Navigator.pop(ctx, id);
            },
          ),
          if (selected != null)
            ListTile(leading: const Icon(Icons.close), title: const Text('Sem conta'), onTap: () => Navigator.pop(ctx, -1)),
          const SizedBox(height: 8),
        ]),
      );
    },
  );
}

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Contas')),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => showAccountEditor(context), icon: const Icon(Icons.add), label: const Text('Conta')),
      body: s.accounts.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Ainda não tens contas.\nCria uma para saberes de onde vem cada movimento e para registar transferências entre contas.', textAlign: TextAlign.center),
              ),
            )
          : ListView(padding: const EdgeInsets.only(bottom: 90), children: [
              for (final a in s.accounts)
                Builder(builder: (_) {
                  final txns = s.transactions.where((t) => t.accountId == a.id).toList();
                  final balance = txns.fold(0, (sum, t) => sum + t.amount);
                  return ListTile(
                    leading: Text(a.emoji.isEmpty ? '🏦' : a.emoji, style: const TextStyle(fontSize: 26)),
                    title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${txns.length} movimentos · saldo dos movimentos ${fmtMoney(balance)}'),
                    onTap: () => showAccountEditor(context, edit: a),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        if (await confirm(context, 'Apagar a conta “${a.name}”? Os ${txns.length} movimentos ficam sem conta.')) s.deleteAccount(a.id);
                      },
                    ),
                  );
                }),
            ]),
    );
  }
}
