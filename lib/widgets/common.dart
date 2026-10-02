import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';

const palette = <int>[
  0xFF5C6BC0, 0xFF66BB6A, 0xFF26A69A, 0xFFEF5350, 0xFF8D6E63, 0xFFFFA726,
  0xFFAB47BC, 0xFF29B6F6, 0xFF9CCC65, 0xFF43A047, 0xFFEC407A, 0xFF78909C,
];

/// Emoji da categoria (ou um marcador neutro se ainda não tem).
class CatBadge extends StatelessWidget {
  final Categoria? category;
  final double size;
  const CatBadge(this.category, {super.key, this.size = 22});
  @override
  Widget build(BuildContext context) {
    final e = category?.emoji ?? '';
    if (category == null) return Icon(Icons.help_outline, size: size, color: Colors.grey);
    return SizedBox(width: size * 1.3, child: Center(child: Text(e.isEmpty ? '🏷️' : e, style: TextStyle(fontSize: size * 0.9))));
  }
}

class MoneyText extends StatelessWidget {
  final int cents;
  final TextStyle? style;
  final bool colored;
  const MoneyText(this.cents, {super.key, this.style, this.colored = true});
  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final color = !colored ? null : Color(cents < 0 ? st.expenseColor : st.incomeColor);
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
// Seletor de categoria: dois dropdowns ligados (categoria → subcategoria)
// ---------------------------------------------------------------------------
class CategorySelector extends StatefulWidget {
  /// Id da categoria ou subcategoria escolhida (null = nenhuma).
  final int? value;
  final ValueChanged<int?> onChanged;
  final bool compact; // lado a lado, para listas
  final bool? income; // filtra rendimentos (true) ou despesas (false)
  const CategorySelector({super.key, required this.value, required this.onChanged, this.compact = false, this.income});

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  static const _none = -1, _newItem = -2;
  int _tick = 0; // força os dropdowns a voltarem ao valor real depois de "Nova…"

  int? get value => widget.value;
  ValueChanged<int?> get onChanged => widget.onChanged;
  bool get compact => widget.compact;
  bool? get income => widget.income;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final chosen = s.cat(value);
    final rootId = chosen == null ? null : (chosen.parentId ?? chosen.id);
    final subId = chosen?.parentId == null ? null : chosen!.id;
    final roots = s.roots.where((r) => income == null || r.isIncome == income).toList();
    final subs = rootId == null ? <Categoria>[] : s.childrenOf(rootId);

    Future<void> createRoot() async {
      final id = await showCategoryEditor(context);
      if (!mounted) return;
      setState(() => _tick++);
      if (id != null) onChanged(id);
    }

    Future<void> createSub() async {
      final id = await showCategoryEditor(context, parentId: rootId);
      if (!mounted) return;
      setState(() => _tick++);
      if (id != null) onChanged(id);
    }

    final catDrop = DropdownButtonFormField<int>(
      key: ValueKey('cat-$rootId-${roots.length}-$_tick'),
      initialValue: rootId,
      isExpanded: true,
      decoration: InputDecoration(labelText: 'Categoria', border: const OutlineInputBorder(), isDense: compact),
      items: [
        for (final r in roots) DropdownMenuItem(value: r.id, child: Text('${r.emoji.isEmpty ? '🏷️' : r.emoji}  ${r.name}', overflow: TextOverflow.ellipsis)),
        const DropdownMenuItem(value: _newItem, child: Text('➕  Nova categoria…')),
        if (rootId != null) const DropdownMenuItem(value: _none, child: Text('✖️  Sem categoria')),
      ],
      onChanged: (v) {
        if (v == _newItem) {
          createRoot();
        } else if (v == _none) {
          onChanged(null);
        } else if (v != rootId) {
          onChanged(v);
        }
      },
    );

    final subDrop = DropdownButtonFormField<int>(
      key: ValueKey('sub-$rootId-$subId-${subs.length}-$_tick'),
      initialValue: subId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Subcategoria',
        border: const OutlineInputBorder(),
        isDense: compact,
        enabled: rootId != null,
      ),
      items: rootId == null
          ? const []
          : [
              for (final k in subs) DropdownMenuItem(value: k.id, child: Text('${k.emoji.isEmpty ? '🏷️' : k.emoji}  ${k.name}', overflow: TextOverflow.ellipsis)),
              const DropdownMenuItem(value: _newItem, child: Text('➕  Nova subcategoria…')),
              if (subId != null) const DropdownMenuItem(value: _none, child: Text('— Sem subcategoria —')),
            ],
      onChanged: rootId == null
          ? null
          : (v) {
              if (v == _newItem) {
                createSub();
              } else if (v == _none) {
                onChanged(rootId);
              } else {
                onChanged(v);
              }
            },
    );

    if (compact) {
      return Row(children: [Expanded(child: catDrop), const SizedBox(width: 8), Expanded(child: subDrop)]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [catDrop, const SizedBox(height: 12), subDrop]);
  }
}

/// Diálogo com o seletor. Devolve o id, -1 para "sem categoria", ou null se cancelado.
Future<int?> pickCategory(BuildContext context, {int? selected, bool? income, bool allowClear = true}) {
  int? v = selected;
  return showDialog<int>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        title: const Text('Escolher categoria'),
        content: SingleChildScrollView(child: CategorySelector(value: v, income: income, onChanged: (x) => set(() => v = x))),
        actions: [
          if (allowClear) TextButton(onPressed: () => Navigator.pop(ctx, -1), child: const Text('Sem categoria')),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: v == null ? null : () => Navigator.pop(ctx, v), child: const Text('Escolher')),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Emoji
// ---------------------------------------------------------------------------
const _emojis = <String>[
  '🏠', '🔑', '💡', '💧', '🔥', '📶', '📱', '📺', '🛒', '🥦', '🍎', '🥩', '🐟', '🍞', '☕', '🍽️',
  '🍕', '🍔', '🍺', '🚗', '⛽', '🚌', '🚆', '✈️', '🚲', '🅿️', '🛣️', '🏥', '💊', '🦷', '👓', '🧘',
  '🏋️', '⚽', '🎬', '🎮', '🎵', '📚', '🎓', '👕', '👟', '💄', '💇', '🛍️', '🎁', '🧸', '👶', '🐶',
  '🐱', '🌴', '🏖️', '🏨', '🧾', '🏦', '💳', '💰', '📈', '🪙', '🐷', '🎯', '🛡️', '🔧', '🧹', '🪴',
  '💼', '🧑‍💻', '📦', '❤️', '⭐', '🏷️',
];

Future<String?> pickEmoji(BuildContext context, String current) {
  final ctrl = TextEditingController(text: current);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Escolher emoji'),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Wrap(spacing: 4, runSpacing: 4, children: [
              for (final e in _emojis)
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Navigator.pop(ctx, e),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: e == current ? Theme.of(ctx).colorScheme.primaryContainer : null,
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 24)),
                  ),
                ),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(labelText: 'Ou usa outro emoji do teclado', border: OutlineInputBorder()),
              onSubmitted: (v) => Navigator.pop(ctx, v.trim().isEmpty ? '' : v.characters.first),
            ),
          ]),
        ),
      ),
      actions: [
        if (current.isNotEmpty) TextButton(onPressed: () => Navigator.pop(ctx, ''), child: const Text('Remover')),
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim().isEmpty ? '' : ctrl.text.trim().characters.first), child: const Text('OK')),
      ],
    ),
  );
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
  late bool income = widget.edit?.isIncome ?? false;
  late String emoji = widget.edit?.emoji ?? '';

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
          Row(children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final e = await pickEmoji(context, emoji);
                if (e != null) setState(() => emoji = e);
              },
              child: Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(12)),
                child: Text(emoji.isEmpty ? '🙂' : emoji, style: TextStyle(fontSize: 28, color: emoji.isEmpty ? Colors.grey : null)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: name, autofocus: true, decoration: const InputDecoration(labelText: 'Nome'))),
          ]),
          const SizedBox(height: 8),
          DropdownButtonFormField<int?>(
            initialValue: parent,
            decoration: const InputDecoration(labelText: 'Categoria-mãe'),
            items: [
              const DropdownMenuItem(value: null, child: Text('— Nenhuma (categoria principal) —')),
              if (!hasKids) ...roots.map((r) => DropdownMenuItem(value: r.id, child: Text('${r.emoji} ${r.name}'.trim()))),
            ],
            onChanged: (v) => setState(() {
              parent = v;
              final p = s.cat(v);
              if (p != null) income = p.isIncome;
            }),
          ),
          if (parentCat == null)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Rendimento'),
              subtitle: const Text('Entradas de dinheiro (salário, etc.), não conta como despesa'),
              value: income,
              onChanged: (v) => setState(() => income = v),
            ),
          if (widget.edit != null && !income)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_repeat),
              title: const Text('Obrigatória em…'),
              subtitle: Text(() {
                final n = s.rangesOf(widget.edit!.id).length;
                return n == 0 ? 'Opcional em todos os meses' : '$n período(s) definido(s)';
              }()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await showMandatoryDialog(context, widget.edit!);
                setState(() {});
              },
            ),
          TextField(controller: desc, decoration: const InputDecoration(labelText: 'Descrição (opcional)'), maxLines: 2),
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
              isIncome: income,
              emoji: emoji,
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
          CategorySelector(value: categoryId, onChanged: (v) => setState(() => categoryId = v)),
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

// ---------------------------------------------------------------------------
// Escolha de cor: paleta + seletor livre
// ---------------------------------------------------------------------------
class ColorChoice extends StatelessWidget {
  final int color;
  final ValueChanged<int> onChanged;
  final List<int> colors;
  const ColorChoice({super.key, required this.color, required this.onChanged, this.colors = palette});

  @override
  Widget build(BuildContext context) {
    final custom = !colors.contains(color);
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final c in colors)
        GestureDetector(
          onTap: () => onChanged(c),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Color(c),
              shape: BoxShape.circle,
              border: color == c ? Border.all(width: 3, color: Theme.of(context).colorScheme.onSurface) : null,
            ),
          ),
        ),
      GestureDetector(
        onTap: () async {
          final c = await pickCustomColor(context, color);
          if (c != null) onChanged(c);
        },
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: custom ? Color(color) : null,
            gradient: custom ? null : const SweepGradient(colors: [Colors.red, Colors.yellow, Colors.green, Colors.cyan, Colors.blue, Colors.purple, Colors.red]),
            border: custom ? Border.all(width: 3, color: Theme.of(context).colorScheme.onSurface) : null,
          ),
          child: const Icon(Icons.colorize, size: 16, color: Colors.white),
        ),
      ),
    ]);
  }
}

/// Seletor de cor livre (matiz, saturação, brilho ou código hexadecimal).
Future<int?> pickCustomColor(BuildContext context, int initial) {
  return showDialog<int>(
    context: context,
    builder: (_) {
      var hsv = HSVColor.fromColor(Color(initial));
      final hex = TextEditingController(text: _hex(hsv.toColor()));
      return StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Escolher cor'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(height: 56, decoration: BoxDecoration(color: hsv.toColor(), borderRadius: BorderRadius.circular(12))),
              const SizedBox(height: 8),
              _slider('Matiz', hsv.hue, 360, (v) => set(() { hsv = hsv.withHue(v); hex.text = _hex(hsv.toColor()); })),
              _slider('Saturação', hsv.saturation, 1, (v) => set(() { hsv = hsv.withSaturation(v); hex.text = _hex(hsv.toColor()); })),
              _slider('Brilho', hsv.value, 1, (v) => set(() { hsv = hsv.withValue(v); hex.text = _hex(hsv.toColor()); })),
              TextField(
                controller: hex,
                decoration: const InputDecoration(labelText: 'Hexadecimal', prefixText: '#'),
                onChanged: (v) {
                  final n = int.tryParse(v.replaceAll('#', ''), radix: 16);
                  if (n != null && v.replaceAll('#', '').length == 6) set(() => hsv = HSVColor.fromColor(Color(0xFF000000 | n)));
                },
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, hsv.toColor().toARGB32()), child: const Text('Usar')),
          ],
        ),
      );
    },
  );
}

String _hex(Color c) => (c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();

Widget _slider(String label, double v, double max, ValueChanged<double> on) => Row(children: [
      SizedBox(width: 78, child: Text(label)),
      Expanded(child: Slider(value: v.clamp(0, max), max: max, onChanged: on)),
    ]);

// ---------------------------------------------------------------------------
// Períodos em que uma categoria é obrigatória
// ---------------------------------------------------------------------------
Future<void> showMandatoryDialog(BuildContext context, Categoria c) {
  return showDialog(context: context, builder: (_) => _MandatoryDialog(category: c));
}

class _MandatoryDialog extends StatelessWidget {
  final Categoria category;
  const _MandatoryDialog({required this.category});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final ranges = s.rangesOf(category.id);
    String m(String k) => fmtMonth(DateTime(int.parse(k.substring(0, 4)), int.parse(k.substring(5, 7))));
    return AlertDialog(
      title: Text('Obrigatória · ${category.name}'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Os meses abaixo contam como despesa obrigatória nesta categoria. Nos restantes meses é opcional.'),
          const SizedBox(height: 8),
          if (ranges.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Nenhum período definido.', style: TextStyle(fontStyle: FontStyle.italic))),
          for (final r in ranges)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(r.end == null ? 'A partir de ${m(r.start)}' : (r.start == r.end ? m(r.start) : '${m(r.start)} → ${m(r.end!)}')),
              trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => s.removeRange(r.id)),
            ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
        FilledButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Adicionar período'),
          onPressed: () async {
            final r = await showDialog<(String, String?)>(context: context, builder: (_) => const _RangePicker());
            if (r != null) s.addRange(category.id, r.$1, r.$2);
          },
        ),
      ],
    );
  }
}

class _RangePicker extends StatefulWidget {
  const _RangePicker();
  @override
  State<_RangePicker> createState() => _RangePickerState();
}

class _RangePickerState extends State<_RangePicker> {
  DateTime from = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? to;
  bool open = false;

  Future<DateTime?> _pick(DateTime initial) async {
    final d = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2000), lastDate: DateTime(2100), helpText: 'Escolhe qualquer dia do mês');
    return d == null ? null : DateTime(d.year, d.month);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo período'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        OutlinedButton(onPressed: () async { final d = await _pick(from); if (d != null) setState(() => from = d); }, child: Text('Desde ${fmtMonth(from)}')),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Sem data de fim'), value: open, onChanged: (v) => setState(() => open = v)),
        if (!open)
          OutlinedButton(
            onPressed: () async { final d = await _pick(to ?? from); if (d != null) setState(() => to = d); },
            child: Text('Até ${fmtMonth(to ?? from)}'),
          ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            var a = from, b = open ? null : (to ?? from);
            if (b != null && b.isBefore(a)) (a, b) = (b, a);
            Navigator.pop(context, (monthKey(a), b == null ? null : monthKey(b)));
          },
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}
