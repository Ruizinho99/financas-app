import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../util/format.dart';
import '../widgets/common.dart';
import 'import_screen.dart';

enum _Filter { all, uncategorized, income, expense, transfers }

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String q = '';
  _Filter filter = _Filter.all;
  DateTime? month; // null = todos
  int? accountFilter; // null = todas as contas
  final selected = <int>{};
  bool searching = false;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final ql = q.toLowerCase();
    final list = s.transactions.where((t) {
      if (month != null && (t.date.year != month!.year || t.date.month != month!.month)) return false;
      if (accountFilter != null && t.accountId != accountFilter) return false;
      switch (filter) {
        case _Filter.uncategorized:
          if (t.categoryId != null || t.isTransfer) return false;
        case _Filter.income:
          if (t.amount <= 0 || t.isTransfer) return false;
        case _Filter.expense:
          if (t.amount >= 0 || t.isTransfer) return false;
        case _Filter.transfers:
          if (!t.isTransfer) return false;
        case _Filter.all:
      }
      if (ql.isEmpty) return true;
      return s.displayName(t).toLowerCase().contains(ql) ||
          t.description.toLowerCase().contains(ql) ||
          t.note.toLowerCase().contains(ql) ||
          s.path(t.categoryId).toLowerCase().contains(ql) ||
          (s.account(t.accountId)?.name.toLowerCase().contains(ql) ?? false);
    }).toList();
    final months = {for (final t in s.transactions) DateTime(t.date.year, t.date.month)}.toList()
      ..sort((a, b) => b.compareTo(a));
    final inc = list.where((t) => t.amount > 0 && !t.isTransfer).fold(0, (a, t) => a + t.amount);
    final exp = list.where((t) => t.amount < 0 && !t.isTransfer).fold(0, (a, t) => a + t.amount);

    return Scaffold(
      appBar: selected.isNotEmpty
          ? AppBar(
              leading: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(selected.clear)),
              title: Text('${selected.length} selecionados'),
              actions: [
                IconButton(
                  tooltip: 'Categorizar',
                  icon: const Icon(Icons.folder_open),
                  onPressed: () async {
                    final id = await pickCategory(context);
                    if (id == null) return;
                    s.assign(s.transactions.where((t) => selected.contains(t.id)).toList(), id == -1 ? null : id);
                    setState(selected.clear);
                  },
                ),
                IconButton(
                  tooltip: 'Apagar',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final ok = await confirm(context, 'Apagar ${selected.length} movimentos?');
                    if (ok) {
                      s.deleteTxns(selected.toList());
                      setState(selected.clear);
                    }
                  },
                ),
              ],
            )
          : AppBar(
              title: searching
                  ? TextField(
                      autofocus: true,
                      decoration: const InputDecoration(hintText: 'Pesquisar…', border: InputBorder.none),
                      onChanged: (v) => setState(() => q = v),
                    )
                  : const Text('Movimentos'),
              actions: [
                IconButton(
                  icon: Icon(searching ? Icons.close : Icons.search),
                  onPressed: () => setState(() {
                    searching = !searching;
                    if (!searching) q = '';
                  }),
                ),
                IconButton(
                  tooltip: 'Importar extrato',
                  icon: const Icon(Icons.upload_file),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportScreen())),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTxnEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Movimento'),
      ),
      body: Column(children: [
        SizedBox(
          height: 64,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), children: [
            for (final (f, label, icon) in [
              (_Filter.all, 'Todos', Icons.all_inclusive),
              (_Filter.expense, 'Despesas', Icons.arrow_downward),
              (_Filter.uncategorized, 'Sem categoria', Icons.format_list_bulleted),
              (_Filter.income, 'Receitas', Icons.arrow_upward),
              (_Filter.transfers, 'Transferências', Icons.swap_horiz),
            ])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  avatar: Icon(filter == f ? Icons.check : icon, size: 18),
                  label: Text(label),
                  selected: filter == f,
                  onSelected: (_) => setState(() => filter = f),
                ),
              ),
            if (s.accounts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: PopupMenuButton<int>(
                  onSelected: (v) => setState(() => accountFilter = v == -1 ? null : v),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: -1, child: Text('Todas as contas')),
                    for (final a in s.accounts) PopupMenuItem(value: a.id, child: Text('${a.emoji} ${a.name}'.trim())),
                  ],
                  child: Chip(avatar: const Icon(Icons.account_balance_wallet_outlined, size: 18), label: Text(accountFilter == null ? 'Todas as contas' : (s.account(accountFilter)?.name ?? 'Conta'))),
                ),
              ),
            PopupMenuButton<DateTime?>(
              onSelected: (v) => setState(() => month = v),
              itemBuilder: (_) => [
                const PopupMenuItem(value: null, child: Text('Todos os meses')),
                for (final m in months) PopupMenuItem(value: m, child: Text(fmtMonth(m))),
              ],
              child: Chip(avatar: const Icon(Icons.calendar_month, size: 18), label: Text(month == null ? 'Todos os meses' : fmtMonth(month!))),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${list.length} movimentos'),
            Text('+${fmtMoney(inc)}  /  ${fmtMoney(exp)}', style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
        const Divider(height: 8),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Sem movimentos.\nImporta um extrato (ícone no topo) ou adiciona manualmente.', textAlign: TextAlign.center)))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final t = list[i];
                    final showHeader = i == 0 || list[i - 1].date != t.date;
                    final c = s.cat(t.categoryId);
                    final tile = ListTile(
                      selected: selected.contains(t.id),
                      leading: t.isTransfer ? const Icon(Icons.swap_horiz) : (c == null ? const Icon(Icons.help_outline, color: Colors.grey) : CatBadge(c)),
                      title: Text(s.displayName(t), maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                          [
                            if (t.investAccountId != null) 'Investimento · ${s.investAccount(t.investAccountId)?.name ?? ''}' else if (t.isTransfer) 'Transferência' else s.path(t.categoryId),
                            if (s.account(t.accountId) != null) s.account(t.accountId)!.name,
                            if (t.note.isNotEmpty) t.note,
                          ].join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (t.receiptPath != null) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.attach_file, size: 16)),
                        MoneyText(t.amount, colored: !t.isTransfer),
                      ]),
                      onTap: () => selected.isNotEmpty
                          ? setState(() => selected.contains(t.id) ? selected.remove(t.id) : selected.add(t.id))
                          : showTxnEditor(context, edit: t),
                      onLongPress: () => setState(() => selected.add(t.id)),
                    );
                    if (!showHeader) return tile;
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Text(fmtDate(t.date), style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey)),
                      ),
                      tile,
                    ]);
                  },
                ),
        ),
      ]),
    );
  }
}

Future<bool> confirm(BuildContext context, String message, {String ok = 'Apagar'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(ok)),
      ],
    ),
  );
  return r ?? false;
}
