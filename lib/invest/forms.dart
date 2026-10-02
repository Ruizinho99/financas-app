import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../analysis/widgets.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import '../widgets/common.dart';
import '../widgets/form_kit.dart';
import 'invest.dart';
import 'price_service.dart';

// ---------------------------------------------------------------------------
// Plataforma
// ---------------------------------------------------------------------------
Future<int?> showInvestAccountEditor(
  BuildContext context, {
  InvestAccount? edit,
}) {
  final s = context.read<AppState>();
  final name = TextEditingController(text: edit?.name ?? '');
  final note = TextEditingController(text: edit?.note ?? '');
  var emoji = edit?.emoji ?? '';
  String? error;
  return showDialog<int>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        title: Text(edit == null ? 'Nova plataforma' : 'Editar plataforma'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      final e = await pickEmoji(ctx, emoji);
                      if (e != null) set(() => emoji = e);
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(ctx).colorScheme.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        emoji.isEmpty ? '📈' : emoji,
                        style: TextStyle(
                          fontSize: 28,
                          color: emoji.isEmpty ? Colors.grey : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: name,
                      autofocus: edit == null,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Nome',
                        hintText: 'Ex.: XTB, Trade Republic',
                        errorText: error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: note,
                decoration: const InputDecoration(labelText: 'Nota (opcional)'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final n = name.text.trim();
              if (n.isEmpty) {
                set(() => error = 'Indica um nome');
                return;
              }
              if (s.investAccounts.any(
                (a) =>
                    a.id != edit?.id && a.name.toLowerCase() == n.toLowerCase(),
              )) {
                set(() => error = 'Já existe uma plataforma com este nome');
                return;
              }
              if (edit == null) {
                Navigator.pop(
                  ctx,
                  s.addInvestAccount(n, emoji: emoji, note: note.text.trim()),
                );
              } else {
                s.updateInvestAccount(
                  edit.copyWith(name: n, emoji: emoji, note: note.text.trim()),
                );
                Navigator.pop(ctx, edit.id);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Ativo
// ---------------------------------------------------------------------------
/// Pesquisa um símbolo no serviço de preços. Devolve o escolhido.
Future<SymbolHit?> showSymbolSearch(
  BuildContext context,
  PriceProvider provider, {
  String initial = '',
}) {
  final s = context.read<AppState>();
  final ctrl = TextEditingController(text: initial);
  List<SymbolHit>? hits;
  String? error;
  var loading = false;
  Future<void> run(StateSetter set) async {
    set(() {
      loading = true;
      error = null;
    });
    try {
      final r = await s.prices.search(provider, ctrl.text);
      set(() => hits = r);
    } on PriceException catch (e) {
      set(() => error = e.message);
    } catch (_) {
      set(() => error = 'Não foi possível pesquisar.');
    }
    set(() => loading = false);
  }

  return showDialog<SymbolHit>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        title: Text('Procurar em ${provider.label}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => run(set),
                decoration: InputDecoration(
                  hintText: provider == PriceProvider.coingecko
                      ? 'Ex.: bitcoin'
                      : 'Ex.: VWCE, Apple, S&P 500',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => run(set),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (loading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    error!,
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                  ),
                ),
              if (hits != null && hits!.isEmpty && !loading)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Nada encontrado.'),
                ),
              if (hits != null && hits!.isNotEmpty)
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final h in hits!)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            h.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${h.symbol}${h.exchange.isEmpty ? '' : ' · ${h.exchange}'}',
                          ),
                          onTap: () => Navigator.pop(ctx, h),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    ),
  );
}

/// Cria ou edita um ativo. Devolve o id.
Future<int?> showHoldingEditor(
  BuildContext context, {
  Holding? edit,
  int? accountId,
}) {
  final s = context.read<AppState>();
  final name = TextEditingController(text: edit?.name ?? '');
  final symbol = TextEditingController(text: edit?.symbol ?? '');
  final price = TextEditingController(
    text: edit?.lastPrice == null
        ? ''
        : edit!.lastPrice!.toString().replaceAll('.', ','),
  );
  var kind = edit?.kind ?? HoldingKind.etf;
  var provider = edit?.provider ?? PriceProvider.yahoo;
  var acc =
      edit?.accountId ??
      accountId ??
      (s.investAccounts.isNotEmpty ? s.investAccounts.first.id : null);
  String? error;
  return showDialog<int>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        title: Text(edit == null ? 'Novo ativo' : 'Editar ativo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: name,
                autofocus: edit == null,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Nome',
                  hintText: 'Ex.: Vanguard FTSE All-World',
                  errorText: error,
                ),
              ),
              const SizedBox(height: 12),
              if (s.investAccounts.length > 1)
                DropdownButtonFormField<int>(
                  initialValue: acc,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Plataforma'),
                  items: [
                    for (final a in s.investAccounts)
                      DropdownMenuItem(
                        value: a.id,
                        child: Text('${a.emoji} ${a.name}'.trim()),
                      ),
                  ],
                  onChanged: (v) => set(() => acc = v),
                ),
              if (s.investAccounts.length > 1) const SizedBox(height: 12),
              Text('Tipo', style: Theme.of(ctx).textTheme.labelLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final k in HoldingKind.values)
                    ChoiceChip(
                      label: Text('${k.emoji} ${k.label}'),
                      selected: kind == k,
                      onSelected: (_) => set(() => kind = k),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text('Preço', style: Theme.of(ctx).textTheme.labelLarge),
              const SizedBox(height: 6),
              SegmentedButton<PriceProvider>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: PriceProvider.yahoo,
                    label: Text('Yahoo'),
                  ),
                  ButtonSegment(
                    value: PriceProvider.coingecko,
                    label: Text('CoinGecko'),
                  ),
                  ButtonSegment(
                    value: PriceProvider.manual,
                    label: Text('Manual'),
                  ),
                ],
                selected: {provider},
                onSelectionChanged: (v) => set(() => provider = v.first),
              ),
              const SizedBox(height: 6),
              Text(switch (provider) {
                PriceProvider.yahoo => 'Gratuito, sem chave. ETFs, ações e câmbios (ex.: VWCE.DE, AAPL, BTC-EUR). Converte para euros.',
                PriceProvider.coingecko => 'Gratuito, sem chave. Criptomoedas, pelo id (ex.: bitcoin, ethereum).',
                PriceProvider.manual => 'Tu defines o preço quando quiseres. Nada é enviado para a internet.',
              }, style: Theme.of(ctx).textTheme.bodySmall),
              const SizedBox(height: 12),
              if (provider != PriceProvider.manual)
                TextField(
                  controller: symbol,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: provider == PriceProvider.coingecko
                        ? 'Id no CoinGecko'
                        : 'Símbolo',
                    suffixIcon: IconButton(
                      tooltip: 'Procurar',
                      icon: const Icon(Icons.search),
                      onPressed: () async {
                        final h = await showSymbolSearch(
                          ctx,
                          provider,
                          initial: name.text.trim(),
                        );
                        if (h != null) {
                          set(() {
                            symbol.text = h.symbol;
                            if (name.text.trim().isEmpty) name.text = h.name;
                          });
                        }
                      },
                    ),
                  ),
                )
              else
                TextField(
                  controller: price,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Preço atual (€, opcional)',
                    prefixText: '€ ',
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final n = name.text.trim();
              if (n.isEmpty || acc == null) {
                set(() => error = 'Indica um nome');
                return;
              }
              if (provider != PriceProvider.manual &&
                  symbol.text.trim().isEmpty) {
                set(() => error = 'Indica o símbolo (ou usa a pesquisa)');
                return;
              }
              final manual = provider == PriceProvider.manual
                  ? parseNum(price.text)
                  : null;
              final base = (edit ?? Holding(id: 0, accountId: acc!, name: n))
                  .copyWith(
                    name: n,
                    accountId: acc,
                    kind: kind,
                    provider: provider,
                    symbol: provider == PriceProvider.manual
                        ? ''
                        : symbol.text.trim(),
                    lastPrice: provider == PriceProvider.manual
                        ? (manual ?? edit?.lastPrice)
                        : edit?.lastPrice,
                    lastPriceAt:
                        provider == PriceProvider.manual && manual != null
                        ? DateTime.now()
                        : edit?.lastPriceAt,
                  );
              int id;
              if (edit == null) {
                id = s.addHolding(base);
              } else {
                s.updateHolding(base);
                id = edit.id;
              }
              Navigator.pop(ctx, id);
              if (base.canAutoPrice) {
                final r = await s.refreshPrices(holdingId: id);
                if (context.mounted && r.failed.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Não consegui obter o preço: ${r.failed.values.first}',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Operação: compra, venda, posição inicial, dividendo, acerto de dinheiro
// ---------------------------------------------------------------------------
class OpFormScreen extends StatefulWidget {
  final OpType type;
  final int? accountId;
  final int? holdingId;
  final InvestOp? edit;
  final int? prefillCents; // ex.: alocar todo o dinheiro por alocar
  const OpFormScreen({
    super.key,
    required this.type,
    this.accountId,
    this.holdingId,
    this.edit,
    this.prefillCents,
  });
  @override
  State<OpFormScreen> createState() => _OpFormScreenState();
}

class _OpFormScreenState extends State<OpFormScreen> {
  late OpType type = widget.edit?.type ?? widget.type;
  late int? accountId = widget.edit?.accountId ?? widget.accountId;
  late int? holdingId = widget.edit?.holdingId ?? widget.holdingId;
  late DateTime date = widget.edit?.date ?? DateTime.now();
  late bool byQty = widget.prefillCents == null;
  late final qtyCtrl = TextEditingController(
    text: widget.edit != null && widget.edit!.quantity > 0
        ? widget.edit!.quantity.toString().replaceAll('.', ',')
        : '',
  );
  late final priceCtrl = TextEditingController(
    text: widget.edit != null && widget.edit!.price > 0
        ? widget.edit!.price.toString().replaceAll('.', ',')
        : '',
  );
  late final totalCtrl = TextEditingController(
    text: widget.prefillCents == null
        ? ''
        : (widget.prefillCents! / 100).toStringAsFixed(2).replaceAll('.', ','),
  );
  late final feeCtrl = TextEditingController(
    text: (widget.edit?.fee ?? 0) > 0
        ? (widget.edit!.fee / 100).toStringAsFixed(2).replaceAll('.', ',')
        : '',
  );
  late final amountCtrl = TextEditingController(
    text:
        widget.edit != null && (type == OpType.dividend || type == OpType.cash)
        ? (widget.edit!.amount.abs() / 100)
              .toStringAsFixed(2)
              .replaceAll('.', ',')
        : '',
  );
  late final noteCtrl = TextEditingController(text: widget.edit?.note ?? '');
  late bool cashIn = (widget.edit?.amount ?? 1) >= 0;
  String? error;

  bool get usesHolding => type != OpType.cash;
  bool get tradeLike =>
      type == OpType.buy || type == OpType.sell || type == OpType.initial;

  double? get price => parseNum(priceCtrl.text);
  double? get totalIn => parseNum(totalCtrl.text);
  double? get qty => byQty
      ? parseNum(qtyCtrl.text)
      : (totalIn != null && price != null && price! > 0
            ? totalIn! / price!
            : null);
  double? get total =>
      byQty ? (qty != null && price != null ? qty! * price! : null) : totalIn;
  int get fee => (parseCents(feeCtrl.text) ?? 0).abs();

  int? get amountCents {
    switch (type) {
      case OpType.buy:
        return total == null ? null : (total! * 100).round() + fee;
      case OpType.sell:
        return total == null ? null : (total! * 100).round() - fee;
      case OpType.initial:
        return total == null ? null : (total! * 100).round();
      case OpType.dividend:
        final v = parseCents(amountCtrl.text);
        return v?.abs();
      case OpType.cash:
        final v = parseCents(amountCtrl.text);
        return v == null ? null : (cashIn ? v.abs() : -v.abs());
    }
  }

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    if (accountId == null && s.investAccounts.length == 1)
      accountId = s.investAccounts.first.id;
    if (accountId == null && holdingId != null)
      accountId = s.holding(holdingId)?.accountId;
    // preço inicial sugerido: o último preço conhecido do ativo
    if (widget.edit == null &&
        priceCtrl.text.isEmpty &&
        holdingId != null &&
        type != OpType.initial) {
      final lp = s.holding(holdingId)?.lastPrice;
      if (lp != null) priceCtrl.text = lp.toString().replaceAll('.', ',');
    }
    for (final c in [qtyCtrl, priceCtrl, totalCtrl, feeCtrl, amountCtrl]) {
      c.addListener(() => setState(() => error = null));
    }
  }

  @override
  void dispose() {
    for (final c in [
      qtyCtrl,
      priceCtrl,
      totalCtrl,
      feeCtrl,
      amountCtrl,
      noteCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save(AppState s) {
    if (accountId == null) {
      setState(() => error = 'Escolhe a plataforma.');
      return;
    }
    if (usesHolding && holdingId == null) {
      setState(() => error = 'Escolhe o ativo (ou cria um).');
      return;
    }
    final amt = amountCents;
    if (amt == null ||
        (type != OpType.cash && amt <= 0) ||
        (type == OpType.cash && amt == 0)) {
      setState(() => error = 'Indica valores válidos.');
      return;
    }
    if (tradeLike && ((qty ?? 0) <= 0 || (price ?? 0) <= 0)) {
      setState(() => error = 'Indica a quantidade e o preço.');
      return;
    }
    if (type == OpType.sell) {
      final pos = _position(s);
      if (pos != null && qty! > pos + 1e-9) {
        setState(() => error = 'Só tens ${fmtQty(pos)} unidades para vender.');
        return;
      }
    }
    final op = InvestOp(
      id: widget.edit?.id ?? 0,
      accountId: accountId!,
      holdingId: usesHolding ? holdingId : null,
      date: date,
      type: type,
      quantity: tradeLike ? qty! : 0,
      price: tradeLike ? price! : 0,
      amount: amt,
      fee: (type == OpType.buy || type == OpType.sell) ? fee : 0,
      note: noteCtrl.text.trim(),
    );
    if (widget.edit == null) {
      s.addOp(op);
    } else {
      s.updateOp(op);
    }
    Navigator.pop(context, true);
  }

  /// Unidades que tens agora do ativo (sem contar com esta operação, se estiver a editar).
  double? _position(AppState s) {
    final p = s.portfolio.positions.where((p) => p.holding.id == holdingId);
    if (p.isEmpty)
      return widget.edit?.type == OpType.sell ? widget.edit!.quantity : 0;
    return p.first.qty +
        (widget.edit?.type == OpType.sell && widget.edit!.holdingId == holdingId
            ? widget.edit!.quantity
            : 0);
  }

  int _cashBefore(AppState s) {
    final a = s.portfolio.accounts.where((a) => a.account.id == accountId);
    var cash = a.isEmpty ? 0 : a.first.cashCents;
    final e = widget.edit;
    if (e != null && e.accountId == accountId) {
      cash += switch (e.type) {
        OpType.buy => e.amount,
        OpType.sell || OpType.dividend || OpType.cash => -e.amount,
        OpType.initial => 0,
      };
    }
    return cash;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final holdings = s.holdings
        .where((h) => !h.archived && h.accountId == accountId)
        .toList();
    final amt = amountCents;
    final cash = accountId == null ? 0 : _cashBefore(s);

    Widget summary() {
      if (amt == null) return const SizedBox.shrink();
      switch (type) {
        case OpType.buy:
          final after = cash - amt;
          return Callout(
            icon: after < 0
                ? Icons.warning_amber_rounded
                : Icons.account_balance_wallet_outlined,
            color: after < 0 ? Colors.orange.shade700 : cs.primary,
            title:
                'Total a pagar: ${fmtMoney(amt)}${fee > 0 ? ' (com ${fmtMoney(fee)} de comissão)' : ''}',
            body: after < 0
                ? 'Só tens ${fmtMoney(cash)} por alocar nesta plataforma. Associa a transferência do banco ou acerta o dinheiro (pode guardar na mesma).'
                : 'Dinheiro por alocar: ${fmtMoney(cash)} → ${fmtMoney(after)}.',
          );
        case OpType.sell:
          final pos = s.portfolio.positions.where(
            (p) => p.holding.id == holdingId,
          );
          final avg = pos.isEmpty ? null : pos.first.avgCost;
          final realized = avg == null || qty == null
              ? null
              : amt - (avg * qty! * 100).round();
          return Callout(
            icon: Icons.south_west,
            color: cs.primary,
            title: 'Recebes ${fmtMoney(amt)}',
            body: [
              'Dinheiro por alocar: ${fmtMoney(cash)} → ${fmtMoney(cash + amt)}.',
              if (realized != null)
                'Ganho realizado: ${fmtSignedMoney(realized)} (preço médio ${fmtPrice(avg!)}).',
            ].join(' '),
          );
        case OpType.initial:
          return Callout(
            icon: Icons.history,
            color: cs.primary,
            title: 'Custo da posição: ${fmtMoney(amt)}',
            body: 'Posição que já tinhas antes de usar a app. Define o preço médio de compra e não mexe no dinheiro por alocar.',
          );
        case OpType.dividend:
          return Callout(
            icon: Icons.payments_outlined,
            color: cs.primary,
            title: 'Entram ${fmtMoney(amt)} no dinheiro por alocar',
            body: '${fmtMoney(cash)} → ${fmtMoney(cash + amt)}.',
          );
        case OpType.cash:
          return Callout(
            icon: Icons.account_balance_wallet_outlined,
            color: cs.primary,
            title:
                'Dinheiro por alocar: ${fmtMoney(cash)} → ${fmtMoney(cash + amt)}',
            body: 'Usa isto para dinheiro que já estava na plataforma antes de começares a usar a app.',
          );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.edit == null ? type.label : 'Editar · ${type.label}',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          FormCard(
            children: [
              if (s.investAccounts.length > 1 || accountId == null) ...[
                const FieldLabel('Plataforma').withTop0(),
                DropdownButtonFormField<int>(
                  initialValue: accountId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.account_balance_outlined),
                    hintText: 'Escolher plataforma',
                  ),
                  items: [
                    for (final a in s.investAccounts)
                      DropdownMenuItem(
                        value: a.id,
                        child: Text('${a.emoji} ${a.name}'.trim()),
                      ),
                  ],
                  onChanged: widget.edit != null
                      ? null
                      : (v) => setState(() {
                          accountId = v;
                          holdingId = null;
                        }),
                ),
              ],
              if (usesHolding && accountId != null) ...[
                const FieldLabel('Ativo'),
                DropdownButtonFormField<int>(
                  key: ValueKey('h-$accountId-${holdings.length}-$holdingId'),
                  initialValue: holdingId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.pie_chart_outline),
                    hintText: 'Escolher ativo',
                  ),
                  items: [
                    for (final h in holdings)
                      DropdownMenuItem(
                        value: h.id,
                        child: Text(
                          '${h.kind.emoji}  ${h.name}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const DropdownMenuItem(
                      value: -1,
                      child: Text('➕  Novo ativo…'),
                    ),
                  ],
                  onChanged: (v) async {
                    if (v == -1) {
                      final id = await showHoldingEditor(
                        context,
                        accountId: accountId,
                      );
                      if (id != null && mounted) setState(() => holdingId = id);
                    } else {
                      setState(() {
                        holdingId = v;
                        if (widget.edit == null && type != OpType.initial) {
                          final lp = s.holding(v)?.lastPrice;
                          if (lp != null)
                            priceCtrl.text = lp.toString().replaceAll('.', ',');
                        }
                      });
                    }
                  },
                ),
              ],
              const FieldLabel('Data'),
              TileField(
                icon: Icons.event,
                text: fmtDate(date),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) setState(() => date = d);
                },
              ),
              if (tradeLike) ...[
                const SizedBox(height: 14),
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: true,
                      label: Text('Quantidade e preço'),
                    ),
                    ButtonSegment(value: false, label: Text('Valor e preço')),
                  ],
                  selected: {byQty},
                  onSelectionChanged: (v) => setState(() {
                    final q = qty, t = total;
                    byQty = v.first;
                    // mantém o que já foi escrito ao trocar de modo
                    if (byQty && q != null)
                      qtyCtrl.text = q
                          .toStringAsFixed(6)
                          .replaceFirst(RegExp(r'\.?0+$'), '')
                          .replaceAll('.', ',');
                    if (!byQty && t != null)
                      totalCtrl.text = t
                          .toStringAsFixed(2)
                          .replaceAll('.', ',');
                  }),
                ),
                if (byQty) ...[
                  FieldLabel(
                    type == OpType.initial
                        ? 'Quantidade que já tens'
                        : 'Quantidade',
                  ),
                  TextField(
                    controller: qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.numbers),
                      hintText: '0',
                    ),
                  ),
                ] else ...[
                  FieldLabel(
                    type == OpType.initial
                        ? 'Valor investido (€)'
                        : (type == OpType.buy
                              ? 'Valor a investir (€)'
                              : 'Valor da venda (€)'),
                  ),
                  TextField(
                    controller: totalCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      prefixText: '€  ',
                      hintText: '0,00',
                    ),
                  ),
                ],
                FieldLabel(
                  type == OpType.initial
                      ? 'Preço médio de compra (€)'
                      : 'Preço por unidade (€)',
                ),
                TextField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    prefixText: '€  ',
                    hintText: '0,00',
                  ),
                ),
                if (!byQty && qty != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '= ${fmtQty(qty!)} unidades',
                      style: tt.bodySmall,
                    ),
                  ),
                if (byQty && total != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '= ${fmtMoney((total! * 100).round())} sem comissão',
                      style: tt.bodySmall,
                    ),
                  ),
                if (type != OpType.initial) ...[
                  const FieldLabel('Comissão (€)', optional: true),
                  TextField(
                    controller: feeCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      prefixText: '€  ',
                      hintText: '0,00',
                    ),
                  ),
                ],
              ],
              if (type == OpType.dividend || type == OpType.cash) ...[
                if (type == OpType.cash) ...[
                  const SizedBox(height: 14),
                  SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text('Entrada'),
                        icon: Icon(Icons.south_west),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('Saída'),
                        icon: Icon(Icons.north_east),
                      ),
                    ],
                    selected: {cashIn},
                    onSelectionChanged: (v) => setState(() => cashIn = v.first),
                  ),
                ],
                FieldLabel(
                  type == OpType.dividend ? 'Valor recebido (€)' : 'Valor (€)',
                ),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    prefixText: '€  ',
                    hintText: '0,00',
                  ),
                ),
              ],
              const FieldLabel('Nota', optional: true),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.notes),
                  hintText: 'Opcional',
                ),
              ),
              const SizedBox(height: 16),
              summary(),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error!, style: TextStyle(color: cs.error)),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _save(s),
                child: Text(
                  widget.edit == null ? 'Guardar' : 'Guardar alterações',
                ),
              ),
              if (widget.edit != null)
                TextButton.icon(
                  onPressed: () {
                    s.deleteOp(widget.edit!.id);
                    Navigator.pop(context, true);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Apagar operação'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

extension on FieldLabel {
  Widget withTop0() =>
      Transform.translate(offset: const Offset(0, -6), child: this);
}

Future<bool?> showOpForm(
  BuildContext context, {
  required OpType type,
  int? accountId,
  int? holdingId,
  InvestOp? edit,
  int? prefillCents,
}) => Navigator.push<bool>(
  context,
  MaterialPageRoute(
    builder: (_) => OpFormScreen(
      type: type,
      accountId: accountId,
      holdingId: holdingId,
      edit: edit,
      prefillCents: prefillCents,
    ),
  ),
);

// ---------------------------------------------------------------------------
// Associar transferências do banco a uma plataforma
// ---------------------------------------------------------------------------
class LinkTransfersScreen extends StatefulWidget {
  final int accountId;
  const LinkTransfersScreen({super.key, required this.accountId});
  @override
  State<LinkTransfersScreen> createState() => _LinkTransfersScreenState();
}

class _LinkTransfersScreenState extends State<LinkTransfersScreen> {
  final selected = <int>{};
  String q = '';
  bool remember = true;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final acc = s.investAccount(widget.accountId);
    final name = (acc?.name ?? '').toLowerCase();
    final ql = q.trim().toLowerCase();
    // candidatos: movimentos ainda não associados a nenhuma plataforma; os que mencionam a plataforma vêm primeiro
    bool mentions(Txn t) =>
        name.isNotEmpty &&
        ('${t.description} ${t.merchantKey}'.toLowerCase().contains(name));
    final list =
        s.transactions
            .where(
              (t) =>
                  t.investAccountId == null &&
                  (ql.isEmpty ||
                      '${s.displayName(t)} ${t.description}'
                          .toLowerCase()
                          .contains(ql)),
            )
            .toList()
          ..sort((a, b) {
            final m = (mentions(b) ? 1 : 0).compareTo(mentions(a) ? 1 : 0);
            return m != 0 ? m : b.date.compareTo(a.date);
          });
    final shown = list.take(300).toList();
    final total = s.transactions
        .where((t) => selected.contains(t.id))
        .fold(0, (a, t) => a - t.amount);

    return Scaffold(
      appBar: AppBar(title: Text('Associar a ${acc?.name ?? 'plataforma'}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Escolhe os movimentos do banco que foram dinheiro enviado para (ou recebido de) esta plataforma. Deixam de contar como despesa.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Pesquisar movimentos',
                  ),
                  onChanged: (v) => setState(() => q = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: shown.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Não há movimentos por associar.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: shown.length,
                    itemBuilder: (_, i) {
                      final t = shown[i];
                      return CheckboxListTile(
                        value: selected.contains(t.id),
                        onChanged: (v) => setState(
                          () => v! ? selected.add(t.id) : selected.remove(t.id),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          s.displayName(t),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${fmtDate(t.date)}${mentions(t) ? ' · parece desta plataforma' : ''}',
                        ),
                        secondary: MoneyText(t.amount),
                      );
                    },
                  ),
          ),
          Material(
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant
                        .withValues(alpha: 0.5),
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Lembrar estes títulos'),
                    subtitle: const Text(
                      'Nas próximas importações, movimentos com o mesmo título são associados sozinhos.',
                    ),
                    value: remember,
                    onChanged: (v) => setState(() => remember = v),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: selected.isEmpty
                          ? null
                          : () {
                              s.linkTransfers(
                                selected.toList(),
                                widget.accountId,
                                rememberTitles: remember,
                              );
                              if (remember) s.applyInvestPatterns();
                              Navigator.pop(context, true);
                            },
                      child: Text(
                        selected.isEmpty
                            ? 'Associar'
                            : 'Associar ${selected.length} (${fmtSignedMoney(total)} para a plataforma)',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
