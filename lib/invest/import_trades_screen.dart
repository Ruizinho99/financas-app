import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../analysis/widgets.dart';
import '../l10n/app_localizations.dart';
import '../import/parsers.dart'
    show decodeText, parseCsv, parseXlsxSheets, pdfText;
import '../state/app_state.dart';
import '../util/format.dart';
import '../widgets/form_kit.dart';
import 'forms.dart' show showInvestAccountEditor;
import 'invest.dart';
import 'price_service.dart';
import 'trade_import.dart';

/// Importa compras, vendas e dividendos de um ficheiro da corretora (PDF, CSV ou Excel).
/// Tudo é lido no telemóvel; a internet só é usada se carregares no botão do câmbio.
class ImportTradesScreen extends StatefulWidget {
  final int? accountId;

  /// Para testes: dá o conteúdo em vez de abrir o seletor de ficheiros.
  final ({String name, Uint8List bytes})? preloaded;
  const ImportTradesScreen({super.key, this.accountId, this.preloaded});
  @override
  State<ImportTradesScreen> createState() => _ImportTradesScreenState();
}

class _ImportTradesScreenState extends State<ImportTradesScreen> {
  int? accountId;
  String? filename;
  String source = '';
  List<List<String>>? table;
  TradeMapping mapping = TradeMapping();
  Map<String, List<List<String>>> sheets = {}; // folhas do Excel
  String? sheet;
  TradeReport? report; // validação da última leitura da tabela
  final Map<String, String> typeOverrides =
      {}; // tipo não reconhecido -> o que fazer
  List<ParsedTrade> trades = [];
  final Set<int> excluded = {};
  DateTime? from, to; // intervalo de datas a importar (nulo = tudo)
  final Map<String, int> choice =
      {}; // chave do instrumento -> id do ativo, 0 = criar novo, -1 = ignorar
  final Map<String, TextEditingController> rateCtrls =
      {}; // moeda -> unidades por 1 da moeda de base
  String defaultCcy = baseCcy;
  bool busy = false;
  String? error;
  bool mappingOpen = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    accountId =
        widget.accountId ??
        (s.investAccounts.length == 1 ? s.investAccounts.first.id : null);
    if (widget.preloaded != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _load(widget.preloaded!.name, widget.preloaded!.bytes),
      );
    }
  }

  @override
  void dispose() {
    for (final c in rateCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick() async {
    final l = AppLocalizations.of(context)!;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'csv', 'xlsx', 'txt'],
      );
      if (files.isEmpty) {
        setState(() => busy = false);
        return;
      }
      final f = files.first;
      await _load(f.name, await f.readAsBytes());
    } catch (e) {
      setState(() {
        error = l.invfReadError('$e');
        busy = false;
      });
    }
  }

  Future<void> _load(String name, Uint8List bytes) async {
    final l = AppLocalizations.of(context)!;
    try {
      final ext = name.split('.').last.toLowerCase();
      filename = name;
      source = ext == 'pdf' ? 'pdf' : (ext == 'xlsx' ? 'xlsx' : 'csv');
      table = null;
      excluded.clear();
      from = to = null;
      if (ext == 'pdf') {
        trades = tradesFromText(pdfText(bytes));
      } else {
        typeOverrides.clear();
        report = null;
        sheets = {};
        if (ext == 'xlsx') {
          sheets = parseXlsxSheets(bytes);
          if (sheets.isEmpty) throw FormatException(l.invfExcelNoData);
          // escolhe a folha onde as colunas são melhor reconhecidas
          var bestScore = -1;
          for (final e in sheets.entries) {
            final m = guessTradeMapping(e.value);
            final score =
                (m.usable ? 1000 : 0) +
                [for (final (f, _) in TradeMapping.fields) m.get_(f)]
                        .where((x) => x != null)
                        .length *
                    10 +
                (e.value.length > 9 ? 9 : e.value.length);
            if (score > bestScore) {
              bestScore = score;
              sheet = e.key;
            }
          }
          table = sheets[sheet];
        } else {
          sheet = null;
          table = parseCsv(decodeText(bytes));
        }
        mapping = guessTradeMapping(table!);
        mappingOpen = !mapping.usable;
        _parseTable();
      }
      _afterParse();
      if (trades.isEmpty) {
        error = ext == 'pdf' ? l.invfPdfNotFound : l.invfNotFoundTrades;
      } else {
        error = null;
      }
    } catch (e) {
      trades = [];
      error = l.invfReadError('$e');
    }
    if (mounted) setState(() => busy = false);
  }

  /// Lê a tabela com as colunas escolhidas e guarda o relatório de validação.
  void _parseTable() {
    if (table == null || !mapping.usable) {
      trades = [];
      report = null;
      return;
    }
    report = parseTradeTable(table!, mapping, typeOverrides: typeOverrides);
    trades = report!.trades;
  }

  void _reparse() {
    final l = AppLocalizations.of(context)!;
    _parseTable();
    excluded.clear();
    _afterParse();
    setState(() => error = trades.isEmpty ? l.invfNotFoundWithColumns : null);
  }

  bool _inRange(ParsedTrade t) {
    final d = DateTime(t.date.year, t.date.month, t.date.day);
    return (from == null ||
            !d.isBefore(DateTime(from!.year, from!.month, from!.day))) &&
        (to == null || !d.isAfter(DateTime(to!.year, to!.month, to!.day)));
  }

  // ---- instrumentos ----
  Map<String, List<ParsedTrade>> get groups {
    final m = <String, List<ParsedTrade>>{};
    for (final t in trades.where(_inRange)) {
      if (t.key.isEmpty) continue;
      (m[t.key] ??= []).add(t);
    }
    return m;
  }

  static String _label(List<ParsedTrade> l) {
    for (final t in l) {
      if (t.name.isNotEmpty) return t.name;
    }
    for (final t in l) {
      if (t.symbol.isNotEmpty) return t.symbol;
    }
    return l.first.isin.isNotEmpty ? l.first.isin : l.first.key;
  }

  /// Ativo que já existe na plataforma e corresponde a este instrumento.
  Holding? _match(AppState s, String key, List<ParsedTrade> l) {
    final name = _label(l).toUpperCase();
    final sym = l
        .map((t) => t.symbol)
        .firstWhere((x) => x.isNotEmpty, orElse: () => '')
        .toUpperCase();
    for (final h in s.holdings.where(
      (h) => !h.archived && h.accountId == accountId,
    )) {
      final hs = h.symbol.toUpperCase(), hn = h.name.toUpperCase();
      if (hs.isNotEmpty &&
          (hs == key ||
              hs == sym ||
              hs == yahooSymbol(sym).toUpperCase() ||
              hs.split('.').first == sym ||
              hs.split('.').first == key))
        return h;
      if (hn == name ||
          (name.length > 3 && (hn.contains(name) || name.contains(hn))))
        return h;
    }
    return null;
  }

  void _afterParse() {
    final s = context.read<AppState>();
    choice.clear();
    for (final e in groups.entries) {
      choice[e.key] = _match(s, e.key, e.value)?.id ?? 0;
    }
    _syncRateFields();
  }

  String _ccyOf(ParsedTrade t) => t.currency.isEmpty ? defaultCcy : t.currency;

  /// Moedas para as quais falta indicar o câmbio.
  Set<String> _neededCcys(AppState s) {
    final out = <String>{};
    for (final t in trades.where(_inRange)) {
      if (_ccyOf(t) != baseCcy && t.rate == null) out.add(_ccyOf(t));
    }
    for (final e in groups.entries) {
      final id = choice[e.key] ?? 0;
      if (id > 0) {
        final h = s.holding(id);
        if (h != null && h.currency != baseCcy) out.add(h.currency);
      }
    }
    return out;
  }

  void _syncRateFields() {
    final s = context.read<AppState>();
    final need = _neededCcys(s);
    for (final c in need) {
      rateCtrls.putIfAbsent(c, () {
        final lastFx = s.holdings
            .where((h) => h.currency == c && (h.lastFx ?? 0) > 0)
            .map((h) => h.lastFx!)
            .firstOrNull;
        return TextEditingController(
          text: lastFx == null ? '' : _num4(1 / lastFx),
        )..addListener(() => setState(() {}));
      });
    }
  }

  static String _num4(double v) => v.toStringAsFixed(4).replaceAll('.', ',');

  Map<String, double> get _rates => {
    for (final e in rateCtrls.entries)
      if ((parseDecimal(e.value.text) ?? 0) > 0)
        e.key: parseDecimal(e.value.text)!,
  };

  Future<void> _liveRate(AppState s, String ccy) async {
    final l = AppLocalizations.of(context)!;
    try {
      final r = await s.prices.fxRate(ccy, baseCcy);
      if (r > 0 && mounted) setState(() => rateCtrls[ccy]?.text = _num4(1 / r));
    } on PriceException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.invfFxFetchFailed(e.message))));
    }
  }

  // ---- operações a gravar ----
  ({
    List<({String key, InvestOp op, ParsedTrade t, bool dup})> ops,
    int missingRate,
    int missingQty,
  })
  _build(AppState s) {
    final out = <({String key, InvestOp op, ParsedTrade t, bool dup})>[];
    var missing = 0, missingQty = 0;
    if (accountId == null) return (ops: out, missingRate: 0, missingQty: 0);
    final existing = {
      for (final o in s.investOps.where((o) => o.accountId == accountId))
        opSignature(o),
    };
    final g = groups;
    for (var i = 0; i < trades.length; i++) {
      final t = trades[i];
      if (!_inRange(t)) continue;
      final key = t.key;
      final c = choice[key];
      if (c == null || c < 0) continue;
      final h = c > 0 ? s.holding(c) : null;
      final hCcy = h?.currency ?? _ccyOf(g[key]!.first);
      final dup = c > 0 && existing.contains(tradeSignature(c, t));
      final op = tradeToOp(
        t,
        accountId: accountId!,
        holdingId: c > 0 ? c : null,
        base: baseCcy,
        defaultCcy: defaultCcy,
        rates: _rates,
        holdingCcy: hCcy,
      );
      if (op == null && !dup) {
        if (t.valueOnly) {
          missingQty++;
        } else {
          missing++;
        }
        continue;
      }
      out.add((
        key: key,
        op:
            op ??
            InvestOp(
              id: 0,
              accountId: accountId!,
              holdingId: c,
              date: t.date,
              type: t.kind == 'buy'
                  ? OpType.buy
                  : (t.kind == 'sell' ? OpType.sell : OpType.dividend),
            ),
        t: t,
        dup: dup,
      ));
    }
    return (ops: out, missingRate: missing, missingQty: missingQty);
  }

  HoldingKind _guessKind(String name, String symbol) {
    final n = name.toUpperCase();
    if (RegExp(r'\bETF\b|UCITS|ISHARES|VANGUARD|SPDR|XTRACKERS|AMUNDI|INVESCO')
        .hasMatch(n))
      return HoldingKind.etf;
    if (RegExp(r'BITCOIN|ETHEREUM|CRYPTO|COIN').hasMatch(n))
      return HoldingKind.crypto;
    return HoldingKind.stock;
  }

  void _import(AppState s) {
    final l = AppLocalizations.of(context)!;
    final b = _build(s);
    final toSave = [
      for (final e in b.ops)
        if (!e.dup && !excluded.contains(trades.indexOf(e.t))) e,
    ];
    final newH = <String, Holding>{};
    final g = groups;
    for (final e in toSave) {
      if (choice[e.key] == 0 && !newH.containsKey(e.key)) {
        final l = g[e.key]!;
        final name = _label(l);
        final sym = l
            .map((t) => t.symbol)
            .firstWhere((x) => x.isNotEmpty, orElse: () => '');
        newH[e.key] = Holding(
          id: 0,
          accountId: accountId!,
          name: name,
          symbol: yahooSymbol(sym),
          provider: sym.isEmpty ? PriceProvider.manual : PriceProvider.yahoo,
          kind: l.first.category.isNotEmpty
              ? kindFromCategory(l.first.category, name)
              : _guessKind(name, sym),
          currency: _ccyOf(l.first),
        );
      }
    }
    final n = s.importTradeOps(
      newHoldings: newH,
      ops: [for (final e in toSave) (key: e.key, op: e.op)],
    );
    final negativeCash = s.portfolio.accounts.any(
      (a) => a.account.id == accountId && a.cashCents < 0,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${l.invfImportedOps(n)}${newH.isEmpty ? '' : l.invfImportedHoldings(newH.length)}${l.invfUpdatePrices}'
          '${negativeCash ? l.invfNegativeCashWarning : ''}',
        ),
        duration: Duration(seconds: negativeCash ? 8 : 4),
      ),
    );
    Navigator.pop(context, true);
  }

  // ---- UI ----
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = context.watch<AppState>();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final g = groups;
    final b = _build(s);
    final active = [
      for (final e in b.ops)
        if (!e.dup && !excluded.contains(trades.indexOf(e.t))) e,
    ];
    final dups = b.ops.where((e) => e.dup).length;
    final need = _neededCcys(s).toList()..sort();
    final missingRate = need.where((c) => !_rates.containsKey(c)).toList();
    final nBuy = active.where((e) => e.op.type == OpType.buy).length;
    final nSell = active.where((e) => e.op.type == OpType.sell).length;
    final nDiv = active.where((e) => e.op.type == OpType.dividend).length;
    final canImport = accountId != null && active.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(l.invfImportTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
        children: [
          FormCard(
            children: [
              Text(l.invfImportIntro, style: tt.bodyMedium),
              FieldLabel(l.invfPlatform),
              DropdownButtonFormField<int>(
                key: ValueKey('acc-$accountId-${s.investAccounts.length}'),
                initialValue: accountId,
                isExpanded: true,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.account_balance_outlined),
                  hintText: l.invfChoosePlatformHint,
                ),
                items: [
                  for (final a in s.investAccounts)
                    DropdownMenuItem(
                      value: a.id,
                      child: Text('${a.emoji} ${a.name}'.trim()),
                    ),
                  DropdownMenuItem(
                    value: -1,
                    child: Text(l.invfNewPlatformItem),
                  ),
                ],
                onChanged: (v) async {
                  if (v == -1) {
                    final id = await showInvestAccountEditor(context);
                    if (id != null && mounted) {
                      setState(() => accountId = id);
                      if (trades.isNotEmpty) _afterParse();
                    }
                  } else {
                    setState(() {
                      accountId = v;
                      if (trades.isNotEmpty) _afterParse();
                    });
                  }
                },
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: busy ? null : _pick,
                icon: const Icon(Icons.upload_file),
                label: Text(
                  filename == null ? l.invfChooseFile : l.invfChooseOtherFile,
                ),
              ),
              if (filename != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(l.invfFileName(filename ?? '')),
                ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(error!, style: TextStyle(color: cs.error)),
                ),
            ],
          ),

          if (table != null) ...[
            const SizedBox(height: 14),
            _mappingCard(context),
            if (report != null || !mapping.usable) ...[
              const SizedBox(height: 14),
              _validationCard(context),
            ],
          ],

          if (trades.isNotEmpty) ...[
            const SizedBox(height: 14),
            DateRangeCard(
              min: trades
                  .map((t) => t.date)
                  .reduce((a, b) => a.isBefore(b) ? a : b),
              max: trades
                  .map((t) => t.date)
                  .reduce((a, b) => a.isAfter(b) ? a : b),
              from: from,
              to: to,
              inRange: trades.where(_inRange).length,
              total: trades.length,
              onChanged: (f, t) => setState(() {
                from = f;
                to = t;
                _afterParse();
              }),
            ),
            const SizedBox(height: 14),
            // moeda e câmbio
            FormCard(
              children: [
                Text(l.invfCurrencyAndRate, style: tt.titleMedium),
                const SizedBox(height: 4),
                Text(l.invfCurrencyIntro(baseCcy), style: tt.bodySmall),
                if (!trades.any((t) => t.currency.isNotEmpty)) ...[
                  FieldLabel(l.invfTransactionCurrency),
                  DropdownButtonFormField<String>(
                    initialValue: defaultCcy,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.currency_exchange),
                    ),
                    items: [
                      for (final c in kCurrencies)
                        DropdownMenuItem(
                          value: c,
                          child: Text(
                            c == baseCcy ? l.invfBaseCurrencyOption(c) : c,
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() {
                      defaultCcy = v ?? baseCcy;
                      _syncRateFields();
                    }),
                  ),
                ],
                for (final c in need) ...[
                  FieldLabel(l.invfFxLabel(baseSym, c)),
                  TextField(
                    controller: rateCtrls[c],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: '1,0850',
                      prefixIcon: const Icon(Icons.currency_exchange),
                      suffixIcon: IconButton(
                        tooltip: l.invfLiveFxTooltip,
                        icon: const Icon(Icons.sync),
                        onPressed: () => _liveRate(s, c),
                      ),
                    ),
                  ),
                ],
                if (need.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(l.invfAllInBase(baseCcy), style: tt.bodySmall),
                  ),
              ],
            ),

            const SizedBox(height: 14),
            // ativos
            FormCard(
              children: [
                Text(l.invfAssetsFound, style: tt.titleMedium),
                const SizedBox(height: 4),
                Text(l.invfAssetsHint, style: tt.bodySmall),
                for (final e in g.entries) ...[
                  const SizedBox(height: 14),
                  Text(
                    l.invfTradeCountLabel(_label(e.value), e.value.length),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (e.value.first.isin.isNotEmpty ||
                      e.value.first.symbol.isNotEmpty)
                    Text(
                      [
                        if (e.value.first.symbol.isNotEmpty)
                          e.value.first.symbol,
                        if (e.value.first.isin.isNotEmpty) e.value.first.isin,
                      ].join(' · '),
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    key: ValueKey('h-${e.key}-${choice[e.key]}-$accountId'),
                    initialValue: choice[e.key],
                    isExpanded: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.pie_chart_outline),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 0,
                        child: Text(l.invfCreateNewAsset),
                      ),
                      for (final h in s.holdings.where(
                        (h) => !h.archived && h.accountId == accountId,
                      ))
                        DropdownMenuItem(
                          value: h.id,
                          child: Text(
                            '${h.kind.emoji}  ${h.name}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      DropdownMenuItem(value: -1, child: Text(l.invfIgnore)),
                    ],
                    onChanged: (v) => setState(() {
                      choice[e.key] = v ?? 0;
                      _syncRateFields();
                    }),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 14),
            // operações
            FormCard(
              children: [
                Text(l.invfOperations, style: tt.titleMedium),
                const SizedBox(height: 4),
                Text(
                  [
                    if (nBuy > 0) l.invfBuysCount(nBuy),
                    if (nSell > 0) l.invfSellsCount(nSell),
                    if (nDiv > 0) l.invfDividendsCount(nDiv),
                    if (dups > 0) l.invfDuplicatesIgnored(dups),
                  ].join(' · '),
                  style: tt.bodySmall,
                ),
                if (missingRate.isNotEmpty || b.missingRate > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Callout(
                      icon: Icons.warning_amber_rounded,
                      color: Colors.orange.shade700,
                      title: l.invfMissingRate,
                      body: l.invfMissingRateBody(
                        missingRate.isEmpty
                            ? l.invfAllCurrencies
                            : missingRate.join(', '),
                      ),
                    ),
                  ),
                if (b.missingQty > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Callout(
                      icon: Icons.warning_amber_rounded,
                      color: Colors.orange.shade700,
                      title: l.invfMissingQtyTitle(b.missingQty),
                      body: l.invfMissingQtyBody,
                    ),
                  ),
                const SizedBox(height: 6),
                for (final e in b.ops.take(300))
                  Material(
                    type: MaterialType.transparency,
                    child: CheckboxListTile(
                      key: ValueKey('t-${trades.indexOf(e.t)}'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: !e.dup && !excluded.contains(trades.indexOf(e.t)),
                      onChanged: e.dup
                          ? null
                          : (v) => setState(
                              () => v == true
                                  ? excluded.remove(trades.indexOf(e.t))
                                  : excluded.add(trades.indexOf(e.t)),
                            ),
                      title: Text(
                        '${_opTypeLabel(l, e.op.type)} · ${_label(groups[e.key]!)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${fmtDate(e.op.date)}${e.op.type == OpType.dividend ? '' : l.invfTradeQtyPart(fmtQty(e.op.quantity), fmtPrice(e.t.price).replaceAll(baseSym, '').trim(), _ccyOf(e.t))}${e.dup ? l.invfAlreadyExists : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      secondary: Text(
                        fmtMoney(e.op.amount),
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                if (b.ops.length > 300)
                  Text(l.invfShowingFirst(b.ops.length), style: tt.bodySmall),
              ],
            ),
          ],
        ],
      ),
      bottomNavigationBar: trades.isEmpty
          ? null
          : Material(
              color: cs.surface,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: FilledButton(
                    onPressed: canImport ? () => _import(s) : null,
                    child: Text(
                      accountId == null
                          ? l.invfChoosePlatformShort
                          : l.invfImportCount(active.length),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _mappingCard(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = table!;
    final headers = mapping.headerRow >= 0 && mapping.headerRow < t.length
        ? t[mapping.headerRow]
        : (t.isEmpty
              ? <String>[]
              : List.generate(
                  t.first.length,
                  (i) => l.invfColumnNumber(i + 1),
                ));
    return FormCard(
      children: [
        InkWell(
          onTap: () => setState(() => mappingOpen = !mappingOpen),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l.invfFileColumns,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Icon(mappingOpen ? Icons.expand_less : Icons.expand_more),
            ],
          ),
        ),
        if (!mappingOpen)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              mapping.usable ? l.invfAutoRecognized : l.invfIndicateColumns,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (mappingOpen) ...[
          if (sheets.length > 1) ...[
            FieldLabel(l.invfExcelSheet),
            DropdownButtonFormField<String>(
              key: ValueKey('sheet-$sheet'),
              initialValue: sheet,
              isExpanded: true,
              items: [
                for (final n in sheets.keys)
                  DropdownMenuItem(
                    value: n,
                    child: Text(
                      l.invfSheetRows(n, sheets[n]!.length),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) {
                if (v == null) return;
                sheet = v;
                table = sheets[v];
                typeOverrides.clear();
                mapping = guessTradeMapping(table!);
                _reparse();
              },
            ),
          ],
          FieldLabel(l.invfHeaderRow),
          DropdownButtonFormField<int>(
            key: ValueKey('hdr-${mapping.headerRow}-$sheet'),
            initialValue: mapping.headerRow,
            isExpanded: true,
            items: [
              DropdownMenuItem(value: -1, child: Text(l.invfNoHeaders)),
              for (var i = 0; i < t.length && i < 30; i++)
                DropdownMenuItem(
                  value: i,
                  child: Text(
                    l.invfHeaderRowItem(
                      i + 1,
                      t[i]
                          .where((c) => c.trim().isNotEmpty)
                          .take(4)
                          .join(' · '),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) {
              if (v == null) return;
              mapping = guessTradeMapping(t, headerRow: v);
              mapping.headerRow = v;
              _reparse();
            },
          ),
          for (final (f, _) in TradeMapping.fields) ...[
            FieldLabel(
              _fieldLabel(l, f),
              optional: !{'date', 'quantity'}.contains(f),
            ),
            DropdownButtonFormField<int?>(
              key: ValueKey('map-$f-${mapping.get_(f)}'),
              initialValue: mapping.get_(f),
              isExpanded: true,
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(l.invfNotExists),
                ),
                for (var i = 0; i < headers.length; i++)
                  DropdownMenuItem<int?>(
                    value: i,
                    child: Text(
                      headers[i].trim().isEmpty
                          ? l.invfColumnNumber(i + 1)
                          : headers[i].trim(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) {
                mapping.set_(f, v);
                _reparse();
              },
            ),
          ],
        ],
      ],
    );
  }

  Widget _validationCard(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final r = report;
    final t = table!;
    final headers = mapping.headerRow >= 0 && mapping.headerRow < t.length
        ? t[mapping.headerRow]
        : <String>[];
    String colName(int? c) => c == null
        ? ''
        : (c < headers.length && headers[c].trim().isNotEmpty
              ? headers[c].trim()
              : 'coluna ${c + 1}');
    final missing = [
      if (mapping.date == null) l.invfDate,
      if (mapping.quantity == null && mapping.comment == null)
        l.invfQuantityOrComment,
      if (mapping.price == null && mapping.total == null) l.invfPriceOrTotal,
    ];
    Widget row(IconData icon, Color color, String text) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: tt.bodyMedium)),
        ],
      ),
    );
    final ok = Colors.green.shade700, warn = Colors.orange.shade800;
    return FormCard(
      children: [
        Text(l.invfFileValidation, style: tt.titleMedium),
        const SizedBox(height: 4),
        if (r == null) ...[
          Text(l.invfRequiredNote, style: tt.bodySmall),
          for (final m in missing)
            row(Icons.error_outline, cs.error, l.invfMissingColumn(m)),
        ] else ...[
          Text(
            '${l.invfValidationSummary(r.dataRows, r.trades.length)}'
            '${r.skipped.isEmpty ? '' : l.invfWithProblems(r.skipped.length)}'
            '${r.ignoredByUser == 0 ? '' : l.invfIgnoredByUser(r.ignoredByUser)}',
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          for (final m in missing)
            row(Icons.error_outline, cs.error, l.invfMissingColumn(m)),
          const SizedBox(height: 6),
          for (final (f, label) in TradeMapping.fields)
            if (mapping.get_(f) != null && r.columns[f] != null)
              () {
                final c = r.columns[f]!;
                final all = c.ok == c.total;
                return row(
                  all
                      ? Icons.check_circle_outline
                      : (c.ok == 0
                            ? Icons.error_outline
                            : Icons.warning_amber_rounded),
                  all ? ok : (c.ok == 0 ? cs.error : warn),
                  (colName(mapping.get_(f)).toLowerCase() ==
                          label.split(' (').first.toLowerCase()
                      ? l.invfColumnValid(
                          _fieldLabel(l, f).split(' (').first,
                          c.ok,
                          c.total,
                        )
                      : l.invfColumnValidNamed(
                          _fieldLabel(l, f).split(' (').first,
                          colName(mapping.get_(f)),
                          c.ok,
                          c.total,
                        )),
                );
              }(),
          if (r.unknownTypes.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(l.invfUnknownTypes, style: tt.titleSmall),
            Text(l.invfUnknownTypesHint, style: tt.bodySmall),
            for (final e in r.unknownTypes.entries) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.invfUnknownTypeRows(
                        e.key.isEmpty ? l.invfEmpty : e.key,
                        e.value,
                      ),
                      style: tt.bodyMedium,
                    ),
                  ),
                  DropdownButton<String>(
                    hint: Text(l.invfChoose),
                    value: typeOverrides[typeKey(e.key)],
                    items: [
                      DropdownMenuItem(value: 'buy', child: Text(l.invfOpBuy)),
                      DropdownMenuItem(
                        value: 'sell',
                        child: Text(l.invfOpSell),
                      ),
                      DropdownMenuItem(
                        value: 'dividend',
                        child: Text(l.invfOpDividend),
                      ),
                      DropdownMenuItem(
                        value: 'ignore',
                        child: Text(l.invfIgnore),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      typeOverrides[typeKey(e.key)] = v;
                      _reparse();
                    },
                  ),
                ],
              ),
            ],
          ],
          if (r.skipped.isNotEmpty) ...[
            const SizedBox(height: 10),
            Material(
              type: MaterialType.transparency,
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  title: Text(
                    l.invfSkippedRows(r.skipped.length),
                    style: tt.titleSmall?.copyWith(color: warn),
                  ),
                  children: [
                    for (final s in r.skipped.take(40))
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          l.invfRowReason(s.row, s.reason),
                          style: TextStyle(color: warn),
                        ),
                        subtitle: Text(
                          s.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (r.skipped.length > 40)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          l.invfAndMore(r.skipped.length - 40),
                          style: tt.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ] else if (r.trades.isNotEmpty)
            row(Icons.check_circle_outline, ok, l.invfAllRowsOk),
        ],
      ],
    );
  }
}

String _fieldLabel(AppLocalizations l, String f) => switch (f) {
  'date' => l.invfFieldDate,
  'type' => l.invfFieldType,
  'name' => l.invfFieldName,
  'category' => l.invfFieldCategory,
  'comment' => l.invfFieldComment,
  'symbol' => l.invfFieldSymbol,
  'isin' => l.invfFieldIsin,
  'quantity' => l.invfFieldQuantity,
  'price' => l.invfFieldPrice,
  'total' => l.invfFieldTotal,
  'fee' => l.invfFieldFee,
  'currency' => l.invfFieldCurrency,
  'rate' => l.invfFieldRate,
  _ => f,
};

String _opTypeLabel(AppLocalizations l, OpType t) => switch (t) {
  OpType.initial => l.invfOpInitial,
  OpType.buy => l.invfOpBuy,
  OpType.sell => l.invfOpSell,
  OpType.dividend => l.invfOpDividend,
  OpType.cash => l.invfOpCash,
};
