import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../util/format.dart';
import '../data/market_cache.dart';
import '../data/price_history.dart';
import '../data/yahoo_market_data.dart';
import '../invest.dart';
import '../metrics/metric_catalog.dart';
import 'analysis_screen.dart';
import 'metric_format.dart';
import 'metric_sheet.dart';
import 'portfolio_analysis.dart';

/// Análise da carteira inteira: retorno, risco, alocação, concentração e dividendos.
class PortfolioAnalysisScreen extends StatefulWidget {
  const PortfolioAnalysisScreen({super.key});
  @override
  State<PortfolioAnalysisScreen> createState() => _State();
}

class _State extends State<PortfolioAnalysisScreen> {
  PortfolioReport? _r;
  bool _loading = true;
  String? _note;

  String get _lang => Localizations.localeOf(context).languageCode;
  String _t(String pt, String en) => _lang == 'en' ? en : pt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final s = context.read<AppState>();
    final pf = s.portfolio;
    // primeiro o que não precisa de rede
    setState(() {
      _r = buildPortfolioReport(portfolio: pf, ops: s.investOps);
      _loading = true;
    });
    final data = YahooMarketData(cache: MarketCache.db(s.db));
    final hist = <String, PriceHistory>{};
    var falhas = 0;
    try {
      final alvo = pf.positions
          .where((p) => p.holding.provider == PriceProvider.yahoo)
          .toList();
      await Future.wait([
        for (final p in alvo)
          () async {
            try {
              hist[p.holding.symbol] = await data.history(
                p.holding.symbol,
                range: '2y',
              );
            } catch (_) {
              falhas++;
            }
          }(),
      ]);
      PriceHistory? bench;
      try {
        bench = await data.history('^GSPC', range: '2y');
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _r = buildPortfolioReport(
          portfolio: pf,
          ops: s.investOps,
          histories: hist,
          benchmark: bench,
        );
        _note = falhas > 0
            ? _t(
                'Não foi possível obter o histórico de $falhas posição(ões).',
                'Could not fetch the history of $falhas position(s).',
              )
            : null;
      });
    } finally {
      data.close();
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _row(String key, String value, {String? label}) {
    final info = metricInfoFor(key);
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => showMetricInfo(context, key),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Expanded(child: Text(label ?? info?.name(_lang) ?? key)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Icon(Icons.info_outline, size: 18, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, List<Widget> children) => Card(
    margin: const EdgeInsets.only(top: 12),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          ...children,
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final r = _r;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(_t('Análise da carteira', 'Portfolio analysis'))),
      body: r == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Text(fmtMoney(r.valueCents), style: tt.headlineMedium),
                Text(
                  '${r.plCents >= 0 ? '+' : ''}${fmtMoney(r.plCents)}'
                  '${r.plPct == null ? '' : '  (${fmtNum(r.plPct! * 100, 1)} %)'}',
                  style: tt.titleMedium?.copyWith(
                    color: r.plCents >= 0 ? Colors.green : cs.error,
                  ),
                ),
                if (_loading) const LinearProgressIndicator(),
                if (_note != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_note!, style: TextStyle(color: cs.tertiary)),
                  ),
                _card(_t('Retorno', 'Return'), [
                  _row(
                    'xirr',
                    r.xirr == null ? '—' : '${fmtNum(r.xirr! * 100, 1)} %',
                  ),
                  _row(
                    'yield_on_cost',
                    r.yieldOnCost == null
                        ? '—'
                        : '${fmtNum(r.yieldOnCost! * 100, 2)} %',
                  ),
                  _row(
                    'dividend_yield',
                    fmtMoney(r.dividendsCents),
                    label: _t('Dividendos recebidos', 'Dividends received'),
                  ),
                ]),
                _card(
                  _t('Risco (com os pesos atuais)', 'Risk (at current weights)'),
                  r.risk.isEmpty
                      ? [
                          Text(
                            _loading
                                ? _t('A obter o histórico…', 'Fetching history…')
                                : _t(
                                    'Sem histórico suficiente (precisa de posições com preço automático do Yahoo).',
                                    'Not enough history (needs positions priced automatically by Yahoo).',
                                  ),
                          ),
                        ]
                      : [
                          for (final k in const [
                            'retorno_1a',
                            'volatilidade_anualizada',
                            'drawdown_maximo',
                            'sharpe',
                            'sortino',
                            'beta_sp500',
                            'correlacao_sp500',
                          ])
                            if (r.riskMetric(k)?.available ?? false)
                              _row(k, formatMetric(r.riskMetric(k)!, baseCcy)),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              _t(
                                'Estimativa com os pesos de hoje sobre os últimos 2 anos, em ${r.riskCovered} posição(ões), sem efeito cambial.',
                                'Estimate using today\'s weights over the last 2 years, ${r.riskCovered} position(s), without FX effect.',
                              ),
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                ),
                _card(_t('Concentração', 'Concentration'), [
                  for (final m in r.concentration)
                    if (m.available) _row(m.key, formatMetric(m, baseCcy)),
                  for (final e in r.byCurrency.entries)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(child: Text('${_t('Moeda', 'Currency')} ${e.key}')),
                          Text('${fmtNum(e.value * 100, 1)} %'),
                        ],
                      ),
                    ),
                ]),
                _card(_t('Posições', 'Positions'), [
                  for (final w in r.weights)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(w.position.holding.name),
                      subtitle: LinearProgressIndicator(value: w.weight),
                      trailing: Text('${fmtNum(w.weight * 100, 1)} %'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AnalysisScreen(
                            initialSymbol:
                                w.position.holding.analysisSymbol.isNotEmpty
                                ? w.position.holding.analysisSymbol
                                : w.position.holding.symbol,
                          ),
                        ),
                      ),
                    ),
                ]),
              ],
            ),
    );
  }
}
