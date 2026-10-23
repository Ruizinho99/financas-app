import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../analysis/widgets.dart';
import '../l10n/app_localizations.dart';
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
  final l = AppLocalizations.of(context)!;
  final s = context.read<AppState>();
  final name = TextEditingController(text: edit?.name ?? '');
  final note = TextEditingController(text: edit?.note ?? '');
  var emoji = edit?.emoji ?? '';
  String? error;
  return showDialog<int>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        title: Text(
          edit == null ? l.invfAccountNewTitle : l.invfAccountEditTitle,
        ),
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
                        labelText: l.invfName,
                        hintText: l.invfAccountNameHint,
                        errorText: error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: note,
                decoration: InputDecoration(labelText: l.invfNoteOptional),
                maxLines: 2,
              ),
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
              final n = name.text.trim();
              if (n.isEmpty) {
                set(() => error = l.invfEnterName);
                return;
              }
              if (s.investAccounts.any(
                (a) =>
                    a.id != edit?.id && a.name.toLowerCase() == n.toLowerCase(),
              )) {
                set(() => error = l.invfAccountNameTaken);
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
            child: Text(l.invfSave),
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
  final l = AppLocalizations.of(context)!;
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
      set(() => error = l.invfSearchFailed);
    }
    set(() => loading = false);
  }

  return showDialog<SymbolHit>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        title: Text(l.invfSearchIn(provider.label)),
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
                      ? l.invfCryptoSearchHint
                      : l.invfSymbolSearchHint,
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
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(l.invfNothingFound),
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
            child: Text(l.invfClose),
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
  final l = AppLocalizations.of(context)!;
  final s = context.read<AppState>();
  final name = TextEditingController(text: edit?.name ?? '');
  final symbol = TextEditingController(text: edit?.symbol ?? '');
  final price = TextEditingController(
    text: edit?.priceOrig == null
        ? ''
        : edit!.priceOrig!.toString().replaceAll('.', ','),
  );
  final fxCtrl = TextEditingController(
    text: edit?.lastFx != null && edit!.lastFx! > 0
        ? (1 / edit.lastFx!).toStringAsFixed(4).replaceAll('.', ',')
        : '',
  );
  var currency = edit?.currency ?? baseCcy;
  var manualCcy = edit?.currencyManual ?? false;
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
        title: Text(
          edit == null ? l.invfHoldingNewTitle : l.invfHoldingEditTitle,
        ),
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
                  labelText: l.invfName,
                  hintText: l.invfHoldingNameHint,
                  errorText: error,
                ),
              ),
              const SizedBox(height: 12),
              if (s.investAccounts.length > 1)
                DropdownButtonFormField<int>(
                  initialValue: acc,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.invfPlatform),
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
              Text(l.invfType, style: Theme.of(ctx).textTheme.labelLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final k in HoldingKind.values)
                    ChoiceChip(
                      label: Text('${k.emoji} ${_kindLabel(l, k)}'),
                      selected: kind == k,
                      onSelected: (_) => set(() => kind = k),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                key: ValueKey('ccy-$provider'),
                initialValue: provider != PriceProvider.manual && !manualCcy
                    ? 'AUTO'
                    : (kCurrencies.contains(currency) ? currency : null),
                isExpanded: true,
                decoration: InputDecoration(labelText: l.invfAssetCurrency),
                items: [
                  if (provider != PriceProvider.manual)
                    DropdownMenuItem(
                      value: 'AUTO',
                      child: Text(l.invfAutoCurrency),
                    ),
                  for (final c in kCurrencies)
                    DropdownMenuItem(
                      value: c,
                      child: Text(
                        c == baseCcy ? l.invfBaseCurrencyOption(c) : c,
                      ),
                    ),
                ],
                onChanged: (v) => set(() {
                  if (v == 'AUTO') {
                    manualCcy = false;
                  } else if (v != null) {
                    currency = v;
                    manualCcy = true;
                  }
                }),
              ),
              const SizedBox(height: 4),
              Text(
                provider != PriceProvider.manual && !manualCcy
                    ? l.invfCurrencyAutoHint(
                        currency == baseCcy && edit?.lastPrice == null
                            ? l.invfDetectedOnPrice
                            : currency,
                      )
                    : currency == baseCcy
                    ? l.invfUsdHint
                    : l.invfForeignCcyHint(currency),
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              Text(l.invfPrice, style: Theme.of(ctx).textTheme.labelLarge),
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
                PriceProvider.yahoo => l.invfYahooHint,
                PriceProvider.coingecko => l.invfCoingeckoHint,
                PriceProvider.manual => l.invfManualHint,
              }, style: Theme.of(ctx).textTheme.bodySmall),
              const SizedBox(height: 12),
              if (provider != PriceProvider.manual)
                TextField(
                  controller: symbol,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: provider == PriceProvider.coingecko
                        ? l.invfCoingeckoId
                        : l.invfSymbol,
                    suffixIcon: IconButton(
                      tooltip: l.invfSearchTooltip,
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
              else ...[
                TextField(
                  controller: price,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l.invfCurrentPriceOptional(currency),
                    prefixText: currency == baseCcy ? '$baseSym ' : null,
                  ),
                ),
                if (currency != baseCcy) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: fxCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l.invfFxLabel(baseSym, currency),
                      suffixIcon: IconButton(
                        tooltip: l.invfLiveFxTooltip,
                        icon: const Icon(Icons.sync),
                        onPressed: () async {
                          try {
                            final r = await s.prices.fxRate(currency, baseCcy);
                            if (r > 0)
                              set(
                                () => fxCtrl.text = (1 / r)
                                    .toStringAsFixed(4)
                                    .replaceAll('.', ','),
                              );
                          } on PriceException catch (e) {
                            set(() => error = l.invfFxFetchFailed(e.message));
                          }
                        },
                      ),
                    ),
                  ),
                ],
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
            onPressed: () async {
              final n = name.text.trim();
              if (n.isEmpty || acc == null) {
                set(() => error = l.invfEnterName);
                return;
              }
              if (provider != PriceProvider.manual &&
                  symbol.text.trim().isEmpty) {
                set(() => error = l.invfSymbolRequired);
                return;
              }
              final manual = provider == PriceProvider.manual
                  ? parseNum(price.text)
                  : null;
              final rate = parseNum(fxCtrl.text);
              final fx = currency == baseCcy
                  ? 1.0
                  : (rate != null && rate > 0 ? 1 / rate : edit?.lastFx);
              if (provider == PriceProvider.manual &&
                  manual != null &&
                  currency != baseCcy &&
                  fx == null) {
                set(() => error = l.invfFxOrSyncRequired);
                return;
              }
              final base = (edit ?? Holding(id: 0, accountId: acc!, name: n))
                  .copyWith(
                    name: n,
                    accountId: acc,
                    kind: kind,
                    provider: provider,
                    symbol: provider == PriceProvider.manual
                        ? ''
                        : symbol.text.trim(),
                    currency: currency,
                    currencyManual:
                        manualCcy || provider == PriceProvider.manual,
                    lastPriceOrig: provider == PriceProvider.manual
                        ? (manual ?? edit?.lastPriceOrig)
                        : edit?.lastPriceOrig,
                    lastFx: provider == PriceProvider.manual && manual != null
                        ? fx
                        : edit?.lastFx,
                    lastPrice: provider == PriceProvider.manual
                        ? (manual == null
                              ? edit?.lastPrice
                              : manual * (fx ?? 1))
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
              s.fetchLogo(id);
              if (base.canAutoPrice) {
                final r = await s.refreshPrices(holdingId: id);
                if (context.mounted && r.failed.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l.invfPriceFetchFailed(r.failed.values.first),
                      ),
                    ),
                  );
                }
              }
            },
            child: Text(l.invfSave),
          ),
        ],
      ),
    ),
  );
}

/// Escolher só a moeda do ativo (manual ou automática) e atualizar o câmbio de mercado.
Future<void> showCurrencyPicker(BuildContext context, Holding h) async {
  final l = AppLocalizations.of(context)!;
  final s = context.read<AppState>();
  var value = h.canAutoPrice && !h.currencyManual ? 'AUTO' : h.currency;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        title: Text(l.invfAssetCurrency),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: value,
              isExpanded: true,
              items: [
                if (h.canAutoPrice)
                  DropdownMenuItem(
                    value: 'AUTO',
                    child: Text(l.invfAutoCurrency),
                  ),
                for (final c in kCurrencies)
                  DropdownMenuItem(
                    value: c,
                    child: Text(c == baseCcy ? l.invfBaseCurrencyOption(c) : c),
                  ),
              ],
              onChanged: (v) => set(() => value = v ?? value),
            ),
            const SizedBox(height: 10),
            Text(
              l.invfCurrencyPickerHint(baseCcy),
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.invfSave),
          ),
        ],
      ),
    ),
  );
  if (ok != true) return;
  final auto = value == 'AUTO';
  final nh = h.copyWith(
    currency: auto ? h.currency : value,
    currencyManual: !auto,
    lastFx: null,
  );
  // sem câmbio conhecido, o valor em moeda de base fica por atualizar até haver internet
  s.updateHolding(
    nh.currency == baseCcy
        ? nh.copyWith(lastFx: 1.0, lastPrice: nh.lastPriceOrig ?? nh.lastPrice)
        : nh,
  );
  if (nh.needsRefresh || nh.canAutoPrice) {
    final r = await s.refreshPrices(holdingId: h.id);
    if (context.mounted && r.failed.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.invfFxFetchFailed(r.failed.values.first))),
      );
    }
  }
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
  late InvestOp? _edit = widget.edit;
  late OpType type = _edit?.type ?? widget.type;
  late int? accountId = _edit?.accountId ?? widget.accountId;
  late int? holdingId = _edit?.holdingId ?? widget.holdingId;
  late DateTime date = _edit?.date ?? DateTime.now();
  late bool byQty = widget.prefillCents == null;
  late final qtyCtrl = TextEditingController(
    text: _edit != null && _edit!.quantity > 0
        ? _edit!.quantity.toString().replaceAll('.', ',')
        : '',
  );
  late final priceCtrl = TextEditingController(
    text: _edit != null && _edit!.price > 0
        ? _edit!.price.toString().replaceAll('.', ',')
        : '',
  );
  late final totalCtrl = TextEditingController(
    text: widget.prefillCents == null
        ? ''
        : (widget.prefillCents! / 100).toStringAsFixed(2).replaceAll('.', ','),
  );
  late final feeCtrl = TextEditingController(
    text: (_edit?.fee ?? 0) > 0
        ? (_edit!.fee / 100).toStringAsFixed(2).replaceAll('.', ',')
        : '',
  );
  final fxCtrl = TextEditingController();
  late final amountCtrl = TextEditingController(
    text: _edit != null && (type == OpType.dividend || type == OpType.cash)
        ? (_edit!.amount.abs() / 100).toStringAsFixed(2).replaceAll('.', ',')
        : '',
  );
  late final noteCtrl = TextEditingController(text: _edit?.note ?? '');
  late bool cashIn = (_edit?.amount ?? 1) >= 0;
  // false: a compra/venda/dividendo não mexe no dinheiro por alocar (ex.: a transferência ainda não está registada)
  late bool allocate = _edit?.allocate ?? true;
  String? error;
  bool? _extrasOpen; // "Mais opções" abre logo se já houver comissão, nota ou modo valor

  bool get usesHolding => type != OpType.cash;
  bool get tradeLike =>
      type == OpType.buy || type == OpType.sell || type == OpType.initial;

  double? get price => parseNum(priceCtrl.text);
  double? get totalIn => parseNum(totalCtrl.text);
  Holding? get _holding =>
      holdingId == null ? null : context.read<AppState>().holding(holdingId);
  String get ccy => _holding?.currency ?? baseCcy;
  String get ccyLabel => ccy == baseCcy ? baseSym : ccy;

  /// Operação num ativo que cota noutra moeda (USD…): o preço é nessa moeda e há câmbio.
  bool get foreignTrade => tradeLike && (_holding?.foreign ?? false);
  double? get rate => parseNum(
    fxCtrl.text,
  ); // unidades da moeda do ativo por 1 unidade da moeda de base
  double? get eurPerUnit =>
      !foreignTrade ? 1 : (rate != null && rate! > 0 ? 1 / rate! : null);

  double? get qty {
    if (byQty) return parseNum(qtyCtrl.text);
    final fx = eurPerUnit;
    return totalIn != null && price != null && price! > 0 && fx != null
        ? totalIn! / (price! * fx)
        : null;
  }

  /// Total em euros, sem comissão.
  double? get total {
    if (!byQty) return totalIn;
    final fx = eurPerUnit;
    return qty != null && price != null && fx != null
        ? qty! * price! * fx
        : null;
  }

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
    // posição inicial: se o ativo já tem uma, abre-a para editar (guardar substitui-a)
    if (_edit == null && type == OpType.initial) {
      final ex = _existingInitial(s, holdingId);
      if (ex != null) _edit = ex;
    }
    if (_edit != null) {
      _applyOp(_edit!, s.holding(_edit!.holdingId));
    } else {
      _prefillFx(s.holding(holdingId));
      // preço inicial sugerido: o último preço conhecido do ativo
      if (priceCtrl.text.isEmpty &&
          holdingId != null &&
          type != OpType.initial) {
        final lp = s.holding(holdingId)?.priceOrig;
        if (lp != null) priceCtrl.text = _num(lp);
      }
    }
    for (final c in [
      qtyCtrl,
      priceCtrl,
      totalCtrl,
      feeCtrl,
      amountCtrl,
      fxCtrl,
    ]) {
      c.addListener(() => setState(() => error = null));
    }
  }

  @override
  void dispose() {
    for (final c in [
      qtyCtrl,
      priceCtrl,
      fxCtrl,
      totalCtrl,
      feeCtrl,
      amountCtrl,
      noteCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Posição inicial já registada para o ativo (a mais recente), se existir.
  InvestOp? _existingInitial(AppState s, int? hid) {
    if (hid == null) return null;
    final l =
        s.investOps
            .where((o) => o.type == OpType.initial && o.holdingId == hid)
            .toList()
          ..sort(
            (a, b) => a.date.compareTo(b.date) != 0
                ? a.date.compareTo(b.date)
                : a.id.compareTo(b.id),
          );
    return l.isEmpty ? null : l.last;
  }

  /// Câmbio sugerido: o do último preço conhecido do ativo.
  void _prefillFx(Holding? h) {
    final fx = h?.lastFx;
    fxCtrl.text = h != null && h.foreign && fx != null && fx > 0
        ? _num(1 / fx)
        : '';
  }

  /// Preenche o formulário com uma operação existente.
  void _applyOp(InvestOp o, Holding? h) {
    byQty = true;
    date = o.date;
    qtyCtrl.text = o.quantity > 0 ? _num(o.quantity) : '';
    totalCtrl.text = '';
    feeCtrl.text = o.fee > 0
        ? (o.fee / 100).toStringAsFixed(2).replaceAll('.', ',')
        : '';
    noteCtrl.text = o.note;
    var p = o.price;
    if (h != null && h.foreign && tradeLike) {
      if (o.fx != null && o.fx! > 0) {
        fxCtrl.text = _num(1 / o.fx!);
      } else {
        // operação antiga, registada em euros: converte pelo câmbio atual para manter o custo em euros
        _prefillFx(h);
        final fx = h.lastFx;
        if (fx != null && fx > 0) p = o.price / fx;
      }
    } else {
      fxCtrl.text = '';
    }
    priceCtrl.text = p > 0 ? _num(p) : '';
  }

  static String _num(double v, [int digits = 6]) {
    final t = double.parse(v.toStringAsFixed(digits));
    return (t == t.roundToDouble() ? t.round().toString() : t.toString())
        .replaceAll('.', ',');
  }

  void _clearFields() {
    for (final c in [qtyCtrl, priceCtrl, totalCtrl, feeCtrl, noteCtrl]) {
      c.clear();
    }
    byQty = true;
  }

  Future<void> _liveFx(AppState s) async {
    final l = AppLocalizations.of(context)!;
    try {
      final fx = await s.prices.fxRate(ccy, baseCcy);
      if (mounted && fx > 0) setState(() => fxCtrl.text = _num(1 / fx));
    } on PriceException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.invfFxFetchFailed(e.message))));
    }
  }

  void _save(AppState s) {
    final l = AppLocalizations.of(context)!;
    if (accountId == null) {
      setState(() => error = l.invfChoosePlatform);
      return;
    }
    if (usesHolding && holdingId == null) {
      setState(() => error = l.invfChooseAsset);
      return;
    }
    final amt = amountCents;
    if (amt == null ||
        (type != OpType.cash && amt <= 0) ||
        (type == OpType.cash && amt == 0)) {
      setState(() => error = l.invfEnterValidAmounts);
      return;
    }
    if (foreignTrade && eurPerUnit == null) {
      setState(() => error = l.invfFxRequired(baseSym, ccy));
      return;
    }
    if (tradeLike && ((qty ?? 0) <= 0 || (price ?? 0) <= 0)) {
      setState(() => error = l.invfEnterQtyPrice);
      return;
    }
    if (type == OpType.sell) {
      final pos = _position(s);
      if (pos != null && qty! > pos + 1e-9) {
        setState(() => error = l.invfOnlyHaveUnits(fmtQty(pos)));
        return;
      }
    }
    final op = InvestOp(
      id: _edit?.id ?? 0,
      accountId: accountId!,
      holdingId: usesHolding ? holdingId : null,
      date: date,
      type: type,
      quantity: tradeLike ? qty! : 0,
      price: tradeLike ? price! : 0,
      fx: foreignTrade ? eurPerUnit : null,
      amount: amt,
      fee: (type == OpType.buy || type == OpType.sell) ? fee : 0,
      note: noteCtrl.text.trim(),
      txnId: _edit?.txnId,
      allocate: !_affectsCash || allocate,
    );
    final int keepId;
    if (_edit == null) {
      keepId = s.addOp(op);
    } else {
      s.updateOp(op);
      keepId = _edit!.id;
    }
    // só pode haver uma posição inicial por ativo: a nova substitui as anteriores
    if (type == OpType.initial) {
      for (final o
          in s.investOps
              .where(
                (o) =>
                    o.type == OpType.initial &&
                    o.holdingId == holdingId &&
                    o.id != keepId,
              )
              .toList()) {
        s.deleteOp(o.id);
      }
    }
    Navigator.pop(context, true);
  }

  /// Unidades que tens agora do ativo (sem contar com esta operação, se estiver a editar).
  double? _position(AppState s) {
    final p = s.portfolio.positions.where((p) => p.holding.id == holdingId);
    if (p.isEmpty) return _edit?.type == OpType.sell ? _edit!.quantity : 0;
    return p.first.qty +
        (_edit?.type == OpType.sell && _edit!.holdingId == holdingId
            ? _edit!.quantity
            : 0);
  }

  /// Compra, venda ou dividendo: mexem no dinheiro por alocar da plataforma (se [allocate]).
  bool get _affectsCash =>
      type == OpType.buy || type == OpType.sell || type == OpType.dividend;

  int _cashBefore(AppState s) {
    final a = s.portfolio.accounts.where((a) => a.account.id == accountId);
    var cash = a.isEmpty ? 0 : a.first.cashCents;
    final e = _edit;
    if (e != null &&
        e.accountId == accountId &&
        (e.allocate || e.type == OpType.cash)) {
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
    final l = AppLocalizations.of(context)!;
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
          if (!allocate) {
            return Callout(
              icon: Icons.link_off,
              color: cs.primary,
              title: (fee > 0
                  ? l.invfTotalToPayFee(fmtMoney(amt), fmtMoney(fee))
                  : l.invfTotalToPay(fmtMoney(amt))),
              body: l.invfNoAllocationHint,
            );
          }
          return Callout(
            icon: after < 0
                ? Icons.warning_amber_rounded
                : Icons.account_balance_wallet_outlined,
            color: after < 0 ? Colors.orange.shade700 : cs.primary,
            title: (fee > 0
                ? l.invfTotalToPayFee(fmtMoney(amt), fmtMoney(fee))
                : l.invfTotalToPay(fmtMoney(amt))),
            body: after < 0
                ? l.invfNotEnoughUnallocated(fmtMoney(amt), fmtMoney(cash))
                : l.invfUnallocatedChange(fmtMoney(cash), fmtMoney(after)),
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
            title: l.invfYouReceive(fmtMoney(amt)),
            body: [
              l.invfUnallocatedChange(fmtMoney(cash), fmtMoney(cash + amt)),
              if (realized != null)
                l.invfRealizedGain(fmtSignedMoney(realized), fmtPrice(avg!)),
            ].join(' '),
          );
        case OpType.initial:
          return Callout(
            icon: Icons.history,
            color: cs.primary,
            title: l.invfPositionCost(fmtMoney(amt)),
            body: l.invfInitialHint,
          );
        case OpType.dividend:
          return Callout(
            icon: Icons.payments_outlined,
            color: cs.primary,
            title: l.invfDividendIn(fmtMoney(amt)),
            body: l.invfBalanceChange(fmtMoney(cash), fmtMoney(cash + amt)),
          );
        case OpType.cash:
          return Callout(
            icon: Icons.account_balance_wallet_outlined,
            color: cs.primary,
            title: l.invfUnallocatedChangeTitle(
              fmtMoney(cash),
              fmtMoney(cash + amt),
            ),
            body: l.invfCashHint,
          );
      }
    }

    final typeLabels = <OpType, String>{
      OpType.buy: l.invfOpBuy,
      OpType.sell: l.invfOpSell,
      OpType.dividend: l.invfOpDividend,
      OpType.initial: l.invfOpAlreadyHeld,
      OpType.cash: l.invfOpCashChip,
    };

    void switchType(OpType t) {
      if (t == type) return;
      setState(() {
        type = t;
        error = null;
        final ex = t == OpType.initial ? _existingInitial(s, holdingId) : null;
        if (ex != null) {
          _edit = ex;
          _applyOp(ex, s.holding(holdingId));
        } else {
          if (_edit != null) {
            _edit = null;
            _clearFields();
            _prefillFx(s.holding(holdingId));
          }
          if (t != OpType.initial && priceCtrl.text.isEmpty) {
            final lp = s.holding(holdingId)?.priceOrig;
            if (lp != null) priceCtrl.text = _num(lp);
          }
        }
      });
    }

    final priceLabel = type == OpType.initial
        ? l.invfAvgPriceWithCcy(ccyLabel)
        : l.invfPriceWithCcy(ccyLabel);
    _extrasOpen ??=
        feeCtrl.text.isNotEmpty ||
        noteCtrl.text.isNotEmpty ||
        !byQty ||
        !allocate;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.edit == null
              ? l.invfOpNewTitle
              : l.invfOpEditTitle(_opTypeLabel(l, type)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          FormCard(
            children: [
              // tipo de operação (só ao criar)
              if (widget.edit == null)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final e in typeLabels.entries)
                      ChoiceChip(
                        label: Text(e.value),
                        selected: type == e.key,
                        onSelected: (_) => switchType(e.key),
                      ),
                  ],
                ),
              if (s.investAccounts.length > 1 || accountId == null) ...[
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: accountId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l.invfPlatform,
                    prefixIcon: Icon(Icons.account_balance_outlined),
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
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  key: ValueKey('h-$accountId-${holdings.length}-$holdingId'),
                  initialValue: holdingId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l.invfHolding,
                    prefixIcon: Icon(Icons.pie_chart_outline),
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
                    DropdownMenuItem(
                      value: -1,
                      child: Text(l.invfNewAssetItem),
                    ),
                  ],
                  onChanged: (v) async {
                    if (v == -1) {
                      final id = await showHoldingEditor(
                        context,
                        accountId: accountId,
                      );
                      if (id != null && mounted) {
                        setState(() {
                          holdingId = id;
                          _prefillFx(s.holding(id));
                        });
                      }
                    } else {
                      setState(() {
                        holdingId = v;
                        final h = s.holding(v);
                        final ex = widget.edit == null && type == OpType.initial
                            ? _existingInitial(s, v)
                            : null;
                        if (ex != null) {
                          _edit = ex;
                          _applyOp(ex, h);
                        } else if (widget.edit == null) {
                          if (_edit != null) {
                            _edit = null;
                            _clearFields();
                          }
                          _prefillFx(h);
                          if (type != OpType.initial) {
                            final lp = h?.priceOrig;
                            if (lp != null) priceCtrl.text = _num(lp);
                          }
                        }
                      });
                    }
                  },
                ),
              ],
              if (tradeLike) ...[
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: byQty
                          ? TextField(
                              controller: qtyCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: l.invfQuantity,
                                hintText: '0',
                              ),
                            )
                          : TextField(
                              controller: totalCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: l.invfValueWithCcy(baseSym),
                                prefixText: '$baseSym  ',
                                hintText: '0,00',
                              ),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: priceLabel,
                          prefixText: ccy == baseCcy ? '$baseSym  ' : null,
                          suffixText: ccy == baseCcy ? null : ccy,
                          hintText: '0,00',
                        ),
                      ),
                    ),
                  ],
                ),
                if (foreignTrade) ...[
                  const SizedBox(height: 14),
                  TextField(
                    controller: fxCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: type == OpType.initial
                          ? l.invfAvgFxLabel(baseSym, ccy)
                          : l.invfFxRateLabel(baseSym, ccy),
                      prefixIcon: const Icon(Icons.currency_exchange),
                      hintText: '1,0850',
                      suffixIcon: IconButton(
                        tooltip: l.invfLiveFxTooltip,
                        icon: const Icon(Icons.sync),
                        onPressed: () => _liveFx(s),
                      ),
                    ),
                  ),
                ],
                if (total != null || (!byQty && qty != null))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      [
                        if (!byQty && qty != null)
                          l.invfUnitsEquals(fmtQty(qty!)),
                        if (byQty && total != null)
                          '= ${fmtMoney((total! * 100).round())}',
                      ].join(' '),
                      style: tt.bodySmall,
                    ),
                  ),
              ],
              if (type == OpType.dividend || type == OpType.cash) ...[
                if (type == OpType.cash) ...[
                  const SizedBox(height: 14),
                  SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: true,
                        label: Text(l.invfCashIn),
                        icon: Icon(Icons.south_west),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text(l.invfCashOut),
                        icon: Icon(Icons.north_east),
                      ),
                    ],
                    selected: {cashIn},
                    onSelectionChanged: (v) => setState(() => cashIn = v.first),
                  ),
                ],
                const SizedBox(height: 14),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: type == OpType.dividend
                        ? l.invfReceivedWithCcy(baseSym)
                        : l.invfValueWithCcy(baseSym),
                    prefixText: '$baseSym  ',
                    hintText: '0,00',
                  ),
                ),
              ],
              const SizedBox(height: 14),
              TileField(
                icon: Icons.event,
                title: l.invfDate,
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
              // o resto, escondido até ser preciso
              Material(
                key: const ValueKey(
                  'extras',
                ), // mantém o estado aberto/fechado quando a coluna muda
                type: MaterialType.transparency,
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    key: const ValueKey('extras-tile'),
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    initiallyExpanded: _extrasOpen!,
                    title: Text(
                      tradeLike ? l.invfMoreOptionsTrade : l.invfNote,
                      style: tt.titleSmall,
                    ),
                    children: [
                      if (tradeLike && type != OpType.initial)
                        TextField(
                          controller: feeCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: l.invfFeeWithCcy(baseSym),
                            prefixText: '$baseSym  ',
                            hintText: '0,00',
                          ),
                        ),
                      if (_affectsCash)
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l.invfDeductUnallocated),
                          subtitle: Text(l.invfDeductHint),
                          value: allocate,
                          onChanged: (v) => setState(() => allocate = v),
                        ),
                      if (tradeLike) ...[
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l.invfUseTotalInstead),
                          value: !byQty,
                          onChanged: (v) => setState(() {
                            final q = qty, t = total;
                            byQty = !v;
                            if (byQty && q != null) qtyCtrl.text = _num(q);
                            if (!byQty && t != null)
                              totalCtrl.text = t
                                  .toStringAsFixed(2)
                                  .replaceAll('.', ',');
                          }),
                        ),
                        if (widget.edit == null && _holding != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              icon: const Icon(
                                Icons.currency_exchange,
                                size: 16,
                              ),
                              label: Text(
                                l.invfAssetCurrencyChange(_holding!.currency),
                              ),
                              onPressed: () async {
                                await showCurrencyPicker(context, _holding!);
                                if (mounted)
                                  setState(() => _prefillFx(_holding));
                              },
                            ),
                          ),
                      ],
                      const SizedBox(height: 8),
                      TextField(
                        controller: noteCtrl,
                        decoration: InputDecoration(
                          labelText: l.invfNote,
                          prefixIcon: Icon(Icons.notes),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (widget.edit == null &&
                  _edit != null &&
                  type == OpType.initial) ...[
                Callout(
                  icon: Icons.history,
                  color: cs.primary,
                  title: l.invfHasInitialTitle,
                  body: l.invfHasInitialBody,
                ),
                const SizedBox(height: 12),
              ],
              summary(),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error!, style: TextStyle(color: cs.error)),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _save(s),
                child: Text(_edit == null ? l.invfSave : l.invfSaveChanges),
              ),
              if (_edit != null)
                TextButton.icon(
                  onPressed: () {
                    s.deleteOp(_edit!.id);
                    Navigator.pop(context, true);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l.invfDeleteOp),
                ),
            ],
          ),
        ],
      ),
    );
  }
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
    final l = AppLocalizations.of(context)!;
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
      appBar: AppBar(
        title: Text(l.invfLinkTitle(acc?.name ?? l.invfPlatformLower)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.invfLinkHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: l.invfSearchTransactions,
                  ),
                  onChanged: (v) => setState(() => q = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: shown.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        l.invfNoTransactionsToLink,
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
                          '${fmtDate(t.date)}${mentions(t) ? l.invfLooksLikeThis : ''}',
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
                    title: Text(l.invfRememberTitles),
                    subtitle: Text(l.invfRememberHint),
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
                            ? l.invfLinkButton
                            : l.invfLinkCount(
                                selected.length,
                                fmtSignedMoney(total),
                              ),
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

String _kindLabel(AppLocalizations l, HoldingKind k) => switch (k) {
  HoldingKind.etf => l.invfKindEtf,
  HoldingKind.stock => l.invfKindStock,
  HoldingKind.crypto => l.invfKindCrypto,
  HoldingKind.fund => l.invfKindFund,
  HoldingKind.bond => l.invfKindBond,
  HoldingKind.other => l.invfKindOther,
};

String _opTypeLabel(AppLocalizations l, OpType t) => switch (t) {
  OpType.initial => l.invfOpInitial,
  OpType.buy => l.invfOpBuy,
  OpType.sell => l.invfOpSell,
  OpType.dividend => l.invfOpDividend,
  OpType.cash => l.invfOpCash,
};
