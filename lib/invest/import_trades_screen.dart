import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../analysis/widgets.dart';
import '../import/parsers.dart' show decodeText, parseCsv, parseXlsx, pdfText;
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
        error = 'Erro ao ler o ficheiro: $e';
        busy = false;
      });
    }
  }

  Future<void> _load(String name, Uint8List bytes) async {
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
        table = ext == 'xlsx' ? parseXlsx(bytes) : parseCsv(decodeText(bytes));
        mapping = guessTradeMapping(table!);
        mappingOpen = !mapping.usable;
        trades = mapping.usable ? tradesFromTable(table!, mapping) : [];
      }
      _afterParse();
      if (trades.isEmpty) {
        error = ext == 'pdf'
            ? 'Não encontrei compras ou vendas neste PDF. Pode ser digitalizado (imagem) ou ter um formato diferente. Se a corretora permitir, exporta em CSV ou Excel.'
            : 'Não encontrei compras ou vendas. Indica abaixo que coluna é cada coisa.';
      } else {
        error = null;
      }
    } catch (e) {
      trades = [];
      error = 'Erro ao ler o ficheiro: $e';
    }
    if (mounted) setState(() => busy = false);
  }

  void _reparse() {
    trades = table == null || !mapping.usable
        ? []
        : tradesFromTable(table!, mapping);
    excluded.clear();
    _afterParse();
    setState(
      () => error = trades.isEmpty
          ? 'Não encontrei compras ou vendas com estas colunas.'
          : null,
    );
  }

  bool _inRange(ParsedTrade t) {
    final d = DateTime(t.date.year, t.date.month, t.date.day);
    return (from == null || !d.isBefore(DateTime(from!.year, from!.month, from!.day))) && (to == null || !d.isAfter(DateTime(to!.year, to!.month, to!.day)));
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
    try {
      final r = await s.prices.fxRate(ccy, baseCcy);
      if (r > 0 && mounted) setState(() => rateCtrls[ccy]?.text = _num4(1 / r));
    } on PriceException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não consegui obter o câmbio: ${e.message}')),
        );
    }
  }

  // ---- operações a gravar ----
  ({
    List<({String key, InvestOp op, ParsedTrade t, bool dup})> ops,
    int missingRate,
  })
  _build(AppState s) {
    final out = <({String key, InvestOp op, ParsedTrade t, bool dup})>[];
    var missing = 0;
    if (accountId == null) return (ops: out, missingRate: 0);
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
        missing++;
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
    return (ops: out, missingRate: missing);
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
          symbol: sym,
          provider: sym.isEmpty ? PriceProvider.manual : PriceProvider.yahoo,
          kind: _guessKind(name, sym),
          currency: _ccyOf(l.first),
        );
      }
    }
    final n = s.importTradeOps(
      newHoldings: newH,
      ops: [for (final e in toSave) (key: e.key, op: e.op)],
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$n operações importadas${newH.isEmpty ? '' : ' e ${newH.length} ${newH.length == 1 ? 'ativo criado' : 'ativos criados'}'}. Atualiza os preços na Carteira.',
        ),
      ),
    );
    Navigator.pop(context, true);
  }

  // ---- UI ----
  @override
  Widget build(BuildContext context) {
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
      appBar: AppBar(title: const Text('Importar compras e vendas')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
        children: [
          FormCard(
            children: [
              Text(
                'Formatos: PDF (com texto), CSV e Excel (.xlsx). O ficheiro é lido no telemóvel e nunca sai daqui. Reconhece compras, vendas e dividendos; o resto (depósitos, impostos…) é ignorado.',
                style: tt.bodyMedium,
              ),
              const FieldLabel('Plataforma'),
              DropdownButtonFormField<int>(
                key: ValueKey('acc-$accountId-${s.investAccounts.length}'),
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
                  const DropdownMenuItem(
                    value: -1,
                    child: Text('➕  Nova plataforma…'),
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
                  filename == null
                      ? 'Escolher ficheiro'
                      : 'Escolher outro ficheiro',
                ),
              ),
              if (filename != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Ficheiro: $filename'),
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
          ],

          if (trades.isNotEmpty) ...[
            const SizedBox(height: 14),
            DateRangeCard(
              min: trades.map((t) => t.date).reduce((a, b) => a.isBefore(b) ? a : b),
              max: trades.map((t) => t.date).reduce((a, b) => a.isAfter(b) ? a : b),
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
                Text('Moeda e câmbio', style: tt.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Linhas sem moeda indicada usam a moeda abaixo. Para moedas diferentes de $baseCcy indica o câmbio médio; podes afinar cada operação depois.',
                  style: tt.bodySmall,
                ),
                if (!trades.any((t) => t.currency.isNotEmpty)) ...[
                  const FieldLabel('Moeda das operações'),
                  DropdownButtonFormField<String>(
                    initialValue: defaultCcy,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.currency_exchange),
                    ),
                    items: [
                      for (final c in kCurrencies)
                        DropdownMenuItem(
                          value: c,
                          child: Text(c == baseCcy ? '$c · moeda de base' : c),
                        ),
                    ],
                    onChanged: (v) => setState(() {
                      defaultCcy = v ?? baseCcy;
                      _syncRateFields();
                    }),
                  ),
                ],
                for (final c in need) ...[
                  FieldLabel('Câmbio: 1 $baseSym = ? $c'),
                  TextField(
                    controller: rateCtrls[c],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: '1,0850',
                      prefixIcon: const Icon(Icons.currency_exchange),
                      suffixIcon: IconButton(
                        tooltip: 'Câmbio de mercado atual (internet)',
                        icon: const Icon(Icons.sync),
                        onPressed: () => _liveRate(s, c),
                      ),
                    ),
                  ),
                ],
                if (need.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Todas as operações estão em $baseCcy.',
                      style: tt.bodySmall,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),
            // ativos
            FormCard(
              children: [
                Text('Ativos encontrados', style: tt.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Liga cada um a um ativo teu, cria um novo ou ignora.',
                  style: tt.bodySmall,
                ),
                for (final e in g.entries) ...[
                  const SizedBox(height: 14),
                  Text(
                    '${_label(e.value)}  ·  ${e.value.length} ${e.value.length == 1 ? 'operação' : 'operações'}',
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
                      const DropdownMenuItem(
                        value: 0,
                        child: Text('➕  Criar ativo novo'),
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
                      const DropdownMenuItem(value: -1, child: Text('Ignorar')),
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
                Text('Operações', style: tt.titleMedium),
                const SizedBox(height: 4),
                Text(
                  [
                    if (nBuy > 0) '$nBuy ${nBuy == 1 ? 'compra' : 'compras'}',
                    if (nSell > 0) '$nSell ${nSell == 1 ? 'venda' : 'vendas'}',
                    if (nDiv > 0)
                      '$nDiv ${nDiv == 1 ? 'dividendo' : 'dividendos'}',
                    if (dups > 0) '$dups já existentes (ignoradas)',
                  ].join(' · '),
                  style: tt.bodySmall,
                ),
                if (missingRate.isNotEmpty || b.missingRate > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Callout(
                      icon: Icons.warning_amber_rounded,
                      color: Colors.orange.shade700,
                      title: 'Falta o câmbio',
                      body:
                          'Indica o câmbio de ${missingRate.isEmpty ? 'todas as moedas' : missingRate.join(', ')} para importar essas operações.',
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
                        '${e.op.type.label} · ${_label(groups[e.key]!)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${fmtDate(e.op.date)}${e.op.type == OpType.dividend ? '' : ' · ${fmtQty(e.op.quantity)} un. × ${fmtPrice(e.t.price).replaceAll(baseSym, '').trim()} ${_ccyOf(e.t)}'}${e.dup ? ' · já existe' : ''}',
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
                  Text(
                    'A mostrar as primeiras 300 de ${b.ops.length}.',
                    style: tt.bodySmall,
                  ),
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
                          ? 'Escolhe a plataforma'
                          : 'Importar ${active.length} ${active.length == 1 ? 'operação' : 'operações'}',
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _mappingCard(BuildContext context) {
    final t = table!;
    final headers = mapping.headerRow >= 0 && mapping.headerRow < t.length
        ? t[mapping.headerRow]
        : (t.isEmpty
              ? <String>[]
              : List.generate(t.first.length, (i) => 'Coluna ${i + 1}'));
    return FormCard(
      children: [
        InkWell(
          onTap: () => setState(() => mappingOpen = !mappingOpen),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Colunas do ficheiro',
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
              mapping.usable
                  ? 'Reconhecidas automaticamente. Toca para ajustar.'
                  : 'Indica que coluna é cada coisa.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (mappingOpen) ...[
          for (final (f, label) in TradeMapping.fields) ...[
            FieldLabel(label, optional: !{'date', 'quantity'}.contains(f)),
            DropdownButtonFormField<int?>(
              key: ValueKey('map-$f-${mapping.get_(f)}'),
              initialValue: mapping.get_(f),
              isExpanded: true,
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('— não existe —'),
                ),
                for (var i = 0; i < headers.length; i++)
                  DropdownMenuItem<int?>(
                    value: i,
                    child: Text(
                      headers[i].trim().isEmpty
                          ? 'Coluna ${i + 1}'
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
}
