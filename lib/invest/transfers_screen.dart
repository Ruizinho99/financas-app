import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../analysis/widgets.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import '../widgets/form_kit.dart';
import 'invest.dart';

/// Linha de uma transferência para uma plataforma: quanto já foi investido e quanto está em espera.
class TransferRow extends StatelessWidget {
  final Txn txn;
  final VoidCallback? onTap;
  const TransferRow(this.txn, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final a = s.transferAllocation(txn);
    final total = txn.amount.abs();
    final pct = total == 0 ? 0.0 : (a.allocated / total).clamp(0.0, 1.0);
    final acc = s.investAccount(txn.investAccountId);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text('${fmtDate(txn.date)} · ${acc?.emoji ?? ''} ${acc?.name ?? 'Plataforma'}'.replaceAll('  ', ' '), maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600))),
            Text(fmtMoney(total), style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: Colors.orange.withValues(alpha: 0.25))),
          const SizedBox(height: 4),
          Text(
            a.allocated == 0
                ? 'Nada associado ainda · toca para escolher as compras'
                : 'Investido ${fmtMoney(a.allocated)} · ${a.onHold >= 0 ? 'em espera ${fmtMoney(a.onHold)}' : 'mais ${fmtMoney(-a.onHold)} do que a transferência'}',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ]),
      ),
    );
  }
}

/// Cartão da Carteira com as últimas transferências para plataformas.
class TransfersCard extends StatelessWidget {
  const TransfersCard({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = s.investDeliveries;
    if (list.isEmpty) return const SizedBox.shrink();
    final hold = list.fold(0, (a, t) => a + (s.transferAllocation(t).onHold > 0 ? s.transferAllocation(t).onHold : 0));
    return SectionCard(
      title: 'Transferências para investir',
      subtitle: hold > 0 ? 'Toca numa para dizer em que compras foi usada. Por investir: ${fmtMoney(hold)}' : 'Toca numa para dizer em que compras foi usada',
      child: Column(children: [
        for (final t in list.take(4)) TransferRow(t, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TransferAllocScreen(txnId: t.id)))),
        if (list.length > 4)
          Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransfersScreen())), child: Text('Ver todas (${list.length})'))),
      ]),
    );
  }
}

class TransfersScreen extends StatelessWidget {
  const TransfersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Transferências para investir')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 32), children: [
        for (final t in s.investDeliveries) TransferRow(t, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TransferAllocScreen(txnId: t.id)))),
        if (s.investDeliveries.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('Ainda não associaste transferências do banco a uma plataforma.')),
      ]),
    );
  }
}

/// Escolhe as compras que foram feitas com o dinheiro de uma transferência; o resto fica em espera.
class TransferAllocScreen extends StatefulWidget {
  final int txnId;
  const TransferAllocScreen({super.key, required this.txnId});
  @override
  State<TransferAllocScreen> createState() => _TransferAllocScreenState();
}

class _TransferAllocScreenState extends State<TransferAllocScreen> {
  late final Set<int> selected;

  Txn? _txn(AppState s) => s.transactions.where((t) => t.id == widget.txnId).firstOrNull;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    selected = {for (final o in s.investOps) if (o.txnId == widget.txnId && o.type == OpType.buy) o.id};
  }

  /// Compras ainda livres desde esta entrega até à seguinte na mesma plataforma.
  Set<int> _suggest(AppState s, Txn t) {
    final next = s.investDeliveries.where((d) => d.investAccountId == t.investAccountId && d.date.isAfter(t.date)).map((d) => d.date).fold<DateTime?>(null, (a, d) => a == null || d.isBefore(a) ? d : a);
    return {
      for (final o in s.investOps)
        if (o.type == OpType.buy && o.accountId == t.investAccountId && (o.txnId == null || o.txnId == t.id) && !o.date.isBefore(DateTime(t.date.year, t.date.month, t.date.day)) && (next == null || o.date.isBefore(next))) o.id,
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = _txn(s);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    if (t == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Transferência apagada.')));
    final total = t.amount.abs();
    final buys = s.investOps.where((o) => o.type == OpType.buy && o.accountId == t.investAccountId).toList()..sort((a, b) => b.date.compareTo(a.date));
    final allocated = buys.where((o) => selected.contains(o.id)).fold(0, (a, o) => a + o.amount);
    final hold = total - allocated;
    final acc = s.investAccount(t.investAccountId);
    return Scaffold(
      appBar: AppBar(title: const Text('Usar esta transferência')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 120), children: [
        FormCard(children: [
          Text('${fmtMoney(total)} para ${acc?.name ?? 'a plataforma'}', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          Text('${fmtDate(t.date)} · ${t.description}', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: total == 0 ? 0 : (allocated / total).clamp(0.0, 1.0), minHeight: 10, backgroundColor: Colors.orange.withValues(alpha: 0.25))),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text('Investido ${fmtMoney(allocated)}', style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700))),
            Text(hold >= 0 ? 'Em espera ${fmtMoney(hold)}' : 'Mais ${fmtMoney(-hold)}', style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: hold >= 0 ? Colors.orange.shade800 : cs.error)),
          ]),
          if (hold < 0)
            Padding(padding: const EdgeInsets.only(top: 6), child: Text('As compras escolhidas somam mais do que a transferência. Deve ter entrado dinheiro de antes; podes continuar.', style: tt.bodySmall)),
          if (hold > 0 && allocated > 0)
            Padding(padding: const EdgeInsets.only(top: 6), child: Text('${fmtMoney(hold)} desta transferência ficou em espera, por investir.', style: tt.bodySmall)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            OutlinedButton.icon(onPressed: () => setState(() => selected..clear()..addAll(_suggest(s, t))), icon: const Icon(Icons.auto_awesome, size: 18), label: const Text('Sugerir')),
            if (selected.isNotEmpty) TextButton(onPressed: () => setState(selected.clear), child: const Text('Limpar (tudo em espera)')),
          ]),
        ]),
        const SizedBox(height: 14),
        Text('Compras nesta plataforma', style: tt.titleMedium),
        const SizedBox(height: 4),
        Text('Marca as que foram pagas com esta transferência.', style: tt.bodySmall),
        const SizedBox(height: 6),
        if (buys.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('Ainda não há compras registadas nesta plataforma.')),
        for (final o in buys)
          Material(
            type: MaterialType.transparency,
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              value: selected.contains(o.id),
              onChanged: (o.txnId != null && o.txnId != t.id)
                  ? null
                  : (v) => setState(() => v == true ? selected.add(o.id) : selected.remove(o.id)),
              title: Text(s.holding(o.holdingId)?.name ?? 'Compra', maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                '${fmtDate(o.date)} · ${fmtQty(o.quantity)} un.${o.txnId != null && o.txnId != t.id ? ' · usada noutra transferência' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              secondary: Text(fmtMoney(o.amount), style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
      ]),
      bottomNavigationBar: Material(
        color: cs.surface,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: FilledButton(
              onPressed: () {
                s.allocateTransfer(t.id, selected);
                Navigator.pop(context);
              },
              child: Text(selected.isEmpty ? 'Guardar (tudo em espera)' : 'Guardar'),
            ),
          ),
        ),
      ),
    );
  }
}
