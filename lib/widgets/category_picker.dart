import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models.dart';
import '../state/app_state.dart';
import 'category_editor.dart';

/// Escolhe uma categoria numa só folha, com pesquisa, a navegar pela árvore em
/// qualquer profundidade (A › B › C › ...).
/// Devolve o id escolhido, `-1` para "sem categoria" ou `null` se for cancelado.
/// [allowNew] esconde "Nova categoria" (ex.: em filtros, onde só se escolhe o que existe).
Future<int?> chooseCategory(
  BuildContext context, {
  int? selected,
  bool? income,
  DateTimeRange? when,
  bool allowNew = true,
}) {
  return showModalBottomSheet<int>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _CategorySheet(
      selected: selected,
      income: income,
      when: when,
      allowNew: allowNew,
    ),
  );
}

class _CategorySheet extends StatefulWidget {
  final int? selected;
  final bool? income;
  final DateTimeRange? when;
  final bool allowNew;
  const _CategorySheet({
    this.selected,
    this.income,
    this.when,
    this.allowNew = true,
  });
  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  String q = '';
  bool showAll = false; // inclui categorias terminadas e futuras
  int? level; // categoria cujo conteúdo se mostra (null = o nível das principais)
  bool _init = false;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final l = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final from = widget.when?.start ?? DateTime.now();
    final to = widget.when?.end ?? from;
    final sel = s.cat(widget.selected);
    if (!_init) {
      _init = true;
      level = sel?.parentId; // abre no nível onde a seleção atual está
    }
    final selChain = <int>{
      if (sel != null) ...[sel.id, ...s.ancestorsOf(sel).map((a) => a.id)],
    };
    // escolhível agora: dentro do período, ou a seleção atual (e o caminho até ela)
    bool visible(Categoria c) =>
        showAll ||
        selChain.contains(c.id) ||
        s.isCategoryActiveDuring(c, from, to);
    // mostra-se no nível se for visível ou se tiver algo visível lá dentro
    bool shown(Categoria c) => visible(c) || s.descendantsOf(c.id).any(visible);
    List<Categoria> kidsOf(int? id) =>
        (id == null ? s.roots.toList() : s.childrenOf(id)).where(shown).toList();
    bool hasShownKids(Categoria c) => s.childrenOf(c.id).any(shown);

    final query = q.trim().toLowerCase();
    final searching = query.isNotEmpty;
    final hiddenExist = s.categories.any(
      (c) =>
          !c.archived &&
          c.hasDates &&
          !showAll &&
          !s.isCategoryActiveDuring(c, from, to),
    );

    Widget chip(Categoria c, {String? label, bool bold = false}) {
      return ChoiceChip(
        key: ValueKey('cat-pick-${c.id}'),
        selected: c.id == widget.selected,
        showCheckmark: false,
        avatar: c.emoji.isEmpty ? null : Text(c.emoji),
        label: Text(label ?? c.name),
        onSelected: (_) => Navigator.pop(context, c.id),
        labelStyle: bold ? const TextStyle(fontWeight: FontWeight.w700) : null,
      );
    }

    final body = <Widget>[];
    var empty = false;
    if (searching) {
      // procura em todos os níveis e mostra o caminho completo
      final hits = [
        for (final c in s.categories)
          if (!c.archived && visible(c) && c.name.toLowerCase().contains(query))
            c,
      ]..sort((a, b) => s.path(a.id).compareTo(s.path(b.id)));
      empty = hits.isEmpty;
      body.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [for (final c in hits) chip(c, label: s.path(c.id))],
          ),
        ),
      );
    } else {
      final cur = s.cat(level);
      final kids = kidsOf(level);
      empty = cur == null && kids.isEmpty;
      if (cur != null) {
        // caminho clicável até aqui: Principais › A › B
        final chain = [...s.ancestorsOf(cur).reversed, cur];
        body.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ActionChip(
                  key: const ValueKey('cat-back'),
                  avatar: const Icon(Icons.arrow_back, size: 18),
                  label: Text(
                    cur.parentId == null
                        ? l.frmMainCategories
                        : (s.cat(cur.parentId)?.name ?? ''),
                  ),
                  onPressed: () => setState(() => level = cur.parentId),
                ),
                const SizedBox(width: 4),
                TextButton(
                  key: const ValueKey('crumb-root'),
                  onPressed: () => setState(() => level = null),
                  child: Text(l.frmMainCategories),
                ),
                for (final a in chain) ...[
                  Text('›', style: tt.bodyMedium),
                  a.id == cur.id
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            a.name,
                            style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : TextButton(
                          key: ValueKey('crumb-${a.id}'),
                          onPressed: () => setState(() => level = a.id),
                          child: Text(a.name),
                        ),
                ],
              ],
            ),
          ),
        );
        body.add(
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: chip(cur, label: l.frmOnlyName(cur.name), bold: true),
            ),
          ),
        );
      }
      body.add(
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final k in kids)
              if (!hasShownKids(k))
                chip(k, bold: cur == null)
              else
                ChoiceChip(
                  key: ValueKey('cat-open-${k.id}'),
                  selected: k.id == widget.selected,
                  showCheckmark: false,
                  avatar: k.emoji.isEmpty ? null : Text(k.emoji),
                  label: Text('${k.name} ›'),
                  labelStyle: cur == null
                      ? const TextStyle(fontWeight: FontWeight.w700)
                      : null,
                  onSelected: (_) => setState(() => level = k.id),
                ),
            if (kids.isEmpty && cur != null)
              Text(
                l.frmNoSubcategories,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
          ],
        ),
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
              decoration: InputDecoration(
                hintText: l.frmSearchCategory,
                prefixIcon: const Icon(Icons.search),
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
                ...body,
                if (empty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        s.roots.isEmpty
                            ? l.frmNoCategoriesYet
                            : l.frmNoCategoryFound,
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                if (widget.allowNew)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.add),
                    title: Text(l.frmNewCategoryTitle),
                    onTap: () async {
                      // uma nova categoria nasce dentro do nível que se está a ver
                      final id = await showCategoryEditor(
                        context,
                        parentId: searching ? null : level,
                      );
                      if (id != null && context.mounted) {
                        Navigator.pop(context, id);
                      }
                    },
                  ),
                if (widget.selected != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.close),
                    title: Text(l.noCategory),
                    onTap: () => Navigator.pop(context, -1),
                  ),
                if (hiddenExist || showAll)
                  TextButton(
                    onPressed: () => setState(() => showAll = !showAll),
                    child: Text(
                      showAll ? l.frmHideEndedFuture : l.frmShowEndedFuture,
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
