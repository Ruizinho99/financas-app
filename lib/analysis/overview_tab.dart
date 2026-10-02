import 'package:flutter/material.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import '../widgets/common.dart';
import 'analytics.dart';
import 'widgets.dart';

/// Resumo: quanto gastei, como estou face ao mês/ano anterior, ritmo, projeção e orçamento.
class OverviewTab extends StatelessWidget {
  final Analytics a;
  final String periodLabel;
  final bool compare;
  final VoidCallback onSavings;
  const OverviewTab({super.key, required this.a, required this.periodLabel, required this.compare, required this.onSavings});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final rate = a.savingsRate;
    final prevRate = a.prevSavingsRate;
    final hasData = a.spends.isNotEmpty || a.income > 0;
    final pr = a.projection();
    final stats = a.budgetStats();
    final potential = a.potentialMonthly;
    final mandColor = cs.primary, optColor = cs.tertiary;

    if (!hasData) {
      return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Sem movimentos neste período (ou os filtros não encontram nada).', textAlign: TextAlign.center)));
    }

    return ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 32), children: [
      // ----- resumo -----
      SectionCard(
        title: periodLabel,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Despesas', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 2),
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(fmtMoney(a.spent), style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800)))),
            const SizedBox(width: 10),
            if (compare) DeltaChip(cur: a.spent, prev: a.prevSpent, showAmount: false),
          ]),
          if (compare && (a.prevSpent > 0 || a.spent > 0))
            Padding(padding: const EdgeInsets.only(top: 2), child: Text('${a.ongoing ? 'Mesmos dias do período anterior' : 'Período anterior'}: ${fmtMoney(a.prevSpent)}', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))),
          if (a.ongoing)
            Padding(padding: const EdgeInsets.only(top: 6), child: Text('Período em curso: valores até hoje (dia ${a.today.day}).', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontStyle: FontStyle.italic))),
          const SizedBox(height: 18),
          Wrap(spacing: 28, runSpacing: 14, children: [
            Stat('Rendimentos', fmtMoney(a.income), color: Colors.green.shade500, extra: compare ? DeltaChip(cur: a.income, prev: a.prevIncome, upIsBad: false) : null),
            Stat('Saldo', fmtMoney(a.balance), color: a.balance >= 0 ? Colors.green.shade500 : Colors.red.shade400),
            if (rate != null)
              Stat('Taxa de poupança', fmtPercent(rate),
                  extra: compare && prevRate != null
                      ? Text('${rate - prevRate >= 0 ? '+' : '−'}${((rate - prevRate).abs() * 100).round()} pp vs anterior',
                          style: tt.bodySmall?.copyWith(color: rate >= prevRate ? Colors.green.shade500 : Colors.red.shade400, fontWeight: FontWeight.w600))
                      : null),
          ]),
          if (a.incomeFromSalary || (a.ongoing && a.income > a.incomeReceived))
            Padding(padding: const EdgeInsets.only(top: 12), child: Text(a.ongoing ? 'Rendimento esperado: salário líquido definido no Orçamento.' : 'Sem rendimentos categorizados: a usar o salário líquido definido no Orçamento.', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))),
          if (rate != null) ...[
            const SizedBox(height: 14),
            ShareBar(ratio: rate.clamp(0.0, 1.0), color: rate >= 0.2 ? Colors.green.shade500 : (rate >= 0 ? Colors.orange.shade600 : Colors.red.shade400), height: 8),
            const SizedBox(height: 6),
            Text(a.ongoing ? 'Período em curso: a taxa de poupança vai mudando até ao fim.' : (rate >= 0.2 ? 'Estás a poupar mais de 20% do que ganhas. Excelente.' : (rate >= 0 ? 'Poupas ${fmtPercent(rate)}. Uma boa meta é 20%.' : 'Estás a gastar mais do que ganhas neste período.')),
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ]),
      ),

      // ----- ritmo e projeção -----
      SectionCard(
        title: 'Ritmo de gastos',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(spacing: 28, runSpacing: 12, children: [
            Stat('Média por dia', fmtMoney(a.dailyAvg)),
            Stat('Movimentos', '${a.count}'),
            Stat('Valor médio', fmtMoney(a.avgTicket)),
          ]),
          if (pr != null) ...[
            const SizedBox(height: 18),
            Row(children: [
              Text('Dia ${pr.elapsedDays} de ${pr.totalDays}', style: tt.bodySmall),
              const Spacer(),
              Text('${fmtPercent(pr.elapsedDays / pr.totalDays)} do mês', style: tt.bodySmall),
            ]),
            const SizedBox(height: 6),
            ShareBar(ratio: pr.elapsedDays / pr.totalDays, color: cs.primary, height: 8),
            const SizedBox(height: 12),
            Callout(
              icon: Icons.trending_up,
              color: pr.budget != null && pr.projected > pr.budget! ? Colors.red.shade400 : cs.primary,
              title: 'Ao ritmo atual, o mês fecha em ${fmtMoney(pr.projected)}',
              body: pr.budget == null
                  ? (a.prevSpent > 0 ? 'No mês anterior gastaste ${fmtMoney(a.prevSpent)}.' : null)
                  : (pr.projected > pr.budget!
                      ? 'Isso são ${fmtMoney(pr.projected - pr.budget!)} acima do orçamento de ${fmtMoney(pr.budget!)}.'
                      : 'Dentro do orçamento de ${fmtMoney(pr.budget!)}, com folga de ${fmtMoney(pr.budget! - pr.projected)}.'),
            ),
          ],
        ]),
      ),

      // ----- obrigatórias vs opcionais -----
      SectionCard(
        title: 'Obrigatórias vs opcionais',
        subtitle: 'O que tens de pagar vs onde tens margem para poupar',
        child: a.spent == 0
            ? const Text('Sem despesas neste período.')
            : Column(children: [
                Center(
                  child: Donut(
                    items: [DonutItem('Obrigatórias', a.mandatoryTotal, mandColor), DonutItem('Opcionais', a.optionalTotal, optColor), DonutItem('Sem categoria', a.unclassifiedTotal, Colors.blueGrey)],
                    centerTop: 'Total',
                    centerBottom: fmtMoney(a.spent, short: true),
                  ),
                ),
                const SizedBox(height: 16),
                LegendRow(color: mandColor, label: 'Obrigatórias', value: fmtMoney(a.mandatoryTotal), share: fmtPercent(a.mandatoryTotal / a.spent), trailing: compare ? DeltaChip(cur: a.mandatoryTotal, prev: a.prevMandatory) : null),
                LegendRow(color: optColor, label: 'Opcionais', value: fmtMoney(a.optionalTotal), share: fmtPercent(a.optionalTotal / a.spent), trailing: compare ? DeltaChip(cur: a.optionalTotal, prev: a.prevOptional) : null),
                if (a.unclassifiedTotal > 0) LegendRow(color: Colors.blueGrey, label: 'Sem categoria', value: fmtMoney(a.unclassifiedTotal), share: fmtPercent(a.unclassifiedTotal / a.spent)),
                if (a.income > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Em % dos rendimentos: obrigatórias ${fmtPercent(a.mandatoryTotal / a.income)}, opcionais ${fmtPercent(a.optionalTotal / a.income)}, sobra ${fmtPercent(a.balance / a.income)}.',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
              ]),
      ),

      // ----- orçamento -----
      if (stats.isNotEmpty)
        SectionCard(
          title: 'Orçamento',
          subtitle: 'Limites e objetivos definidos${a.filter.isActive ? ' (não depende dos filtros)' : ''}',
          child: Column(children: [
            for (final x in stats.take(6))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    CatBadge(x.category, size: 18),
                    const SizedBox(width: 6),
                    Expanded(child: Text(x.category.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
                    Text('${fmtMoney(x.spent)} / ${fmtMoney(x.target)}', style: tt.bodySmall),
                  ]),
                  const SizedBox(height: 6),
                  BudgetBar(spent: x.spent < 0 ? 0 : x.spent, target: x.target, type: x.category.budgetType, height: 8),
                  const SizedBox(height: 4),
                  Text(_budgetNote(x), style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ]),
              ),
          ]),
        ),

      // ----- convite para a poupança -----
      if (potential > 0)
        Card(
          color: cs.primaryContainer.withValues(alpha: 0.45),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onSavings,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Icon(Icons.savings_outlined, color: cs.primary, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Onde posso poupar?', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('Encontrámos até ${fmtMoney(potential)} por mês de margem.', style: tt.bodySmall),
                  ]),
                ),
                const Icon(Icons.chevron_right),
              ]),
            ),
          ),
        ),
    ]);
  }

  String _budgetNote(CategoryStat x) {
    final left = x.target - x.spent;
    if (x.category.budgetType == BudgetType.goal) {
      return x.ratio >= 1 ? 'Objetivo atingido 🎉' : 'Faltam ${fmtMoney(left)} para o objetivo (${fmtPercent(x.ratio)})';
    }
    if (x.ratio > 1) return 'Excedeste o limite em ${fmtMoney(-left)}';
    if (x.ratio >= 0.85) return 'Perto do limite: restam ${fmtMoney(left)}';
    return 'Restam ${fmtMoney(left)} (${fmtPercent(x.ratio)} usado)';
  }
}
