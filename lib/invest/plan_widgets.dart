import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
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
    final l = AppLocalizations.of(context)!;
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
            Text(l.invPlanTitle, style: tt.titleMedium),
            const SizedBox(height: 4),
            Text(l.invPlanCardDesc, style: tt.bodySmall),
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
                          ? l.invNoPlan
                          : '${l.invAssetsCount(lines.length)} · ${_pct(sum)}%${sum < 10000 ? ' · ${l.invMissingPercent(_pct(10000 - sum))}' : ''}',
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
  final l = AppLocalizations.of(context)!;
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
                l.invPlanOf(a.name),
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                l.invPlanEditorHint,
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              if (holdings.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(l.invPlanNoAssets),
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
                      ? l.invPlanOver(_pct(t - 10000))
                      : '${l.invPlanTotal(_pct(t))}${t < 10000 ? ' · ${l.invMissingPercent(_pct(10000 - t))}' : ''}',
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
                    set(() => error = l.invSumOver100);
                    return;
                  }
                  final bp = <int, int>{};
                  for (final e in ctrls.entries) {
                    final v = bpOf(e.value.text);
                    if (v == null) {
                      set(() => error = l.invInvalidValue);
                      return;
                    }
                    bp[e.key] = v;
                  }
                  s.setInvestPlan(a.id, bp);
                  Navigator.pop(ctx);
                },
                child: Text(l.invSavePlan),
              ),
              if (s.investPlan.containsKey(a.id))
                TextButton(
                  onPressed: () {
                    s.setInvestPlan(a.id, const {});
                    Navigator.pop(ctx);
                  },
                  child: Text(l.invRemovePlan),
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
    final l = AppLocalizations.of(context)!;
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
                    l.invPendingDeliveries(list.length),
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
                          s.holding(part.holdingId)?.name ??
                              l.invHoldingDeletedShort,
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
                    l.invUndistributed(fmtMoney(p.undistributed)),
                    style: tt.bodySmall,
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.check),
                  label: Text(l.invSeen),
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
