import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import '../widgets/common.dart';
import 'import_screen.dart';
import 'txn_form_screen.dart' show corrigirValor;

enum _Filter { all, uncategorized, income, expense, transfers }

class TransactionsScreen extends StatefulWidget {
  final int? accountId; // começa filtrado nesta conta
  const TransactionsScreen({super.key, this.accountId});
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
  bool selecting = false; // modo de seleção: caixas visíveis em cada movimento

  @override
  void initState() {
    super.initState();
    accountFilter = widget.accountId;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = context.watch<AppState>();
    final ql = q.toLowerCase();
    final list = s.transactions.where((t) {
      if (month != null &&
          (t.date.year != month!.year || t.date.month != month!.month))
        return false;
      if (accountFilter != null && t.accountId != accountFilter) return false;
      switch (filter) {
        case _Filter.uncategorized:
          if (t.categoryId != null || t.isTransfer) return false;
        case _Filter.income:
          if (s.flowAmount(t) <= 0 || t.isTransfer) return false;
        case _Filter.expense:
          if (s.flowAmount(t) >= 0 || t.isTransfer) return false;
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
    final months = {
      for (final t in s.transactions) DateTime(t.date.year, t.date.month),
    }.toList()..sort((a, b) => b.compareTo(a));
    final inc = list
        .where((t) => s.flowAmount(t) > 0 && !t.isTransfer)
        .fold(0, (a, t) => a + s.flowAmount(t));
    final exp = list
        .where((t) => s.flowAmount(t) < 0 && !t.isTransfer)
        .fold(0, (a, t) => a + s.flowAmount(t));

    return Scaffold(
      appBar: selecting
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  selected.clear();
                  selecting = false;
                }),
              ),
              title: Text(l.selectedCount(selected.length)),
              actions: [
                IconButton(
                  tooltip: list.every((t) => selected.contains(t.id))
                      ? l.selDeselectAll
                      : l.selSelectAll,
                  icon: Icon(
                    list.isNotEmpty &&
                            list.every((t) => selected.contains(t.id))
                        ? Icons.deselect
                        : Icons.select_all,
                  ),
                  onPressed: () => setState(() {
                    if (list.every((t) => selected.contains(t.id))) {
                      selected.removeAll(list.map((t) => t.id));
                    } else {
                      selected.addAll(list.map((t) => t.id));
                    }
                  }),
                ),
                if (selected.length == 1)
                  IconButton(
                    tooltip: l.edvFixAmount,
                    icon: const Icon(Icons.price_change_outlined),
                    onPressed: () async {
                      final t = s.transactions
                          .where((t) => t.id == selected.first)
                          .firstOrNull;
                      if (t == null) return;
                      if (await corrigirValor(context, t)) {
                        setState(() {
                          selected.clear();
                          selecting = false;
                        });
                      }
                    },
                  ),
                IconButton(
                  tooltip: l.categorize,
                  icon: const Icon(Icons.folder_open),
                  onPressed: selected.isEmpty
                      ? null
                      : () async {
                          final id = await pickCategory(context);
                          if (id == null) return;
                          s.assign(
                            s.transactions
                                .where((t) => selected.contains(t.id))
                                .toList(),
                            id == -1 ? null : id,
                          );
                          setState(() {
                            selected.clear();
                            selecting = false;
                          });
                        },
                ),
                IconButton(
                  tooltip: l.delete,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: selected.isEmpty
                      ? null
                      : () async {
                          final ok = await confirm(
                            context,
                            l.deleteTransactionsQuestion(selected.length),
                          );
                          if (ok) {
                            s.deleteTxns(selected.toList());
                            setState(() {
                              selected.clear();
                              selecting = false;
                            });
                          }
                        },
                ),
              ],
            )
          : AppBar(
              title: searching
                  ? TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: l.search,
                        border: InputBorder.none,
                      ),
                      onChanged: (v) => setState(() => q = v),
                    )
                  : Text(l.transactions),
              actions: [
                IconButton(
                  tooltip: l.selSelect,
                  icon: const Icon(Icons.checklist),
                  onPressed: () => setState(() => selecting = true),
                ),
                IconButton(
                  icon: Icon(searching ? Icons.close : Icons.search),
                  onPressed: () => setState(() {
                    searching = !searching;
                    if (!searching) q = '';
                  }),
                ),
                IconButton(
                  tooltip: l.frmImportStatementTip,
                  icon: const Icon(Icons.upload_file),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ImportScreen()),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTxnEditor(context),
        icon: const Icon(Icons.add),
        label: Text(l.transaction),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 64,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                for (final (f, label, icon) in [
                  (_Filter.all, l.frmAll, Icons.all_inclusive),
                  (_Filter.expense, l.frmExpenses, Icons.arrow_downward),
                  (
                    _Filter.uncategorized,
                    l.noCategory,
                    Icons.format_list_bulleted,
                  ),
                  (_Filter.income, l.income, Icons.arrow_upward),
                  (_Filter.transfers, l.frmTransfers, Icons.swap_horiz),
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
                      onSelected: (v) =>
                          setState(() => accountFilter = v == -1 ? null : v),
                      itemBuilder: (_) => [
                        PopupMenuItem(value: -1, child: Text(l.allAccounts)),
                        for (final a in s.accounts)
                          PopupMenuItem(
                            value: a.id,
                            child: Text('${a.emoji} ${a.name}'.trim()),
                          ),
                      ],
                      child: Chip(
                        avatar: const Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 18,
                        ),
                        label: Text(
                          accountFilter == null
                              ? l.allAccounts
                              : (s.account(accountFilter)?.name ??
                                    l.accountFallback),
                        ),
                      ),
                    ),
                  ),
                PopupMenuButton<DateTime?>(
                  onSelected: (v) => setState(() => month = v),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: null, child: Text(l.allMonths)),
                    for (final m in months)
                      PopupMenuItem(value: m, child: Text(fmtMonth(m))),
                  ],
                  child: Chip(
                    avatar: const Icon(Icons.calendar_month, size: 18),
                    label: Text(month == null ? l.allMonths : fmtMonth(month!)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.frmTransactionsCount(list.length)),
                Text(
                  '+${fmtMoney(inc)}  /  ${fmtMoney(exp)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Divider(height: 8),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        l.noTransactionsHint,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 90),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final t = list[i];
                      final showHeader = i == 0 || list[i - 1].date != t.date;
                      final c = s.cat(t.categoryId);
                      final tile = ListTile(
                        selected: selected.contains(t.id),
                        leading: selecting
                            ? Checkbox(
                                value: selected.contains(t.id),
                                onChanged: (_) => setState(
                                  () => selected.contains(t.id)
                                      ? selected.remove(t.id)
                                      : selected.add(t.id),
                                ),
                              )
                            : (t.isTransfer
                                  ? const Icon(Icons.swap_horiz)
                                  : (c == null
                                        ? const Icon(
                                            Icons.help_outline,
                                            color: Colors.grey,
                                          )
                                        : CatBadge(c))),
                        title: Text(
                          s.displayName(t),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          [
                            if (t.investAccountId != null)
                              l.frmInvestmentOf(
                                s.investAccount(t.investAccountId)?.name ?? '',
                              )
                            else if (t.isTransfer)
                              l.frmTransfer
                            else
                              s.path(t.categoryId),
                            if (s.account(t.accountId) != null)
                              s.account(t.accountId)!.name,
                            if (reversalLabel(l, s, t) != null)
                              reversalLabel(l, s, t)!,
                            if (linkLabel(l, s, t) != null) linkLabel(l, s, t)!,
                            if (goalLabel(l, s, t) != null) goalLabel(l, s, t)!,
                            if (t.note.isNotEmpty) t.note,
                          ].join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (t.valueEdited)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Tooltip(
                                  message: l.edvOriginalValue(
                                    fmtMoney(t.originalAmount!),
                                  ),
                                  child: const Icon(Icons.edit_note, size: 16),
                                ),
                              ),
                            if (t.receiptPath != null)
                              const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(Icons.attach_file, size: 16),
                              ),
                            MoneyText(t.amount, colored: !t.isTransfer),
                          ],
                        ),
                        onTap: () => selecting
                            ? setState(
                                () => selected.contains(t.id)
                                    ? selected.remove(t.id)
                                    : selected.add(t.id),
                              )
                            : showTxnEditor(context, edit: t),
                        onLongPress: () => setState(() {
                          selecting = true;
                          selected.add(t.id);
                        }),
                      );
                      if (!showHeader) return tile;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                            child: Text(
                              fmtDate(t.date),
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ),
                          tile,
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Texto para os movimentos ligados a uma anulação: a receita diz que despesa anula;
/// a despesa diz quanto já foi anulado.
String? reversalLabel(AppLocalizations l, AppState s, Txn t) {
  if (t.reversesId != null && t.reversedCents > 0) {
    final exp = s.transactions.where((x) => x.id == t.reversesId).firstOrNull;
    if (exp == null) return l.reversalDeleted(fmtMoney(t.reversedCents));
    return l.reversalOf(s.displayName(exp), fmtMoney(t.reversedCents));
  }
  final done = t.amount < 0 ? (s.reversedByExpense[t.id] ?? 0) : 0;
  if (done > 0) {
    return l.reversedLeft(fmtMoney(done), fmtMoney(-s.effectiveAmount(t)));
  }
  return null;
}

/// Texto dos movimentos ligados à mão: com que movimentos está ligado e o líquido do grupo.
String? linkLabel(AppLocalizations l, AppState s, Txn t) {
  if (!s.isLinked(t)) return null;
  final names = s.linkedWith(t).map(s.displayName).join(', ');
  return l.lnkLinkedTo(names, fmtMoney(s.linkNet(t.linkGroup!)));
}

/// Divisão de um movimento pelos objetivos: "Objetivos: Férias 50,00 € · Alimentação 50,00 €".
String? goalLabel(AppLocalizations l, AppState s, Txn t) {
  final parts = [
    for (final a in s.goalAllocations)
      if (a.txnId == t.id)
        '${s.goals.where((g) => g.id == a.goalId).firstOrNull?.name ?? l.goalFallback} ${fmtMoney(a.cents)}',
  ];
  return parts.isEmpty ? null : l.goalsSplit(parts.join(' · '));
}

Future<bool> confirm(BuildContext context, String message, {String? ok}) async {
  final l = AppLocalizations.of(context)!;
  final r = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(ok ?? l.delete),
        ),
      ],
    ),
  );
  return r ?? false;
}
