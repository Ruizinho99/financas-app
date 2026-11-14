import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../stats/category_stats.dart';
import '../util/format.dart';
import '../widgets/common.dart';

/// Estatísticas de uma categoria: totais, evolução mensal com a média, subcategorias e onde mais gastas.
class CategoryStatsScreen extends StatelessWidget {
  final int categoryId;
  const CategoryStatsScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = s.cat(categoryId);
    final en = Localizations.localeOf(context).languageCode == 'en';
    String t(String pt, String e) => en ? e : pt;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    if (c == null) return const Scaffold();
    final st = categoryStats(s, categoryId);

    Widget tile(String label, String value) => Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(value, style: tt.titleLarge),
            ],
          ),
        ),
      ),
    );

    Widget shareRow(String name, int cents, int total) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total <= 0 ? 0 : (cents / total).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: cs.surfaceContainerHighest,
              ),
            ),
          ),
          SizedBox(
            width: 74,
            child: Text(
              fmtMoney(cents),
              textAlign: TextAlign.right,
              style: tt.bodySmall,
            ),
          ),
        ],
      ),
    );

    Widget card(String title, Widget child) => Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: tt.titleSmall),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );

    final maxY = st.monthly.fold<int>(0, (a, b) => a > b ? a : b);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CatBadge(c, size: 24),
            const SizedBox(width: 8),
            Expanded(child: Text(c.name, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      body: st.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  t(
                    'Ainda não há despesas nesta categoria nos últimos 12 meses.',
                    'No expenses in this category in the last 12 months yet.',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Row(
                  children: [
                    tile(t('Total (12 meses)', 'Total (12 months)'), fmtMoney(st.total)),
                    const SizedBox(width: 8),
                    tile(t('Média por mês', 'Monthly average'), fmtMoney(st.averagePerMonth)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    tile(
                      t('Maior gasto', 'Biggest expense'),
                      st.biggest == null
                          ? '—'
                          : fmtMoney(-s.effectiveAmount(st.biggest!)),
                    ),
                    const SizedBox(width: 8),
                    tile(t('Movimentos', 'Transactions'), '${st.count}'),
                  ],
                ),
                card(
                  t('Evolução mensal e média', 'Monthly trend and average'),
                  SizedBox(
                    height: 180,
                    child: BarChart(
                      BarChartData(
                        maxY: maxY * 1.15,
                        gridData: const FlGridData(drawVerticalLine: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(),
                          rightTitles: const AxisTitles(),
                          leftTitles: const AxisTitles(),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              getTitlesWidget: (v, _) {
                                final i = v.toInt();
                                if (i < 0 || i >= st.monthKeys.length) {
                                  return const SizedBox.shrink();
                                }
                                final k = st.monthKeys[i];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    fmtMonthShort(
                                      DateTime(int.parse(k.substring(0, 4)), int.parse(k.substring(5, 7))),
                                    ).substring(0, 1).toUpperCase(),
                                    style: tt.labelSmall,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (g, gi, rod, ri) => BarTooltipItem(
                              '${st.monthKeys[gi]}\n${fmtMoney(rod.toY.round())}',
                              TextStyle(color: cs.onInverseSurface, fontSize: 12),
                            ),
                          ),
                        ),
                        extraLinesData: ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(
                              y: st.averagePerMonth.toDouble(),
                              color: cs.outline,
                              strokeWidth: 1,
                              dashArray: [4, 3],
                            ),
                          ],
                        ),
                        barGroups: [
                          for (var i = 0; i < st.monthly.length; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: st.monthly[i].toDouble(),
                                  width: 14,
                                  color: i == st.monthly.length - 1
                                      ? cs.primary
                                      : cs.primary.withValues(alpha: 0.45),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (st.bySubcategory.length > 1)
                  card(
                    t('Subcategorias', 'Subcategories'),
                    Column(
                      children: [
                        for (final e in st.bySubcategory.take(8))
                          shareRow(e.key, e.value, st.total),
                      ],
                    ),
                  ),
                if (st.byMerchant.isNotEmpty)
                  card(
                    t('Onde mais gastas', 'Where you spend most'),
                    Column(
                      children: [
                        for (final e in st.byMerchant)
                          shareRow(e.key, e.value, st.byMerchant.first.value),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
