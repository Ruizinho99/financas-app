import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'transactions_screen.dart' show confirm;

/// Lista de grupos: cada grupo junta vários títulos de movimentos sob um nome e uma categoria.
class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = context.watch<AppState>();
    final counts = s.titleCounts();
    return Scaffold(
      appBar: AppBar(title: Text(l.impGroups)),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(l.impNewGroup),
        onPressed: () async {
          final name = await _askName(context, l.impNewGroup, '');
          if (name == null || name.isEmpty || !context.mounted) return;
          final existing = s.groupByName(name);
          final id = existing?.id ?? s.createGroup(name);
          if (context.mounted)
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => GroupDetailScreen(groupId: id)),
            );
        },
      ),
      body: s.groups.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l.impGroupsEmpty, textAlign: TextAlign.center),
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 90),
              children: [
                for (final g in s.groups)
                  Builder(
                    builder: (_) {
                      final rules = s.rulesOfGroup(g.id);
                      final n = rules.fold(
                        0,
                        (a, r) => a + (counts[r.pattern] ?? 0),
                      );
                      final cat = s.cat(g.categoryId);
                      return ListTile(
                        leading: CatBadge(cat),
                        title: Text(
                          g.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${s.path(g.categoryId)} · ${l.impTitleCount(rules.length)} · ${l.impTxnCount(n)}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroupDetailScreen(groupId: g.id),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
    );
  }
}

Future<String?> _askName(BuildContext context, String title, String initial) {
  final l = AppLocalizations.of(context)!;
  final ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: l.impName,
          hintText: l.impExampleRestaurant,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
          child: Text(l.impCreate),
        ),
      ],
    ),
  );
}

/// Detalhe de um grupo: nome, categoria, nota e a lista de títulos que o compõem.
class GroupDetailScreen extends StatefulWidget {
  final int groupId;
  const GroupDetailScreen({super.key, required this.groupId});
  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late final TextEditingController name;
  late final TextEditingController note;
  int? category;
  bool loaded = false;

  void _load(AppState s) {
    final g = s.groupById(widget.groupId);
    name = TextEditingController(text: g?.name ?? '');
    note = TextEditingController(text: g?.note ?? '');
    category = g?.categoryId;
    loaded = true;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = context.watch<AppState>();
    if (!loaded) _load(s);
    final g = s.groupById(widget.groupId);
    if (g == null)
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l.impGroupDeleted)),
      );
    final rules = s.rulesOfGroup(g.id);
    final counts = s.titleCounts();

    void save() {
      final n = name.text.trim();
      if (n.isEmpty) return;
      final other = s.groupByName(n);
      if (other != null && other.id != g.id) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.impGroupExists(other.name))));
        return;
      }
      s.updateGroup(
        Grupo(id: g.id, name: n, categoryId: category, note: note.text.trim()),
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.impGroupSaved)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(g.name),
        actions: [
          IconButton(
            tooltip: l.impDeleteGroup,
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              if (await confirm(context, l.impDeleteGroupQuestion(g.name))) {
                s.deleteGroup(g.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_link),
        label: Text(l.impJoinTitles),
        onPressed: () => _addTitles(context, s, g),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          TextField(
            controller: name,
            decoration: InputDecoration(labelText: l.impGroupName),
          ),
          const SizedBox(height: 12),
          CategorySelector(
            value: category,
            onChanged: (v) => setState(() => category = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: note,
            decoration: InputDecoration(labelText: l.impDescriptionOptional),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: save,
              icon: const Icon(Icons.check),
              label: Text(l.impSave),
            ),
          ),
          const Divider(height: 32),
          Text(
            l.impTitlesInGroup(rules.length),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(l.impGroupAnyTitle),
          if (rules.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                l.impGroupEmptyHint,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          for (final r in rules)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.link),
              title: Text(r.pattern),
              subtitle: Text(
                '${r.exact ? l.impEquals : l.impContains} · ${l.impTxnCount(counts[r.pattern] ?? 0)}',
              ),
              trailing: IconButton(
                tooltip: l.impRemoveFromGroup,
                icon: const Icon(Icons.link_off),
                onPressed: () => s.removeFromGroup(r.id),
              ),
            ),
        ],
      ),
    );
  }

  /// Escolhe títulos existentes (ou escreve um texto "contém") para juntar ao grupo.
  Future<void> _addTitles(BuildContext context, AppState s, Grupo g) async {
    final l = AppLocalizations.of(context)!;
    final counts = s.titleCounts();
    final inGroup = s.rulesOfGroup(g.id).map((r) => r.pattern).toSet();
    final others = counts.keys.where((k) => !inGroup.contains(k)).toList()
      ..sort();
    final chosen = <String>{};
    final custom = TextEditingController();
    var q = '';
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) {
          final shown = others
              .where((k) => k.toLowerCase().contains(q.toLowerCase()))
              .toList();
          return AlertDialog(
            title: Text(l.impJoinTitles),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: l.impSearchTitles,
                      isDense: true,
                    ),
                    onChanged: (v) => set(() => q = v),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: shown.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(l.impNoTitlesFound),
                          )
                        : ListView(
                            shrinkWrap: true,
                            children: [
                              for (final k in shown)
                                Builder(
                                  builder: (_) {
                                    final r = s.ruleFor(k);
                                    final other =
                                        r?.groupId != null && r!.groupId != g.id
                                        ? s.groupById(r.groupId)
                                        : null;
                                    return CheckboxListTile(
                                      dense: true,
                                      value: chosen.contains(k),
                                      onChanged: (v) => set(
                                        () => v!
                                            ? chosen.add(k)
                                            : chosen.remove(k),
                                      ),
                                      title: Text(k),
                                      subtitle: Text(
                                        '${l.impTxnCount(counts[k] ?? 0)}${other != null ? l.impAlreadyInGroup(other.name) : ''}',
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                  ),
                  const Divider(),
                  TextField(
                    controller: custom,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: l.impOrAnyTitle,
                      hintText: 'ARMINDA',
                      isDense: true,
                    ),
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
                  if (chosen.isNotEmpty) s.addKeysToGroup(g.id, chosen);
                  final c = custom.text.trim().toUpperCase();
                  if (c.isNotEmpty) s.addKeysToGroup(g.id, [c], exact: false);
                  Navigator.pop(ctx);
                },
                child: Text(l.impJoin),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Junta títulos a um grupo existente ou cria um grupo novo com o nome escrito.
Future<void> joinGroupDialog(
  BuildContext context,
  Set<String> keys, {
  int? suggestedCategory,
}) async {
  final l = AppLocalizations.of(context)!;
  final s = context.read<AppState>();
  final ctrl = TextEditingController();
  int? existing;
  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) {
        final typed = ctrl.text.trim();
        final match = s.groupByName(typed);
        return AlertDialog(
          title: Text(l.impJoinAGroup),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  keys.length == 1
                      ? l.impTitleLabel(keys.first)
                      : l.impTitlesList(keys.length, keys.join(', ')),
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                if (s.groups.isNotEmpty)
                  DropdownButtonFormField<int>(
                    initialValue: existing,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l.impExistingGroup),
                    items: [
                      for (final g in s.groups)
                        DropdownMenuItem(
                          value: g.id,
                          child: Text(g.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) => set(() {
                      existing = v;
                      ctrl.clear();
                    }),
                  ),
                if (s.groups.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: Text(l.impOr)),
                  ),
                TextField(
                  controller: ctrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l.impNewGroup,
                    hintText: l.impExampleRestaurant,
                    helperText: match != null
                        ? l.impExistsJoins(match.name)
                        : null,
                  ),
                  onChanged: (_) => set(() => existing = null),
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
              onPressed: (existing == null && typed.isEmpty)
                  ? null
                  : () {
                      final gid = existing ?? match?.id;
                      if (gid != null) {
                        s.addKeysToGroup(gid, keys);
                      } else {
                        s.createGroup(
                          typed,
                          categoryId: suggestedCategory,
                          keys: keys,
                        );
                      }
                      Navigator.pop(ctx);
                    },
              child: Text(l.impJoin),
            ),
          ],
        );
      },
    ),
  );
}
