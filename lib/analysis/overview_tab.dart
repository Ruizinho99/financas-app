import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
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
  const OverviewTab({
    super.key,
    required this.a,
    required this.periodLabel,
    required this.compare,
    required this.onSavings,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(l.anNoDataPeriod, textAlign: TextAlign.center),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        // ----- resumo -----
        SectionCard(
          title: periodLabel,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.anExpenses,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        fmtMoney(a.spent),
                        style: tt.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (compare)
                    DeltaChip(
                      cur: a.spent,
                      prev: a.prevSpent,
                      showAmount: false,
                    ),
                ],
              ),
              if (compare && (a.prevSpent > 0 || a.spent > 0))
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    a.ongoing
                        ? l.anSamePeriodPrev(fmtMoney(a.prevSpent))
                        : l.anPrevPeriodAmount(fmtMoney(a.prevSpent)),
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              if (a.ongoing)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    l.anOngoingToday(a.today.day),
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 28,
                runSpacing: 14,
                children: [
                  Stat(
                    l.anIncomes,
                    fmtMoney(a.income),
                    color: Colors.green.shade500,
                    extra: compare
                        ? DeltaChip(
                            cur: a.income,
                            prev: a.prevIncome,
                            upIsBad: false,
                          )
                        : null,
                  ),
                  Stat(
                    l.anBalance,
                    fmtMoney(a.balance),
                    color: a.balance >= 0
                        ? Colors.green.shade500
                        : Colors.red.shade400,
                  ),
                  if (a.invested != 0)
                    Stat(
                      l.anInvested,
                      fmtMoney(a.invested),
                      extra: a.income > 0
                          ? Text(
                              l.anOfIncome(fmtPercent(a.invested / a.income)),
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            )
                          : null,
                    ),
                  if (rate != null)
                    Stat(
                      l.anSavingsRate,
                      fmtPercent(rate),
                      extra: compare && prevRate != null
                          ? Text(
                              l.anPpVsPrev(
                                rate - prevRate >= 0 ? '+' : '−',
                                ((rate - prevRate).abs() * 100).round(),
                              ),
                              style: tt.bodySmall?.copyWith(
                                color: rate >= prevRate
                                    ? Colors.green.shade500
                                    : Colors.red.shade400,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : null,
                    ),
                ],
              ),
              if (a.incomeFromSalary ||
                  (a.ongoing && a.income > a.incomeReceived))
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    a.ongoing ? l.anIncomeExpected : l.anIncomeFromSalary,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              if (rate != null) ...[
                const SizedBox(height: 14),
                ShareBar(
                  ratio: rate.clamp(0.0, 1.0),
                  color: rate >= 0.2
                      ? Colors.green.shade500
                      : (rate >= 0
                            ? Colors.orange.shade600
                            : Colors.red.shade400),
                  height: 8,
                ),
                const SizedBox(height: 6),
                Text(
                  a.ongoing
                      ? l.anRateOngoing
                      : (rate >= 0.2
                            ? l.anRateExcellent
                            : (rate >= 0
                                  ? l.anRateOk(fmtPercent(rate))
                                  : l.anRateNegative)),
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),

        // ----- ritmo e projeção -----
        SectionCard(
          title: l.anPace,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 28,
                runSpacing: 12,
                children: [
                  Stat(l.anAvgPerDay, fmtMoney(a.dailyAvg)),
                  Stat(l.transactions, '${a.count}'),
                  Stat(l.anAvgValue, fmtMoney(a.avgTicket)),
                ],
              ),
              if (pr != null) ...[
                const SizedBox(height: 18),
                Row(
                  children: [
                    Text(
                      l.anDayOf(pr.elapsedDays, pr.totalDays),
                      style: tt.bodySmall,
                    ),
                    const Spacer(),
                    Text(
                      l.anOfMonth(fmtPercent(pr.elapsedDays / pr.totalDays)),
                      style: tt.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ShareBar(
                  ratio: pr.elapsedDays / pr.totalDays,
                  color: cs.primary,
                  height: 8,
                ),
                const SizedBox(height: 12),
                Callout(
                  icon: Icons.trending_up,
                  color: pr.budget != null && pr.projected > pr.budget!
                      ? Colors.red.shade400
                      : cs.primary,
                  title: l.anProjected(fmtMoney(pr.projected)),
                  body: pr.budget == null
                      ? (a.prevSpent > 0
                            ? l.anPrevMonthSpent(fmtMoney(a.prevSpent))
                            : null)
                      : (pr.projected > pr.budget!
                            ? l.anAboveBudget(
                                fmtMoney(pr.projected - pr.budget!),
                                fmtMoney(pr.budget!),
                              )
                            : l.anWithinBudget(
                                fmtMoney(pr.budget!),
                                fmtMoney(pr.budget! - pr.projected),
                              )),
                ),
              ],
            ],
          ),
        ),

        // ----- obrigatórias vs opcionais -----
        SectionCard(
          title: l.anMandVsOpt,
          subtitle: l.anMandVsOptSub,
          child: a.spent == 0
              ? Text(l.anNoSpendPeriod)
              : Column(
                  children: [
                    Center(
                      child: Donut(
                        items: [
                          DonutItem(l.anMandatory, a.mandatoryTotal, mandColor),
                          DonutItem(l.anOptional, a.optionalTotal, optColor),
                          DonutItem(
                            l.anNoCategory,
                            a.unclassifiedTotal,
                            Colors.blueGrey,
                          ),
                        ],
                        centerTop: l.anTotal,
                        centerBottom: fmtMoney(a.spent, short: true),
                      ),
                    ),
                    const SizedBox(height: 16),
                    LegendRow(
                      color: mandColor,
                      label: l.anMandatory,
                      value: fmtMoney(a.mandatoryTotal),
                      share: fmtPercent(a.mandatoryTotal / a.spent),
                      trailing: compare
                          ? DeltaChip(
                              cur: a.mandatoryTotal,
                              prev: a.prevMandatory,
                            )
                          : null,
                    ),
                    LegendRow(
                      color: optColor,
                      label: l.anOptional,
                      value: fmtMoney(a.optionalTotal),
                      share: fmtPercent(a.optionalTotal / a.spent),
                      trailing: compare
                          ? DeltaChip(
                              cur: a.optionalTotal,
                              prev: a.prevOptional,
                            )
                          : null,
                    ),
                    if (a.unclassifiedTotal > 0)
                      LegendRow(
                        color: Colors.blueGrey,
                        label: l.anNoCategory,
                        value: fmtMoney(a.unclassifiedTotal),
                        share: fmtPercent(a.unclassifiedTotal / a.spent),
                      ),
                    if (a.income > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          l.anPctOfIncome(
                            fmtPercent(a.mandatoryTotal / a.income),
                            fmtPercent(a.optionalTotal / a.income),
                            fmtPercent(a.balance / a.income),
                          ),
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
        ),

        // ----- orçamento -----
        if (stats.isNotEmpty)
          SectionCard(
            title: l.budget,
            subtitle: a.filter.isActive ? l.anBudgetSubFiltered : l.anBudgetSub,
            child: Column(
              children: [
                for (final x in stats.take(6))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CatBadge(x.category, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                x.category.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${fmtMoney(x.spent)} / ${fmtMoney(x.target)}',
                              style: tt.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        BudgetBar(
                          spent: x.spent < 0 ? 0 : x.spent,
                          target: x.target,
                          type: x.category.budgetType,
                          height: 8,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _budgetNote(l, x),
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
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
                child: Row(
                  children: [
                    Icon(Icons.savings_outlined, color: cs.primary, size: 32),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.anWhereSave,
                            style: tt.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l.anFoundUpTo(fmtMoney(potential)),
                            style: tt.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _budgetNote(AppLocalizations l, CategoryStat x) {
    final left = x.target - x.spent;
    if (x.category.budgetType == BudgetType.goal) {
      return x.ratio >= 1
          ? l.anGoalReached
          : l.anGoalLeft(fmtMoney(left), fmtPercent(x.ratio));
    }
    if (x.ratio > 1) return l.anOverLimit(fmtMoney(-left));
    if (x.ratio >= 0.85) return l.anNearLimit(fmtMoney(left));
    return l.anLeftUsed(fmtMoney(left), fmtPercent(x.ratio));
  }
}
