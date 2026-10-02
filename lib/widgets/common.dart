import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';

const palette = <int>[
  0xFF5C6BC0, 0xFF66BB6A, 0xFF26A69A, 0xFFEF5350, 0xFF8D6E63, 0xFFFFA726,
  0xFFAB47BC, 0xFF29B6F6, 0xFF9CCC65, 0xFF43A047, 0xFFEC407A, 0xFF78909C,
];

class Dot extends StatelessWidget {
  final int color;
  final double size;
  const Dot(this.color, {super.key, this.size = 12});
  @override
  Widget build(BuildContext context) =>
      Container(width: size, height: size, decoration: BoxDecoration(color: Color(color), shape: BoxShape.circle));
}

class MoneyText extends StatelessWidget {
  final int cents;
  final TextStyle? style;
  final bool colored;
  const MoneyText(this.cents, {super.key, this.style, this.colored = true});
  @override
  Widget build(BuildContext context) {
    final color = !colored ? null : (cents < 0 ? Colors.red.shade400 : Colors.green.shade500);
    return Text(fmtMoney(cents), style: (style ?? const TextStyle()).copyWith(color: color, fontWeight: FontWeight.w600));
  }
}

/// Barra de progresso de orçamento. Limite: verde → laranja → vermelho; Objetivo: cresce até ao alvo.
class BudgetBar extends StatelessWidget {
  final int spent, target;
  final BudgetType type;
  final double height;
  const BudgetBar({super.key, required this.spent, required this.target, required this.type, this.height = 10});

  static Color colorFor(BudgetType type, double ratio) {
    if (type == BudgetType.limit) {
      if (ratio > 1) return Colors.red.shade500;
      if (ratio >= 0.85) return Colors.orange.shade600;
      return Colors.green.shade500;
    }
    if (ratio >= 1) return Colors.green.shade600;
    if (ratio >= 0.5) return Colors.lightBlue.shade500;
    return Colors.amber.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final ratio = target <= 0 ? 0.0 : spent / target;
    final c = colorFor(type, ratio);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Stack(children: [
        Container(height: height, color: c.withValues(alpha: 0.18)),
        FractionallySizedBox(
          widthFactor: ratio.clamp(0.0, 1.0),
          child: Container(height: height, color: c),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Escolher categoria (hierárquico, com pesquisa e criação rápida)
// ---------------------------------------------------------------------------
/// Devolve o id escolhido, -1 para "sem categoria", ou null se cancelado.
Future<int?> pickCategory(BuildContext context, {int? selected, bool? income, bool allowClear = true}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _CategoryPicker(selected: selected, income: income, allowClear: allowClear),
  );
}

class _CategoryPicker extends StatefulWidget {
  final int? selected;
  final bool? income;
  final bool allowClear;
  const _CategoryPicker({this.selected, this.income, required this.allowClear});
  @override
  State<_CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<_CategoryPicker> {
  String q = '';
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final query = q.toLowerCase();
    final tiles = <Widget>[];
    for (final r in s.roots) {
      final kids = s.childrenOf(r.id);
      final rootMatch = r.name.toLowerCase().contains(query);
      final shownKids = kids.where((k) => rootMatch || k.name.toLowerCase().contains(query)).toList();
      if (!rootMatch && shownKids.isEmpty) continue;
      tiles.add(ListTile(
        leading: Dot(r.color),
        title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(r.isIncome ? 'Rendimento' : (r.mandatory ? 'Obrigatória' : 'Opcional')),
        selected: widget.selected == r.id,
        trailing: IconButton(
          tooltip: 'Nova subcategoria',
          icon: const Icon(Icons.add),
          onPressed: () async {
            final id = await showCategoryEditor(context, parentId: r.id);
            if (id != null && context.mounted) Navigator.pop(context, id);
          },
        ),
        onTap: () => Navigator.pop(context, r.id),
      ));
      for (final k in shownKids) {
        tiles.add(ListTile(
          contentPadding: const EdgeInsets.only(left: 56, right: 16),
          leading: Dot(k.color, size: 8),
          title: Text(k.name),
          selected: widget.selected == k.id,
          onTap: () => Navigator.pop(context, k.id),
        ));
      }
    }
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (_, controller) => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            autofocus: false,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Pesquisar categoria', border: OutlineInputBorder()),
            onChanged: (v) => setState(() => q = v),
          ),
        ),
        Expanded(child: ListView(controller: controller, children: tiles)),
        SafeArea(
          child: Row(children: [
            if (widget.allowClear)
              TextButton.icon(
                  onPressed: () => Navigator.pop(context, -1),
                  icon: const Icon(Icons.label_off_outlined),
                  label: const Text('Sem categoria')),
            const Spacer(),
            TextButton.icon(
              onPressed: () async {
                final id = await showCategoryEditor(context);
                if (id != null && context.mounted) Navigator.pop(context, id);
              },
              icon: const Icon(Icons.create_new_folder_outlined),
              label: const Text('Nova categoria'),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Editor de categoria
// ---------------------------------------------------------------------------
/// Cria ou edita uma categoria/subcategoria. Devolve o id.
Future<int?> showCategoryEditor(BuildContext context, {Categoria? edit, int? parentId}) {
  return showDialog<int>(
    context: context,
    builder: (_) => _CategoryEditor(edit: edit, parentId: parentId ?? edit?.parentId),
  );
}

class _CategoryEditor extends StatefulWidget {
  final Categoria? edit;
  final int? parentId;
  const _CategoryEditor({this.edit, this.parentId});
  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  late final name = TextEditingController(text: widget.edit?.name ?? '');
  late final desc = TextEditingController(text: widget.edit?.description ?? '');
  late int? parent = widget.parentId;
  late bool mandatory = widget.edit?.mandatory ?? false;
  late bool income = widget.edit?.isIncome ?? false;
  late int color = widget.edit?.color ?? palette[DateTime.now().millisecond % palette.length];

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final roots = s.roots.where((r) => r.id != widget.edit?.id).toList();
    final hasKids = widget.edit != null && s.childrenOf(widget.edit!.id).isNotEmpty;
    final parentCat = s.cat(parent);
    return AlertDialog(
      title: Text(widget.edit == null ? (parent == null ? 'Nova categoria' : 'Nova subcategoria') : 'Editar categoria'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, autofocus: true, decoration: const InputDecoration(labelText: 'Nome')),
          const SizedBox(height: 8),
          DropdownButtonFormField<int?>(
            initialValue: parent,
            decoration: const InputDecoration(labelText: 'Categoria-mãe'),
            items: [
              const DropdownMenuItem(value: null, child: Text('— Nenhuma (categoria principal) —')),
              if (!hasKids) ...roots.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))),
            ],
            onChanged: (v) => setState(() {
              parent = v;
              final p = s.cat(v);
              if (p != null) {
                mandatory = p.mandatory;
                income = p.isIncome;
                color = p.color;
              }
            }),
          ),
          if (parentCat == null) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Obrigatória'),
              subtitle: const Text('Despesa que tenho todos os meses (casa, alimentação, tarifários…)'),
              value: mandatory,
              onChanged: income ? null : (v) => setState(() => mandatory = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Rendimento'),
              value: income,
              onChanged: (v) => setState(() {
                income = v;
                if (v) mandatory = false;
              }),
            ),
          ] else
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Obrigatória'),
              subtitle: Text('Por omissão herda de “${parentCat.name}”'),
              value: mandatory,
              onChanged: income ? null : (v) => setState(() => mandatory = v),
            ),
          TextField(controller: desc, decoration: const InputDecoration(labelText: 'Descrição (opcional)'), maxLines: 2),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in palette)
              GestureDetector(
                onTap: () => setState(() => color = c),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: color == c ? Border.all(width: 3, color: Theme.of(context).colorScheme.onSurface) : null,
                  ),
                ),
              ),
          ]),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            final n = name.text.trim();
            if (n.isEmpty) return;
            final e = widget.edit;
            final cat = Categoria(
              id: e?.id ?? 0,
              name: n,
              parentId: parent,
              mandatory: income ? false : mandatory,
              isIncome: income,
              color: color,
              description: desc.text.trim(),
              budgetType: e?.budgetType ?? (income ? BudgetType.goal : BudgetType.limit),
              budgetPercent: e?.budgetPercent ?? false,
              budgetValue: e?.budgetValue ?? 0,
              hasBudget: e?.hasBudget ?? false,
              archived: e?.archived ?? false,
            );
            if (e == null) {
              Navigator.pop(context, s.addCategory(cat));
            } else {
              s.updateCategory(cat);
              Navigator.pop(context, e.id);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Editor de movimento (manual ou existente)
// ---------------------------------------------------------------------------
Future<void> showTxnEditor(BuildContext context, {Txn? edit}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _TxnEditor(edit: edit),
  );
}

class _TxnEditor extends StatefulWidget {
  final Txn? edit;
  const _TxnEditor({this.edit});
  @override
  State<_TxnEditor> createState() => _TxnEditorState();
}

class _TxnEditorState extends State<_TxnEditor> {
  late DateTime date = widget.edit?.date ?? DateTime.now();
  late final desc = TextEditingController(text: widget.edit?.description ?? '');
  late final amount = TextEditingController(
      text: widget.edit == null ? '' : (widget.edit!.amount.abs() / 100).toStringAsFixed(2).replaceAll('.', ','));
  late final note = TextEditingController(text: widget.edit?.note ?? '');
  late bool expense = (widget.edit?.amount ?? -1) < 0;
  late int? categoryId = widget.edit?.categoryId;
  String? error;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(widget.edit == null ? 'Novo movimento' : 'Editar movimento', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Despesa'), icon: Icon(Icons.arrow_downward)),
              ButtonSegment(value: false, label: Text('Receita'), icon: Icon(Icons.arrow_upward)),
            ],
            selected: {expense},
            onSelectionChanged: (v) => setState(() => expense = v.first),
          ),
          const SizedBox(height: 12),
          TextField(controller: desc, decoration: const InputDecoration(labelText: 'Descrição', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Montante (€)', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(fmtDate(date)),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                onPressed: () async {
                  final d = await showDatePicker(
                      context: context, initialDate: date, firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (d != null) setState(() => date = d);
                },
              ),
            ),
          ]),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.folder_open),
            label: Align(alignment: Alignment.centerLeft, child: Text(s.path(categoryId))),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            onPressed: () async {
              final id = await pickCategory(context, selected: categoryId);
              if (id != null) setState(() => categoryId = id == -1 ? null : id);
            },
          ),
          const SizedBox(height: 12),
          TextField(controller: note, decoration: const InputDecoration(labelText: 'Nota (opcional)', border: OutlineInputBorder()), maxLines: 2),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 16),
          Row(children: [
            if (widget.edit != null)
              TextButton.icon(
                onPressed: () {
                  s.deleteTxns([widget.edit!.id]);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Apagar'),
              ),
            const Spacer(),
            FilledButton(
              onPressed: () {
                final v = parseCents(amount.text);
                if (desc.text.trim().isEmpty || v == null || v == 0) {
                  setState(() => error = 'Indica descrição e montante válidos.');
                  return;
                }
                final cents = expense ? -v.abs() : v.abs();
                final e = widget.edit;
                if (e == null) {
                  s.addManual(date: date, description: desc.text.trim(), amount: cents, categoryId: categoryId, note: note.text.trim());
                } else {
                  s.updateTxn(Txn(
                    id: e.id,
                    date: date,
                    description: desc.text.trim(),
                    amount: cents,
                    balance: e.balance,
                    categoryId: categoryId,
                    note: note.text.trim(),
                    source: e.source,
                    merchantKey: e.merchantKey,
                    importId: e.importId,
                  ));
                }
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ]),
        ]),
      ),
    );
  }
}
