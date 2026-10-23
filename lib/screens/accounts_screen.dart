import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../analysis/analytics.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import '../widgets/common.dart';
import 'goals_screen.dart' show GoalDetailScreen;
import 'transactions_screen.dart' show TransactionsScreen, confirm;

/// Cria ou edita uma conta (nome, ícone e saldo inicial). Devolve o id.
Future<int?> showAccountEditor(BuildContext context, {Conta? edit}) {
  final l = AppLocalizations.of(context)!;
  final s = context.read<AppState>();
  final name = TextEditingController(text: edit?.name ?? '');
  final opening = TextEditingController(
    text: edit == null || edit.openingCents == 0
        ? ''
        : (edit.openingCents / 100).toStringAsFixed(2).replaceAll('.', ','),
  );
  var emoji = edit?.emoji ?? '';
  return showDialog<int>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        title: Text(edit == null ? l.frmNewAccount : l.frmEditAccount),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
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
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(ctx).colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      emoji.isEmpty ? '🏦' : emoji,
                      style: TextStyle(
                        fontSize: 28,
                        color: emoji.isEmpty ? Colors.grey : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: name,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l.frmName,
                      hintText: l.frmAccountNameHint,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: opening,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l.frmOpeningBalanceCurrency(baseSym),
                prefixText: '$baseSym  ',
                helperText: l.frmOpeningBalanceHelp,
                helperMaxLines: 2,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () {
              final n = name.text.trim();
              if (n.isEmpty) return;
              final cents = parseCents(opening.text) ?? 0;
              if (edit == null) {
                Navigator.pop(
                  ctx,
                  s.addAccount(n, emoji: emoji, openingCents: cents),
                );
              } else {
                s.updateAccount(
                  Conta(
                    id: edit.id,
                    name: n,
                    emoji: emoji,
                    openingCents: cents,
                  ),
                );
                Navigator.pop(ctx, edit.id);
              }
            },
            child: Text(l.frmSave),
          ),
        ],
      ),
    ),
  );
}

/// Escolher uma conta (folha inferior). Devolve o id, -1 para "sem conta" ou null se cancelado.
Future<int?> pickAccount(
  BuildContext context, {
  int? selected,
  int? exclude,
  String? title,
}) {
  return showModalBottomSheet<int>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (ctx) {
      final s = ctx.watch<AppState>();
      final l = AppLocalizations.of(ctx)!;
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title ?? l.frmAccount,
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
              ),
            ),
            for (final a in s.accounts.where((a) => a.id != exclude))
              ListTile(
                leading: Text(
                  a.emoji.isEmpty ? '🏦' : a.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(a.name),
                selected: a.id == selected,
                trailing: a.id == selected ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(ctx, a.id),
              ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: Text(l.frmNewAccountItem),
              onTap: () async {
                final id = await showAccountEditor(ctx);
                if (id != null && ctx.mounted) Navigator.pop(ctx, id);
              },
            ),
            if (selected != null)
              ListTile(
                leading: const Icon(Icons.close),
                title: Text(l.frmNoAccount),
                onTap: () => Navigator.pop(ctx, -1),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.frmAccounts)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAccountEditor(context),
        icon: const Icon(Icons.add),
        label: Text(l.frmAccount),
      ),
      body: s.accounts.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(l.frmNoAccountsYet, textAlign: TextAlign.center),
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 90),
              children: [
                for (final a in s.accounts)
                  Builder(
                    builder: (_) {
                      final count = s.transactions
                          .where((t) => t.accountId == a.id)
                          .length;
                      return ListTile(
                        leading: Text(
                          a.emoji.isEmpty ? '🏦' : a.emoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                        title: Text(
                          a.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          l.frmAccountSubtitle(
                            count,
                            fmtMoney(s.accountBalance(a.id)),
                          ),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AccountDetailScreen(accountId: a.id),
                          ),
                        ),
                        trailing: IconButton(
                          tooltip: l.delete,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            if (await confirm(
                              context,
                              l.frmDeleteAccountQuestion(a.name, count),
                            ))
                              s.deleteAccount(a.id);
                          },
                        ),
                      );
                    },
                  ),
              ],
            ),
    );
  }
}

/// Uma conta por dentro: saldo, resumo do mês, objetivos alimentados por esta conta e os seus movimentos.
class AccountDetailScreen extends StatelessWidget {
  final int accountId;
  const AccountDetailScreen({super.key, required this.accountId});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final l = AppLocalizations.of(context)!;
    final a = s.account(accountId);
    if (a == null) {
      return Scaffold(body: Center(child: Text(l.frmAccountDeleted)));
    }
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final period = s.periodOfMonth(s.currentMonthKey);
    final an = Analytics(
      s,
      period,
      AnalysisFilter(accountIds: {accountId}),
      today: now,
    );
    final mine = s.transactions.where((t) => t.accountId == accountId).toList();
    final contributions = s.goalContributionsFrom(accountId);
    final recent = mine.take(30).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${a.emoji} ${a.name}'.trim()),
        actions: [
          IconButton(
            tooltip: l.frmEdit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showAccountEditor(context, edit: a),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.frmBalance, style: tt.bodySmall),
                  Text(
                    fmtMoney(s.accountBalance(accountId)),
                    style: tt.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.frmOpeningBalanceLine(
                      fmtMoney(a.openingCents),
                      mine.length,
                    ),
                    style: tt.bodySmall,
                  ),
                  const Divider(height: 24),
                  Text(l.frmThisMonth, style: tt.titleSmall),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _Stat(l.spent, fmtMoney(an.spent), cs.error),
                      ),
                      Expanded(
                        child: _Stat(
                          l.frmIncome,
                          fmtMoney(an.income),
                          cs.primary,
                        ),
                      ),
                      Expanded(
                        child: _Stat(
                          l.frmMonthBalance,
                          fmtMoney(an.income - an.spent),
                          null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(l.frmGoalsFedByAccount, style: tt.titleSmall),
          const SizedBox(height: 4),
          if (contributions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(l.frmNoGoalFunded, style: tt.bodySmall),
            ),
          for (final e in contributions.entries)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Text('🎯', style: TextStyle(fontSize: 20)),
              title: Text(
                s.goals.where((g) => g.id == e.key).firstOrNull?.name ??
                    l.goalFallback,
              ),
              trailing: Text(fmtMoney(e.value), style: tt.titleSmall),
              onTap: () {
                final g = s.goals.where((g) => g.id == e.key).firstOrNull;
                if (g == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GoalDetailScreen(goalId: g.id),
                  ),
                );
              },
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Text(l.transactions, style: tt.titleSmall)),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TransactionsScreen(accountId: accountId),
                  ),
                ),
                child: Text(l.seeAll),
              ),
            ],
          ),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(l.frmNoTransactionsInAccount, style: tt.bodySmall),
            ),
          for (final t in recent)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                s.displayName(t),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text('${fmtDate(t.date)} · ${s.path(t.categoryId)}'),
              trailing: MoneyText(t.amount, colored: !t.isTransfer),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _Stat(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 2),
      Text(
        value,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.w700, color: color),
      ),
    ],
  );
}
