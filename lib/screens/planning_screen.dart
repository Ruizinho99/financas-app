import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../planning/planning.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import '../widgets/category_picker.dart';
import 'budget_screen.dart' show showSalaryEditor;

/// Planeamento de um mês: salário, despesas obrigatórias e opcionais planeadas, e o que sobra.
class PlanningScreen extends StatefulWidget {
  /// Mês a abrir (por omissão, o atual).
  final DateTime? initialMonth;
  const PlanningScreen({super.key, this.initialMonth});
  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  late DateTime month = widget.initialMonth != null
      ? DateTime(widget.initialMonth!.year, widget.initialMonth!.month)
      : DateTime(DateTime.now().year, DateTime.now().month);

  void _shift(int delta) =>
      setState(() => month = DateTime(month.year, month.month + delta));

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final key = monthKey(month);
    final items = s.planFor(key);
    final salary = s.salaryFor(key);
    final totals = planTotals(salary, items);
    final mandatory = items.where((i) => i.mandatory).toList();
    final optional = items.where((i) => !i.mandatory).toList();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final prevKey = monthKey(DateTime(month.year, month.month - 1));
    final canCopy = items.isEmpty && s.planFor(prevKey).isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planeamento'),
        actions: [
          if (canCopy)
            IconButton(
              tooltip: 'Copiar o plano do mês anterior',
              icon: const Icon(Icons.content_copy_outlined),
              onPressed: () {
                final n = s.copyPlan(prevKey, key);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Copiadas $n despesas de ${fmtMonth(DateTime(month.year, month.month - 1))}.',
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addItem(context, s, key),
        icon: const Icon(Icons.add),
        label: const Text('Despesa planeada'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: 'Mês anterior',
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _shift(-1),
              ),
              Text(fmtMonth(month), style: tt.titleMedium),
              IconButton(
                tooltip: 'Mês seguinte',
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _shift(1),
              ),
            ],
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row(
                    context,
                    'Salário líquido',
                    salary == 0 ? 'Definir' : fmtMoney(salary),
                    onTap: () => showSalaryEditor(context, s, key),
                  ),
                  _row(
                    context,
                    'Obrigatórias planeadas',
                    fmtMoney(totals.mandatory),
                  ),
                  _row(
                    context,
                    'Opcionais planeadas',
                    fmtMoney(totals.optional),
                  ),
                  const Divider(height: 22),
                  _row(
                    context,
                    totals.left < 0 ? 'Excede o salário em' : 'Por planear',
                    fmtMoney(totals.left.abs()),
                    bold: true,
                    color: totals.left < 0 ? cs.error : null,
                  ),
                  if (salary == 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Define o salário deste mês para ver o que sobra.',
                        style: tt.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                canCopy
                    ? 'Ainda sem despesas planeadas. Usa o ícone de copiar para trazer o plano do mês anterior.'
                    : 'Ainda sem despesas planeadas. Acrescenta as obrigatórias (renda, luz…) e as opcionais (lazer, subscrições…).',
                textAlign: TextAlign.center,
                style: tt.bodyMedium,
              ),
            ),
          if (mandatory.isNotEmpty)
            ..._section(context, s, 'Obrigatórias', mandatory, key),
          if (optional.isNotEmpty)
            ..._section(context, s, 'Opcionais', optional, key),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    VoidCallback? onTap,
    bool bold = false,
    Color? color,
  }) {
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
      color: color,
    );
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value, style: style),
          ],
        ),
      ),
    );
  }

  List<Widget> _section(
    BuildContext context,
    AppState s,
    String title,
    List<PlannedItem> items,
    String key,
  ) {
    final tt = Theme.of(context).textTheme;
    final total = items.fold(0, (a, i) => a + i.cents);
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: tt.titleSmall),
            Text(fmtMoney(total), style: tt.titleSmall),
          ],
        ),
      ),
      for (final i in items) _ItemTile(item: i, month: key),
    ];
  }

  Future<void> _addItem(BuildContext context, AppState s, String key) async {
    final id = await chooseCategory(context, income: false);
    if (id == null || id == -1 || !context.mounted) return;
    if (s.planFor(key).any((p) => p.categoryId == id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Esta categoria já está planeada neste mês. Edita a linha existente.',
          ),
        ),
      );
      return;
    }
    final c = s.cat(id);
    final added = await showPlanItemEditor(
      context,
      s,
      key,
      categoryId: id,
      title: c == null ? 'Despesa planeada' : s.path(c.id),
    );
    if (added != null && context.mounted) {
      final ok = s.addPlanned(
        month: key,
        categoryId: id,
        cents: added.cents,
        mandatory: added.mandatory,
      );
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Esta categoria já está planeada neste mês.'),
          ),
        );
      }
    }
  }
}

class _ItemTile extends StatelessWidget {
  final PlannedItem item;
  final String month;
  const _ItemTile({required this.item, required this.month});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = s.cat(item.categoryId);
    if (c == null) return const SizedBox.shrink();
    final spent = s.actualSpent(item.categoryId, month);
    final ratio = item.cents <= 0 ? 0.0 : (spent / item.cents).clamp(0.0, 1.0);
    final over = spent > item.cents;
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final r = await showPlanItemEditor(
            context,
            s,
            month,
            categoryId: item.categoryId,
            title: s.path(c.id),
            current: item,
          );
          if (r != null) {
            s.updatePlanned(
              PlannedItem(
                id: item.id,
                month: month,
                categoryId: item.categoryId,
                cents: r.cents,
                mandatory: r.mandatory,
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 4, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${c.emoji.isEmpty ? '' : '${c.emoji} '}${s.path(c.id)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(fmtMoney(item.cents)),
                  IconButton(
                    tooltip: 'Apagar',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => s.deletePlanned(item.id),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: ratio,
                minHeight: 5,
                borderRadius: BorderRadius.circular(3),
                color: over ? cs.error : cs.primary,
              ),
              const SizedBox(height: 4),
              Text(
                over
                    ? 'Gasto ${fmtMoney(spent)} · passou ${fmtMoney(spent - item.cents)}'
                    : 'Gasto ${fmtMoney(spent)} · faltam ${fmtMoney(item.cents - spent)}',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: over ? cs.error : null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanValue {
  final int cents;
  final bool mandatory;
  const _PlanValue(this.cents, this.mandatory);
}

/// Valor e tipo (obrigatória/opcional) de uma despesa planeada. Devolve nulo se for cancelado.
Future<_PlanValue?> showPlanItemEditor(
  BuildContext context,
  AppState s,
  String month, {
  required int categoryId,
  required String title,
  PlannedItem? current,
}) {
  final ctrl = TextEditingController(
    text: current == null
        ? ''
        : (current.cents / 100).toStringAsFixed(2).replaceAll('.', ','),
  );
  var mandatory = current?.mandatory ?? false;
  return showDialog<_PlanValue>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        title: Text(title),
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
                labelText: 'Valor planeado ($baseSym)',
                prefixText: '$baseSym  ',
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: true, label: Text('Obrigatória')),
                ButtonSegment(value: false, label: Text('Opcional')),
              ],
              selected: {mandatory},
              onSelectionChanged: (v) => set(() => mandatory = v.first),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final v = (parseCents(ctrl.text) ?? 0).abs();
              if (v <= 0) return;
              Navigator.pop(ctx, _PlanValue(v, mandatory));
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  ).whenComplete(ctrl.dispose);
}
