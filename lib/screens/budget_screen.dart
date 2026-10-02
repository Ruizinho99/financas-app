import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import '../widgets/common.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final period = Period.month(month);
    final key = monthKey(month);
    final salary = s.salaryFor(key);
    final own = s.totalsByCategory(period);
    final allocated = s.totalAllocated(salary);
    final income = s.txnsIn(period).where((t) => t.amount > 0 && (s.cat(t.categoryId)?.isIncome ?? false)).fold(0, (a, t) => a + t.amount);
    final expenseRoots = s.roots.where((c) => !c.isIncome).toList();
    final mandatory = expenseRoots.where((c) => c.mandatory).toList();
    final optional = expenseRoots.where((c) => !c.mandatory).toList();
    final unallocated = salary - allocated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orçamento'),
        actions: [
          IconButton(
            tooltip: 'Copiar salário para todos os meses',
            icon: const Icon(Icons.payments_outlined),
            onPressed: () => _editSalary(context, s, key),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(12, 0, 12, 90), children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => month = DateTime(month.year, month.month - 1))),
          Text(fmtMonth(month), style: Theme.of(context).textTheme.titleMedium),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => month = DateTime(month.year, month.month + 1))),
        ]),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('Salário líquido', style: Theme.of(context).textTheme.titleMedium)),
                TextButton.icon(onPressed: () => _editSalary(context, s, key), icon: const Icon(Icons.edit, size: 18), label: Text(salary == 0 ? 'Definir' : fmtMoney(salary))),
              ]),
              if (s.salaries.containsKey(key)) const Text('Valor específico deste mês', style: TextStyle(fontSize: 12)),
              if (salary > 0) ...[
                const SizedBox(height: 8),
                BudgetBar(spent: allocated, target: salary, type: BudgetType.limit, height: 14),
                const SizedBox(height: 6),
                Text('Alocado ${fmtMoney(allocated)} (${fmtPercent(allocated / salary)})  ·  ${unallocated >= 0 ? 'Por alocar ${fmtMoney(unallocated)}' : 'Excedido em ${fmtMoney(-unallocated)}'}',
                    style: TextStyle(color: unallocated < 0 ? Colors.red : null)),
                if (income > 0) Text('Rendimentos recebidos este mês: ${fmtMoney(income)}', style: Theme.of(context).textTheme.bodySmall),
              ] else
                const Padding(padding: EdgeInsets.only(top: 8), child: Text('Define o teu salário líquido para distribuir por categorias.')),
            ]),
          ),
        ),
        _section(context, s, 'Obrigatórias', mandatory, own, salary),
        _section(context, s, 'Opcionais', optional, own, salary),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Nova categoria'),
            onPressed: () => showCategoryEditor(context),
          ),
        ),
      ]),
    );
  }

  Widget _section(BuildContext context, AppState s, String title, List<Categoria> cats, Map<int, int> own, int salary) {
    if (cats.isEmpty) return const SizedBox.shrink();
    final total = cats.fold(0, (a, c) => a + s.effectiveMonthlyTarget(c, salary));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
        child: Row(children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const Spacer(),
          if (total > 0) Text('${fmtMoney(total)}${salary > 0 ? '  ·  ${fmtPercent(total / salary)}' : ''}'),
        ]),
      ),
      for (final c in cats) _CategoryBudgetTile(category: c, own: own, salary: salary),
    ]);
  }

  Future<void> _editSalary(BuildContext context, AppState s, String key) async {
    final ctrl = TextEditingController(text: s.salaryFor(key) == 0 ? '' : (s.salaryFor(key) / 100).toStringAsFixed(2).replaceAll('.', ','));
    var onlyThisMonth = false;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Salário líquido mensal'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: ctrl, autofocus: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Valor (€)', suffixText: '€')),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Só para este mês'),
              subtitle: const Text('Desligado: passa a ser o valor por omissão de todos os meses'),
              value: onlyThisMonth,
              onChanged: (v) => set(() => onlyThisMonth = v),
            ),
          ]),
          actions: [
            if (s.salaries.containsKey(key)) TextButton(onPressed: () { s.setSalary(key, null); Navigator.pop(ctx); }, child: const Text('Usar valor base')),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
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
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBudgetTile extends StatelessWidget {
  final Categoria category;
  final Map<int, int> own;
  final int salary;
  const _CategoryBudgetTile({required this.category, required this.own, required this.salary});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = category;
    final kids = s.childrenOf(c.id);
    final spent = s.rollup(c, own);
    final target = s.effectiveMonthlyTarget(c, salary);
    final hasAny = target > 0;
    final type = c.hasBudget ? c.budgetType : (kids.firstWhere((k) => k.hasBudget, orElse: () => c).budgetType);
    return Card(
      margin: const EdgeInsets.only(top: 6),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Dot(c.color, size: 14),
        title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: hasAny
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  BudgetBar(spent: spent < 0 ? 0 : spent, target: target, type: type),
                  const SizedBox(height: 4),
                  Text('${fmtMoney(spent)} de ${fmtMoney(target)} · ${type == BudgetType.limit ? 'Limite' : 'Objetivo'}', style: Theme.of(context).textTheme.bodySmall),
                ])
              : Text('Gasto: ${fmtMoney(spent)} · sem orçamento', style: Theme.of(context).textTheme.bodySmall),
        ),
        children: [
          ListTile(
            dense: true,
            title: Text(c.hasBudget ? _describe(c, salary) : 'Orçamento da categoria (opcional)'),
            subtitle: kids.any((k) => k.hasBudget) && !c.hasBudget ? const Text('Soma das subcategorias') : null,
            trailing: const Icon(Icons.edit, size: 18),
            onTap: () => showBudgetEditor(context, c),
          ),
          for (final k in kids) _subTile(context, s, k),
          Row(children: [
            TextButton.icon(onPressed: () => showCategoryEditor(context, parentId: c.id), icon: const Icon(Icons.add), label: const Text('Subcategoria')),
            TextButton.icon(onPressed: () => showCategoryEditor(context, edit: c), icon: const Icon(Icons.settings_outlined), label: const Text('Editar')),
          ]),
        ],
      ),
    );
  }

  Widget _subTile(BuildContext context, AppState s, Categoria k) {
    final spent = own[k.id] ?? 0;
    final t = k.monthlyTarget(salary);
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 32, right: 16),
      title: Text(k.name),
      subtitle: k.hasBudget
          ? Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                BudgetBar(spent: spent < 0 ? 0 : spent, target: t, type: k.budgetType, height: 8),
                const SizedBox(height: 2),
                Text('${fmtMoney(spent)} de ${fmtMoney(t)} · ${k.budgetType == BudgetType.limit ? 'Limite' : 'Objetivo'}'),
              ]),
            )
          : Text('Gasto: ${fmtMoney(spent)} · definir orçamento'),
      onTap: () => showBudgetEditor(context, k),
    );
  }

  String _describe(Categoria c, int salary) =>
      '${c.budgetType == BudgetType.limit ? 'Limite' : 'Objetivo'}: ${c.budgetPercent ? '${(c.budgetValue / 100).toStringAsFixed(1)}% do salário (${fmtMoney(c.monthlyTarget(salary))})' : fmtMoney(c.budgetValue)}';
}

/// Define a alocação de uma categoria/subcategoria.
Future<void> showBudgetEditor(BuildContext context, Categoria c) {
  final s = context.read<AppState>();
  var has = c.hasBudget;
  var type = c.budgetType;
  var percent = c.budgetPercent;
  final ctrl = TextEditingController(
      text: !c.hasBudget ? '' : (c.budgetValue / 100).toStringAsFixed(2).replaceAll('.', ','));
  return showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        title: Text('Orçamento · ${c.name}'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Ter orçamento'), value: has, onChanged: (v) => set(() => has = v)),
            if (has) ...[
              SegmentedButton<BudgetType>(
                segments: const [
                  ButtonSegment(value: BudgetType.limit, label: Text('Limite'), icon: Icon(Icons.vertical_align_top)),
                  ButtonSegment(value: BudgetType.goal, label: Text('Objetivo'), icon: Icon(Icons.flag_outlined)),
                ],
                selected: {type},
                onSelectionChanged: (v) => set(() => type = v.first),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  type == BudgetType.limit ? 'Limite: queres gastar no máximo este valor.' : 'Objetivo: queres atingir pelo menos este valor (ex.: poupança).',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [ButtonSegment(value: false, label: Text('Valor (€)')), ButtonSegment(value: true, label: Text('% do salário'))],
                selected: {percent},
                onSelectionChanged: (v) => set(() => percent = v.first),
              ),
              TextField(
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: percent ? 'Percentagem' : 'Valor mensal', suffixText: percent ? '%' : '€'),
              ),
            ],
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final v = has ? (parseCents(ctrl.text) ?? 0) : 0;
              s.updateCategory(Categoria(
                id: c.id, name: c.name, parentId: c.parentId, mandatory: c.mandatory, isIncome: c.isIncome, color: c.color,
                description: c.description, budgetType: type, budgetPercent: percent, budgetValue: v,
                hasBudget: has && v > 0, archived: c.archived,
              ));
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );
}
