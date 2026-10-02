import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../analysis/widgets.dart';
import '../screens/transactions_screen.dart' show confirm;
import '../state/app_state.dart';
import '../util/format.dart';
import 'forms.dart';
import 'invest.dart';
import 'widgets.dart';

/// Um ativo: preço, posição (quantidade, preço médio de compra, ganho/perda) e operações.
class HoldingScreen extends StatefulWidget {
  final int holdingId;
  const HoldingScreen({super.key, required this.holdingId});
  @override
  State<HoldingScreen> createState() => _HoldingScreenState();
}

class _HoldingScreenState extends State<HoldingScreen> {
  bool refreshing = false;

  Future<void> _setPrice(AppState s, Holding h) async {
    final ctrl = TextEditingController(text: h.lastPrice?.toString().replaceAll('.', ',') ?? '');
    final v = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Definir preço'),
        content: TextField(controller: ctrl, autofocus: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Preço por unidade (€)', prefixText: '€  ')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, parseNum(ctrl.text)), child: const Text('Guardar')),
        ],
      ),
    );
    if (v != null && v > 0) s.setHoldingPrice(h.id, v);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final h = s.holding(widget.holdingId);
    if (h == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Ativo apagado.')));
    final acc = s.investAccount(h.accountId);
    final pf = s.portfolio;
    final p = pf.accounts.expand((a) => a.positions).where((x) => x.holding.id == h.id).firstOrNull ?? Position(h, 0, 0, 0, 0);
    final ops = s.investOps.where((o) => o.holdingId == h.id).toList()..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: Text(h.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(tooltip: 'Editar', icon: const Icon(Icons.edit_outlined), onPressed: () => showHoldingEditor(context, edit: h)),
          IconButton(
            tooltip: 'Apagar',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              if (await confirm(context, 'Apagar o ativo “${h.name}” e as suas operações?')) {
                s.deleteHolding(h.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 32), children: [
        // ----- preço -----
        SectionCard(
          title: 'Preço atual',
          subtitle: '${h.kind.emoji} ${h.kind.label} · ${acc?.name ?? ''} · ${h.provider.label}${h.symbol.isEmpty ? '' : ' (${h.symbol})'}',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(h.lastPrice == null ? 'Sem preço' : fmtPrice(h.lastPrice!), style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            if (h.lastPriceAt != null) Text('Atualizado ${fmtAgo(h.lastPriceAt!)} · ${fmtDate(h.lastPriceAt!)}', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (h.canAutoPrice)
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                  onPressed: refreshing
                      ? null
                      : () async {
                          setState(() => refreshing = true);
                          final r = await s.refreshPrices(holdingId: h.id);
                          if (!mounted) return;
                          setState(() => refreshing = false);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.updated == 1 ? 'Preço atualizado.' : 'Não consegui atualizar: ${r.failed.values.firstOrNull ?? 'erro'}')));
                        },
                  icon: refreshing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.sync, size: 18),
                  label: const Text('Atualizar preço'),
                ),
              OutlinedButton.icon(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)), onPressed: () => _setPrice(s, h), icon: const Icon(Icons.edit, size: 18), label: const Text('Definir à mão')),
            ]),
          ]),
        ),

        // ----- posição -----
        SectionCard(
          title: 'A minha posição',
          child: p.qty <= 1e-9 && ops.isEmpty
              ? const Text('Ainda sem posição. Regista a quantidade e o preço médio do que já tinhas, ou uma compra.')
              : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Wrap(spacing: 28, runSpacing: 14, children: [
                    Stat('Quantidade', fmtQty(p.qty)),
                    Stat('Preço médio de compra', p.open ? fmtPrice(p.avgCost) : '–'),
                    Stat('Investido', fmtMoney(p.costCents)),
                    Stat('Valor atual', fmtMoney(p.valueCents)),
                    if (p.open && p.priced) Stat('Ganho / perda', fmtSignedMoney(p.plCents), color: plColor(context, p.plCents), extra: p.plPct == null ? null : Text(fmtSignedPercent(p.plPct!), style: tt.bodySmall?.copyWith(color: plColor(context, p.plCents), fontWeight: FontWeight.w600))),
                    if (p.realizedCents != 0) Stat('Ganho realizado', fmtSignedMoney(p.realizedCents), color: plColor(context, p.realizedCents)),
                    if (p.dividendsCents > 0) Stat('Dividendos', fmtMoney(p.dividendsCents)),
                  ]),
                  if (p.open && !p.priced) Padding(padding: const EdgeInsets.only(top: 10), child: Text('Define o preço atual para ver o ganho ou perda.', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))),
                ]),
        ),

        // ----- ações -----
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.icon(style: FilledButton.styleFrom(minimumSize: const Size(0, 46)), onPressed: () => showOpForm(context, type: OpType.buy, holdingId: h.id, accountId: h.accountId), icon: const Icon(Icons.add_shopping_cart, size: 18), label: const Text('Comprar')),
          OutlinedButton.icon(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)), onPressed: p.open ? () => showOpForm(context, type: OpType.sell, holdingId: h.id, accountId: h.accountId) : null, icon: const Icon(Icons.sell_outlined, size: 18), label: const Text('Vender')),
          OutlinedButton.icon(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)), onPressed: () => showOpForm(context, type: OpType.initial, holdingId: h.id, accountId: h.accountId), icon: const Icon(Icons.history, size: 18), label: const Text('Posição inicial')),
          OutlinedButton.icon(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)), onPressed: () => showOpForm(context, type: OpType.dividend, holdingId: h.id, accountId: h.accountId), icon: const Icon(Icons.payments_outlined, size: 18), label: const Text('Dividendo')),
        ]),

        if (ops.isNotEmpty)
          SectionCard(
            title: 'Operações',
            subtitle: 'Toca para editar',
            child: Column(children: [for (final o in ops) OpTile(o, onTap: () => showOpForm(context, type: o.type, edit: o))]),
          ),
      ]),
    );
  }
}
