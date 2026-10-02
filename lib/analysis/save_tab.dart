import 'package:flutter/material.dart';

import '../util/format.dart';
import 'analytics.dart';
import 'widgets.dart';

/// Onde posso poupar: potencial, simulador, sugestões concretas, pagamentos recorrentes e pequenas compras.
class SaveTab extends StatefulWidget {
  final Analytics a;
  /// Abre a categoria na aba "Gastos" (aplica o filtro).
  final ValueChanged<int> onViewCategory;
  const SaveTab({super.key, required this.a, required this.onViewCategory});
  @override
  State<SaveTab> createState() => _SaveTabState();
}

class _SaveTabState extends State<SaveTab> {
  double cut = 0.10;

  (IconData, Color) _look(InsightKind k, ColorScheme cs) => switch (k) {
        InsightKind.overBudget => (Icons.error_outline, Colors.red.shade400),
        InsightKind.increase => (Icons.trending_up, Colors.orange.shade600),
        InsightKind.topOptional => (Icons.tune, cs.primary),
        InsightKind.smallFrequent => (Icons.coffee_outlined, Colors.brown.shade400),
        InsightKind.recurring => (Icons.autorenew, Colors.blue.shade400),
        InsightKind.unclassified => (Icons.label_off_outlined, Colors.blueGrey),
      };

  @override
  Widget build(BuildContext context) {
    final a = widget.a;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    if (a.spends.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Sem despesas neste período para analisar.', textAlign: TextAlign.center)));
    }
    final insights = a.insights();
    final potential = insights.fold(0, (x, e) => x + (e.monthlySaving ?? 0));
    final rec = a.recurring();
    final small = a.frequentSmall();
    final sim = a.simulate(cut);
    final rate = a.savingsRate;

    return ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 32), children: [
      // ----- potencial -----
      Card(
        color: cs.primaryContainer.withValues(alpha: 0.45),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(Icons.savings_outlined, color: cs.primary), const SizedBox(width: 8), Text('Potencial de poupança', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700))]),
            const SizedBox(height: 10),
            if (potential > 0) ...[
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(fmtMoney(potential), style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: cs.primary)))),
                const SizedBox(width: 6),
                Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('por mês', style: tt.bodyMedium)),
              ]),
              const SizedBox(height: 4),
              Text('Isso são até ${fmtMoney(potential * 12)} por ano, só com as sugestões abaixo.', style: tt.bodySmall),
            ] else
              Text('Neste período não encontrámos margens óbvias. Experimenta outro intervalo ou o simulador.', style: tt.bodyMedium),
          ]),
        ),
      ),

      // ----- simulador -----
      SectionCard(
        title: 'E se cortasse nas opcionais?',
        subtitle: 'Despesas opcionais neste período: ${fmtMoney(a.optionalTotal)}',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text('Cortar', style: tt.bodyMedium),
            Text(fmtPercent(cut), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: cs.primary)),
            const SizedBox(width: 8),
            for (final p in [0.05, 0.10, 0.20])
              ChoiceChip(label: Text('${(p * 100).round()}%'), selected: (cut - p).abs() < 0.001, onSelected: (_) => setState(() => cut = p), visualDensity: VisualDensity.compact),
          ]),
          Slider(value: cut, min: 0, max: 0.5, divisions: 10, label: fmtPercent(cut), onChanged: (v) => setState(() => cut = v)),
          const SizedBox(height: 4),
          Wrap(spacing: 28, runSpacing: 12, children: [
            Stat('Poupas por mês', fmtMoney(sim.monthly), color: Colors.green.shade500),
            Stat('Poupas por ano', fmtMoney(sim.yearly), color: Colors.green.shade500),
            if (rate != null && sim.newRate != null) Stat('Taxa de poupança', '${fmtPercent(rate)} → ${fmtPercent(sim.newRate!)}'),
          ]),
        ]),
      ),

      // ----- sugestões -----
      if (insights.isNotEmpty)
        SectionCard(
          title: 'Sugestões',
          subtitle: 'Ordenadas pelo que mais poupa',
          child: Column(children: [
            for (var i = 0; i < insights.length; i++) ...[
              if (i > 0) const Divider(height: 16),
              Builder(builder: (context) {
                final ins = insights[i];
                final (icon, color) = _look(ins.kind, cs);
                return Callout(
                  icon: icon,
                  color: color,
                  title: ins.title,
                  body: ins.detail,
                  trailing: ins.monthlySaving != null && ins.monthlySaving! > 0 ? SavingChip(ins.monthlySaving!) : null,
                  onTap: ins.categoryId == null ? null : () => widget.onViewCategory(ins.categoryId!),
                );
              }),
            ],
          ]),
        ),

      // ----- recorrentes -----
      if (rec.isNotEmpty)
        SectionCard(
          title: 'Pagamentos recorrentes',
          subtitle: () {
            final opt = rec.where((e) => !e.mandatory);
            final man = rec.where((e) => e.mandatory);
            final o = opt.fold(0, (x, e) => x + e.monthly), m = man.fold(0, (x, e) => x + e.monthly);
            return [
              if (opt.isNotEmpty) 'Opcionais: ${fmtMoney(o)}/mês (${fmtMoney(o * 12)}/ano)',
              if (man.isNotEmpty) 'Obrigatórios: ${fmtMoney(m)}/mês',
            ].join(' · ');
          }(),
          child: Column(children: [
            for (final r in rec.take(12))
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: SizedBox(width: 28, child: Text(r.emoji.isEmpty ? '🔁' : r.emoji, style: const TextStyle(fontSize: 20), textAlign: TextAlign.center)),
                title: Text(r.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text('${r.months} meses · último ${fmtDate(r.last)}'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: (r.mandatory ? cs.outline : cs.primary).withValues(alpha: 0.16), borderRadius: BorderRadius.circular(8)),
                    child: Text(r.mandatory ? 'obrigatória' : 'opcional', style: TextStyle(fontSize: 11, color: r.mandatory ? cs.onSurfaceVariant : cs.primary, fontWeight: FontWeight.w600)),
                  ),
                ]),
                trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${fmtMoney(r.monthly)}/mês', style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('${fmtMoney(r.yearly)}/ano', style: tt.bodySmall),
                ]),
              ),
            const SizedBox(height: 4),
            Text('Cancelar o que já não usas é a forma mais fácil de poupar.', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ]),
        ),

      // ----- pequenas compras -----
      if (small.isNotEmpty)
        SectionCard(
          title: 'Pequenas compras frequentes',
          subtitle: 'Compras de baixo valor que se repetem muito',
          child: Column(children: [
            for (final sl in small.take(8))
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: SizedBox(width: 28, child: Text(sl.emoji.isEmpty ? '🛍️' : sl.emoji, style: const TextStyle(fontSize: 20), textAlign: TextAlign.center)),
                title: Text(sl.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${sl.count} compras · média ${fmtMoney(sl.avg)}'),
                trailing: Text(fmtMoney(sl.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
          ]),
        ),
    ]);
  }
}
