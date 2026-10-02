import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../util/format.dart';

/// Paleta de 8 cores para gráficos, derivada da cor principal da app.
List<Color> chartColors(ColorScheme cs) {
  final hsl = HSLColor.fromColor(cs.primary);
  final dark = cs.brightness == Brightness.dark;
  return [for (var i = 0; i < 8; i++) HSLColor.fromAHSL(1, (hsl.hue + i * 47) % 360, 0.55, dark ? 0.62 : 0.46).toColor()];
}

/// Cartão com título, subtítulo e conteúdo (padrão de todas as secções da Análise).
class SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;
  const SectionCard({super.key, required this.title, this.subtitle, this.trailing, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: padding,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(subtitle!, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))),
              ]),
            ),
            if (trailing != null) trailing!,
          ]),
          const SizedBox(height: 14),
          child,
        ]),
      ),
    );
  }
}

/// Variação face ao período anterior. Em despesas, descer é bom (verde) e subir é mau (vermelho).
class DeltaChip extends StatelessWidget {
  final int cur, prev;
  final bool upIsBad;
  final bool showAmount;
  const DeltaChip({super.key, required this.cur, required this.prev, this.upIsBad = true, this.showAmount = false});

  @override
  Widget build(BuildContext context) {
    final delta = cur - prev;
    if (prev == 0 && cur == 0) return const SizedBox.shrink();
    // variações abaixo de 1% contam como "estável" (cinzento)
    final stable = delta == 0 || (prev > 0 && delta.abs() / prev < 0.01);
    final up = delta > 0;
    final bad = stable ? false : (up == upIsBad);
    final color = stable ? Theme.of(context).colorScheme.onSurfaceVariant : (bad ? Colors.red.shade400 : Colors.green.shade500);
    final pct = stable ? 'estável' : (prev > 0 ? '${delta >= 0 ? '+' : '−'}${(delta.abs() / prev * 100).round()}%' : 'novo');
    final text = showAmount && !stable ? '$pct · ${delta >= 0 ? '+' : '−'}${fmtMoney(delta.abs())}' : pct;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(stable ? Icons.remove : (up ? Icons.arrow_upward : Icons.arrow_downward), size: 13, color: color),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}

/// Valor + legenda (mini estatística).
class Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final Widget? extra;
  const Stat(this.label, this.value, {super.key, this.color, this.extra});
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      const SizedBox(height: 2),
      Text(value, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: color)),
      if (extra != null) Padding(padding: const EdgeInsets.only(top: 4), child: extra!),
    ]);
  }
}

class DonutItem {
  final String label;
  final int value;
  final Color color;
  const DonutItem(this.label, this.value, this.color);
}

/// Gráfico em anel com o total ao centro e legenda ao lado/baixo.
class Donut extends StatelessWidget {
  final List<DonutItem> items;
  final String centerTop;
  final String centerBottom;
  final double size;
  const Donut({super.key, required this.items, required this.centerTop, required this.centerBottom, this.size = 150});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final total = items.fold(0, (a, e) => a + e.value);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        PieChart(PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: size * 0.33,
          sections: [
            for (final e in items.where((e) => e.value > 0))
              PieChartSectionData(value: e.value.toDouble(), color: e.color, title: '', radius: size * 0.16),
            if (total == 0) PieChartSectionData(value: 1, color: cs.outlineVariant, title: '', radius: size * 0.16),
          ],
        )),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text(centerTop, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          Text(centerBottom, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700), maxLines: 1),
        ]),
      ]),
    );
  }
}

class LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final String? share;
  final Widget? trailing;
  const LegendRow({super.key, required this.color, required this.label, required this.value, this.share, this.trailing});
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        Text(value, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        if (share != null) ...[const SizedBox(width: 6), Text(share!, style: tt.bodySmall)],
        if (trailing != null) ...[const SizedBox(width: 6), trailing!],
      ]),
    );
  }
}

/// Barra horizontal fina (parte de um máximo).
class ShareBar extends StatelessWidget {
  final double ratio;
  final Color color;
  final double height;
  const ShareBar({super.key, required this.ratio, required this.color, this.height = 6});
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: Stack(children: [
          Container(height: height, color: color.withValues(alpha: 0.16)),
          FractionallySizedBox(widthFactor: ratio.clamp(0.0, 1.0), child: Container(height: height, color: color)),
        ]),
      );
}

/// Aviso/sugestão com ícone.
class Callout extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? body;
  final Widget? trailing;
  final VoidCallback? onTap;
  const Callout({super.key, required this.icon, required this.color, required this.title, this.body, this.trailing, this.onTap});
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.16), shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              if (body != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(body!, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))),
            ]),
          ),
          if (trailing != null) Padding(padding: const EdgeInsets.only(left: 8), child: trailing!),
        ]),
      ),
    );
  }
}

/// "poupa até €X/mês"
class SavingChip extends StatelessWidget {
  final int monthly;
  const SavingChip(this.monthly, {super.key});
  @override
  Widget build(BuildContext context) {
    final c = Colors.green.shade500;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
      child: Text('até ${fmtMoney(monthly)}/mês', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c)),
    );
  }
}
