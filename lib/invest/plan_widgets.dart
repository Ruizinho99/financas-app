import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../util/format.dart';
import 'allocation_plan.dart';
import 'invest.dart';

String _pct(int bp) => (bp / 100)
    .toStringAsFixed(2)
    .replaceAll(RegExp(r'\.?0+$'), '')
    .replaceAll('.', ',');

/// Secção do orçamento: o plano de distribuição de cada plataforma (por ativo, em percentagem).
class InvestPlanCard extends StatelessWidget {
  const InvestPlanCard({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final accounts = s.investAccounts.where((a) => !a.archived).toList();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    if (accounts.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plano de investimento', style: tt.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Quando entra uma transferência numa plataforma, a Carteira mostra quanto vai para cada ativo. A app não regista compras.',
              style: tt.bodySmall,
            ),
            for (final a in accounts)
              Builder(
                builder: (ctx) {
                  final lines = s.investPlan[a.id] ?? const [];
                  final sum = lines.fold<int>(0, (x, l) => x + l.bp);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Text(
                      a.emoji.isEmpty ? '🏦' : a.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                    title: Text(a.name),
                    subtitle: Text(
                      lines.isEmpty
                          ? 'Sem plano'
                          : '${lines.length} ativos · ${_pct(sum)}%${sum < 10000 ? ' · faltam ${_pct(10000 - sum)}% por distribuir' : ''}',
                      style: sum > 10000 ? TextStyle(color: cs.error) : null,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showInvestPlanEditor(context, s, a),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Edita as percentagens de uma plataforma. Cada ativo recebe a sua parte de cada entrega.
Future<void> showInvestPlanEditor(
  BuildContext context,
  AppState s,
  InvestAccount a,
) {
  final holdings = s.holdings
      .where((h) => h.accountId == a.id && !h.archived)
      .toList();
  final current = {
    for (final l in s.investPlan[a.id] ?? const <PlanLine>[]) l.holdingId: l.bp,
  };
  final ctrls = {
    for (final h in holdings)
      h.id: TextEditingController(
        text: current[h.id] == null ? '' : _pct(current[h.id]!),
      ),
  };
  String? error;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) {
        int? bpOf(String t) {
          final v = double.tryParse(t.trim().replaceAll(',', '.'));
          if (v == null || v < 0) return null;
          return (v * 100).round();
        }

        int total() =>
            ctrls.values.fold<int>(0, (x, c) => x + (bpOf(c.text) ?? 0));
        final t = total();
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Plano de ${a.name}',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Percentagem de cada entrega para cada ativo. Podes deixar parte por distribuir.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              if (holdings.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Esta plataforma ainda não tem ativos. Adiciona ativos na Carteira.',
                  ),
                ),
              for (final h in holdings)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: ctrls[h.id],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => set(() => error = null),
                    decoration: InputDecoration(
                      labelText: '${h.kind.emoji} ${h.name}',
                      suffixText: '%',
                    ),
                  ),
                ),
              if (holdings.isNotEmpty)
                Text(
                  t > 10000
                      ? 'Passa ${_pct(t - 10000)}% dos 100%.'
                      : 'Total: ${_pct(t)}%${t < 10000 ? ' · ${_pct(10000 - t)}% por distribuir' : ''}',
                  style: TextStyle(
                    color: t > 10000 ? Theme.of(ctx).colorScheme.error : null,
                  ),
                ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    error!,
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                  ),
                ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () {
                  if (t > 10000) {
                    set(() => error = 'A soma não pode passar 100%.');
                    return;
                  }
                  final bp = <int, int>{};
                  for (final e in ctrls.entries) {
                    final v = bpOf(e.value.text);
                    if (v == null) {
                      set(() => error = 'Valor inválido.');
                      return;
                    }
                    bp[e.key] = v;
                  }
                  s.setInvestPlan(a.id, bp);
                  Navigator.pop(ctx);
                },
                child: const Text('Guardar plano'),
              ),
              if (s.investPlan.containsKey(a.id))
                TextButton(
                  onPressed: () {
                    s.setInvestPlan(a.id, const {});
                    Navigator.pop(ctx);
                  },
                  child: const Text('Remover plano'),
                ),
            ],
          ),
        );
      },
    ),
  ).whenComplete(() {
    for (final c in ctrls.values) {
      c.dispose();
    }
  });
}

/// Entregas recentes para distribuir, com o valor de cada ativo. Marca-se como vistas.
class PendingAllocationsCard extends StatelessWidget {
  const PendingAllocationsCard({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = s.pendingAllocations;
    if (list.isEmpty) return const SizedBox.shrink();
    final tt = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Entregas para distribuir (${list.length})',
                    style: tt.titleMedium,
                  ),
                ),
              ],
            ),
            for (final p in list) ...[
              const Divider(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${fmtDate(p.txn.date)} · ${p.account.name}',
                      style: tt.bodySmall,
                    ),
                  ),
                  Text(fmtMoney(-p.txn.amount), style: tt.titleSmall),
                ],
              ),
              for (final part in p.parts)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.holding(part.holdingId)?.name ?? 'Ativo apagado',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(fmtMoney(part.cents)),
                    ],
                  ),
                ),
              if (p.undistributed > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Por distribuir: ${fmtMoney(p.undistributed)}',
                    style: tt.bodySmall,
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Visto'),
                  onPressed: () => s.dismissAllocation(p.txn.id),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
