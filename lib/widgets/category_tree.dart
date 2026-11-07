import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/app_state.dart';

/// Árvore expansível de categorias com caixas, a qualquer profundidade.
/// Escolher uma categoria inclui tudo o que está dentro dela (as descendentes ficam
/// marcadas e bloqueadas); uma categoria com só algumas descendentes escolhidas fica "meio marcada".
class CategoryTreeChecks extends StatelessWidget {
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;
  const CategoryTreeChecks({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final r in s.roots) _node(context, s, r, covered: false)],
    );
  }

  Widget _node(
    BuildContext context,
    AppState s,
    Categoria c, {
    required bool covered, // uma antecessora já está escolhida
  }) {
    final kids = s.childrenOf(c.id);
    final own = selected.contains(c.id);
    final on = covered || own;
    final partial = !on && kids.any((k) => _touched(s, k));
    final title = Text('${c.emoji.isEmpty ? '🏷️' : c.emoji}  ${c.name}');

    void toggle() {
      final next = {...selected};
      if (own || partial) {
        next.remove(c.id);
        for (final d in s.descendantsOf(c.id)) {
          next.remove(d.id);
        }
      } else {
        next.add(c.id);
        for (final d in s.descendantsOf(c.id)) {
          next.remove(d.id);
        }
      }
      onChanged(next);
    }

    final box = Checkbox(
      key: ValueKey('tree-check-${c.id}'),
      value: on ? true : (partial ? null : false),
      tristate: true,
      onChanged: covered ? null : (_) => toggle(),
    );
    if (kids.isEmpty) {
      return ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: box,
        title: title,
        onTap: covered ? null : toggle,
      );
    }
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: PageStorageKey('tree-${c.id}'),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(left: 24),
        initiallyExpanded: partial,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: box,
        title: title,
        children: [for (final k in kids) _node(context, s, k, covered: on)],
      ),
    );
  }

  /// Esta categoria ou alguma das suas descendentes está escolhida.
  bool _touched(AppState s, Categoria c) =>
      selected.contains(c.id) || s.childrenOf(c.id).any((k) => _touched(s, k));
}
