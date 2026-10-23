import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
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
  int? openRoot; // passo 2: a categoria principal aberta, cujas subcategorias se mostram

  /// Aceita o tipo pedido (despesa/receita). "Despesas e receitas" aceita sempre.
  bool fits(Categoria c) =>
      widget.income == null || c.both || c.isIncome == widget.income;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final l = AppLocalizations.of(context)!;
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
    final searching = query.isNotEmpty;

    // subcategorias de uma principal que se podem escolher agora
    List<Categoria> subsOf(Categoria r) => s
        .childrenOf(r.id)
        .where((k) => visible(k) && (fits(k) || r.both))
        .toList();

    // passo 1: principais (ou, a pesquisar, principais e subcategorias que coincidem)
    final tops = <(Categoria, List<Categoria>)>[];
    for (final r in s.roots.where((r) => fits(r) || r.both)) {
      final subs = subsOf(r);
      if (searching) {
        final rootMatches = r.name.toLowerCase().contains(query);
        final subMatches = subs
            .where((k) => k.name.toLowerCase().contains(query))
            .toList();
        if (!rootMatches && subMatches.isEmpty) continue;
        tops.add((r, rootMatches ? subs : subMatches));
      } else {
        if (!visible(r) && subs.isEmpty) continue;
        tops.add((r, subs));
      }
    }
    (Categoria, List<Categoria>)? open;
    for (final t in tops) {
      if (t.$1.id == openRoot) open = t;
    }
    final hiddenExist = s.categories.any(
      (c) =>
          !c.archived &&
          c.hasDates &&
          !showAll &&
          !s.isCategoryActiveDuring(c, from, to),
    );

    Widget chip(Categoria c, {String? label, bool root = false}) {
      final on = c.id == widget.selected;
      return ChoiceChip(
        selected: on,
        showCheckmark: false,
        avatar: c.emoji.isEmpty ? null : Text(c.emoji),
        label: Text(label ?? c.name),
        onSelected: (_) => Navigator.pop(context, c.id),
        labelStyle: root ? const TextStyle(fontWeight: FontWeight.w700) : null,
      );
    }

    final body = <Widget>[];
    if (searching || open == null) {
      // lista de principais; as que têm subcategorias abrem o passo 2
      for (final (r, subs) in tops) {
        if (searching) {
          body.add(
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [chip(r, root: true), for (final k in subs) chip(k)],
              ),
            ),
          );
        } else {
          body.add(
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (subs.isEmpty)
                    chip(r, root: true)
                  else
                    ChoiceChip(
                      selected: r.id == widget.selected,
                      showCheckmark: false,
                      avatar: r.emoji.isEmpty ? null : Text(r.emoji),
                      label: Text('${r.name} ›'),
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                      onSelected: (_) => setState(() => openRoot = r.id),
                    ),
                ],
              ),
            ),
          );
        }
      }
    } else {
      // passo 2: subcategorias da principal escolhida
      final (r, subs) = open;
      body.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ActionChip(
                avatar: const Icon(Icons.arrow_back, size: 18),
                label: Text(l.frmMainCategories),
                onPressed: () => setState(() => openRoot = null),
              ),
              chip(r, label: l.frmOnlyName(r.name), root: true),
            ],
          ),
        ),
      );
      body.add(
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            '${r.emoji} ${r.name}',
            style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      );
      body.add(
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final k in subs) chip(k),
            if (subs.isEmpty)
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
                ...body,
                if (tops.isEmpty)
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
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.add),
                  title: Text(l.frmNewCategoryTitle),
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
