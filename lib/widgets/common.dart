import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../screens/txn_form_screen.dart';
import '../util/format.dart';
import 'form_kit.dart';

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
  final bool form; // rótulos por cima e ícones, como nos formulários
  final bool? income; // filtra rendimentos (true) ou despesas (false)
  /// Intervalo de datas dos movimentos: só mostra categorias que existiam nessa altura
  /// (por omissão, as que existem hoje).
  final DateTimeRange? when;
  const CategorySelector({super.key, required this.value, required this.onChanged, this.compact = false, this.form = false, this.income, this.when});

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  static const _none = -1, _newItem = -2, _toggleAll = -3;
  bool _showAll = false; // incluir categorias fora do período
  int _tick = 0; // força os dropdowns a voltarem ao valor real depois de "Nova…"

  bool _showAllOrVisible(Categoria c, AppState s, DateTime from, DateTime to) => _showAll || s.isCategoryActiveDuring(c, from, to);

  int? get value => widget.value;
  ValueChanged<int?> get onChanged => widget.onChanged;
  bool get compact => widget.compact;
  bool get form => widget.form;
  bool? get income => widget.income;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final chosen = s.cat(value);
    final rootId = chosen == null ? null : (chosen.parentId ?? chosen.id);
    final subId = chosen?.parentId == null ? null : chosen!.id;
    final from = widget.when?.start ?? DateTime.now();
    final to = widget.when?.end ?? from;
    bool visible(Categoria c) {
      if (_showAll || c.id == value || c.id == rootId) return true;
      return s.isCategoryActiveDuring(c, from, to);
    }

    String tag(Categoria c) => (!c.hasDates && !(s.cat(c.parentId)?.hasDates ?? false))
        ? ''
        : (s.isCategoryActiveNow(c) ? '' : ((c.activeTo ?? s.cat(c.parentId)?.activeTo) != null && (c.activeTo ?? s.cat(c.parentId)!.activeTo!).compareTo(monthKey(DateTime.now())) < 0 ? '  · terminada' : '  · futura'));

    final allRoots = s.roots.where((r) => income == null || r.isIncome == income).toList();
    final roots = allRoots.where(visible).toList();
    final subs = rootId == null ? <Categoria>[] : s.childrenOf(rootId).where(visible).toList();
    final hiddenExist = s.categories.any((c) => !c.archived && c.hasDates && !_showAllOrVisible(c, s, from, to));

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
      decoration: form
          ? const InputDecoration(hintText: 'Seleciona uma categoria', prefixIcon: Icon(Icons.sell_outlined))
          : InputDecoration(labelText: 'Categoria', isDense: compact),
      items: [
        for (final r in roots) DropdownMenuItem(value: r.id, child: Text('${r.emoji.isEmpty ? '🏷️' : r.emoji}  ${r.name}${tag(r)}', overflow: TextOverflow.ellipsis)),
        const DropdownMenuItem(value: _newItem, child: Text('➕  Nova categoria…')),
        if (hiddenExist || _showAll) DropdownMenuItem(value: _toggleAll, child: Text(_showAll ? '🙈  Esconder terminadas e futuras' : '👁  Mostrar terminadas e futuras')),
        if (rootId != null) const DropdownMenuItem(value: _none, child: Text('✖️  Sem categoria')),
      ],
      onChanged: (v) {
        if (v == _newItem) {
          createRoot();
        } else if (v == _toggleAll) {
          setState(() {
            _showAll = !_showAll;
            _tick++;
          });
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
      decoration: form
          ? InputDecoration(hintText: 'Seleciona uma subcategoria', prefixIcon: const Icon(Icons.format_list_bulleted), enabled: rootId != null)
          : InputDecoration(labelText: 'Subcategoria', isDense: compact, enabled: rootId != null),
      items: rootId == null
          ? const []
          : [
              for (final k in subs) DropdownMenuItem(value: k.id, child: Text('${k.emoji.isEmpty ? '🏷️' : k.emoji}  ${k.name}${tag(k)}', overflow: TextOverflow.ellipsis)),
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

    if (form) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const FieldLabel('Categoria'),
        catDrop,
        const FieldLabel('Subcategoria', optional: true),
        subDrop,
      ]);
    }
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
              decoration: const InputDecoration(labelText: 'Ou usa outro emoji do teclado'),
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
  late String? activeFrom = widget.edit?.activeFrom;
  late String? activeTo = widget.edit?.activeTo;
  late bool hasDates = widget.edit?.hasDates ?? false;

  Widget _monthTile(String label, String? month, ValueChanged<String> onPick, {bool clearable = true, VoidCallback? onClear}) {
    String txt(String? k) => k == null ? 'Escolher mês' : fmtMonth(DateTime(int.parse(k.substring(0, 4)), int.parse(k.substring(5, 7))));
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final init = month == null ? DateTime.now() : DateTime(int.parse(month.substring(0, 4)), int.parse(month.substring(5, 7)));
        final d = await showDatePicker(context: context, initialDate: init, firstDate: DateTime(2000), lastDate: DateTime(2100), helpText: 'Escolhe qualquer dia do mês');
        if (d != null) onPick(monthKey(d));
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.event), suffixIcon: onClear == null ? null : IconButton(icon: const Icon(Icons.close), onPressed: onClear)),
        child: Text(txt(month)),
      ),
    );
  }

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
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Só existe num período'),
            subtitle: const Text('Ex.: “Férias 2027”. Fora do período deixa de aparecer nas escolhas e no orçamento.'),
            value: hasDates,
            onChanged: (v) => setState(() {
              hasDates = v;
              if (v && activeFrom == null) activeFrom = monthKey(DateTime.now());
            }),
          ),
          if (hasDates) ...[
            _monthTile('Desde', activeFrom, (m) => setState(() => activeFrom = m), clearable: false),
            const SizedBox(height: 8),
            if (activeTo == null)
              Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => setState(() => activeTo = activeFrom ?? monthKey(DateTime.now())), icon: const Icon(Icons.event_busy), label: const Text('Definir fim')))
            else
              _monthTile('Até', activeTo, (m) => setState(() => activeTo = m), onClear: () => setState(() => activeTo = null)),
          ],
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
              activeFrom: hasDates ? activeFrom : null,
              activeTo: hasDates ? (activeTo != null && activeFrom != null && activeTo!.compareTo(activeFrom!) < 0 ? activeFrom : activeTo) : null,
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
// Editor de movimento (manual ou existente): ecrã completo
// ---------------------------------------------------------------------------
Future<void> showTxnEditor(BuildContext context, {Txn? edit}) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => TxnFormScreen(edit: edit)));

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
