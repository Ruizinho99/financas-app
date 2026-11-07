import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../screens/txn_form_screen.dart';
import '../util/format.dart';
import 'category_icons.dart';
import 'category_picker.dart';
import 'form_kit.dart';

export 'category_editor.dart' show showCategoryEditor;

const palette = <int>[
  0xFF5C6BC0,
  0xFF66BB6A,
  0xFF26A69A,
  0xFFEF5350,
  0xFF8D6E63,
  0xFFFFA726,
  0xFFAB47BC,
  0xFF29B6F6,
  0xFF9CCC65,
  0xFF43A047,
  0xFFEC407A,
  0xFF78909C,
];

/// Emoji da categoria (ou um marcador neutro se ainda não tem).
class CatBadge extends StatelessWidget {
  final Categoria? category;
  final double size;
  const CatBadge(this.category, {super.key, this.size = 22});
  @override
  Widget build(BuildContext context) {
    final e = category?.emoji ?? '';
    if (category == null)
      return Icon(Icons.help_outline, size: size, color: Colors.grey);
    return SizedBox(
      width: size * 1.3,
      child: Center(
        // o emoji escolhido pelo utilizador manda; sem emoji, um ícone de linha pelo nome da categoria
        child: e.isEmpty
            ? Icon(
                categoryIconFor(category!.name),
                size: size,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              )
            : Text(e, style: TextStyle(fontSize: size * 0.9)),
      ),
    );
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
    final color = !colored
        ? null
        : Color(cents < 0 ? st.expenseColor : st.incomeColor);
    return Text(
      fmtMoney(cents),
      style: (style ?? const TextStyle()).copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Barra de progresso de orçamento. Limite: verde → laranja → vermelho; Objetivo: cresce até ao alvo.
class BudgetBar extends StatelessWidget {
  final int spent, target;
  final BudgetType type;
  final double height;
  const BudgetBar({
    super.key,
    required this.spent,
    required this.target,
    required this.type,
    this.height = 10,
  });

  static Color colorFor(BudgetType type, double ratio) {
    if (type == BudgetType.limit) {
      if (ratio > 1) return Colors.red.shade500;
      if (ratio >= 0.85) return Colors.orange.shade600;
      return Colors.green.shade500;
    }
    if (ratio >= 1) return Colors.green.shade600;
    return Colors.amber.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final ratio = target <= 0 ? 0.0 : spent / target;
    final c = colorFor(type, ratio);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Stack(
        children: [
          Container(height: height, color: c.withValues(alpha: 0.18)),
          FractionallySizedBox(
            widthFactor: ratio.clamp(0.0, 1.0),
            child: Container(height: height, color: c),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Seletor de categoria: um só campo com o caminho completo (A › B › C),
// que abre a escolha em árvore (chooseCategory)
// ---------------------------------------------------------------------------
class CategorySelector extends StatelessWidget {
  /// Id da categoria escolhida, a qualquer profundidade (null = nenhuma).
  final int? value;
  final ValueChanged<int?> onChanged;
  final bool compact; // campo mais baixo, para listas
  final bool form; // rótulo por cima e ícone, como nos formulários
  final bool? income; // ignorado: todas as categorias servem para tudo
  /// Intervalo de datas dos movimentos: só mostra categorias que existiam nessa altura
  /// (por omissão, as que existem hoje).
  final DateTimeRange? when;

  /// Categoria sugerida (ex.: pelo nome do movimento) e descrição de onde tirar a sugestão:
  /// passam para o seletor, que as mostra no topo.
  final int? suggestedId;
  final String? description;
  const CategorySelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.compact = false,
    this.form = false,
    this.income,
    this.when,
    this.suggestedId,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final text = s.cat(value) == null ? '' : s.path(value);

    Future<void> open() async {
      final id = await chooseCategory(
        context,
        selected: value,
        income: income,
        when: when,
        suggestedId: suggestedId,
        description: description,
      );
      if (id == null) return;
      onChanged(id == -1 ? null : id);
    }

    final field = InkWell(
      onTap: open,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        isEmpty: text.isEmpty && !form,
        decoration: form
            ? InputDecoration(
                prefixIcon: s.cat(value) == null
                    ? const Icon(Icons.sell_outlined)
                    : CatBadge(s.cat(value), size: 22),
              )
            : InputDecoration(
                labelText: l.frmCategory,
                isDense: compact,
                suffixIcon: const Icon(Icons.arrow_drop_down),
              ),
        child: Row(
          children: [
            // fora do formato "form" o ícone vai dentro do texto; no "form" fica no prefixo
            if (!form && text.isNotEmpty) ...[
              CatBadge(s.cat(value), size: 18),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                text.isEmpty && form ? l.frmSelectCategory : text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.isEmpty && form
                    ? TextStyle(color: cs.onSurfaceVariant)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
    if (form) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [FieldLabel(l.frmCategory), field],
      );
    }
    return field;
  }
}

/// Diálogo com o seletor. Devolve o id, -1 para "sem categoria", ou null se cancelado.
Future<int?> pickCategory(
  BuildContext context, {
  int? selected,
  bool? income,
  bool allowClear = true,
}) {
  final l = AppLocalizations.of(context)!;
  int? v = selected;
  return showDialog<int>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        title: Text(l.frmChooseCategory),
        content: SingleChildScrollView(
          child: CategorySelector(
            value: v,
            income: income,
            onChanged: (x) => set(() => v = x),
          ),
        ),
        actions: [
          if (allowClear)
            TextButton(
              onPressed: () => Navigator.pop(ctx, -1),
              child: Text(l.noCategory),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: v == null ? null : () => Navigator.pop(ctx, v),
            child: Text(l.frmChoose),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Emoji
// ---------------------------------------------------------------------------
const _emojis = <String>[
  '🏠',
  '🔑',
  '💡',
  '💧',
  '🔥',
  '📶',
  '📱',
  '📺',
  '🛒',
  '🥦',
  '🍎',
  '🥩',
  '🐟',
  '🍞',
  '☕',
  '🍽️',
  '🍕',
  '🍔',
  '🍺',
  '🚗',
  '⛽',
  '🚌',
  '🚆',
  '✈️',
  '🚲',
  '🅿️',
  '🛣️',
  '🏥',
  '💊',
  '🦷',
  '👓',
  '🧘',
  '🏋️',
  '⚽',
  '🎬',
  '🎮',
  '🎵',
  '📚',
  '🎓',
  '👕',
  '👟',
  '💄',
  '💇',
  '🛍️',
  '🎁',
  '🧸',
  '👶',
  '🐶',
  '🐱',
  '🌴',
  '🏖️',
  '🏨',
  '🧾',
  '🏦',
  '💳',
  '💰',
  '📈',
  '🪙',
  '🐷',
  '🎯',
  '🛡️',
  '🔧',
  '🧹',
  '🪴',
  '💼',
  '🧑‍💻',
  '📦',
  '❤️',
  '⭐',
  '🏷️',
];

Future<String?> pickEmoji(BuildContext context, String current) {
  final l = AppLocalizations.of(context)!;
  final ctrl = TextEditingController(text: current);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.frmChooseEmoji),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
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
                          color: e == current
                              ? Theme.of(ctx).colorScheme.primaryContainer
                              : null,
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                decoration: InputDecoration(labelText: l.frmOrUseKeyboardEmoji),
                onSubmitted: (v) => Navigator.pop(
                  ctx,
                  v.trim().isEmpty ? '' : v.characters.first,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (current.isNotEmpty)
          TextButton(
            onPressed: () => Navigator.pop(ctx, ''),
            child: Text(l.frmRemove),
          ),
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
        FilledButton(
          onPressed: () => Navigator.pop(
            ctx,
            ctrl.text.trim().isEmpty ? '' : ctrl.text.trim().characters.first,
          ),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Editor de movimento (manual ou existente): ecrã completo
// ---------------------------------------------------------------------------
Future<void> showTxnEditor(BuildContext context, {Txn? edit}) => Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => TxnFormScreen(edit: edit)),
);

// ---------------------------------------------------------------------------
// Escolha de cor: paleta + seletor livre
// ---------------------------------------------------------------------------
class ColorChoice extends StatelessWidget {
  final int color;
  final ValueChanged<int> onChanged;
  final List<int> colors;
  const ColorChoice({
    super.key,
    required this.color,
    required this.onChanged,
    this.colors = palette,
  });

  @override
  Widget build(BuildContext context) {
    final custom = !colors.contains(color);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in colors)
          GestureDetector(
            onTap: () => onChanged(c),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(c),
                shape: BoxShape.circle,
                border: color == c
                    ? Border.all(
                        width: 3,
                        color: Theme.of(context).colorScheme.onSurface,
                      )
                    : null,
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
              gradient: custom
                  ? null
                  : const SweepGradient(
                      colors: [
                        Colors.red,
                        Colors.yellow,
                        Colors.green,
                        Colors.cyan,
                        Colors.blue,
                        Colors.purple,
                        Colors.red,
                      ],
                    ),
              border: custom
                  ? Border.all(
                      width: 3,
                      color: Theme.of(context).colorScheme.onSurface,
                    )
                  : null,
            ),
            child: const Icon(Icons.colorize, size: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

/// Seletor de cor livre (matiz, saturação, brilho ou código hexadecimal).
Future<int?> pickCustomColor(BuildContext context, int initial) {
  final l = AppLocalizations.of(context)!;
  return showDialog<int>(
    context: context,
    builder: (_) {
      var hsv = HSVColor.fromColor(Color(initial));
      final hex = TextEditingController(text: _hex(hsv.toColor()));
      return StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(l.frmChooseColor),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: hsv.toColor(),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 8),
                _slider(
                  l.frmHue,
                  hsv.hue,
                  360,
                  (v) => set(() {
                    hsv = hsv.withHue(v);
                    hex.text = _hex(hsv.toColor());
                  }),
                ),
                _slider(
                  l.frmSaturation,
                  hsv.saturation,
                  1,
                  (v) => set(() {
                    hsv = hsv.withSaturation(v);
                    hex.text = _hex(hsv.toColor());
                  }),
                ),
                _slider(
                  l.frmBrightness,
                  hsv.value,
                  1,
                  (v) => set(() {
                    hsv = hsv.withValue(v);
                    hex.text = _hex(hsv.toColor());
                  }),
                ),
                TextField(
                  controller: hex,
                  decoration: InputDecoration(
                    labelText: l.frmHex,
                    prefixText: '#',
                  ),
                  onChanged: (v) {
                    final n = int.tryParse(v.replaceAll('#', ''), radix: 16);
                    if (n != null && v.replaceAll('#', '').length == 6)
                      set(
                        () => hsv = HSVColor.fromColor(Color(0xFF000000 | n)),
                      );
                  },
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
              onPressed: () => Navigator.pop(ctx, hsv.toColor().toARGB32()),
              child: Text(l.frmUse),
            ),
          ],
        ),
      );
    },
  );
}

String _hex(Color c) =>
    (c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();

Widget _slider(String label, double v, double max, ValueChanged<double> on) =>
    Row(
      children: [
        SizedBox(width: 78, child: Text(label)),
        Expanded(
          child: Slider(value: v.clamp(0, max), max: max, onChanged: on),
        ),
      ],
    );

// ---------------------------------------------------------------------------
// Períodos em que uma categoria é obrigatória
// ---------------------------------------------------------------------------
Future<void> showMandatoryDialog(BuildContext context, Categoria c) {
  return showDialog(
    context: context,
    builder: (_) => _MandatoryDialog(category: c),
  );
}

class _MandatoryDialog extends StatelessWidget {
  final Categoria category;
  const _MandatoryDialog({required this.category});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final l = AppLocalizations.of(context)!;
    final ranges = s.rangesOf(category.id);
    String m(String k) => fmtMonth(
      DateTime(int.parse(k.substring(0, 4)), int.parse(k.substring(5, 7))),
    );
    return AlertDialog(
      title: Text(l.frmMandatoryTitle(category.name)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.frmMandatoryExplain),
            const SizedBox(height: 8),
            if (ranges.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  l.frmNoPeriodDefined,
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            for (final r in ranges)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  r.end == null
                      ? l.frmFromMonth(m(r.start))
                      : (r.start == r.end
                            ? m(r.start)
                            : '${m(r.start)} → ${m(r.end!)}'),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => s.removeRange(r.id),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.frmClose),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.add),
          label: Text(l.frmAddPeriod),
          onPressed: () async {
            final r = await showDialog<(String, String?)>(
              context: context,
              builder: (_) => const _RangePicker(),
            );
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
    final l = AppLocalizations.of(context)!;
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: l.frmPickAnyDayOfMonth,
    );
    return d == null ? null : DateTime(d.year, d.month);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l.frmNewPeriod),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton(
            onPressed: () async {
              final d = await _pick(from);
              if (d != null) setState(() => from = d);
            },
            child: Text(l.frmSinceMonth(fmtMonth(from))),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.frmNoEndDate),
            value: open,
            onChanged: (v) => setState(() => open = v),
          ),
          if (!open)
            OutlinedButton(
              onPressed: () async {
                final d = await _pick(to ?? from);
                if (d != null) setState(() => to = d);
              },
              child: Text(l.frmUntilMonth(fmtMonth(to ?? from))),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () {
            var a = from, b = open ? null : (to ?? from);
            if (b != null && b.isBefore(a)) (a, b) = (b, a);
            Navigator.pop(context, (
              monthKey(a),
              b == null ? null : monthKey(b),
            ));
          },
          child: Text(l.frmAdd),
        ),
      ],
    );
  }
}
