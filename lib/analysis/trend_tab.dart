import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../util/format.dart';
import 'analytics.dart';
import 'widgets.dart';

/// Evolução mês a mês: despesas (obrigatórias/opcionais), rendimentos, saldo e uma categoria à escolha.
class TrendTab extends StatefulWidget {
  final Analytics a;
  const TrendTab({super.key, required this.a});
  @override
  State<TrendTab> createState() => _TrendTabState();
}

class _TrendTabState extends State<TrendTab> {
  int? categoryId; // categoria principal escolhida em "Evolução por categoria"

  @override
  Widget build(BuildContext context) {
    final a = widget.a;
    final s = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final n = a.period.monthCount.clamp(6, 24);
    final pts = a.monthly(n);
    if (pts.every((p) => p.spent == 0 && p.income == 0)) {
      return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Ainda não há dados suficientes para mostrar a evolução.', textAlign: TextAlign.center)));
    }
    // médias e "melhor/pior mês" só com meses completos e com despesas registadas
    final withSpend = [for (var i = 0; i < pts.length; i++) if (pts[i].spent > 0 && !(a.ongoing && i == pts.length - 1)) pts[i]];
    final avg = withSpend.isEmpty ? 0 : (withSpend.fold(0, (x, p) => x + p.spent) / withSpend.length).round();
    final best = withSpend.isEmpty ? null : withSpend.reduce((x, y) => x.spent <= y.spent ? x : y);
    final worst = withSpend.isEmpty ? null : withSpend.reduce((x, y) => x.spent >= y.spent ? x : y);
    final maxY = pts.fold(1, (m, p) => p.spent > m ? p.spent : m).toDouble();
    final mand = cs.primary, opt = cs.tertiary;
    String mlabel(DateTime d) => fmtMonthShort(d).split(' ').first;

    // categoria escolhida
    final roots = s.roots.where((r) => !r.isIncome).toList();
    List<int>? catSeries;
    if (categoryId != null) {
      final f = a.filter.copyWith(categoryIds: {categoryId!});
      final sub = Analytics(s, a.period, f, previous: a.previous, today: a.today);
      catSeries = [for (final p in sub.monthly(n)) p.spent];
    }
    final catMax = (catSeries == null || catSeries.isEmpty) ? 1 : catSeries.reduce((x, y) => x > y ? x : y).clamp(1, 1 << 30);

    Widget bars(List<BarChartGroupData> groups, {double? maxYv, double? avgLine, required String Function(int) tip}) => SizedBox(
          height: 190,
          child: BarChart(BarChartData(
            maxY: (maxYv ?? maxY) * 1.15,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            extraLinesData: avgLine == null ? null : ExtraLinesData(horizontalLines: [HorizontalLine(y: avgLine, color: cs.outline, strokeWidth: 1.2, dashArray: [5, 4])]),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: n > 12 ? (n / 8).ceilToDouble() : 1,
                  getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 6), child: Text(mlabel(pts[v.toInt()].month), style: tt.labelSmall)),
                ),
              ),
            ),
            barTouchData: BarTouchData(touchTooltipData: BarTouchTooltipData(getTooltipItem: (g, gi, r, ri) => BarTooltipItem(tip(gi), TextStyle(color: cs.onInverseSurface, fontSize: 12, fontWeight: FontWeight.w600)))),
            barGroups: groups,
          )),
        );

    return ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 32), children: [
      SectionCard(
        title: 'Despesas por mês',
        subtitle: 'Últimos $n meses · a linha tracejada é a média (${fmtMoney(avg)})',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          bars(
            [
              for (var i = 0; i < pts.length; i++)
                BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: pts[i].spent.toDouble(),
                    width: n > 12 ? 9 : 18,
                    borderRadius: BorderRadius.circular(5),
                    rodStackItems: [
                      BarChartRodStackItem(0, pts[i].mandatory.toDouble(), mand),
                      BarChartRodStackItem(pts[i].mandatory.toDouble(), (pts[i].mandatory + pts[i].optional).toDouble(), opt),
                      BarChartRodStackItem((pts[i].mandatory + pts[i].optional).toDouble(), pts[i].spent.toDouble(), Colors.blueGrey),
                    ],
                  ),
                ]),
            ],
            avgLine: avg > 0 ? avg.toDouble() : null,
            tip: (i) => '${fmtMonth(pts[i].month)}\n${fmtMoney(pts[i].spent)}',
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 16, runSpacing: 6, children: [
            _dot(mand, 'Obrigatórias'),
            _dot(opt, 'Opcionais'),
            _dot(Colors.blueGrey, 'Sem categoria'),
          ]),
          if (best != null && worst != null && best.month != worst.month) ...[
            const SizedBox(height: 14),
            Callout(icon: Icons.thumb_up_alt_outlined, color: Colors.green.shade500, title: 'Melhor mês: ${fmtMonth(best.month)}', body: 'Gastaste ${fmtMoney(best.spent)}, ${fmtMoney(avg - best.spent)} abaixo da média.'),
            Callout(icon: Icons.warning_amber_rounded, color: Colors.orange.shade600, title: 'Mês mais caro: ${fmtMonth(worst.month)}', body: 'Gastaste ${fmtMoney(worst.spent)}, ${fmtMoney(worst.spent - avg)} acima da média.'),
          ],
        ]),
      ),
      SectionCard(
        title: 'Rendimentos vs despesas',
        subtitle: 'Se a linha das despesas passa a dos rendimentos, estás a gastar mais do que ganhas',
        child: SizedBox(
          height: 180,
          child: LineChart(LineChartData(
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            minY: 0,
            maxY: ([maxY, ...pts.map((p) => p.income.toDouble())].reduce((x, y) => x > y ? x : y)) * 1.15,
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: n > 12 ? (n / 8).ceilToDouble() : 1,
                  getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 6), child: Text(mlabel(pts[v.toInt()].month), style: tt.labelSmall)),
                ),
              ),
            ),
            lineTouchData: LineTouchData(touchTooltipData: LineTouchTooltipData(getTooltipItems: (spots) => [for (final sp in spots) LineTooltipItem(fmtMoney(sp.y.round()), TextStyle(color: sp.bar.color, fontWeight: FontWeight.w700, fontSize: 12))])),
            lineBarsData: [
              LineChartBarData(spots: [for (var i = 0; i < pts.length; i++) FlSpot(i.toDouble(), pts[i].income.toDouble())], isCurved: false, color: Colors.green.shade500, barWidth: 3, dotData: const FlDotData(show: false)),
              LineChartBarData(spots: [for (var i = 0; i < pts.length; i++) FlSpot(i.toDouble(), pts[i].spent.toDouble())], isCurved: false, color: Colors.red.shade400, barWidth: 3, dotData: const FlDotData(show: false)),
            ],
          )),
        ),
      ),
      SectionCard(
        title: 'Mês a mês',
        child: Column(children: [
          Row(children: [
            Expanded(flex: 3, child: Text('Mês', style: tt.labelSmall)),
            Expanded(flex: 3, child: Text('Despesas', style: tt.labelSmall, textAlign: TextAlign.right)),
            Expanded(flex: 3, child: Text('Saldo', style: tt.labelSmall, textAlign: TextAlign.right)),
            Expanded(flex: 2, child: Text('Poup.', style: tt.labelSmall, textAlign: TextAlign.right)),
          ]),
          const Divider(height: 14),
          for (final p in pts.reversed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                Expanded(flex: 3, child: Text(fmtMonthShort(p.month))),
                // meses sem despesas registadas não têm saldo nem taxa de poupança com significado
                Expanded(flex: 3, child: Text(p.spent == 0 ? '–' : fmtMoney(p.spent), textAlign: TextAlign.right)),
                Expanded(flex: 3, child: Text(p.spent == 0 ? '–' : fmtMoney(p.balance), textAlign: TextAlign.right, style: TextStyle(color: p.balance >= 0 ? Colors.green.shade500 : Colors.red.shade400, fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text(p.spent == 0 || p.savingsRate == null ? '–' : fmtPercent(p.savingsRate!), textAlign: TextAlign.right)),
              ]),
            ),
        ]),
      ),
      SectionCard(
        title: 'Evolução por categoria',
        subtitle: 'Escolhe uma categoria para a ver mês a mês',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          DropdownButtonFormField<int?>(
            initialValue: categoryId,
            isExpanded: true,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.category_outlined), hintText: 'Escolher categoria'),
            items: [
              const DropdownMenuItem(value: null, child: Text('— nenhuma —')),
              for (final r in roots) DropdownMenuItem(value: r.id, child: Text('${r.emoji.isEmpty ? '🏷️' : r.emoji}  ${r.name}', overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => setState(() => categoryId = v),
          ),
          if (catSeries != null) ...[
            const SizedBox(height: 14),
            bars(
              [for (var i = 0; i < catSeries.length; i++) BarChartGroupData(x: i, barRods: [BarChartRodData(toY: catSeries[i].toDouble(), width: n > 12 ? 9 : 18, color: cs.primary, borderRadius: BorderRadius.circular(5))])],
              maxYv: catMax.toDouble(),
              tip: (i) => '${fmtMonth(pts[i].month)}\n${fmtMoney(catSeries![i])}',
            ),
            const SizedBox(height: 8),
            Builder(builder: (_) {
              final nz = catSeries!.where((v) => v > 0).toList();
              final m = nz.isEmpty ? 0 : (nz.reduce((x, y) => x + y) / nz.length).round();
              return Text('Média nos meses com gasto: ${fmtMoney(m)}.', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant));
            }),
          ],
        ]),
      ),
    ]);
  }

  Widget _dot(Color c, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(t, style: Theme.of(context).textTheme.bodySmall),
      ]);
}
