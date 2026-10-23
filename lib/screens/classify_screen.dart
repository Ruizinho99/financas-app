import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import '../widgets/common.dart';
import 'groups_screen.dart';
import 'transactions_screen.dart' show confirm;

class ClassifyScreen extends StatefulWidget {
  const ClassifyScreen({super.key});
  @override
  State<ClassifyScreen> createState() => _ClassifyScreenState();
}

class _ClassifyScreenState extends State<ClassifyScreen> {
  bool onlyPending = true;
  String q = '';
  String sort = 'count';
  // estado por cartão (chave do cartão)
  final picks = <String, int?>{};
  final remembers = <String, bool>{};
  final selected = <String>{};

  int? pickOf(AppState s, TxnGroup g) =>
      picks.containsKey(g.key) ? picks[g.key] : s.ruleFor(g.rep)?.categoryId;

  bool rememberOf(AppState s, TxnGroup g) {
    if (remembers.containsKey(g.key)) return remembers[g.key]!;
    final r = s.ruleFor(g.rep);
    return r == null || r.categoryId != pickOf(s, g);
  }

  /// Aplica a categoria escolhida em cada cartão da lista [groups]; devolve quantos movimentos mexeu.
  int _apply(AppState s, Iterable<TxnGroup> groups) {
    var n = 0;
    for (final g in groups) {
      final pick = pickOf(s, g);
      if (pick == null) continue;
      final rule = s.ruleFor(g.rep);
      s.assign(
        g.txns,
        pick,
        remember: rememberOf(s, g),
        label: rule?.label ?? '',
        note: rule?.note ?? '',
      );
      n += g.txns.length;
      picks.remove(g.key);
      remembers.remove(g.key);
      selected.remove(g.key);
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = context.watch<AppState>();
    var groups = onlyPending ? s.unclassifiedGroups() : s.allGroups();
    final ql = q.toLowerCase();
    if (q.isNotEmpty) {
      groups = groups
          .where(
            (g) =>
                g.key.toLowerCase().contains(ql) ||
                (s.groupById(g.groupId)?.name.toLowerCase().contains(ql) ??
                    false) ||
                g.txns.any((t) => t.description.toLowerCase().contains(ql)),
          )
          .toList();
    }
    if (sort == 'total')
      groups.sort((a, b) => b.total.abs().compareTo(a.total.abs()));
    if (sort == 'recent')
      groups.sort((a, b) => b.txns.first.date.compareTo(a.txns.first.date));
    if (sort == 'name') groups.sort((a, b) => a.key.compareTo(b.key));
    final pendingTx = s.transactions
        .where((t) => t.categoryId == null && !t.isTransfer)
        .length;
    final shownKeys = groups.map((g) => g.key).toSet();
    selected.removeWhere((k) => !shownKeys.contains(k));
    final selGroups = groups.where((g) => selected.contains(g.key)).toList();
    final applicable = selGroups
        .where((g) => pickOf(s, g) != null)
        .fold(0, (a, g) => a + g.txns.length);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 96,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.impClassifyTitle),
            const SizedBox(height: 2),
            Text(
              l.impClassifySubtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: l.impSort,
            onSelected: (v) => setState(() => sort = v),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'count', child: Text(l.impSortCount)),
              PopupMenuItem(value: 'total', child: Text(l.impSortTotal)),
              PopupMenuItem(value: 'recent', child: Text(l.impSortRecent)),
              PopupMenuItem(value: 'name', child: Text(l.impSortName)),
            ],
          ),
          IconButton(
            tooltip: l.impGroups,
            icon: const Icon(Icons.hub_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GroupsScreen()),
            ),
          ),
          IconButton(
            tooltip: l.impRules,
            icon: const Icon(Icons.rule),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RulesScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l.impSearchGroups,
              ),
              onChanged: (v) => setState(() => q = v),
            ),
          ),
          SizedBox(
            height: 68,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              children: [
                ChoiceChip(
                  avatar: Icon(
                    onlyPending ? Icons.check_circle : Icons.pending_outlined,
                    size: 18,
                  ),
                  label: Text(l.impToClassifyChip(pendingTx)),
                  selected: onlyPending,
                  onSelected: (_) => setState(() => onlyPending = true),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: Text(l.impAll),
                  selected: !onlyPending,
                  onSelected: (_) => setState(() => onlyPending = false),
                ),
                const SizedBox(width: 10),
                ActionChip(
                  avatar: const Icon(Icons.tune, size: 18),
                  label: Text(l.impApplyRules),
                  onPressed: () {
                    final n = s.applyRules();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.impClassifiedByRules(n))),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: groups.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            onlyPending
                                ? Icons.check_circle_outline
                                : Icons.inbox_outlined,
                            size: 64,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            onlyPending
                                ? l.impAllClassified
                                : l.impNoTransactionsYet,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: groups.length,
                    itemBuilder: (_, i) {
                      final g = groups[i];
                      return _GroupCard(
                        key: ValueKey(g.key),
                        group: g,
                        pick: pickOf(s, g),
                        remember: rememberOf(s, g),
                        selected: selected.contains(g.key),
                        onPick: (v) => setState(() => picks[g.key] = v),
                        onRemember: (v) => setState(() => remembers[g.key] = v),
                        onSelect: (v) => setState(
                          () =>
                              v ? selected.add(g.key) : selected.remove(g.key),
                        ),
                        onApply: () {
                          final n = _apply(s, [g]);
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l.impClassifiedCount(n))),
                          );
                        },
                      );
                    },
                  ),
          ),
          if (groups.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                border: Border(
                  top: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: Row(
                children: [
                  Checkbox(
                    tristate: true,
                    value: selected.isEmpty
                        ? false
                        : (selected.length == groups.length ? true : null),
                    onChanged: (_) => setState(() {
                      if (selected.length == groups.length) {
                        selected.clear();
                      } else {
                        selected.addAll(shownKeys);
                      }
                    }),
                  ),
                  Text(l.impSelectAll),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        icon: const Icon(Icons.check, size: 20),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(l.impApplyTo(applicable)),
                        ),
                        onPressed: applicable == 0
                            ? null
                            : () {
                                final n = _apply(s, selGroups);
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l.impClassifiedCount(n)),
                                  ),
                                );
                              },
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatefulWidget {
  final TxnGroup group;
  final int? pick;
  final bool remember, selected;
  final ValueChanged<int?> onPick;
  final ValueChanged<bool> onRemember, onSelect;
  final VoidCallback onApply;
  const _GroupCard({
    super.key,
    required this.group,
    required this.pick,
    required this.remember,
    required this.selected,
    required this.onPick,
    required this.onRemember,
    required this.onSelect,
    required this.onApply,
  });
  @override
  State<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<_GroupCard> {
  bool expanded = false;
  final selectedTx = <int>{};

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final g = widget.group;
    final rule = s.ruleFor(g.rep);
    final grp = s.groupById(g.groupId);
    final txns = g.txns;
    final dates = txns.map((t) => t.date).toList()..sort();
    final dist = <int?, int>{};
    for (final t in txns) {
      dist[t.categoryId] = (dist[t.categoryId] ?? 0) + 1;
    }
    final title = grp != null
        ? grp.name
        : ((rule != null && rule.label.isNotEmpty) ? rule.label : g.key);
    final pick = widget.pick;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => expanded = !expanded),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: widget.selected,
                    onChanged: (v) => widget.onSelect(v ?? false),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.event,
                                size: 16,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  l.impTxnCountDate(
                                    txns.length,
                                    fmtDate(dates.last),
                                  ),
                                  style: tt.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MoneyText(g.total, style: tt.titleMedium),
                        Icon(
                          expanded ? Icons.expand_less : Icons.expand_more,
                          color: cs.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in dist.entries)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: e.key == null
                        ? Icon(
                            Icons.cancel_outlined,
                            size: 18,
                            color: cs.onSurfaceVariant,
                          )
                        : CatBadge(s.cat(e.key), size: 16),
                    label: Text('${s.path(e.key)} · ${e.value}'),
                  ),
                if (grp != null)
                  ActionChip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.hub_outlined, size: 16),
                    label: Text(l.impGroupChip(g.keys.length)),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupDetailScreen(groupId: grp.id),
                      ),
                    ),
                  )
                else if (rule != null)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.bookmark, size: 16),
                    label: Text(l.impRemembered),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            CategorySelector(
              value: pick,
              compact: true,
              when: DateTimeRange(start: dates.first, end: dates.last),
              onChanged: widget.onPick,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.bookmark_border, color: cs.primary),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l.impRememberForFuture)),
                  IconButton(
                    tooltip: l.impWhatIsThis,
                    icon: Icon(
                      Icons.info_outline,
                      size: 20,
                      color: cs.onSurfaceVariant,
                    ),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(l.impRememberForFuture),
                        content: Text(l.impRememberHelp),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(l.impOk),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Switch(value: widget.remember, onChanged: widget.onRemember),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              icon: const Icon(Icons.check),
              label: Text(l.impApplyTo(txns.length)),
              onPressed: pick == null ? null : widget.onApply,
            ),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.end,
              children: [
                if (grp == null)
                  TextButton.icon(
                    icon: const Icon(Icons.edit_note),
                    label: Text(l.impNameAndNotes),
                    onPressed: () => _details(context, txns, rule),
                  ),
                TextButton.icon(
                  icon: const Icon(Icons.hub_outlined),
                  label: Text(grp == null ? l.impJoinGroup : l.impManageGroup),
                  onPressed: () => grp == null
                      ? joinGroupDialog(
                          context,
                          g.keys,
                          suggestedCategory: pick,
                        )
                      : Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroupDetailScreen(groupId: grp.id),
                          ),
                        ),
                ),
                if (rule != null && grp == null)
                  TextButton.icon(
                    icon: const Icon(Icons.bookmark_remove_outlined),
                    label: Text(l.impForgetRule),
                    onPressed: () async {
                      if (await confirm(
                        context,
                        l.impForgetRuleQuestion(g.key),
                        ok: l.impForget,
                      ))
                        s.deleteRule(rule.id);
                    },
                  ),
              ],
            ),
            if (expanded) ...[
              const Divider(height: 24),
              if (selectedTx.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Text(l.impSelectedCount(selectedTx.length)),
                      const Spacer(),
                      TextButton(
                        onPressed: pick == null
                            ? null
                            : () {
                                s.assign(
                                  txns
                                      .where((t) => selectedTx.contains(t.id))
                                      .toList(),
                                  pick,
                                  remember: false,
                                );
                                setState(selectedTx.clear);
                              },
                        child: Text(
                          pick == null
                              ? l.impChooseCategory
                              : l.impMoveTo(s.path(pick)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(selectedTx.clear),
                      ),
                    ],
                  ),
                ),
              for (final t in txns)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Checkbox(
                    value: selectedTx.contains(t.id),
                    onChanged: (v) => setState(
                      () => v! ? selectedTx.add(t.id) : selectedTx.remove(t.id),
                    ),
                  ),
                  title: Text(
                    t.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${fmtDate(t.date)} · ${s.path(t.categoryId)}${t.note.isEmpty ? '' : '\n${t.note}'}',
                  ),
                  isThreeLine: t.note.isNotEmpty,
                  trailing: MoneyText(t.amount),
                  onTap: () => showTxnEditor(context, edit: t),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _details(
    BuildContext context,
    List<Txn> txns,
    Rule? rule,
  ) async {
    final l = AppLocalizations.of(context)!;
    final s = context.read<AppState>();
    final label = TextEditingController(text: rule?.label ?? '');
    final note = TextEditingController(text: rule?.note ?? '');
    final txNote = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.impNameAndNotes),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: label,
                decoration: InputDecoration(
                  labelText: l.impFriendlyName,
                  hintText: l.impExampleGym,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: note,
                decoration: InputDecoration(labelText: l.impRuleDescription),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: txNote,
                decoration: InputDecoration(labelText: l.impNoteAllTx),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Text(l.impNameSavedHint, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () {
              final cid = widget.pick ?? rule?.categoryId;
              if (cid != null ||
                  label.text.trim().isNotEmpty ||
                  note.text.trim().isNotEmpty ||
                  rule != null) {
                s.saveRule(
                  widget.group.rep,
                  cid,
                  label: label.text.trim(),
                  note: note.text.trim(),
                );
              }
              if (txNote.text.trim().isNotEmpty)
                s.setNote(txns.map((t) => t.id).toList(), txNote.text.trim());
              Navigator.pop(ctx);
            },
            child: Text(l.impSave),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(l.impRules)),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(l.impRule),
        onPressed: () => _editRule(context),
      ),
      body: s.rules.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l.impNoRules, textAlign: TextAlign.center),
              ),
            )
          : ListView(
              children: [
                for (final r in s.rules)
                  ListTile(
                    leading: CatBadge(s.cat(r.categoryId)),
                    title: Text(
                      r.label.isEmpty
                          ? r.pattern
                          : '${r.label}  (${r.pattern})',
                    ),
                    subtitle: Text(
                      '${r.exact ? l.impEquals : l.impContains} → ${s.path(r.categoryId)}${r.note.isEmpty ? '' : '\n${r.note}'}',
                    ),
                    isThreeLine: r.note.isNotEmpty,
                    onTap: () => _editRule(context, edit: r),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => s.deleteRule(r.id),
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _editRule(BuildContext context, {Rule? edit}) async {
    final l = AppLocalizations.of(context)!;
    final s = context.read<AppState>();
    final pattern = TextEditingController(text: edit?.pattern ?? '');
    final label = TextEditingController(text: edit?.label ?? '');
    final note = TextEditingController(text: edit?.note ?? '');
    var exact = edit?.exact ?? false;
    var cat = edit?.categoryId;
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(edit == null ? l.impNewRule : l.impEditRule),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: pattern,
                  enabled: edit == null,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(labelText: l.impTextToRecognize),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.impExactName),
                  subtitle: Text(l.impExactNameOff),
                  value: exact,
                  onChanged: edit == null ? (v) => set(() => exact = v) : null,
                ),
                const SizedBox(height: 8),
                CategorySelector(
                  value: cat,
                  onChanged: (v) => set(() => cat = v),
                ),
                TextField(
                  controller: label,
                  decoration: InputDecoration(labelText: l.impFriendlyName),
                ),
                TextField(
                  controller: note,
                  decoration: InputDecoration(
                    labelText: l.impDescriptionOptional,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (pattern.text.trim().isEmpty ||
                    (cat == null && label.text.trim().isEmpty))
                  return;
                s.saveRule(
                  pattern.text.trim().toUpperCase(),
                  cat,
                  exact: exact,
                  label: label.text.trim(),
                  note: note.text.trim(),
                );
                s.applyRules();
                Navigator.pop(ctx);
              },
              child: Text(l.impSave),
            ),
          ],
        ),
      ),
    );
  }
}
