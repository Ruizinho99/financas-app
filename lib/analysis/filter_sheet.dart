import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../util/format.dart';
import 'analytics.dart';

String _typeLabel(SpendType t) => switch (t) {
      SpendType.all => 'Todas',
      SpendType.mandatory => 'Obrigatórias',
      SpendType.optional => 'Opcionais',
    };

/// Linha com o botão "Filtros" e os filtros ativos (cada um removível).
class FilterBar extends StatelessWidget {
  final AnalysisFilter filter;
  final ValueChanged<AnalysisFilter> onChanged;
  const FilterBar({super.key, required this.filter, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final f = filter;
    String eur(int c) => fmtMoney(c, short: c % 100 == 0);
    final chips = <Widget>[
      if (f.type != SpendType.all)
        InputChip(label: Text(_typeLabel(f.type)), onDeleted: () => onChanged(f.copyWith(type: SpendType.all))),
      if (f.categoryIds.isNotEmpty)
        InputChip(
          label: Text(f.categoryIds.length == 1 ? (s.cat(f.categoryIds.first)?.name ?? 'Categoria') : '${f.categoryIds.length} categorias'),
          onDeleted: () => onChanged(f.copyWith(categoryIds: {})),
        ),
      if (f.accountIds.isNotEmpty)
        InputChip(
          label: Text(f.accountIds.length == 1 ? (s.account(f.accountIds.first)?.name ?? 'Conta') : '${f.accountIds.length} contas'),
          onDeleted: () => onChanged(f.copyWith(accountIds: {})),
        ),
      if (f.minCents != null || f.maxCents != null)
        InputChip(
          label: Text([if (f.minCents != null) '≥ ${eur(f.minCents!)}', if (f.maxCents != null) '≤ ${eur(f.maxCents!)}'].join('  ')),
          onDeleted: () => onChanged(f.copyWith(minCents: null, maxCents: null)),
        ),
      if (f.query.trim().isNotEmpty) InputChip(label: Text('“${f.query.trim()}”'), onDeleted: () => onChanged(f.copyWith(query: ''))),
    ];
    return SizedBox(
      height: 52,
      child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6), children: [
        Badge(
          isLabelVisible: f.activeCount > 0,
          label: Text('${f.activeCount}'),
          child: ActionChip(
            avatar: const Icon(Icons.tune, size: 18),
            label: const Text('Filtros'),
            onPressed: () async {
              final r = await showAnalysisFilterSheet(context, f);
              if (r != null) onChanged(r);
            },
          ),
        ),
        for (final c in chips) Padding(padding: const EdgeInsets.only(left: 8), child: c),
        if (f.activeCount > 1)
          Padding(padding: const EdgeInsets.only(left: 8), child: TextButton(onPressed: () => onChanged(const AnalysisFilter()), child: const Text('Limpar tudo'))),
      ]),
    );
  }
}

Future<AnalysisFilter?> showAnalysisFilterSheet(BuildContext context, AnalysisFilter current) {
  return showModalBottomSheet<AnalysisFilter>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _FilterSheet(current: current),
  );
}

class _FilterSheet extends StatefulWidget {
  final AnalysisFilter current;
  const _FilterSheet({required this.current});
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late SpendType type = widget.current.type;
  late Set<int> cats = {...widget.current.categoryIds};
  late Set<int> accounts = {...widget.current.accountIds};
  late final query = TextEditingController(text: widget.current.query);
  late final minC = TextEditingController(text: _fmt(widget.current.minCents));
  late final maxC = TextEditingController(text: _fmt(widget.current.maxCents));

  static String _fmt(int? c) => c == null ? '' : (c / 100).toStringAsFixed(c % 100 == 0 ? 0 : 2).replaceAll('.', ',');

  @override
  void dispose() {
    query.dispose();
    minC.dispose();
    maxC.dispose();
    super.dispose();
  }

  void _apply() {
    Navigator.pop(
      context,
      AnalysisFilter(
        type: type,
        categoryIds: cats,
        accountIds: accounts,
        query: query.text.trim(),
        minCents: parseCents(minC.text),
        maxCents: parseCents(maxC.text),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(t, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final roots = s.roots.where((r) => !r.isIncome).toList();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      builder: (_, controller) => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 8, 0),
          child: Row(children: [
            Expanded(child: Text('Filtros', style: Theme.of(context).textTheme.titleLarge)),
            TextButton(
              onPressed: () => setState(() {
                type = SpendType.all;
                cats.clear();
                accounts.clear();
                query.clear();
                minC.clear();
                maxC.clear();
              }),
              child: const Text('Limpar'),
            ),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ]),
        ),
        Expanded(
          child: ListView(controller: controller, padding: const EdgeInsets.fromLTRB(24, 0, 24, 16), children: [
            _label('Tipo de despesa'),
            SegmentedButton<SpendType>(
              showSelectedIcon: false,
              segments: [for (final t in SpendType.values) ButtonSegment(value: t, label: Text(_typeLabel(t)))],
              selected: {type},
              onSelectionChanged: (v) => setState(() => type = v.first),
            ),
            _label('Pesquisar'),
            TextField(controller: query, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Nome, nota, categoria…')),
            _label('Valor do movimento'),
            Row(children: [
              Expanded(child: TextField(controller: minC, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Mínimo (€)'))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: maxC, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Máximo (€)'))),
            ]),
            if (s.accounts.isNotEmpty) ...[
              _label('Contas'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final a in s.accounts)
                  FilterChip(
                    label: Text('${a.emoji} ${a.name}'.trim()),
                    selected: accounts.contains(a.id),
                    showCheckmark: false,
                    avatar: accounts.contains(a.id) ? const Icon(Icons.check, size: 18) : null,
                    onSelected: (v) => setState(() => v ? accounts.add(a.id) : accounts.remove(a.id)),
                  ),
              ]),
            ],
            _label('Categorias'),
            if (roots.isEmpty) const Text('Ainda não há categorias.'),
            for (final r in roots)
              Builder(builder: (_) {
                final kids = s.childrenOf(r.id);
                final rootOn = cats.contains(r.id);
                final anyKid = kids.any((k) => cats.contains(k.id));
                return Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(left: 32),
                    initiallyExpanded: anyKid,
                    shape: const Border(),
                    collapsedShape: const Border(),
                    leading: Checkbox(
                      value: rootOn ? true : (anyKid ? null : false),
                      tristate: true,
                      onChanged: (_) => setState(() {
                        if (rootOn || anyKid) {
                          cats.remove(r.id);
                          for (final k in kids) {
                            cats.remove(k.id);
                          }
                        } else {
                          cats.add(r.id);
                          for (final k in kids) {
                            cats.remove(k.id);
                          }
                        }
                      }),
                    ),
                    title: Text('${r.emoji.isEmpty ? '🏷️' : r.emoji}  ${r.name}'),
                    children: [
                      for (final k in kids)
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: rootOn || cats.contains(k.id),
                          onChanged: rootOn ? null : (v) => setState(() => v! ? cats.add(k.id) : cats.remove(k.id)),
                          title: Text('${k.emoji.isEmpty ? '' : '${k.emoji}  '}${k.name}'),
                        ),
                    ],
                  ),
                );
              }),
          ]),
        ),
        Container(
          decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)))),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: SizedBox(width: double.infinity, child: FilledButton(onPressed: _apply, child: const Text('Aplicar filtros'))),
        ),
      ]),
    );
  }
}
