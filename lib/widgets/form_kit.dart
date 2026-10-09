import 'package:flutter/material.dart';

import '../util/format.dart';

/// Cartão grande e arredondado que agrupa os campos de um formulário.
class FormCard extends StatelessWidget {
  final List<Widget> children;
  const FormCard({super.key, required this.children});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

/// Rótulo por cima de um campo; "(opcional)" a destacar.
class FieldLabel extends StatelessWidget {
  final String text;
  final bool optional;
  const FieldLabel(this.text, {super.key, this.optional = false});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.titleSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w500);
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text.rich(TextSpan(style: style, children: [
        TextSpan(text: text),
        if (optional) TextSpan(text: ' (opcional)', style: TextStyle(color: cs.primary)),
      ])),
    );
  }
}

/// Caixa com contorno, ícone à esquerda e conteúdo; opcionalmente toca-se (data, conta, recibo…).
class TileField extends StatelessWidget {
  final IconData icon;
  final String? title; // linha pequena em cima (ex.: "Conta")
  final Widget? titleWidget; // alternativa a [title]
  final String text; // valor ou sugestão
  final bool isHint;
  final IconData trailing;
  final VoidCallback? onTap;
  const TileField({
    super.key,
    required this.icon,
    this.title,
    this.titleWidget,
    required this.text,
    this.isHint = false,
    this.trailing = Icons.keyboard_arrow_down,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: cs.outlineVariant)),
        child: Row(children: [
          Icon(icon, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              if (titleWidget != null) titleWidget!,
              if (title != null) Text(title!, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (title != null || titleWidget != null ? t.bodySmall : t.bodyLarge)?.copyWith(color: isHint ? cs.onSurfaceVariant : cs.onSurface),
              ),
            ]),
          ),
          Icon(trailing, color: cs.onSurfaceVariant),
        ]),
      ),
    );
  }
}

/// Caixa com contorno para texto livre com ícone ao topo (ex.: descrição).
class BoxField extends StatelessWidget {
  final IconData icon;
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  const BoxField({super.key, required this.icon, required this.controller, required this.hint, this.maxLines = 3, this.maxLength, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: cs.outlineVariant)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon, color: cs.primary)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              minLines: maxLines,
              maxLength: maxLength,
              onChanged: onChanged,
              buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
              decoration: InputDecoration(
                hintText: hint,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
              ),
            ),
          ),
        ]),
      ),
      if (maxLength != null)
        Padding(
          padding: const EdgeInsets.only(top: 4, right: 4),
          child: Align(
            alignment: Alignment.centerRight,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, v, __) => Text('${v.text.length}/$maxLength', style: Theme.of(context).textTheme.bodySmall),
            ),
          ),
        ),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Calculadora simples para o campo de montante
// ---------------------------------------------------------------------------
/// Avalia expressões como "12,5+3*2" (+ - * / e parênteses). Devolve null se inválida.
double? evalExpression(String input) {
  final s = input.replaceAll(' ', '').replaceAll('×', '*').replaceAll('÷', '/').replaceAll('−', '-');
  if (s.isEmpty) return null;
  final p = _ExprParser(s);
  try {
    final v = p.parseExpr();
    if (p.pos != s.length || v.isNaN || v.isInfinite) return null;
    return v;
  } catch (_) {
    return null;
  }
}

class _ExprParser {
  final String s;
  int pos = 0;
  _ExprParser(this.s);

  double parseExpr() {
    var v = parseTerm();
    while (pos < s.length && (s[pos] == '+' || s[pos] == '-')) {
      final op = s[pos++];
      final r = parseTerm();
      v = op == '+' ? v + r : v - r;
    }
    return v;
  }

  double parseTerm() {
    var v = parseFactor();
    while (pos < s.length && (s[pos] == '*' || s[pos] == '/')) {
      final op = s[pos++];
      final r = parseFactor();
      v = op == '*' ? v * r : v / r;
    }
    return v;
  }

  double parseFactor() {
    if (pos < s.length && s[pos] == '-') {
      pos++;
      return -parseFactor();
    }
    if (pos < s.length && s[pos] == '(') {
      pos++;
      final v = parseExpr();
      if (pos >= s.length || s[pos] != ')') throw const FormatException('parêntese');
      pos++;
      return v;
    }
    final start = pos;
    while (pos < s.length && RegExp(r'[0-9.,]').hasMatch(s[pos])) {
      pos++;
    }
    if (start == pos) throw const FormatException('número');
    return double.parse(s.substring(start, pos).replaceAll(',', '.'));
  }
}

/// Abre a calculadora; devolve o resultado em cêntimos ou null.
Future<int?> showCalculator(BuildContext context, {String initial = ''}) {
  final ctrl = TextEditingController(text: initial);
  return showDialog<int>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) {
        final v = evalExpression(ctrl.text);
        void insert(String c) {
          final sel = ctrl.selection;
          final at = sel.isValid ? sel.start : ctrl.text.length;
          ctrl.text = ctrl.text.replaceRange(at, sel.isValid ? sel.end : at, c);
          ctrl.selection = TextSelection.collapsed(offset: at + c.length);
          set(() {});
        }

        return AlertDialog(
          title: const Text('Calculadora'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(hintText: 'Ex.: 12,50+3*2'),
              onChanged: (_) => set(() {}),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              for (final op in ['+', '−', '×', '÷', '(', ')']) OutlinedButton(onPressed: () => insert(op), child: Text(op)),
            ]),
            const SizedBox(height: 12),
            Text(v == null ? '—' : '= ${fmtMoney((v * 100).round())}', style: Theme.of(ctx).textTheme.titleLarge),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(onPressed: v == null ? null : () => Navigator.pop(ctx, (v * 100).round()), child: const Text('Usar')),
          ],
        );
      },
    ),
  );
}

/// Restringe o que se importa a um intervalo de datas. [min]/[max] são as datas do ficheiro.
class DateRangeCard extends StatelessWidget {
  final DateTime min;
  final DateTime max;
  final DateTime? from;
  final DateTime? to;
  final int inRange;
  final int total;
  final void Function(DateTime? from, DateTime? to) onChanged;
  const DateRangeCard({super.key, required this.min, required this.max, required this.from, required this.to, required this.inRange, required this.total, required this.onChanged});

  Future<DateTime?> _pick(BuildContext context, DateTime initial) => showDatePicker(
        context: context,
        initialDate: initial.isBefore(min) ? min : (initial.isAfter(max) ? max : initial),
        firstDate: min.isBefore(DateTime(2000)) ? min : DateTime(2000),
        lastDate: max.isAfter(DateTime(2100)) ? max : DateTime(2100),
      );

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final f = from ?? min, t = to ?? max;
    final restricted = from != null || to != null;
    return FormCard(children: [
      Row(children: [
        Expanded(child: Text('Período a importar', style: tt.titleMedium)),
        if (restricted) TextButton(onPressed: () => onChanged(null, null), child: const Text('Todo o ficheiro')),
      ]),
      Text('O ficheiro tem dados de ${fmtDate(min)} a ${fmtDate(max)}. Escolhe só o intervalo que queres importar.', style: tt.bodySmall),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: TileField(
            icon: Icons.event,
            title: 'De',
            text: fmtDate(f),
            onTap: () async {
              final d = await _pick(context, f);
              if (d != null) onChanged(d, to != null && to!.isBefore(d) ? d : to);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TileField(
            icon: Icons.event,
            title: 'Até',
            text: fmtDate(t),
            onTap: () async {
              final d = await _pick(context, t);
              if (d != null) onChanged(from != null && from!.isAfter(d) ? d : from, d);
            },
          ),
        ),
      ]),
      const SizedBox(height: 10),
      Text(restricted ? '$inRange de $total no período' : '$total no ficheiro', style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
    ]);
  }
}
