import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../util/format.dart';
import '../data/market_cache.dart';
import '../data/yahoo_market_data.dart';
import '../metrics/dcf.dart';
import '../metrics/metric_catalog.dart';
import '../metrics/metric_info.dart';
import '../invest.dart';
import '../price_service.dart';
import 'asset_analysis.dart';
import 'metric_format.dart';
import 'metric_sheet.dart';

/// "Analisar um ativo": o utilizador escreve um ticker (ou nome) e vê as métricas fundamentais e de risco.
class AnalysisScreen extends StatefulWidget {
  /// Símbolo para abrir já analisado (ex.: a partir de uma posição).
  final String? initialSymbol;
  const AnalysisScreen({super.key, this.initialSymbol});
  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

const _sectionTitles = <String, (String, String)>{
  'valuation': ('Avaliação', 'Valuation'),
  'profitability': ('Margens', 'Margins'),
  'growth': ('Crescimento', 'Growth'),
  'returns': ('Retorno', 'Returns'),
  'efficiency': ('Eficiência', 'Efficiency'),
  'liquidity': ('Liquidez', 'Liquidity'),
  'solvency': ('Dívida', 'Debt'),
  'cashflow': ('Caixa', 'Cash flow'),
  'pershare': ('Por ação', 'Per share'),
  'dividends': ('Dividendos', 'Dividends'),
  'scores': ('Pontuações de saúde', 'Health scores'),
  'dcf': ('DCF (valor intrínseco)', 'DCF (intrinsic value)'),
  'quality': ('Qualidade do negócio', 'Business quality'),
  'sector': ('Específicas do setor', 'Sector specific'),
  'redflags': ('Alertas', 'Red flags'),
  'risk': ('Mercado e risco', 'Market and risk'),
};

class _AnalysisScreenState extends State<AnalysisScreen> {
  final _ctl = TextEditingController();
  YahooMarketData? _data;
  List<SymbolHit> _hits = [];
  AssetAnalysis? _a;
  bool _loading = false, _searching = false;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final s = widget.initialSymbol;
    if (s != null && s.isNotEmpty) {
      _ctl.text = s;
      WidgetsBinding.instance.addPostFrameCallback((_) => _analyze(s));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctl.dispose();
    _data?.close();
    super.dispose();
  }

  YahooMarketData _yahoo(AppState s) =>
      _data ??= YahooMarketData(cache: MarketCache.db(s.db));

  String get _lang => Localizations.localeOf(context).languageCode;
  String _t(String pt, String en) => _lang == 'en' ? en : pt;

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() => _hits = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      final s = context.read<AppState>();
      setState(() => _searching = true);
      try {
        final r = await s.prices.search(PriceProvider.yahoo, q.trim());
        if (!mounted) return;
        setState(() => _hits = r.take(8).toList());
      } on PriceException {
        if (mounted) setState(() => _hits = []);
      } finally {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  Future<void> _analyze(String symbol, {DcfAssumptions? assumptions}) async {
    final s = context.read<AppState>();
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _hits = [];
    });
    try {
      final a = await analyzeSymbol(
        _yahoo(s),
        symbol.trim().toUpperCase(),
        assumptions: assumptions ?? const DcfAssumptions(),
      );
      if (!mounted) return;
      setState(() => _a = a);
    } on PriceException catch (e) {
      if (!mounted) return;
      setState(() {
        _a = null;
        _error = e.message;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final a = _a;
    return Scaffold(
      appBar: AppBar(title: Text(_t('Analisar um ativo', 'Analyse an asset'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          TextField(
            controller: _ctl,
            textInputAction: TextInputAction.search,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: _t('Ticker ou nome (ex.: NVDA)', 'Ticker or name (e.g. NVDA)'),
              border: const OutlineInputBorder(),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () => _analyze(_ctl.text),
                    ),
            ),
            onChanged: _onChanged,
            onSubmitted: _analyze,
          ),
          for (final h in _hits)
            ListTile(
              dense: true,
              title: Text('${h.symbol} · ${h.name}'),
              subtitle: Text(
                [h.exchange, h.quoteType].where((x) => x.isNotEmpty).join(' · '),
              ),
              onTap: () {
                _ctl.text = h.symbol;
                _analyze(h.symbol);
              },
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _t(
                  'Não foi possível obter dados: $_error',
                  'Could not get data: $_error',
                ),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (a != null && !_loading) ..._report(a, s),
          if (a == null && !_loading && _error == null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _t(
                  'Escreve um ticker para ver margens, retorno, dívida, caixa, avaliação, DCF e risco. Toca no ⓘ de qualquer métrica para ver o que significa.',
                  'Type a ticker to see margins, returns, debt, cash flow, valuation, DCF and risk. Tap the ⓘ on any metric to see what it means.',
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _report(AssetAnalysis a, AppState s) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final snap = a.snapshot;
    final ccy = snap.currency;
    final change = a.metric('retorno_1d')?.value;
    return [
      const SizedBox(height: 12),
      Text(snap.name.isEmpty ? a.symbol : snap.name, style: tt.titleLarge),
      Text(
        [a.symbol, snap.sector, snap.industry]
            .where((x) => x.isNotEmpty)
            .join(' · '),
        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      ),
      const SizedBox(height: 8),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            snap.price == null
                ? '—'
                : fmtPriceIn(
                    snap.price! / (snap.fxApplied == 0 ? 1 : snap.fxApplied),
                    snap.quoteCurrency,
                  ),
            style: tt.headlineMedium,
          ),
          const SizedBox(width: 10),
          if (change != null)
            Text(
              '${change >= 0 ? '+' : ''}${fmtNum(change * 100, 2)} %',
              style: tt.titleMedium?.copyWith(
                color: change >= 0 ? Colors.green : cs.error,
              ),
            ),
        ],
      ),
      if (a.financialsFailed)
        _note(
          _t(
            'Não foi possível obter as demonstrações financeiras agora (falha de ligação). Tenta de novo mais tarde.',
            'Financial statements could not be fetched right now (connection failure). Try again later.',
          ),
        )
      else if (a.marketOnly)
        _note(
          _t(
            'Para este tipo de ativo (ETF, fundo, cripto ou sem demonstrações) só há métricas de mercado e risco.',
            'For this kind of asset (ETF, fund, crypto or no statements) only market and risk metrics apply.',
          ),
        ),
      const SizedBox(height: 12),
      if (!a.marketOnly) _scoreCards(a),
      for (final sec in a.sections)
        if (sec.hasData || !a.marketOnly) _sectionCard(a, sec),
      const SizedBox(height: 8),
      Text(
        _t(
          'Dados gratuitos do Yahoo Finance. Informação para estudo, não é aconselhamento financeiro.',
          'Free Yahoo Finance data. For study only, not financial advice.',
        ),
        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      ),
    ];
  }

  Widget _note(String text) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.tertiary)),
  );

  Widget _scoreCards(AssetAnalysis a) {
    final ccy = a.snapshot.currency;
    final items = <(String, String)>[
      ('piotroski_f', 'Piotroski'),
      ('altman_z', 'Altman Z'),
      ('beneish_m', 'Beneish M'),
      ('roic', 'ROIC'),
      ('pe_ttm', 'P/E'),
      ('fcf_yield', 'FCF yield'),
    ];
    return SizedBox(
      height: 84,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final (key, label) in items)
            if (a.metric(key) != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  onPressed: () => showMetricInfo(context, key),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatMetric(a.metric(key)!, ccy),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(label, style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _sectionCard(AssetAnalysis a, AnalysisSection sec) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final title = _sectionTitles[sec.id];
    final ccy = a.snapshot.currency;
    final rows = <Widget>[];
    for (final m in sec.metrics) {
      final info = metricInfoFor(m.key);
      final unavailable = info?.availability == MetricAvailability.unavailable;
      if (!m.available && !unavailable) continue; // sem dados: não mostrar linha vazia
      rows.add(
        InkWell(
          onTap: () => showMetricInfo(context, m.key),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              children: [
                Expanded(
                  child: Text(info?.name(_lang) ?? m.key, style: tt.bodyMedium),
                ),
                Text(
                  unavailable
                      ? _t('não disponível', 'not available')
                      : formatMetric(m, ccy),
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: unavailable ? cs.onSurfaceVariant : null,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.info_outline, size: 18, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      );
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title == null ? sec.id : _t(title.$1, title.$2),
              style: tt.titleMedium,
            ),
            const SizedBox(height: 4),
            if (sec.id == 'dcf') _dcfEditor(a),
            ...rows,
          ],
        ),
      ),
    );
  }

  /// Premissas do DCF editáveis: crescimento explícito e crescimento terminal.
  Widget _dcfEditor(AssetAnalysis a) {
    final g = a.metric('dcf_implied_growth');
    final cur = a.assumptions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t(
            'Crescimento explícito: ${cur.explicitGrowth == null ? 'automático' : '${fmtNum(cur.explicitGrowth! * 100, 1)} %'}',
            'Explicit growth: ${cur.explicitGrowth == null ? 'automatic' : '${fmtNum(cur.explicitGrowth! * 100, 1)} %'}',
          ),
        ),
        Slider(
          value: ((cur.explicitGrowth ?? 0.05) * 100).clamp(-5, 30).toDouble(),
          min: -5,
          max: 30,
          divisions: 70,
          label: '${fmtNum((cur.explicitGrowth ?? 0.05) * 100, 1)} %',
          onChanged: (v) =>
              setState(() => _a = a.withAssumptions(cur.copyWithGrowth(v / 100))),
        ),
        if (g == null) const SizedBox.shrink(),
      ],
    );
  }
}
