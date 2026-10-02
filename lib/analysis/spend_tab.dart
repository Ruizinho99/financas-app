import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../util/format.dart';
import '../widgets/common.dart';
import 'analytics.dart';
import 'widgets.dart';

enum _View { category, sub, merchant, account }

/// Onde gasto: ranking por categoria / subcategoria / comerciante / conta, com detalhe ao tocar,
/// dias da semana e maiores despesas.
class SpendTab extends StatefulWidget {
  final Analytics a;
  final bool compare;
  /// Aplica um filtro de categoria à análise toda.
  final ValueChanged<int> onFilterCategory;
  const SpendTab({super.key, required this.a, required this.compare, required this.onFilterCategory});
  @override
  State<SpendTab> createState() => _SpendTabState();
}

class _SpendTabState extends State<SpendTab> {
  _View view = _View.category;
  bool showAll = false;

  List<Slice> _slices(Analytics a) => switch (view) {
        _View.category => a.byCategory(),
        _View.sub => a.bySubcategory(),
        _View.merchant => a.byMerchant(),
        _View.account => a.byAccount(),
      };

  @override
  Widget build(BuildContext context) {
    final a = widget.a;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final colors = chartColors(cs);
    if (a.spends.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Sem despesas neste período (ou os filtros não encontram nada).', textAlign: TextAlign.center)));
    }
    final slices = _slices(a);
    final top = slices.take(6).toList();
    final others = slices.skip(6).fold(0, (x, e) => x + e.amount);
    final max = slices.isEmpty ? 1 : slices.first.amount;
    final shown = showAll ? slices : slices.take(10).toList();
    final w = a.byWeekday();
    const names = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    const longNames = ['à segunda', 'à terça', 'à quarta', 'à quinta', 'à sexta', 'ao sábado', 'ao domingo'];
    final maxDay = w.totals.indexOf(w.totals.reduce((x, y) => x > y ? x : y));

    return ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 32), children: [
      SizedBox(
        height: 52,
        child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(vertical: 6), children: [
          for (final (v, label, icon) in [
            (_View.category, 'Categorias', Icons.category_outlined),
            (_View.sub, 'Subcategorias', Icons.account_tree_outlined),
            (_View.merchant, 'Comerciantes', Icons.storefront_outlined),
            (_View.account, 'Contas', Icons.account_balance_wallet_outlined),
          ])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(avatar: Icon(view == v ? Icons.check : icon, size: 18), label: Text(label), selected: view == v, onSelected: (_) => setState(() {
                    view = v;
                    showAll = false;
                  })),
            ),
        ]),
      ),
      SectionCard(
        title: switch (view) {
          _View.category => 'Para onde vai o dinheiro',
          _View.sub => 'Detalhe por subcategoria',
          _View.merchant => 'Onde mais gastas',
          _View.account => 'Gastos por conta',
        },
        subtitle: 'Toca numa linha para ver os movimentos',
        child: Column(children: [
          LayoutBuilder(builder: (context, c) {
            final donut = Donut(
              items: [for (var i = 0; i < top.length; i++) DonutItem(top[i].label, top[i].amount, colors[i]), if (others > 0) DonutItem('Outros', others, cs.outline)],
              centerTop: 'Total',
              centerBottom: fmtMoney(a.spent, short: true),
            );
            final legend = Column(children: [
              for (var i = 0; i < top.length; i++) LegendRow(color: colors[i], label: top[i].label, value: fmtPercent(top[i].amount / a.spent), share: null),
              if (others > 0) LegendRow(color: cs.outline, label: 'Outros', value: fmtPercent(others / a.spent)),
            ]);
            if (c.maxWidth < 340) return Column(children: [donut, const SizedBox(height: 12), legend]);
            return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [donut, const SizedBox(width: 14), Expanded(child: legend)]);
          }),
          const Divider(height: 28),
          for (var i = 0; i < shown.length; i++)
            _SliceRow(
              slice: shown[i],
              color: i < 6 ? colors[i] : cs.outline,
              share: shown[i].amount / a.spent,
              ratio: shown[i].amount / max,
              compare: widget.compare,
              onTap: () => _openDetail(context, shown[i]),
            ),
          if (slices.length > 10)
            TextButton(onPressed: () => setState(() => showAll = !showAll), child: Text(showAll ? 'Mostrar menos' : 'Ver todos (${slices.length})')),
        ]),
      ),
      // ----- dias da semana -----
      SectionCard(
        title: 'Em que dias gastas mais',
        subtitle: w.totals[maxDay] > 0 ? 'Gastas mais ${longNames[maxDay]}: ${fmtMoney(w.totals[maxDay])} em ${w.counts[maxDay]} movimentos' : null,
        child: SizedBox(
          height: 150,
          child: BarChart(BarChartData(
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            alignment: BarChartAlignment.spaceAround,
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 6), child: Text(names[v.toInt()], style: tt.labelSmall)))),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(getTooltipItem: (g, gi, r, ri) => BarTooltipItem('${names[gi]}\n${fmtMoney(r.toY.round())}', TextStyle(color: cs.onInverseSurface, fontSize: 12, fontWeight: FontWeight.w600))),
            ),
            barGroups: [
              for (var i = 0; i < 7; i++)
                BarChartGroupData(x: i, barRods: [BarChartRodData(toY: w.totals[i].toDouble(), width: 18, color: i == maxDay ? cs.primary : cs.primary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(6))]),
            ],
          )),
        ),
      ),
      // ----- maiores despesas -----
      SectionCard(
        title: 'Maiores despesas',
        subtitle: 'As que mais pesaram neste período',
        child: Column(children: [
          for (final e in a.largest(5))
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: e.cat == null ? const Icon(Icons.help_outline) : CatBadge(e.cat),
              title: Text(context.read<AppState>().displayName(e.t), maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${fmtDate(e.t.date)} · ${context.read<AppState>().path(e.t.categoryId)}', maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text(fmtMoney(e.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
              onTap: () => showTxnEditor(context, edit: e.t),
            ),
        ]),
      ),
    ]);
  }

  void _openDetail(BuildContext context, Slice sl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _SliceDetail(
        slice: sl,
        a: widget.a,
        compare: widget.compare,
        onFilter: sl.categoryId == null
            ? null
            : () {
                Navigator.pop(context);
                widget.onFilterCategory(sl.categoryId!);
              },
      ),
    );
  }
}

class _SliceRow extends StatelessWidget {
  final Slice slice;
  final Color color;
  final double share, ratio;
  final bool compare;
  final VoidCallback onTap;
  const _SliceRow({required this.slice, required this.color, required this.share, required this.ratio, required this.compare, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            SizedBox(width: 30, child: Text(slice.emoji.isEmpty ? '•' : slice.emoji, style: const TextStyle(fontSize: 20), textAlign: TextAlign.center)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(slice.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                Text(
                  [if (slice.subtitle != null) slice.subtitle!, '${slice.count} ${slice.count == 1 ? 'movimento' : 'movimentos'}'].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ]),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(fmtMoney(slice.amount), style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text(fmtPercent(share), style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                if (compare) ...[const SizedBox(width: 6), DeltaChip(cur: slice.amount, prev: slice.prev)],
              ]),
            ]),
          ]),
          const SizedBox(height: 8),
          Padding(padding: const EdgeInsets.only(left: 38), child: ShareBar(ratio: ratio, color: color)),
        ]),
      ),
    );
  }
}

/// Detalhe de uma fatia: de onde vem o valor e os movimentos.
class _SliceDetail extends StatelessWidget {
  final Slice slice;
  final Analytics a;
  final bool compare;
  final VoidCallback? onFilter;
  const _SliceDetail({required this.slice, required this.a, required this.compare, this.onFilter});

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final items = [...slice.items]..sort((x, y) => y.t.date.compareTo(x.t.date));
    // de onde vem: subcategorias (se for uma categoria) ou meses
    final bySub = <String, int>{};
    for (final e in slice.items) {
      final label = e.cat == null ? 'Sem categoria' : (e.cat!.parentId == null ? (s.childrenOf(e.cat!.id).isEmpty ? e.cat!.name : '${e.cat!.name} (geral)') : e.cat!.name);
      bySub[label] = (bySub[label] ?? 0) + e.amount;
    }
    final parts = bySub.entries.toList()..sort((x, y) => y.value.compareTo(x.value));
    final byMonth = <String, int>{};
    for (final e in slice.items) {
      byMonth[e.month] = (byMonth[e.month] ?? 0) + e.amount;
    }
    final months = byMonth.entries.toList()..sort((x, y) => x.key.compareTo(y.key));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, controller) => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 8, 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(slice.emoji.isEmpty ? '•' : slice.emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(slice.label, style: tt.titleLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(children: [
                  Text(fmtMoney(slice.amount), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Text('${fmtPercent(a.spent == 0 ? 0 : slice.amount / a.spent)} das despesas', style: tt.bodySmall),
                  if (compare) ...[const SizedBox(width: 8), DeltaChip(cur: slice.amount, prev: slice.prev)],
                ]),
              ]),
            ),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ]),
        ),
        Expanded(
          child: ListView(controller: controller, padding: const EdgeInsets.fromLTRB(24, 0, 24, 24), children: [
            Wrap(spacing: 28, runSpacing: 10, children: [
              Stat('Movimentos', '${slice.count}'),
              Stat('Valor médio', fmtMoney(slice.avg)),
              Stat('Por mês', fmtMoney(a.perMonth(slice.amount))),
              if (compare && slice.prev > 0) Stat('Período anterior', fmtMoney(slice.prev)),
            ]),
            if (parts.length > 1) ...[
              const SizedBox(height: 20),
              Text('De onde vem', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final p in parts.take(8))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Expanded(child: Text(p.key, maxLines: 1, overflow: TextOverflow.ellipsis)), Text(fmtMoney(p.value), style: const TextStyle(fontWeight: FontWeight.w600))]),
                    const SizedBox(height: 4),
                    ShareBar(ratio: p.value / slice.amount, color: cs.primary),
                  ]),
                ),
            ],
            if (months.length > 1) ...[
              const SizedBox(height: 20),
              Text('Mês a mês', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              SizedBox(
                height: 110,
                child: BarChart(BarChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: months.length > 8 ? (months.length / 6).ceilToDouble() : 1,
                        getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 4), child: Text(months[v.toInt()].key.substring(5), style: tt.labelSmall)),
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(touchTooltipData: BarTouchTooltipData(getTooltipItem: (g, gi, r, ri) => BarTooltipItem('${months[gi].key}\n${fmtMoney(r.toY.round())}', TextStyle(color: cs.onInverseSurface, fontSize: 12, fontWeight: FontWeight.w600)))),
                  barGroups: [for (var i = 0; i < months.length; i++) BarChartGroupData(x: i, barRods: [BarChartRodData(toY: months[i].value.toDouble(), width: months.length > 12 ? 8 : 16, color: cs.primary, borderRadius: BorderRadius.circular(4))])],
                )),
              ),
            ],
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: Text('Movimentos', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
              if (onFilter != null) TextButton.icon(onPressed: onFilter, icon: const Icon(Icons.filter_alt_outlined, size: 18), label: const Text('Analisar só esta')),
            ]),
            for (final e in items.take(30))
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(s.displayName(e.t), maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${fmtDate(e.t.date)} · ${s.path(e.t.categoryId)}', maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Text(fmtMoney(e.amount), style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => showTxnEditor(context, edit: e.t),
              ),
            if (items.length > 30) Padding(padding: const EdgeInsets.all(8), child: Text('… e mais ${items.length - 30}', style: tt.bodySmall)),
          ]),
        ),
      ]),
    );
  }
}
