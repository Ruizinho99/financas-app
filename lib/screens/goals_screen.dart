import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../goals/goals.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import '../widgets/category_picker.dart';
import '../widgets/form_kit.dart';
import 'transactions_screen.dart' show confirm;

/// Lista dos objetivos de poupança, com o progresso de cada um.
class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = s.goals.where((g) => !g.archived).toList();
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.goals)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GoalFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: Text(l.bpGoal),
      ),
      body: list.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l.bpNoGoalsHint, textAlign: TextAlign.center),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
              children: [
                for (final g in list)
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                      title: Text(
                        '🎯 ${g.name}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: _GoalSummary(g),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GoalDetailScreen(goalId: g.id),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _GoalSummary extends StatelessWidget {
  final Goal g;
  const _GoalSummary(this.g);
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = s.goalProgressOf(g);
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.done
                ? l.bpGoalReachedAmount(fmtMoney(p.saved))
                : l.bpGoalProgress(
                    fmtMoney(p.saved),
                    fmtMoney(p.target),
                    fmtMoney(p.remaining),
                  ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: p.fraction,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
            color: p.done ? cs.tertiary : cs.primary,
          ),
        ],
      ),
    );
  }
}

/// Criar ou editar um objetivo. Ao criar, escolhe-se a categoria onde fica a subcategoria do objetivo.
class GoalFormScreen extends StatefulWidget {
  final Goal? edit;
  const GoalFormScreen({super.key, this.edit});
  @override
  State<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends State<GoalFormScreen> {
  late final name = TextEditingController(text: widget.edit?.name ?? '');
  late final desc = TextEditingController(text: widget.edit?.description ?? '');
  late final target = TextEditingController(
    text: widget.edit == null
        ? ''
        : (widget.edit!.targetCents / 100)
              .toStringAsFixed(2)
              .replaceAll('.', ','),
  );
  late DateTime? endDate = widget.edit?.endDate;
  int? parentId;
  String? error;

  @override
  void dispose() {
    name.dispose();
    desc.dispose();
    target.dispose();
    super.dispose();
  }

  Future<void> _pickParent(AppState s) async {
    final id = await chooseCategory(context, selected: parentId);
    if (id == null || id == -1) return;
    setState(() => parentId = id);
  }

  Future<void> _pickEnd() async {
    final d = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now().add(const Duration(days: 180)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => endDate = d);
  }

  void _save(AppState s) {
    final l = AppLocalizations.of(context)!;
    final n = name.text.trim();
    final cents = (parseCents(target.text) ?? 0).abs();
    if (n.isEmpty) {
      setState(() => error = l.bpEnterName);
      return;
    }
    if (cents <= 0) {
      setState(() => error = l.bpEnterGoalAmount);
      return;
    }
    final e = widget.edit;
    if (e == null) {
      if (parentId == null) {
        setState(() => error = l.bpChooseGoalCategory);
        return;
      }
      s.addGoal(
        name: n,
        description: desc.text,
        parentCategoryId: parentId!,
        targetCents: cents,
        endDate: endDate,
      );
    } else {
      final updated = e.copyWith(
        name: n,
        description: desc.text,
        endDate: endDate,
      );
      s.updateGoal(updated);
      if (cents != e.targetCents) s.changeGoalTarget(updated, cents);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final parent = s.cat(parentId);
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.edit == null ? l.bpNewGoal : l.bpEditGoal),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          TextField(
            controller: name,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l.bpName,
              hintText: l.bpGoalNameHint,
              errorText: error,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: target,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l.bpGoalAmount(baseSym),
              prefixText: '$baseSym  ',
              helperText: widget.edit == null ? null : l.bpPreviousAmountKept,
            ),
          ),
          const SizedBox(height: 14),
          TileField(
            icon: Icons.event_outlined,
            title: l.bpDeadlineOptional,
            text: endDate == null ? l.bpNoDeadline : fmtDate(endDate!),
            isHint: endDate == null,
            onTap: _pickEnd,
          ),
          if (endDate != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => endDate = null),
                child: Text(l.bpRemoveDeadline),
              ),
            ),
          const SizedBox(height: 14),
          TextField(
            controller: desc,
            maxLines: 2,
            decoration: InputDecoration(labelText: l.bpDescriptionOptional),
          ),
          if (widget.edit == null) ...[
            const SizedBox(height: 14),
            TileField(
              icon: Icons.sell_outlined,
              title: l.bpCategoryWhere,
              text: parent == null
                  ? l.bpChooseCategory
                  : '${parent.emoji.isEmpty ? '' : '${parent.emoji} '}${s.path(parent.id)}',
              isHint: parent == null,
              onTap: () => _pickParent(s),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l.bpGoalCategoryHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
          const SizedBox(height: 22),
          FilledButton(onPressed: () => _save(s), child: Text(l.bpSave)),
        ],
      ),
    );
  }
}

/// Detalhe de um objetivo: progresso, previsão, movimentos associados e histórico do valor.
class GoalDetailScreen extends StatelessWidget {
  final int goalId;
  const GoalDetailScreen({super.key, required this.goalId});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    Goal? g;
    for (final x in s.goals) {
      if (x.id == goalId) g = x;
    }
    final l = AppLocalizations.of(context)!;
    if (g == null) {
      return Scaffold(body: Center(child: Text(l.bpGoalDeleted)));
    }
    final goal = g;
    final p = s.goalProgressOf(goal);
    final history = s.goalHistory(goal.id);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.name),
        actions: [
          IconButton(
            tooltip: l.bpEdit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => GoalFormScreen(edit: goal)),
            ),
          ),
          IconButton(
            tooltip: l.delete,
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              if (await confirm(context, l.bpDeleteGoalQuestion(goal.name)) &&
                  context.mounted) {
                s.deleteGoal(goal);
                Navigator.pop(context);
              }
            },
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
                  if (goal.description.isNotEmpty) ...[
                    Text(goal.description, style: tt.bodyMedium),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      Expanded(child: _Stat(l.bpGoal, fmtMoney(p.target))),
                      Expanded(
                        child: _Stat(l.bpAlreadyHave, fmtMoney(p.saved)),
                      ),
                      Expanded(
                        child: _Stat(
                          p.done ? l.bpExceeded : l.bpRemaining,
                          fmtMoney(p.done ? -p.remaining : p.remaining),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  LinearProgressIndicator(
                    value: p.fraction,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                    color: p.done ? cs.tertiary : cs.primary,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.bpGoalPercentDeadline(
                      '${(p.fraction * 100).round()}',
                      goal.endDate == null
                          ? l.bpNoDeadlineLower
                          : l.bpDeadlineDate(fmtDate(goal.endDate!)),
                    ),
                    style: tt.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Text(_statusText(l, p, goal), style: tt.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                icon: const Icon(Icons.link),
                label: Text(l.bpLinkTransaction),
                onPressed: () => _pickMovement(context, s, goal, p),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.flag_outlined),
                label: Text(l.bpChangeAmount),
                onPressed: () => _changeTarget(context, s, goal),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(l.transactions, style: tt.titleSmall),
          const SizedBox(height: 4),
          if (p.entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(l.bpNoGoalEntriesHint, style: tt.bodySmall),
            ),
          for (final e in p.entries)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                s.displayName(e.txn),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                l.bpEntrySubtitle(
                  fmtDate(e.txn.date),
                  e.manual ? l.bpLinkedManual : l.bpLinkedByCategory,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(fmtMoney(e.cents), style: tt.titleSmall),
                  if (e.manual)
                    IconButton(
                      tooltip: l.bpUnlink,
                      icon: const Icon(Icons.link_off),
                      onPressed: () => s.unlinkMovement(e.allocationId!),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          Text(l.bpAmountHistory, style: tt.titleSmall),
          const SizedBox(height: 4),
          for (final h in history.reversed)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(fmtMoney(h.cents)),
              subtitle: Text(fmtDate(h.date)),
            ),
        ],
      ),
    );
  }

  String _statusText(AppLocalizations l, GoalProgress p, Goal g) {
    if (p.done) return l.bpStatusReached;
    final needed = p.neededPerMonth;
    if (needed != null) {
      final monthly = fmtMoney(p.monthly);
      return p.onTrack!
          ? l.bpStatusOnTrack(monthly, fmtMoney(needed))
          : l.bpStatusBehind(fmtMoney(needed), monthly);
    }
    if (p.eta != null) {
      return l.bpStatusEta(fmtMoney(p.monthly), fmtDate(p.eta!));
    }
    return l.bpStatusNoRecent(fmtMoney(p.remaining));
  }

  Future<void> _changeTarget(BuildContext context, AppState s, Goal g) async {
    final l = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(
      text: (g.targetCents / 100).toStringAsFixed(2).replaceAll('.', ','),
    );
    final cents = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.bpChangeGoalAmountTitle),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l.bpNewAmount(baseSym),
            helperText: l.bpChangeAmountHint,
            helperMaxLines: 3,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () {
              final v = (parseCents(ctrl.text) ?? 0).abs();
              if (v > 0) Navigator.pop(ctx, v);
            },
            child: Text(l.bpSave),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (cents != null && cents != g.targetCents) s.changeGoalTarget(g, cents);
  }

  Future<void> _pickMovement(
    BuildContext context,
    AppState s,
    Goal g,
    GoalProgress p,
  ) async {
    final l = AppLocalizations.of(context)!;
    final txn = await showModalBottomSheet<Txn>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        var q = '';
        return StatefulBuilder(
          builder: (ctx, set) {
            final query = q.trim().toLowerCase();
            final list = [
              for (final t in s.transactions)
                if (t.amount != 0 &&
                    (t.amount.abs() - s.allocatedOf(t.id)) > 0 &&
                    (query.isEmpty ||
                        s.displayName(t).toLowerCase().contains(query)))
                  t,
            ].take(200).toList();
            return SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.75,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: l.bpSearchTransaction,
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                      onChanged: (v) => set(() => q = v),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final t in list)
                          ListTile(
                            title: Text(
                              s.displayName(t),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              l.bpTxnLinkSubtitle(
                                fmtDate(t.date),
                                fmtMoney(t.amount.abs()),
                                fmtMoney(t.amount.abs() - s.allocatedOf(t.id)),
                              ),
                            ),
                            onTap: () => Navigator.pop(ctx, t),
                          ),
                        if (list.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Text(l.bpNoTransactionsToLink),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (txn == null || !context.mounted) return;
    final left = txn.amount.abs() - s.allocatedOf(txn.id);
    final suggested = left < p.remaining ? left : p.remaining;
    final ctrl = TextEditingController(
      text: suggested > 0
          ? (suggested / 100).toStringAsFixed(2).replaceAll('.', ',')
          : '',
    );
    final cents = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.displayName(txn)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l.bpAmountForGoal(g.name, baseSym),
            helperText: l.bpUnlinkedHint(fmtMoney(left)),
            helperMaxLines: 3,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () {
              final v = (parseCents(ctrl.text) ?? 0).abs();
              if (v > 0 && v <= left) Navigator.pop(ctx, v);
            },
            child: Text(l.bpLink),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (cents != null) s.linkMovement(txn.id, g.id, cents);
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 2),
      Text(
        value,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    ],
  );
}
