import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import '../widgets/common.dart';
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

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final g = widget.group;
    final rule = s.ruleFor(g.key);
    final txns = g.txns;
    final dates = txns.map((t) => t.date).toList()..sort();
    // distribuição por categoria
    final dist = <int?, int>{};
    for (final t in txns) {
      dist[t.categoryId] = (dist[t.categoryId] ?? 0) + 1;
    }
    final title = (rule != null && rule.label.isNotEmpty) ? rule.label : g.key;

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
                    avatar: e.key == null ? const Icon(Icons.help_outline, size: 16) : Dot(s.cat(e.key)?.color ?? 0xFF9E9E9E, size: 10),
                    label: Text('${s.path(e.key)} · ${e.value}'),
                  ),
                if (rule != null)
                  const Chip(visualDensity: VisualDensity.compact, avatar: Icon(Icons.push_pin, size: 14), label: Text('Memorizado')),
              ]),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Wrap(children: [
            TextButton.icon(
              icon: const Icon(Icons.drive_file_move_outline),
              label: Text('Mover todas (${txns.length})'),
              onPressed: () => _move(context, txns, defaultRemember: true),
            ),
            TextButton.icon(
              icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
              label: Text(expanded ? 'Fechar' : 'Ver movimentos'),
              onPressed: () => setState(() => expanded = !expanded),
            ),
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
                  onPressed: () => _move(context, txns.where((t) => selected.contains(t.id)).toList(), defaultRemember: false),
                  child: const Text('Mover selecionados'),
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
          if (rule != null)
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

  Future<void> _move(BuildContext context, List<Txn> txns, {required bool defaultRemember}) async {
    final s = context.read<AppState>();
    final rule = s.ruleFor(widget.group.key);
    final result = await showDialog<_MoveResult>(
      context: context,
      builder: (_) => _MoveDialog(count: txns.length, remember: defaultRemember, label: rule?.label ?? '', note: rule?.note ?? ''),
    );
    if (result == null) return;
    s.assign(txns, result.categoryId, remember: result.remember, label: result.label, note: result.note);
    if (result.noteForTxns.isNotEmpty) s.setNote(txns.map((t) => t.id).toList(), result.noteForTxns);
    setState(selected.clear);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${txns.length} movimentos movidos para ${s.path(result.categoryId)}')));
    }
  }
}

class _MoveResult {
  final int categoryId;
  final bool remember;
  final String label, note, noteForTxns;
  _MoveResult(this.categoryId, this.remember, this.label, this.note, this.noteForTxns);
}

class _MoveDialog extends StatefulWidget {
  final int count;
  final bool remember;
  final String label, note;
  const _MoveDialog({required this.count, required this.remember, required this.label, required this.note});
  @override
  State<_MoveDialog> createState() => _MoveDialogState();
}

class _MoveDialogState extends State<_MoveDialog> {
  int? cat;
  late bool remember = widget.remember;
  late final label = TextEditingController(text: widget.label);
  late final note = TextEditingController(text: widget.note);
  final txNote = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    return AlertDialog(
      title: Text('Mover ${widget.count} movimentos'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.folder_open),
            label: Align(alignment: Alignment.centerLeft, child: Text(cat == null ? 'Escolher categoria…' : s.path(cat))),
            onPressed: () async {
              final id = await pickCategory(context, selected: cat, allowClear: false);
              if (id != null && id != -1) setState(() => cat = id);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Memorizar para futuros'),
            subtitle: const Text('Novos movimentos com este nome vão automaticamente para esta categoria'),
            value: remember,
            onChanged: (v) => setState(() => remember = v),
          ),
          if (remember) ...[
            TextField(controller: label, decoration: const InputDecoration(labelText: 'Nome amigável (opcional)', hintText: 'Ex.: Ginásio')),
            TextField(controller: note, decoration: const InputDecoration(labelText: 'Descrição da regra (opcional)'), maxLines: 2),
          ],
          TextField(controller: txNote, decoration: const InputDecoration(labelText: 'Nota nestes movimentos (opcional)'), maxLines: 2),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: cat == null ? null : () => Navigator.pop(context, _MoveResult(cat!, remember, label.text.trim(), note.text.trim(), txNote.text.trim())),
          child: const Text('Mover'),
        ),
      ],
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
                  leading: Dot(s.cat(r.categoryId)?.color ?? 0xFF9E9E9E, size: 14),
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
              OutlinedButton.icon(
                icon: const Icon(Icons.folder_open),
                label: Text(cat == null ? 'Escolher categoria…' : s.path(cat)),
                onPressed: () async {
                  final id = await pickCategory(ctx, selected: cat, allowClear: false);
                  if (id != null && id != -1) set(() => cat = id);
                },
              ),
              TextField(controller: label, decoration: const InputDecoration(labelText: 'Nome amigável (opcional)')),
              TextField(controller: note, decoration: const InputDecoration(labelText: 'Descrição (opcional)'), maxLines: 2),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (pattern.text.trim().isEmpty || cat == null) return;
                s.saveRule(pattern.text.trim().toUpperCase(), cat!, exact: exact, label: label.text.trim(), note: note.text.trim());
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
