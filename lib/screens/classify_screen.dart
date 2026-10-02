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

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    var groups = onlyPending ? s.unclassifiedGroups() : s.allGroups();
    if (q.isNotEmpty) groups = groups.where((g) => g.key.toLowerCase().contains(q.toLowerCase()) || g.txns.any((t) => t.description.toLowerCase().contains(q.toLowerCase()))).toList();
    if (sort == 'total') groups.sort((a, b) => b.total.abs().compareTo(a.total.abs()));
    if (sort == 'recent') groups.sort((a, b) => b.txns.first.date.compareTo(a.txns.first.date));
    if (sort == 'name') groups.sort((a, b) => a.key.compareTo(b.key));
    final pendingTx = s.transactions.where((t) => t.categoryId == null).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classificar'),
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
          IconButton(
            tooltip: 'Grupos',
            icon: const Icon(Icons.hub_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupsScreen())),
          ),
          IconButton(
            tooltip: 'Regras memorizadas',
            icon: const Icon(Icons.rule),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RulesScreen())),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Pesquisar grupos', isDense: true, border: OutlineInputBorder()),
            onChanged: (v) => setState(() => q = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            ChoiceChip(label: Text('Por classificar ($pendingTx)'), selected: onlyPending, onSelected: (_) => setState(() => onlyPending = true)),
            const SizedBox(width: 8),
            ChoiceChip(label: const Text('Todos'), selected: !onlyPending, onSelected: (_) => setState(() => onlyPending = false)),
            const Spacer(),
            if (pendingTx > 0)
              TextButton(
                onPressed: () {
                  final n = s.applyRules();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$n movimentos classificados pelas regras.')));
                },
                child: const Text('Aplicar regras'),
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
                      const SizedBox(height: 12),
                      Text(onlyPending ? 'Tudo classificado! 🎉' : 'Ainda não há movimentos.', style: Theme.of(context).textTheme.titleMedium),
                    ]),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  itemCount: groups.length,
                  itemBuilder: (_, i) => _GroupCard(key: ValueKey(groups[i].key), group: groups[i]),
                ),
        ),
      ]),
    );
  }
}

class _GroupCard extends StatefulWidget {
  final TxnGroup group;
  const _GroupCard({super.key, required this.group});
  @override
  State<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<_GroupCard> {
  bool expanded = false;
  final selected = <int>{};
  int? pick; // categoria/subcategoria escolhida nos dropdowns
  bool remember = true;
  bool initDone = false;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final g = widget.group;
    final rule = s.ruleFor(g.rep);
    final grp = s.groupById(g.groupId);
    final txns = g.txns;
    final dates = txns.map((t) => t.date).toList()..sort();
    // distribuição por categoria
    final dist = <int?, int>{};
    for (final t in txns) {
      dist[t.categoryId] = (dist[t.categoryId] ?? 0) + 1;
    }
    final title = grp != null ? grp.name : ((rule != null && rule.label.isNotEmpty) ? rule.label : g.key);
    if (!initDone) {
      initDone = true;
      pick = rule?.categoryId;
      remember = rule == null || rule.categoryId != pick;
    }

    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          onTap: () => setState(() => expanded = !expanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                MoneyText(g.total),
              ]),
              const SizedBox(height: 2),
              Text('${txns.length} movimentos · ${fmtDate(dates.first)}${dates.first == dates.last ? '' : ' → ${fmtDate(dates.last)}'}',
                  style: Theme.of(context).textTheme.bodySmall),
              if (rule != null && rule.note.isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 4), child: Text(rule.note, style: const TextStyle(fontStyle: FontStyle.italic))),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 4, children: [
                for (final e in dist.entries)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: e.key == null ? const Icon(Icons.help_outline, size: 16) : CatBadge(s.cat(e.key), size: 16),
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
                  const Chip(visualDensity: VisualDensity.compact, avatar: Icon(Icons.push_pin, size: 14), label: Text('Memorizado')),
              ]),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            CategorySelector(value: pick, compact: true, onChanged: (v) => setState(() => pick = v)),
            Row(children: [
              Checkbox(value: remember, onChanged: (v) => setState(() => remember = v ?? true), visualDensity: VisualDensity.compact),
              const Expanded(child: Text('Memorizar para futuros')),
              if (grp == null) IconButton(tooltip: 'Nome amigável e notas', icon: const Icon(Icons.edit_note), onPressed: () => _details(context, txns, rule)),
              IconButton(
                tooltip: grp == null ? 'Juntar a um grupo' : 'Gerir grupo',
                icon: const Icon(Icons.hub_outlined),
                onPressed: () => grp == null
                    ? joinGroupDialog(context, g.keys, suggestedCategory: pick)
                    : Navigator.push(context, MaterialPageRoute(builder: (_) => GroupDetailScreen(groupId: grp.id))),
              ),
            ]),
            Row(children: [
              TextButton.icon(
                icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                label: Text(expanded ? 'Fechar' : 'Ver movimentos'),
                onPressed: () => setState(() => expanded = !expanded),
              ),
              const Spacer(),
              FilledButton.icon(
                icon: const Icon(Icons.drive_file_move_outline),
                label: Text('Mover ${txns.length}'),
                onPressed: pick == null ? null : () => _move(context, txns),
              ),
            ]),
          ]),
        ),
        if (expanded) ...[
          const Divider(height: 1),
          if (selected.isNotEmpty)
            Container(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [
                Text('${selected.length} selecionados'),
                const Spacer(),
                TextButton(
                  onPressed: pick == null ? null : () => _move(context, txns.where((t) => selected.contains(t.id)).toList(), remember: false),
                  child: Text(pick == null ? 'Escolhe a categoria acima' : 'Mover para ${s.path(pick)}'),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => setState(selected.clear)),
              ]),
            ),
          for (final t in txns)
            ListTile(
              dense: true,
              leading: Checkbox(
                value: selected.contains(t.id),
                onChanged: (v) => setState(() => v! ? selected.add(t.id) : selected.remove(t.id)),
              ),
              title: Text(t.description, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text('${fmtDate(t.date)} · ${s.path(t.categoryId)}${t.note.isEmpty ? '' : '\n${t.note}'}'),
              isThreeLine: t.note.isNotEmpty,
              trailing: MoneyText(t.amount),
              onTap: () => showTxnEditor(context, edit: t),
            ),
          if (rule != null && grp == null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.push_pin_outlined),
                label: Text('Esquecer regra (${s.path(rule.categoryId)})'),
                onPressed: () async {
                  if (await confirm(context, 'Esquecer a regra para “${g.key}”? Os movimentos já classificados mantêm-se.', ok: 'Esquecer')) {
                    s.deleteRule(rule.id);
                  }
                },
              ),
            ),
        ],
      ]),
    );
  }

  void _move(BuildContext context, List<Txn> txns, {bool? remember}) {
    final s = context.read<AppState>();
    final rule = s.ruleFor(widget.group.rep);
    final rem = remember ?? this.remember;
    s.assign(txns, pick, remember: rem, label: rule?.label ?? '', note: rule?.note ?? '');
    setState(selected.clear);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${txns.length} movimentos movidos para ${s.path(pick)}')));
  }

  Future<void> _details(BuildContext context, List<Txn> txns, Rule? rule) async {
    final s = context.read<AppState>();
    final label = TextEditingController(text: rule?.label ?? '');
    final note = TextEditingController(text: rule?.note ?? '');
    final txNote = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Detalhes do grupo'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: label, decoration: const InputDecoration(labelText: 'Nome amigável (opcional)', hintText: 'Ex.: Ginásio')),
            TextField(controller: note, decoration: const InputDecoration(labelText: 'Descrição da regra (opcional)'), maxLines: 2),
            TextField(controller: txNote, decoration: const InputDecoration(labelText: 'Nota em todos os movimentos (opcional)'), maxLines: 2),
            const SizedBox(height: 8),
            const Text('O nome e a descrição ficam guardados na regra; escolhe a categoria e carrega em “Mover” para os aplicar.', style: TextStyle(fontSize: 12)),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final cid = pick ?? rule?.categoryId;
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
