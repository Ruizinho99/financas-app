import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/app_state.dart';
import 'category_editor.dart';

/// Escolhe uma categoria ou subcategoria numa só folha, com pesquisa.
/// Devolve o id escolhido, `-1` para "sem categoria" ou `null` se for cancelado.
Future<int?> chooseCategory(
  BuildContext context, {
  int? selected,
  bool? income,
  DateTimeRange? when,
}) {
  return showModalBottomSheet<int>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) =>
        _CategorySheet(selected: selected, income: income, when: when),
  );
}

class _CategorySheet extends StatefulWidget {
  final int? selected;
  final bool? income;
  final DateTimeRange? when;
  const _CategorySheet({this.selected, this.income, this.when});
  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  String q = '';
  bool showAll = false; // inclui categorias terminadas e futuras

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final from = widget.when?.start ?? DateTime.now();
    final to = widget.when?.end ?? from;
    final sel = s.cat(widget.selected);
    final selRoot = sel == null ? null : (sel.parentId ?? sel.id);
    bool visible(Categoria c) =>
        showAll ||
        c.id == widget.selected ||
        c.id == selRoot ||
        s.isCategoryActiveDuring(c, from, to);
    final query = q.trim().toLowerCase();

    final groups = <(Categoria, List<Categoria>)>[];
    for (final r in s.roots.where(
      (r) => widget.income == null || r.both || r.isIncome == widget.income,
    )) {
      final subs = s.childrenOf(r.id).where(visible).toList();
      final rootMatches = r.name.toLowerCase().contains(query);
      final subMatches = subs
          .where((k) => k.name.toLowerCase().contains(query))
          .toList();
      if (!visible(r) && subMatches.isEmpty) continue;
      if (query.isNotEmpty && !rootMatches && subMatches.isEmpty) continue;
      groups.add((r, query.isEmpty || rootMatches ? subs : subMatches));
    }
    final hiddenExist = s.categories.any(
      (c) =>
          !c.archived &&
          c.hasDates &&
          !showAll &&
          !s.isCategoryActiveDuring(c, from, to),
    );

    Widget chip(Categoria c, {bool root = false}) {
      final on = c.id == widget.selected;
      return ChoiceChip(
        selected: on,
        showCheckmark: false,
        avatar: c.emoji.isEmpty ? null : Text(c.emoji),
        label: Text(c.name),
        onSelected: (_) => Navigator.pop(context, c.id),
        labelStyle: root ? const TextStyle(fontWeight: FontWeight.w700) : null,
      );
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Procurar categoria',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => q = v),
            ),
          ),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                for (final (r, subs) in groups) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 4),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        chip(r, root: true),
                        for (final k in subs) chip(k),
                      ],
                    ),
                  ),
                ],
                if (groups.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        s.roots.isEmpty
                            ? 'Ainda não tens categorias. Cria a primeira.'
                            : 'Nenhuma categoria encontrada.',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.add),
                  title: const Text('Nova categoria'),
                  onTap: () async {
                    final id = await showCategoryEditor(context);
                    if (id != null && context.mounted)
                      Navigator.pop(context, id);
                  },
                ),
                if (widget.selected != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.close),
                    title: const Text('Sem categoria'),
                    onTap: () => Navigator.pop(context, -1),
                  ),
                if (hiddenExist || showAll)
                  TextButton(
                    onPressed: () => setState(() => showAll = !showAll),
                    child: Text(
                      showAll
                          ? 'Esconder terminadas e futuras'
                          : 'Mostrar terminadas e futuras',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
