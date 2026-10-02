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
    final ctrl = TextEditingController(text: h.priceOrig?.toString().replaceAll('.', ',') ?? '');
    final fxCtrl = TextEditingController(text: h.lastFx != null && h.lastFx! > 0 ? (1 / h.lastFx!).toStringAsFixed(4).replaceAll('.', ',') : '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Definir preço'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: ctrl, autofocus: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Preço por unidade (${h.foreign ? h.currency : baseSym})', prefixText: h.foreign ? null : '$baseSym  ')),
          if (h.foreign) ...[
            const SizedBox(height: 12),
            TextField(controller: fxCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Câmbio: 1 $baseSym = ? ${h.currency}')),
          ],
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
        ],
      ),
    );
    final v = parseNum(ctrl.text), rate = parseNum(fxCtrl.text);
    if (ok == true && v != null && v > 0) s.setHoldingPrice(h.id, v, eurPerUnit: h.foreign && rate != null && rate > 0 ? 1 / rate : null);
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
          subtitle: '${h.kind.emoji} ${h.kind.label} · ${h.currency} · ${acc?.name ?? ''} · ${h.provider.label}${h.symbol.isEmpty ? '' : ' (${h.symbol})'}',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(h.lastPrice == null ? 'Sem preço' : fmtPriceIn(h.priceOrig ?? h.lastPrice!, h.currency), style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                avatar: const Icon(Icons.currency_exchange, size: 16),
                label: Text('Moeda: ${h.currency} · ${h.currencyManual || !h.canAutoPrice ? 'escolhida' : 'automática'}'),
                onPressed: () => showCurrencyPicker(context, h),
              ),
            ),
            if (h.foreign && h.lastPrice != null)
              Text('≈ ${fmtPrice(h.lastPrice!)}${h.lastFx != null && h.lastFx! > 0 ? ' · 1 $baseSym = ${fmtNum(1 / h.lastFx!, 4)} ${h.currency}' : ''}', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            if (h.lastPriceAt != null) Text('Atualizado ${fmtAgo(h.lastPriceAt!)} · ${fmtDate(h.lastPriceAt!)}', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (h.needsRefresh)
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
                    Stat('Preço médio de compra', p.open ? fmtPriceIn(h.foreign ? p.avgCostOrig : p.avgCost, h.currency) : '–', extra: h.foreign && p.open ? Text('≈ ${fmtPrice(p.avgCost)}', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)) : null),
                    Stat('Investido', fmtMoney(p.costCents)),
                    Stat('Valor atual', fmtMoney(p.valueCents)),
                    if (p.open && p.priced) Stat('Ganho / perda', fmtSignedMoney(p.plCents), color: plColor(context, p.plCents), extra: p.plPct == null ? null : Text(fmtSignedPercent(p.plPct!), style: tt.bodySmall?.copyWith(color: plColor(context, p.plCents), fontWeight: FontWeight.w600))),
                    if (p.plOrig != null) Stat('Ganho em ${h.currency}', '${p.plOrig! >= 0 ? '+' : '−'}${fmtPriceIn(p.plOrig!.abs(), h.currency)}', extra: p.plOrigPct == null ? null : Text('${fmtSignedPercent(p.plOrigPct!)} · só o preço', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))),
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
            child: Column(children: [for (final o in ops) OpTile(o, currencyCode: h.currency, onTap: () => showOpForm(context, type: o.type, edit: o))]),
          ),
      ]),
    );
  }
}
