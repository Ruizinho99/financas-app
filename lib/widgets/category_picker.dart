import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models.dart';
import '../state/app_state.dart';
import 'common.dart';

/// Escolhe uma categoria numa só folha, com pesquisa, a navegar pela árvore em
/// qualquer profundidade (A › B › C › ...).
/// Devolve o id escolhido, `-1` para "sem categoria" ou `null` se for cancelado.
/// [allowNew] esconde "Nova categoria" (ex.: em filtros, onde só se escolhe o que existe).
/// [suggestedId] mostra uma categoria sugerida (ex.: pelo nome do movimento); se faltar,
/// mas houver [description], a sugestão vem do histórico (`suggestCategoryFor`).
/// [mostUsed] força a lista das mais usadas; por omissão vem do histórico, em saídas
/// ou entradas conforme [income].
Future<int?> chooseCategory(
  BuildContext context, {
  int? selected,
  bool? income,
  DateTimeRange? when,
  bool allowNew = true,
  int? suggestedId,
  List<int>? mostUsed,
  String? description,
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
      suggestedId: suggestedId,
      mostUsed: mostUsed,
      description: description,
    ),
  );
}

/// Minúsculas e sem acentos, mantendo o comprimento (para realçar o troço que coincide).
String _fold(String s) {
  const from = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿ';
  const to = 'aaaaaaceeeeiiiinooooouuuuyy';
  final b = StringBuffer();
  for (final c in s.toLowerCase().split('')) {
    final i = from.indexOf(c);
    b.write(i >= 0 ? to[i] : c);
  }
  return b.toString();
}

class _CategorySheet extends StatefulWidget {
  final int? selected;
  final bool? income;
  final DateTimeRange? when;
  final bool allowNew;
  final int? suggestedId;
  final List<int>? mostUsed;
  final String? description;
  const _CategorySheet({
    this.selected,
    this.income,
    this.when,
    this.allowNew = true,
    this.suggestedId,
    this.mostUsed,
    this.description,
  });
  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  String q = '';
  bool showAll = false; // inclui categorias terminadas e futuras
  int? level; // categoria cujo conteúdo se mostra (null = as principais)
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
        (id == null ? s.roots.toList() : s.childrenOf(id))
            .where(shown)
            .toList();

    final cur = s.cat(level);
    final query = _fold(q.trim());
    final searching = query.isNotEmpty;
    final hiddenExist = s.categories.any(
      (c) =>
          !c.archived &&
          c.hasDates &&
          !showAll &&
          !s.isCategoryActiveDuring(c, from, to),
    );

    // ---- peças ----
    Widget circle(Categoria c) => Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.surfaceContainerHighest,
      ),
      child: CatBadge(c, size: 20),
    );

    Widget check() => Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Icon(Icons.check_circle, size: 20, color: cs.primary),
    );

    /// Linha de categoria: tocar à esquerda escolhe; a seta, à direita, abre o interior.
    Widget row(Categoria c) {
      final kids = s.childrenOf(c.id).where(shown).toList();
      final isSel = c.id == widget.selected;
      return Material(
        color: isSel ? cs.primaryContainer.withValues(alpha: 0.4) : null,
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  key: ValueKey('cat-pick-${c.id}'),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                  onTap: () => Navigator.pop(context, c.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        circle(c),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            c.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isSel) check(),
                      ],
                    ),
                  ),
                ),
              ),
              if (kids.isNotEmpty) ...[
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  indent: 8,
                  endIndent: 8,
                  color: cs.outlineVariant,
                ),
                Tooltip(
                  message: l.pksOpen(c.name),
                  child: InkWell(
                    key: ValueKey('cat-open-${c.id}'),
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(12),
                    ),
                    onTap: () => setState(() => level = c.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${kids.length}',
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right,
                            color: cs.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    Widget header(String text) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        text,
        style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant),
      ),
    );

    Widget chip(Categoria c, String keyPrefix, {String? label}) {
      return ChoiceChip(
        key: ValueKey('$keyPrefix-${c.id}'),
        selected: c.id == widget.selected,
        showCheckmark: false,
        avatar: CatBadge(c, size: 16),
        label: Text(label ?? c.name),
        onSelected: (_) => Navigator.pop(context, c.id),
      );
    }

    /// Nome com o troço que coincide com a pesquisa a negrito.
    Widget highlighted(Categoria c) {
      final base = tt.bodyLarge!.copyWith(fontWeight: FontWeight.w600);
      final f = _fold(c.name);
      final i = f.length == c.name.length ? f.indexOf(query) : -1;
      if (i < 0) return Text(c.name, style: base);
      return Text.rich(
        TextSpan(
          style: base,
          children: [
            TextSpan(text: c.name.substring(0, i)),
            TextSpan(
              text: c.name.substring(i, i + query.length),
              style: TextStyle(
                color: cs.primary,
                backgroundColor: cs.primary.withValues(alpha: 0.15),
                fontWeight: FontWeight.w800,
              ),
            ),
            TextSpan(text: c.name.substring(i + query.length)),
          ],
        ),
      );
    }

    // ---- corpo ----
    final body = <Widget>[];
    var empty = false;
    if (searching) {
      // procura em todos os níveis (dentro da categoria aberta, se houver uma)
      final hits = [
        for (final c in s.categories)
          if (!c.archived &&
              visible(c) &&
              (cur == null || s.inSubtree(c.id, cur.id) && c.id != cur.id) &&
              _fold(c.name).contains(query))
            c,
      ]..sort((a, b) => s.path(a.id).compareTo(s.path(b.id)));
      empty = hits.isEmpty;
      if (!empty) body.add(header(l.pksResults(hits.length)));
      for (final c in hits) {
        final parents = s.ancestorsOf(c).reversed.map((a) => a.name).join(' › ');
        body.add(
          InkWell(
            key: ValueKey('cat-pick-${c.id}'),
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.pop(context, c.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  circle(c),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        highlighted(c),
                        if (parents.isNotEmpty)
                          Text(
                            parents,
                            key: ValueKey('cat-path-${c.id}'),
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (c.id == widget.selected) check(),
                ],
              ),
            ),
          ),
        );
      }
    } else {
      final kids = kidsOf(level);
      empty = cur == null && kids.isEmpty;
      if (cur != null) {
        // migalhas clicáveis: Todas › A › B
        final chain = [...s.ancestorsOf(cur).reversed, cur];
        body.add(
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Wrap(
              spacing: 2,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton(
                  key: const ValueKey('crumb-root'),
                  onPressed: () => setState(() => level = null),
                  child: Text(l.pksAll),
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
        // escolher a própria categoria aberta
        body.add(
          Material(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              key: const ValueKey('cat-self'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.pop(context, cur.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    circle(cur),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l.pksOnlyThis(cur.name),
                        style: tt.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ),
                    if (cur.id == widget.selected) check(),
                  ],
                ),
              ),
            ),
          ),
        );
        body.add(const SizedBox(height: 8));
      } else {
        // sugerida e mais usadas só aparecem ao abrir, no nível das principais
        final sugId =
            widget.suggestedId ??
            (widget.description == null
                ? null
                : s.suggestCategoryFor(widget.description!));
        final sug = s.cat(sugId);
        final showSug = sug != null && !sug.archived && shown(sug);
        if (showSug) {
          body.add(header(l.pksSuggested));
          body.add(
            Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                key: ValueKey('cat-sug-${sug.id}'),
                avatar: const Icon(Icons.auto_awesome, size: 18),
                label: Text(
                  s.path(sug.id),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                side: BorderSide(color: cs.primary),
                onPressed: () => Navigator.pop(context, sug.id),
              ),
            ),
          );
        }
        final used = [
          for (final id in widget.mostUsed ??
              s.mostUsedCategoryIds(limit: 6, income: widget.income))
            if (s.cat(id) != null &&
                !s.cat(id)!.archived &&
                shown(s.cat(id)!) &&
                !(showSug && id == sug.id))
              s.cat(id)!,
        ].take(5).toList();
        if (used.isNotEmpty) {
          body.add(header(l.pksMostUsed));
          body.add(
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [for (final c in used) chip(c, 'cat-top', label: null)],
            ),
          );
        }
        if (showSug || used.isNotEmpty) body.add(header(l.pksAll));
      }
      for (final k in kids) {
        body.add(row(k));
      }
      if (kids.isEmpty && cur != null) {
        body.add(
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              l.frmNoSubcategories,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        );
      }
    }

    // "Nova categoria" cria já no nível em que se está; a pesquisa abre o editor com o texto
    Future<void> create({String? name}) async {
      final id = await showCategoryEditor(
        context,
        parentId: level,
        name: name,
      );
      if (id != null && context.mounted) Navigator.pop(context, id);
    }

    final rawQuery = q.trim();
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
                hintText: cur == null
                    ? l.frmSearchCategory
                    : l.pksSearchIn(cur.name),
                prefixIcon: const Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => q = v),
            ),
          ),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
                const SizedBox(height: 8),
                if (widget.allowNew && searching)
                  ListTile(
                    key: const ValueKey('cat-create-text'),
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.add),
                    title: Text(l.pksCreateNamed(rawQuery)),
                    onTap: () => create(name: rawQuery),
                  ),
                if (widget.allowNew && !searching)
                  ListTile(
                    key: const ValueKey('cat-create'),
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.add),
                    title: Text(
                      cur == null
                          ? l.frmNewCategoryTitle
                          : l.pksNewSub(cur.name),
                    ),
                    onTap: () => create(),
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
