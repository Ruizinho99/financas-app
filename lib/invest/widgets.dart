import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../util/format.dart';
import 'invest.dart';

/// Cor de ganho/perda (usa as cores de receitas/despesas escolhidas em Aparência).
Color plColor(BuildContext context, int cents) {
  if (cents == 0) return Theme.of(context).colorScheme.onSurfaceVariant;
  final st = context.read<AppState>();
  return Color(cents > 0 ? st.incomeColor : st.expenseColor);
}

/// "+€ 24,90 · +16,0%" colorido.
class PlText extends StatelessWidget {
  final int cents;
  final double? pct;
  final TextStyle? style;
  const PlText(this.cents, {super.key, this.pct, this.style});
  @override
  Widget build(BuildContext context) => Text(
        '${fmtSignedMoney(cents)}${pct == null ? '' : ' · ${fmtSignedPercent(pct!)}'}',
        style: (style ?? const TextStyle()).copyWith(color: plColor(context, cents), fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
}

/// Linha de uma posição: nome, quantidade, preço médio → preço atual, valor e ganho/perda.
class PositionRow extends StatelessWidget {
  final Position p;
  final VoidCallback? onTap;
  const PositionRow(this.p, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final h = p.holding;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 30, child: Text(h.kind.emoji, style: const TextStyle(fontSize: 20), textAlign: TextAlign.center)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(h.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                p.open ? '${fmtQty(p.qty)} un. · médio ${fmtPriceIn(h.foreign ? p.avgCostOrig : p.avgCost, h.currency)}${p.priced ? ' → ${fmtPriceIn(p.priceOrig ?? p.price!, h.currency)}' : ' · sem preço'}' : 'Posição fechada',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(fmtMoney(p.valueCents), style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
            if (p.open && p.priced) PlText(p.plCents, pct: p.plPct, style: tt.bodySmall),
          ]),
        ]),
      ),
    );
  }
}

/// Linha de uma operação (histórico).
class OpTile extends StatelessWidget {
  final InvestOp op;
  final String? holdingName;
  final String? currencyCode; // moeda do ativo
  final VoidCallback? onTap;
  const OpTile(this.op, {super.key, this.holdingName, this.currencyCode, this.onTap});

  @override
  Widget build(BuildContext context) {
    final currency = currencyCode ?? baseCcy;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final (icon, cash) = switch (op.type) {
      OpType.buy => (Icons.add_shopping_cart, -op.amount),
      OpType.sell => (Icons.sell_outlined, op.amount),
      OpType.initial => (Icons.history, 0),
      OpType.dividend => (Icons.payments_outlined, op.amount),
      OpType.cash => (Icons.account_balance_wallet_outlined, op.amount),
    };
    final detail = switch (op.type) {
      OpType.buy || OpType.sell || OpType.initial => '${fmtQty(op.quantity)} un. × ${op.fx == null || currency == baseCcy ? fmtPrice(op.price) : '${fmtPriceIn(op.price, currency)} (1 $baseSym = ${fmtNum(1 / op.fx!, 4)} $currency)'}${op.fee > 0 ? ' · comissão ${fmtMoney(op.fee)}' : ''}',
      _ => op.note,
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      onTap: onTap,
      leading: CircleAvatar(radius: 18, backgroundColor: cs.primaryContainer.withValues(alpha: 0.5), child: Icon(icon, size: 18, color: cs.primary)),
      title: Text('${op.type.label}${holdingName == null ? '' : ' · $holdingName'}', maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${fmtDate(op.date)}${detail.isEmpty ? '' : ' · $detail'}', maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: op.type == OpType.initial
          ? Text(fmtMoney(op.amount), style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant))
          : Text(fmtSignedMoney(cash), style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: plColor(context, cash))),
    );
  }
}
