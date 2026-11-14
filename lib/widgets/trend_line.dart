import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../util/format.dart';

/// Linha com área suave: a evolução de valores em cêntimos. [target] (opcional) desenha uma linha tracejada.
class TrendLine extends StatelessWidget {
  final List<int> cents;
  final List<String> labels; // um por ponto (usado no tooltip)
  final int? target;
  final double height;
  const TrendLine({
    super.key,
    required this.cents,
    required this.labels,
    this.target,
    this.height = 110,
  });

  @override
  Widget build(BuildContext context) {
    if (cents.length < 2) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    var lo = cents.reduce((a, b) => a < b ? a : b).toDouble();
    var hi = cents.reduce((a, b) => a > b ? a : b).toDouble();
    if (target != null && target! > hi) hi = target!.toDouble();
    if (hi == lo) hi = lo + 100;
    final pad = (hi - lo) * 0.1;
    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: lo - pad,
          maxY: hi + pad,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          extraLinesData: target == null
              ? null
              : ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: target!.toDouble(),
                      color: cs.outline,
                      strokeWidth: 1,
                      dashArray: [4, 3],
                    ),
                  ],
                ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => [
                for (final sp in spots)
                  LineTooltipItem(
                    '${labels[sp.x.toInt()]}\n${fmtMoney(sp.y.round())}',
                    TextStyle(color: cs.onInverseSurface, fontSize: 12),
                  ),
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < cents.length; i++)
                  FlSpot(i.toDouble(), cents[i].toDouble()),
              ],
              isCurved: true,
              curveSmoothness: 0.2,
              preventCurveOverShooting: true,
              color: cs.primary,
              barWidth: 2,
              dotData: FlDotData(
                getDotPainter: (spot, p, bar, i) => FlDotCirclePainter(
                  radius: i == cents.length - 1 ? 4 : 0,
                  color: cs.primary,
                  strokeColor: cs.surface,
                  strokeWidth: 2,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: cs.primary.withValues(alpha: 0.10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
