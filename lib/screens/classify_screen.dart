import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  int? pickOf(AppState s, TxnGroup g) => picks.containsKey(g.key) ? picks[g.key] : s.ruleFor(g.rep)?.categoryId;

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
      s.assign(g.txns, pick, remember: rememberOf(s, g), label: rule?.label ?? '', note: rule?.note ?? '');
      n += g.txns.length;
      picks.remove(g.key);
      remembers.remove(g.key);
      selected.remove(g.key);
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    var groups = onlyPending ? s.unclassifiedGroups() : s.allGroups();
    final ql = q.toLowerCase();
    if (q.isNotEmpty) {
      groups = groups.where((g) => g.key.toLowerCase().contains(ql) || (s.groupById(g.groupId)?.name.toLowerCase().contains(ql) ?? false) || g.txns.any((t) => t.description.toLowerCase().contains(ql))).toList();
    }
    if (sort == 'total') groups.sort((a, b) => b.total.abs().compareTo(a.total.abs()));
    if (sort == 'recent') groups.sort((a, b) => b.txns.first.date.compareTo(a.txns.first.date));
    if (sort == 'name') groups.sort((a, b) => a.key.compareTo(b.key));
    final pendingTx = s.transactions.where((t) => t.categoryId == null && !t.isTransfer).length;
    final shownKeys = groups.map((g) => g.key).toSet();
    selected.removeWhere((k) => !shownKeys.contains(k));
    final selGroups = groups.where((g) => selected.contains(g.key)).toList();
    final applicable = selGroups.where((g) => pickOf(s, g) != null).fold(0, (a, g) => a + g.txns.length);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 96,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Classificar'),
          const SizedBox(height: 2),
          Text('Revê e categoriza as tuas transações importadas', maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ]),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Ordenar',
            onSelected: (v) => setState(() => sort = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'count', child: Text('Mais movimentos')),
              PopupMenuItem(value: 'total', child: Text('Maior valor')),
              PopupMenuItem(value: 'recent', child: Text('Mais recentes')),
              PopupMenuItem(value: 'name', child: Text('Nome (A-Z)')),
            ],
          ),
          IconButton(tooltip: 'Grupos', icon: const Icon(Icons.hub_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupsScreen()))),
          IconButton(tooltip: 'Regras memorizadas', icon: const Icon(Icons.rule), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RulesScreen()))),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Pesquisar grupos ou estabelecimentos…'),
            onChanged: (v) => setState(() => q = v),
          ),
        ),
        SizedBox(
          height: 68,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), children: [
            ChoiceChip(avatar: Icon(onlyPending ? Icons.check_circle : Icons.pending_outlined, size: 18), label: Text('Por classificar ($pendingTx)'), selected: onlyPending, onSelected: (_) => setState(() => onlyPending = true)),
            const SizedBox(width: 10),
            ChoiceChip(label: const Text('Todos'), selected: !onlyPending, onSelected: (_) => setState(() => onlyPending = false)),
            const SizedBox(width: 10),
            ActionChip(
              avatar: const Icon(Icons.tune, size: 18),
              label: const Text('Aplicar regras'),
              onPressed: () {
                final n = s.applyRules();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$n movimentos classificados pelas regras.')));
              },
            ),
          ]),
        ),
        Expanded(
          child: groups.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(onlyPending ? Icons.check_circle_outline : Icons.inbox_outlined, size: 64, color: Colors.green),
                      const SizedBox(height: 16),
                      Text(onlyPending ? 'Tudo classificado! 🎉' : 'Ainda não há movimentos.', style: Theme.of(context).textTheme.titleMedium),
                    ]),
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
                      onSelect: (v) => setState(() => v ? selected.add(g.key) : selected.remove(g.key)),
                      onApply: () {
                        final n = _apply(s, [g]);
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$n movimentos classificados.')));
                      },
                    );
                  },
                ),
        ),
        if (groups.isNotEmpty)
          Container(
            decoration: BoxDecoration(color: cs.surfaceContainer, border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)))),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: Row(children: [
              Checkbox(
                tristate: true,
                value: selected.isEmpty ? false : (selected.length == groups.length ? true : null),
                onChanged: (_) => setState(() {
                  if (selected.length == groups.length) {
                    selected.clear();
                  } else {
                    selected.addAll(shownKeys);
                  }
                }),
              ),
              const Text('Selecionar tudo'),
              const SizedBox(width: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 48), padding: const EdgeInsets.symmetric(horizontal: 16)),
                    icon: const Icon(Icons.check, size: 20),
                    label: FittedBox(fit: BoxFit.scaleDown, child: Text('Aplicar a $applicable ${applicable == 1 ? 'movimento' : 'movimentos'}')),
                    onPressed: applicable == 0
                        ? null
                        : () {
                            final n = _apply(s, selGroups);
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$n movimentos classificados.')));
                          },
                  ),
                ),
              ),
            ]),
          ),
      ]),
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
    final title = grp != null ? grp.name : ((rule != null && rule.label.isNotEmpty) ? rule.label : g.key);
    final pick = widget.pick;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => expanded = !expanded),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Checkbox(value: widget.selected, onChanged: (v) => widget.onSelect(v ?? false)),
              const SizedBox(width: 6),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Row(children: [
                      Icon(Icons.event, size: 16, color: cs.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${txns.length} ${txns.length == 1 ? 'movimento' : 'movimentos'} · ${fmtDate(dates.last)}',
                          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ),
                    ]),
                  ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  MoneyText(g.total, style: tt.titleMedium),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more, color: cs.onSurfaceVariant),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final e in dist.entries)
              Chip(
                visualDensity: VisualDensity.compact,
                avatar: e.key == null ? Icon(Icons.cancel_outlined, size: 18, color: cs.onSurfaceVariant) : CatBadge(s.cat(e.key), size: 16),
                label: Text('${s.path(e.key)} · ${e.value}'),
              ),
            if (grp != null)
              ActionChip(
                visualDensity: VisualDensity.compact,
                avatar: const Icon(Icons.hub_outlined, size: 16),
                label: Text('Grupo · ${g.keys.length} ${g.keys.length == 1 ? 'título' : 'títulos'}'),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupDetailScreen(groupId: grp.id))),
              )
            else if (rule != null)
              const Chip(visualDensity: VisualDensity.compact, avatar: Icon(Icons.bookmark, size: 16), label: Text('Memorizado')),
          ]),
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
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: cs.outlineVariant)),
            child: Row(children: [
              Icon(Icons.bookmark_border, color: cs.primary),
              const SizedBox(width: 12),
              const Expanded(child: Text('Memorizar para futuros')),
              IconButton(
                tooltip: 'O que é isto?',
                icon: Icon(Icons.info_outline, size: 20, color: cs.onSurfaceVariant),
                onPressed: () => showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Memorizar para futuros'),
                    content: const Text('Guarda uma regra: da próxima vez que aparecer um movimento com este título, a app aplica logo o nome e a categoria que escolheste.'),
                    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                  ),
                ),
              ),
              Switch(value: widget.remember, onChanged: widget.onRemember),
            ]),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            icon: const Icon(Icons.check),
            label: Text('Aplicar a ${txns.length} ${txns.length == 1 ? 'movimento' : 'movimentos'}'),
            onPressed: pick == null ? null : widget.onApply,
          ),
          const SizedBox(height: 4),
          Wrap(alignment: WrapAlignment.end, children: [
            if (grp == null) TextButton.icon(icon: const Icon(Icons.edit_note), label: const Text('Nome e notas'), onPressed: () => _details(context, txns, rule)),
            TextButton.icon(
              icon: const Icon(Icons.hub_outlined),
              label: Text(grp == null ? 'Juntar a grupo' : 'Gerir grupo'),
              onPressed: () => grp == null
                  ? joinGroupDialog(context, g.keys, suggestedCategory: pick)
                  : Navigator.push(context, MaterialPageRoute(builder: (_) => GroupDetailScreen(groupId: grp.id))),
            ),
            if (rule != null && grp == null)
              TextButton.icon(
                icon: const Icon(Icons.bookmark_remove_outlined),
                label: const Text('Esquecer regra'),
                onPressed: () async {
                  if (await confirm(context, 'Esquecer a regra para “${g.key}”? Os movimentos já classificados mantêm-se.', ok: 'Esquecer')) s.deleteRule(rule.id);
                },
              ),
          ]),
          if (expanded) ...[
            const Divider(height: 24),
            if (selectedTx.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Text('${selectedTx.length} selecionados'),
                  const Spacer(),
                  TextButton(
                    onPressed: pick == null
                        ? null
                        : () {
                            s.assign(txns.where((t) => selectedTx.contains(t.id)).toList(), pick, remember: false);
                            setState(selectedTx.clear);
                          },
                    child: Text(pick == null ? 'Escolhe a categoria' : 'Mover para ${s.path(pick)}'),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => setState(selectedTx.clear)),
                ]),
              ),
            for (final t in txns)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Checkbox(value: selectedTx.contains(t.id), onChanged: (v) => setState(() => v! ? selectedTx.add(t.id) : selectedTx.remove(t.id))),
                title: Text(t.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text('${fmtDate(t.date)} · ${s.path(t.categoryId)}${t.note.isEmpty ? '' : '\n${t.note}'}'),
                isThreeLine: t.note.isNotEmpty,
                trailing: MoneyText(t.amount),
                onTap: () => showTxnEditor(context, edit: t),
              ),
          ],
        ]),
      ),
    );
  }

  Future<void> _details(BuildContext context, List<Txn> txns, Rule? rule) async {
    final s = context.read<AppState>();
    final label = TextEditingController(text: rule?.label ?? '');
    final note = TextEditingController(text: rule?.note ?? '');
    final txNote = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nome e notas'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: label, decoration: const InputDecoration(labelText: 'Nome amigável (opcional)', hintText: 'Ex.: Ginásio')),
            const SizedBox(height: 12),
            TextField(controller: note, decoration: const InputDecoration(labelText: 'Descrição da regra (opcional)'), maxLines: 2),
            const SizedBox(height: 12),
            TextField(controller: txNote, decoration: const InputDecoration(labelText: 'Nota em todos os movimentos (opcional)'), maxLines: 2),
            const SizedBox(height: 12),
            const Text('O nome e a descrição ficam guardados na regra, para as próximas importações.', style: TextStyle(fontSize: 12)),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final cid = widget.pick ?? rule?.categoryId;
              if (cid != null || label.text.trim().isNotEmpty || note.text.trim().isNotEmpty || rule != null) {
                s.saveRule(widget.group.rep, cid, label: label.text.trim(), note: note.text.trim());
              }
              if (txNote.text.trim().isNotEmpty) s.setNote(txns.map((t) => t.id).toList(), txNote.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
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
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Regras memorizadas')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Regra'),
        onPressed: () => _editRule(context),
      ),
      body: s.rules.isEmpty
          ? const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Sem regras. Ao mover movimentos com “Memorizar”, as regras aparecem aqui.', textAlign: TextAlign.center)))
          : ListView(children: [
              for (final r in s.rules)
                ListTile(
                  leading: CatBadge(s.cat(r.categoryId)),
                  title: Text(r.label.isEmpty ? r.pattern : '${r.label}  (${r.pattern})'),
                  subtitle: Text('${r.exact ? 'Igual a' : 'Contém'} → ${s.path(r.categoryId)}${r.note.isEmpty ? '' : '\n${r.note}'}'),
                  isThreeLine: r.note.isNotEmpty,
                  onTap: () => _editRule(context, edit: r),
                  trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => s.deleteRule(r.id)),
                ),
            ]),
    );
  }

  Future<void> _editRule(BuildContext context, {Rule? edit}) async {
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
          title: Text(edit == null ? 'Nova regra' : 'Editar regra'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: pattern, enabled: edit == null, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Texto a reconhecer (MAIÚSCULAS)')),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Nome exatamente igual'), subtitle: const Text('Desligado: basta conter o texto'), value: exact, onChanged: edit == null ? (v) => set(() => exact = v) : null),
              const SizedBox(height: 8),
              CategorySelector(value: cat, onChanged: (v) => set(() => cat = v)),
              TextField(controller: label, decoration: const InputDecoration(labelText: 'Nome amigável (opcional)')),
              TextField(controller: note, decoration: const InputDecoration(labelText: 'Descrição (opcional)'), maxLines: 2),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (pattern.text.trim().isEmpty || (cat == null && label.text.trim().isEmpty)) return;
                s.saveRule(pattern.text.trim().toUpperCase(), cat, exact: exact, label: label.text.trim(), note: note.text.trim());
                s.applyRules();
                Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
