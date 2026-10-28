import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import '../invest/plan_widgets.dart';
import '../widgets/common.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  // o mês da app em foco (nomeado pelo mês em que termina)
  late DateTime month = _keyToMonth(context.read<AppState>().currentMonthKey);

  static DateTime _keyToMonth(String k) =>
      DateTime(int.parse(k.substring(0, 4)), int.parse(k.substring(5, 7)));

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final l = AppLocalizations.of(context)!;
    final key = monthKey(month);
    final period = s.periodOfMonth(key);
    final salary = s.salaryFor(key);
    final own = s.totalsByCategory(period);
    final allocated = s.totalAllocated(salary, key);
    final income = s
        .txnsIn(period)
        .where(s.isIncomeTxn)
        .fold(0, (a, t) => a + s.effectiveAmount(t));
    // só categorias que existem neste mês (ou que tiveram movimentos nele)
    final expenseRoots = s.roots
        .where(
          (c) =>
              // categorias que eram só de receita só aparecem se tiverem orçamento ou gastos
              (!c.isIncome || c.hasBudget || s.rollup(c, own) != 0) &&
              (s.isCategoryActive(c, key) || s.rollup(c, own) != 0),
        )
        .toList();
    final unallocated = salary - allocated;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.budget),
        actions: [
          IconButton(
            tooltip: l.bpCopySalaryTooltip,
            icon: const Icon(Icons.payments_outlined),
            onPressed: () => showSalaryEditor(context, s, key),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(
                  () => month = DateTime(month.year, month.month - 1),
                ),
              ),
              Text(
                fmtMonth(month),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(
                  () => month = DateTime(month.year, month.month + 1),
                ),
              ),
            ],
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.bpNetSalary,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => showSalaryEditor(context, s, key),
                        icon: const Icon(Icons.edit, size: 18),
                        label: Text(salary == 0 ? l.bpSet : fmtMoney(salary)),
                      ),
                    ],
                  ),
                  if (s.salaries.containsKey(key))
                    Text(l.bpSpecificThisMonth, style: TextStyle(fontSize: 12)),
                  if (salary > 0) ...[
                    const SizedBox(height: 8),
                    BudgetBar(
                      spent: allocated,
                      target: salary,
                      type: BudgetType.limit,
                      height: 14,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${l.bpAllocatedSummary(fmtMoney(allocated), fmtPercent(allocated / salary))}  ·  ${unallocated >= 0 ? l.bpUnallocatedLeft(fmtMoney(unallocated)) : l.bpOverAllocated(fmtMoney(-unallocated))}',
                      style: TextStyle(
                        color: unallocated < 0 ? Colors.red : null,
                      ),
                    ),
                    if (income > 0)
                      Text(
                        l.bpIncomeThisMonth(fmtMoney(income)),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(l.bpDefineSalaryHint),
                    ),
                ],
              ),
            ),
          ),
          if (expenseRoots.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l.bpNoCategoriesBudget, textAlign: TextAlign.center),
            )
          else
            _section(
              context,
              s,
              l.bpCategories,
              expenseRoots,
              own,
              salary,
              key,
            ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(l.bpNewCategory),
              onPressed: () => showCategoryEditor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(
    BuildContext context,
    AppState s,
    String title,
    List<Categoria> cats,
    Map<int, int> own,
    int salary,
    String month,
  ) {
    if (cats.isEmpty) return const SizedBox.shrink();
    final total = cats.fold(
      0,
      (a, c) => a + s.effectiveMonthlyTarget(c, salary, month),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
          child: Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (total > 0)
                Text(
                  '${fmtMoney(total)}${salary > 0 ? '  ·  ${fmtPercent(total / salary)}' : ''}',
                ),
            ],
          ),
        ),
        for (final c in cats)
          _CategoryBudgetTile(
            category: c,
            own: own,
            salary: salary,
            month: month,
          ),
        const SizedBox(height: 16),
        const InvestPlanCard(),
      ],
    );
  }
}

class _CategoryBudgetTile extends StatelessWidget {
  final Categoria category;
  final Map<int, int> own;
  final int salary;
  final String month;
  const _CategoryBudgetTile({
    required this.category,
    required this.own,
    required this.salary,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final l = AppLocalizations.of(context)!;
    final c = category;
    final kids = s
        .childrenOf(c.id)
        .where((k) => s.isCategoryActive(k, month) || (own[k.id] ?? 0) != 0)
        .toList();
    final spent = s.rollup(c, own);
    final target = s.effectiveMonthlyTarget(c, salary, month);
    final hasAny = target > 0;
    final type = c.hasBudget
        ? c.budgetType
        : (kids.firstWhere((k) => k.hasBudget, orElse: () => c).budgetType);
    return Card(
      margin: const EdgeInsets.only(top: 6),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: CatBadge(c),
        title: Text(
          c.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: hasAny
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BudgetBar(
                      spent: spent < 0 ? 0 : spent,
                      target: target,
                      type: type,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.bpSpentOfTarget(
                        fmtMoney(spent),
                        fmtMoney(target),
                        type == BudgetType.limit
                            ? l.bpBudgetLimit
                            : l.bpBudgetGoal,
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                )
              : Text(
                  l.bpSpentNoBudget(fmtMoney(spent)),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
        ),
        children: [
          Builder(
            builder: (_) {
              final direct = s.isMandatoryDirect(c, month);
              final inherited = !direct && s.isMandatory(c, month);
              return SwitchListTile(
                dense: true,
                title: Text(
                  l.bpMandatoryInMonth(
                    fmtMonth(
                      DateTime(
                        int.parse(month.substring(0, 4)),
                        int.parse(month.substring(5, 7)),
                      ),
                    ),
                  ),
                ),
                subtitle: Text(
                  inherited ? l.bpInheritedFromParent : l.bpOnlyThisMonthHint,
                ),
                value: direct || inherited,
                onChanged: inherited
                    ? null
                    : (v) => s.setMandatoryInMonth(c.id, month, v),
              );
            },
          ),
          ListTile(
            dense: true,
            title: Text(
              c.hasBudget
                  ? _describe(l, c, salary)
                  : l.bpCategoryBudgetOptional,
            ),
            subtitle: kids.any((k) => k.hasBudget) && !c.hasBudget
                ? Text(l.bpSumOfSubcategories)
                : null,
            trailing: const Icon(Icons.edit, size: 18),
            onTap: () => showBudgetEditor(context, c),
          ),
          for (final k in kids) _subTile(context, s, k),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => showCategoryEditor(context, parentId: c.id),
                icon: const Icon(Icons.add),
                label: Text(l.bpSubcategory),
              ),
              TextButton.icon(
                onPressed: () => showMandatoryDialog(context, c),
                icon: const Icon(Icons.event_repeat),
                label: Text(l.bpPeriods),
              ),
              TextButton.icon(
                onPressed: () => showCategoryEditor(context, edit: c),
                icon: const Icon(Icons.settings_outlined),
                label: Text(l.bpEdit),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _subTile(BuildContext context, AppState s, Categoria k) {
    final l = AppLocalizations.of(context)!;
    final spent = own[k.id] ?? 0;
    final t = k.monthlyTarget(salary);
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 32, right: 16),
      title: Text(k.name),
      subtitle: k.hasBudget
          ? Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BudgetBar(
                    spent: spent < 0 ? 0 : spent,
                    target: t,
                    type: k.budgetType,
                    height: 8,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l.bpSpentOfTarget(
                      fmtMoney(spent),
                      fmtMoney(t),
                      k.budgetType == BudgetType.limit
                          ? l.bpBudgetLimit
                          : l.bpBudgetGoal,
                    ),
                  ),
                ],
              ),
            )
          : Text(l.bpSpentSetBudget(fmtMoney(spent))),
      onTap: () => showBudgetEditor(context, k),
    );
  }

  String _describe(AppLocalizations l, Categoria c, int salary) {
    final type = c.budgetType == BudgetType.limit
        ? l.bpBudgetLimit
        : l.bpBudgetGoal;
    return c.budgetPercent
        ? l.bpBudgetDescPercent(
            type,
            (c.budgetValue / 100).toStringAsFixed(1),
            fmtMoney(c.monthlyTarget(salary)),
          )
        : l.bpBudgetDescValue(type, fmtMoney(c.budgetValue));
  }
}

/// Define a alocação de uma categoria/subcategoria.
Future<void> showBudgetEditor(BuildContext context, Categoria c) {
  final s = context.read<AppState>();
  final l = AppLocalizations.of(context)!;
  var has = c.hasBudget;
  var type = c.budgetType;
  var percent = c.budgetPercent;
  final ctrl = TextEditingController(
    text: !c.hasBudget
        ? ''
        : (c.budgetValue / 100).toStringAsFixed(2).replaceAll('.', ','),
  );
  return showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        title: Text(l.bpBudgetEditorTitle(c.name)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.bpHasBudget),
                value: has,
                onChanged: (v) => set(() => has = v),
              ),
              if (has) ...[
                SegmentedButton<BudgetType>(
                  segments: [
                    ButtonSegment(
                      value: BudgetType.limit,
                      label: Text(l.bpBudgetLimit),
                      icon: const Icon(Icons.vertical_align_top),
                    ),
                    ButtonSegment(
                      value: BudgetType.goal,
                      label: Text(l.bpBudgetGoal),
                      icon: const Icon(Icons.flag_outlined),
                    ),
                  ],
                  selected: {type},
                  onSelectionChanged: (v) => set(() => type = v.first),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    type == BudgetType.limit ? l.bpLimitHint : l.bpGoalHint,
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: false,
                      label: Text(l.bpValueWithCurrency(baseSym)),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text(l.bpPercentOfSalary),
                    ),
                  ],
                  selected: {percent},
                  onSelectionChanged: (v) => set(() => percent = v.first),
                ),
                TextField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: percent ? l.bpPercentage : l.bpMonthlyAmount,
                    suffixText: percent ? '%' : baseSym,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () {
              final v = has ? (parseCents(ctrl.text) ?? 0) : 0;
              s.updateCategory(
                c.copyWith(
                  budgetType: type,
                  budgetPercent: percent,
                  budgetValue: v,
                  hasBudget: has && v > 0,
                ),
              );
              Navigator.pop(ctx);
            },
            child: Text(l.bpSave),
          ),
        ],
      ),
    ),
  );
}

/// Edita o salário de um mês (ou o valor por omissão de todos os meses).
Future<void> showSalaryEditor(
  BuildContext context,
  AppState s,
  String key,
) async {
  final l = AppLocalizations.of(context)!;
  final ctrl = TextEditingController(
    text: s.salaryFor(key) == 0
        ? ''
        : (s.salaryFor(key) / 100).toStringAsFixed(2).replaceAll('.', ','),
  );
  var onlyThisMonth = false;
  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        title: Text(l.bpNetSalaryMonthly),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l.bpValueWithCurrency(baseSym),
                suffixText: baseSym,
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.bpOnlyThisMonth),
              subtitle: Text(l.bpSalaryDefaultHint),
              value: onlyThisMonth,
              onChanged: (v) => set(() => onlyThisMonth = v),
            ),
          ],
        ),
        actions: [
          if (s.salaries.containsKey(key))
            TextButton(
              onPressed: () {
                s.setSalary(key, null);
                Navigator.pop(ctx);
              },
              child: Text(l.bpUseBaseSalary),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () {
              final v = parseCents(ctrl.text);
              if (v == null) return;
              if (onlyThisMonth) {
                s.setSalary(key, v);
              } else {
                s.setSalary(key, null);
                s.setDefaultSalary(v);
              }
              Navigator.pop(ctx);
            },
            child: Text(l.bpSave),
          ),
        ],
      ),
    ),
  );
}
