import '../invest/category_link.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../budget/budget_stats.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import '../invest/plan_widgets.dart';
import '../widgets/category_editor.dart';
import '../widgets/common.dart';
import 'classify_screen.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

enum _Sort { state, spent, name }

class _BudgetScreenState extends State<BudgetScreen> {
  // o mês da app em foco (nomeado pelo mês em que termina)
  late DateTime month = _keyToMonth(context.read<AppState>().currentMonthKey);
  _Sort sort = _Sort.state;

  static DateTime _keyToMonth(String k) =>
      DateTime(int.parse(k.substring(0, 4)), int.parse(k.substring(5, 7)));

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final l = AppLocalizations.of(context)!;
    final key = monthKey(month);
    final period = s.periodOfMonth(key);
    final salary = s.salaryFor(key);
    final allocated = s.totalAllocated(salary, key);
    // movimentos sem categoria do mês: contam como despesa/receita em "Por classificar"
    final unclassifiedSpent = s.unclassifiedSpent(period);
    final unclassifiedCount = s.txnsIn(period).where(s.isUnclassified).length;
    final rows = budgetRows(s, key, salary);
    final sum = summarize(s, rows);
    final pace = paceOf(period);
    final unallocated = salary - allocated;
    final income = s.incomeIn(period);

    int bySpent(CatBudget a, CatBudget b) => b.spent.compareTo(a.spent);
    final attention =
        rows
            .where(
              (r) =>
                  r.state == BudgetState.over || r.state == BudgetState.below,
            )
            .toList()
          ..sort(bySpent);
    final ok = rows.where((r) => r.state == BudgetState.ok).toList()
      ..sort(bySpent);
    final none = rows.where((r) => r.state == BudgetState.none).toList()
      ..sort(bySpent);
    final flat = [...rows]
      ..sort(
        sort == _Sort.name
            ? (a, b) => a.category.name.toLowerCase().compareTo(
                b.category.name.toLowerCase(),
              )
            : bySpent,
      );

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
          _SummaryCard(
            sum: sum,
            pace: pace,
            period: period,
            salary: salary,
            unallocated: unallocated,
            income: income,
            specificSalary: s.salaries.containsKey(key),
            onEditSalary: () => showSalaryEditor(context, s, key),
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l.bpNoCategoriesBudget, textAlign: TextAlign.center),
            )
          else ...[
            if (sort == _Sort.state) ...[
              _group(
                context,
                l.budGroupAttention(attention.length),
                attention,
                key,
                salary,
                sortable: true,
              ),
              _group(context, l.budGroupOk(ok.length), ok, key, salary),
              _group(context, l.budGroupNone(none.length), none, key, salary),
              if (none.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                  child: Text(
                    l.budSuggestNote,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ] else
              _group(
                context,
                l.budGroupAll(flat.length),
                flat,
                key,
                salary,
                sortable: true,
              ),
          ],
          if (unclassifiedCount > 0)
            Card(
              margin: const EdgeInsets.only(top: 12),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blueGrey,
                  child: Icon(Icons.label_off_outlined, color: Colors.white),
                ),
                title: Text(
                  l.uncLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(l.uncBudgetSubtitle(unclassifiedCount)),
                trailing: unclassifiedSpent > 0
                    ? Text(
                        fmtMoney(unclassifiedSpent),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      )
                    : null,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ClassifyScreen()),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(l.bpNewCategory),
              onPressed: () => showCategoryEditor(context),
            ),
          ),
          const SizedBox(height: 16),
          const InvestPlanCard(),
        ],
      ),
    );
  }

  /// Um grupo de categorias com cabeçalho; [sortable] mostra o seletor de ordem nesse cabeçalho.
  Widget _group(
    BuildContext context,
    String title,
    List<CatBudget> list,
    String key,
    int salary, {
    bool sortable = false,
  }) {
    if (list.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    final modeLabel = switch (sort) {
      _Sort.state => l.budSortState,
      _Sort.spent => l.budSortSpent,
      _Sort.name => l.budSortName,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: tt.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (sortable)
                PopupMenuButton<_Sort>(
                  tooltip: l.budSortLabel(modeLabel),
                  initialValue: sort,
                  onSelected: (v) => setState(() => sort = v),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _Sort.state,
                      child: Text(l.budSortState),
                    ),
                    PopupMenuItem(
                      value: _Sort.spent,
                      child: Text(l.budSortSpent),
                    ),
                    PopupMenuItem(
                      value: _Sort.name,
                      child: Text(l.budSortName),
                    ),
                  ],
                  child: Row(
                    children: [
                      Text(l.budSortLabel(modeLabel), style: tt.bodySmall),
                      const Icon(Icons.arrow_drop_down, size: 18),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < list.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _BudgetRow(row: list[i], monthKey: key, salary: salary),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Cor de um estado (vermelho, âmbar, verde, laranja perto do máximo, neutro sem orçamento).
Color stateColor(CatBudget r) => switch (r.state) {
  BudgetState.over => Colors.red.shade500,
  BudgetState.below => Colors.amber.shade700,
  BudgetState.none => Colors.blueGrey.shade300,
  BudgetState.ok =>
    r.nearLimit ? Colors.orange.shade600 : Colors.green.shade500,
};

/// Texto curto do resultado ("+50 € acima", "faltam 50 €", "restam 50 €").
String pillText(AppLocalizations l, CatBudget r) {
  switch (r.state) {
    case BudgetState.over:
      return l.budPillOver(fmtMoney(r.spent - r.target));
    case BudgetState.below:
      return l.budPillMissing(fmtMoney(r.target - r.spent));
    case BudgetState.ok:
      return r.isMax
          ? l.budPillLeft(fmtMoney(r.target - r.spent))
          : l.budPillReached;
    case BudgetState.none:
      return '';
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill(this.text, this.color);
  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: HSLColor.fromColor(color).withLightness(0.32).toColor(),
        ),
      ),
    );
  }
}

/// Barra do mês: no máximo o excesso aparece a vermelho dentro da barra; no mínimo a meta fica marcada na ponta.
class StateBar extends StatelessWidget {
  final CatBudget row;
  final double height;
  const StateBar(this.row, {super.key, this.height = 7});
  @override
  Widget build(BuildContext context) {
    final c = stateColor(row);
    final r = row.ratio;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (ctx, box) {
            final w = box.maxWidth;
            final over = row.isMax && r > 1;
            final fill = over ? w / r : w * r.clamp(0.0, 1.0);
            return Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(color: c.withValues(alpha: 0.18)),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: fill,
                  child: ColoredBox(
                    color: over ? c.withValues(alpha: 0.45) : c,
                  ),
                ),
                if (over)
                  Positioned(
                    left: fill,
                    top: 0,
                    bottom: 0,
                    right: 0,
                    child: ColoredBox(color: c),
                  ),
                if (!row.isMax && row.target > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: 2,
                    child: ColoredBox(
                      color: Theme.of(ctx).colorScheme.onSurface,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final BudgetSummary sum;
  final double? pace;
  final Period period;
  final int salary, unallocated, income;
  final bool specificSalary;
  final VoidCallback onEditSalary;
  const _SummaryCard({
    required this.sum,
    required this.pace,
    required this.period,
    required this.salary,
    required this.unallocated,
    required this.income,
    required this.specificSalary,
    required this.onEditSalary,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final ratio = sum.budgeted <= 0 ? 0.0 : sum.spentBudgeted / sum.budgeted;
    final barColor = sum.spentBudgeted > sum.budgeted
        ? Colors.red.shade500
        : (pace != null && ratio > pace! + 0.1
              ? Colors.orange.shade600
              : Colors.green.shade500);
    final today = DateTime.now();
    final day = pace == null
        ? null
        : DateTime(
                today.year,
                today.month,
                today.day,
              ).difference(period.start).inDays +
              1;
    final totalDays = period.end.difference(period.start).inDays;

    Widget metric(String label, String value, {VoidCallback? onTap}) =>
        Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: tt.bodySmall),
                  Text(
                    value,
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              day == null
                  ? l.budSpentThisMonth
                  : '${l.budSpentThisMonth} · ${l.budDayOfTotal(day, totalDays)}',
              style: tt.bodySmall,
            ),
            const SizedBox(height: 2),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 8,
              children: [
                Text(
                  fmtMoney(sum.spentBudgeted),
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (sum.budgeted > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      l.budOfBudgeted(fmtMoney(sum.budgeted)),
                      style: tt.bodySmall,
                    ),
                  ),
              ],
            ),
            if (sum.budgeted > 0) ...[
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (ctx, box) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 10,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ColoredBox(
                                color: barColor.withValues(alpha: 0.18),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: box.maxWidth * ratio.clamp(0.0, 1.0),
                              child: ColoredBox(color: barColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (pace != null)
                      Positioned(
                        left: box.maxWidth * pace! - 1,
                        top: -3,
                        bottom: -3,
                        width: 2,
                        child: ColoredBox(color: cs.onSurface),
                      ),
                  ],
                ),
              ),
              if (pace != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(l.budPaceMark, style: tt.bodySmall),
                ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                metric(
                  l.budMetricLeft,
                  sum.budgeted > 0 ? fmtMoney(sum.left) : '—',
                ),
                const SizedBox(width: 8),
                metric(
                  l.budMetricUnallocated,
                  salary > 0 ? fmtMoney(unallocated) : '—',
                ),
                const SizedBox(width: 8),
                metric(
                  l.budMetricSalary,
                  salary > 0 ? fmtMoney(salary) : l.bpSet,
                  onTap: onEditSalary,
                ),
              ],
            ),
            if (salary <= 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(l.bpDefineSalaryHint, style: tt.bodySmall),
              )
            else if (specificSalary)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(l.bpSpecificThisMonth, style: tt.bodySmall),
              ),
            if (income > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l.bpIncomeThisMonth(fmtMoney(income)),
                  style: tt.bodySmall,
                ),
              ),
            if (sum.unbudgetedSpent > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l.budUnbudgetedNote(fmtMoney(sum.unbudgetedSpent)),
                  style: tt.bodySmall,
                ),
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (sum.over > 0)
                  _Pill(l.budCountOver(sum.over), Colors.red.shade500),
                if (sum.below > 0)
                  _Pill(l.budCountBelow(sum.below), Colors.amber.shade700),
                _Pill(l.budCountOk(sum.ok), Colors.green.shade500),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  final CatBudget row;
  final String monthKey;
  final int salary;
  const _BudgetRow({
    required this.row,
    required this.monthKey,
    required this.salary,
  });

  /// Compras de ativos associados a esta categoria neste mês (ex.: "Compras: 110 € · 0,8 NVDA · 2 compras").
  List<Widget> _purchasesLine(BuildContext context, AppState s, TextTheme tt) {
    final p = purchasesForCategory(s, row.category.id, monthKey);
    if (p.isEmpty) return const [];
    final en = Localizations.localeOf(context).languageCode == 'en';
    final qty = p.quantityByAsset.entries
        .map((e) => '${fmtQty(e.value)} ${e.key}')
        .join(', ');
    return [
      Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          '${en ? 'Purchases' : 'Compras'}: ${fmtMoney(p.cents)} · $qty · '
          '${p.count} ${en ? (p.count == 1 ? 'purchase' : 'purchases') : (p.count == 1 ? 'compra' : 'compras')}',
          style: tt.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final l = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    final c = row.category;
    final c0 = stateColor(row);
    final hasBudget = row.target > 0;
    final suggestion = hasBudget
        ? null
        : suggestBudget(s, c, monthKey, row.spent);
    return InkWell(
      onTap: () => showCategoryBudgetSheet(
        context,
        categoryId: c.id,
        monthKey: monthKey,
        salary: salary,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 8),
              child: CatBadge(c, size: 24),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (hasBudget)
                        _Pill(pillText(l, row), c0)
                      else if (suggestion != null)
                        ActionChip(
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            l.budSuggest(fmtMoney(suggestion)),
                            style: const TextStyle(fontSize: 11),
                          ),
                          onPressed: () => s.updateCategory(
                            c.copyWith(
                              budgetType: BudgetType.limit,
                              budgetPercent: false,
                              budgetValue: suggestion,
                              hasBudget: true,
                            ),
                          ),
                        )
                      else
                        TextButton(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => showBudgetEditor(context, c),
                          child: Text(
                            l.budSetBudget,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                  if (hasBudget) ...[
                    const SizedBox(height: 6),
                    StateBar(row),
                    const SizedBox(height: 4),
                    Text(
                      row.isMax
                          ? l.budRowMax(
                              fmtMoney(row.spent),
                              fmtMoney(row.target),
                            )
                          : l.budRowMin(
                              fmtMoney(row.spent),
                              fmtMoney(row.target),
                            ),
                      style: tt.bodySmall,
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        l.budNoBudgetSpent(fmtMoney(row.spent)),
                        style: tt.bodySmall,
                      ),
                    ),
                  ..._purchasesLine(context, s, tt),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Detalhe de uma categoria no mês: orçamento, subcategorias, últimos 6 meses e ações.
Future<void> showCategoryBudgetSheet(
  BuildContext context, {
  required int categoryId,
  required String monthKey,
  required int salary,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _CategorySheet(
      categoryId: categoryId,
      monthKey: monthKey,
      salary: salary,
    ),
  );
}

class _CategorySheet extends StatelessWidget {
  final int categoryId;
  final String monthKey;
  final int salary;
  const _CategorySheet({
    required this.categoryId,
    required this.monthKey,
    required this.salary,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final l = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final c = s.cat(categoryId);
    if (c == null) return const SizedBox.shrink();
    final row = budgetRows(
      s,
      monthKey,
      salary,
    ).where((r) => r.category.id == c.id).firstOrNull;
    final own = s.totalsByCategory(s.periodOfMonth(monthKey));
    final spent = row?.spent ?? 0;
    final target = row?.target ?? 0;
    final type = row?.type ?? c.budgetType;
    // gasto agregado (rollup) de uma categoria: ela e tudo o que tem dentro
    int agg(Categoria k) => s.rollup(k, own);
    // filhas diretas visíveis neste mês (ativas ou com gasto), a qualquer profundidade
    List<Categoria> visibleKids(Categoria p) => s
        .childrenOf(p.id)
        .where((k) => s.isCategoryActive(k, monthKey) || agg(k) != 0)
        .toList();
    final kids = visibleKids(c);
    final hist = history(s, c, monthKey);
    final hist0 = hist.map((e) => e.$2).fold(0, (a, b) => a > b ? a : b);
    final scale = [hist0, target, 1].reduce((a, b) => a > b ? a : b);
    final month = DateTime(
      int.parse(monthKey.substring(0, 4)),
      int.parse(monthKey.substring(5, 7)),
    );

    Widget kidRow(Categoria k, int depth) {
      final ks = agg(k) < 0 ? 0 : agg(k);
      final kt = k.monthlyTarget(salary);
      final kr = CatBudget(
        k,
        ks,
        kt,
        k.budgetType,
        stateOf(k.budgetType, ks, kt),
      );
      return InkWell(
        key: ValueKey('kid-row-${k.id}'),
        onTap: () => showBudgetEditor(context, k),
        child: Padding(
          // cada nível desce um degrau; a indentação para de crescer ao fim de 5
          padding: EdgeInsets.only(
            left: (depth > 5 ? 5 : depth) * 14.0,
            top: 6,
            bottom: 6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(k.name)),
                  Text(fmtMoney(ks), style: tt.bodySmall),
                ],
              ),
              const SizedBox(height: 4),
              if (k.hasBudget)
                StateBar(kr, height: 6)
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: spent <= 0 ? 0 : (ks / spent).clamp(0.0, 1.0),
                    minHeight: 6,
                    color: cs.outline,
                    backgroundColor: cs.surfaceContainerHighest,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CatBadge(c, size: 26),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    c.name,
                    style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (row != null && target > 0)
                  _Pill(pillText(l, row), stateColor(row)),
              ],
            ),
            const SizedBox(height: 12),
            if (target > 0) ...[
              Row(
                children: [
                  ChoiceChip(
                    label: Text(l.bpBudgetLimit),
                    selected: type == BudgetType.limit,
                    onSelected: (_) => s.updateCategory(
                      c.copyWith(budgetType: BudgetType.limit),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(l.bpBudgetGoal),
                    selected: type == BudgetType.goal,
                    onSelected: (_) => s.updateCategory(
                      c.copyWith(budgetType: BudgetType.goal),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => showBudgetEditor(context, c),
                    icon: const Icon(Icons.edit, size: 16),
                    label: Text(fmtMoney(target)),
                  ),
                ],
              ),
              if (row != null) StateBar(row, height: 10),
              const SizedBox(height: 6),
              Text(
                type == BudgetType.limit
                    ? l.budSheetOfMax(
                        fmtMoney(spent),
                        fmtPercent(row?.ratio ?? 0),
                      )
                    : l.budSheetOfMin(
                        fmtMoney(spent),
                        fmtPercent(row?.ratio ?? 0),
                      ),
                style: tt.bodyMedium,
              ),
            ] else ...[
              Text(l.budNoBudgetYet, style: tt.bodyMedium),
              const SizedBox(height: 4),
              Text(l.bpSpentNoBudget(fmtMoney(spent)), style: tt.bodySmall),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => showBudgetEditor(context, c),
                icon: const Icon(Icons.add),
                label: Text(l.budSetBudget),
              ),
            ],
            if (kids.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l.budSubcategories,
                style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              // árvore recursiva: cada filha com o seu valor agregado, indentada pelo nível
              ...() {
                final out = <Widget>[];
                void add(Categoria k, int depth) {
                  out.add(kidRow(k, depth));
                  for (final g in visibleKids(k)) {
                    add(g, depth + 1);
                  }
                }

                for (final k in kids) {
                  add(k, 0);
                }
                return out;
              }(),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.budLast6,
                    style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
                if (target > 0)
                  Text(
                    type == BudgetType.limit
                        ? l.budChartMax(fmtMoney(target))
                        : l.budChartMin(fmtMoney(target)),
                    style: tt.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 84,
              child: LayoutBuilder(
                builder: (ctx, box) {
                  final h = box.maxHeight - 18; // espaço para o rótulo do mês
                  return Stack(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final (k, v) in hist)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      height: (h * v / scale).clamp(2.0, h),
                                      decoration: BoxDecoration(
                                        color: stateColor(
                                          CatBudget(
                                            c,
                                            v,
                                            target,
                                            type,
                                            stateOf(type, v, target),
                                          ),
                                        ),
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(3),
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      fmtMonthShort(
                                        DateTime(
                                          int.parse(k.substring(0, 4)),
                                          int.parse(k.substring(5, 7)),
                                        ),
                                      ),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (target > 0)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 18 + h * target / scale,
                          child: Container(
                            height: 1,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (_) {
                final direct = s.isMandatoryDirect(c, monthKey);
                final inherited = !direct && s.isMandatory(c, monthKey);
                return SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(l.bpMandatoryInMonth(fmtMonth(month))),
                  subtitle: Text(
                    inherited ? l.bpInheritedFromParent : l.bpOnlyThisMonthHint,
                  ),
                  value: direct || inherited,
                  onChanged: inherited
                      ? null
                      : (v) => s.setMandatoryInMonth(c.id, monthKey, v),
                );
              },
            ),
            Wrap(
              spacing: 4,
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
      ),
    );
  }
}

/// Estado de um orçamento: máximo (excedido ou não) ou mínimo (atingido ou em falta).
String budgetStatus(
  AppLocalizations l,
  BudgetType type,
  int spent,
  int target,
) {
  final s = spent < 0 ? 0 : spent;
  if (type == BudgetType.limit) {
    return s > target
        ? l.bpStatusOver(fmtMoney(s - target))
        : l.bpStatusOk(fmtMoney(target - s));
  }
  return s >= target
      ? l.bpStatusMinOk
      : l.bpStatusMinBelow(fmtMoney(target - s));
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
