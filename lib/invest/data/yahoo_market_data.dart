/// Cliente do Yahoo Finance (sem chave) para a análise fundamental: histórico de preços, demonstrações
/// financeiras e dados de mercado/perfil, já convertidos para o contrato `metrics/financials.dart`.
///
/// Regras:
///  - `financials()` nunca lança: sem dados ou com erro devolve listas vazias.
///  - `snapshot()` e `history()` só lançam [PriceException] se o pedido do preço (chart) falhar; o perfil
///    (quoteSummary, com cookie e crumb) é melhor esforço: se falhar, esses campos ficam nulos/vazios.
///  - Todos os valores monetários do snapshot saem na moeda de reporte (ver [MarketSnapshot]).
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../metrics/financials.dart';
import '../price_service.dart';
import 'market_cache.dart';
import 'price_history.dart';

/// Um campo do contrato, os tipos do Yahoo de onde vem (por ordem de preferência) e se é um fluxo
/// (soma-se em 12 meses) ou um valor de balanço (vale no fecho do período).
class _Field {
  final String name;
  final List<String> types;
  final bool flow;
  const _Field(this.name, this.types, this.flow);
}

const _fields = <_Field>[
  // demonstração de resultados (fluxos)
  _Field('revenue', ['TotalRevenue'], true),
  _Field('costOfRevenue', ['CostOfRevenue'], true),
  _Field('grossProfit', ['GrossProfit'], true),
  _Field('operatingIncome', ['OperatingIncome'], true),
  _Field('ebit', ['EBIT'], true),
  _Field('ebitda', ['EBITDA'], true),
  _Field('netIncome', ['NetIncome'], true),
  _Field('pretaxIncome', ['PretaxIncome'], true),
  _Field('taxProvision', ['TaxProvision'], true),
  _Field('interestExpense', ['InterestExpense'], true),
  _Field('depreciationAmortization', [
    'DepreciationAndAmortization',
    'ReconciledDepreciation',
  ], true),
  _Field('stockBasedComp', ['StockBasedCompensation'], true),
  _Field('sellingGeneralAdmin', ['SellingGeneralAndAdministration'], true),
  _Field('researchDevelopment', ['ResearchAndDevelopment'], true),
  _Field('netInterestIncome', ['NetInterestIncome'], true),
  _Field('specialItems', ['SpecialIncomeCharges'], true),
  _Field('impairment', ['ImpairmentOfCapitalAssets'], true),
  _Field('dilutedEps', ['DilutedEPS'], true),
  // média de ações: não se soma; o TTM usa o valor do `trailing` ou do último trimestre
  _Field('dilutedShares', ['DilutedAverageShares'], false),
  // balanço (no fecho)
  _Field('totalAssets', ['TotalAssets'], false),
  _Field('currentAssets', ['CurrentAssets'], false),
  _Field('currentLiabilities', ['CurrentLiabilities'], false),
  _Field('cash', ['CashAndCashEquivalents'], false),
  _Field('cashAndShortTermInvestments', [
    'CashCashEquivalentsAndShortTermInvestments',
  ], false),
  _Field('receivables', ['AccountsReceivable'], false),
  _Field('inventory', ['Inventory'], false),
  _Field('payables', ['AccountsPayable'], false),
  _Field('totalDebt', ['TotalDebt'], false),
  _Field('longTermDebt', ['LongTermDebt'], false),
  _Field('currentDebt', ['CurrentDebt'], false),
  _Field('equity', ['StockholdersEquity'], false),
  _Field('tangibleBookValue', ['TangibleBookValue'], false),
  _Field('retainedEarnings', ['RetainedEarnings'], false),
  _Field('totalLiabilities', ['TotalLiabilitiesNetMinorityInterest'], false),
  _Field('goodwill', ['Goodwill'], false),
  _Field('minorityInterest', ['MinorityInterest'], false),
  _Field('sharesOutstanding', ['OrdinarySharesNumber'], false),
  _Field('netPpe', ['NetPPE'], false),
  _Field('investedCapital', ['InvestedCapital'], false),
  _Field('preferredStock', ['PreferredStockEquity'], false),
  _Field('leaseLiabilities', ['CapitalLeaseObligations'], false),
  // fluxos de caixa
  _Field('operatingCashFlow', ['OperatingCashFlow'], true),
  _Field('capex', ['CapitalExpenditure'], true),
  _Field('freeCashFlow', ['FreeCashFlow'], true),
  _Field('dividendsPaid', ['CashDividendsPaid'], true),
  _Field('buybacks', ['RepurchaseOfCapitalStock'], true),
  _Field('incomeTaxPaid', ['IncomeTaxPaidSupplementalData'], true),
  _Field('interestPaid', ['InterestPaidSupplementalData'], true),
  _Field('acquisitions', ['PurchaseOfBusiness'], true),
  _Field('stockIssuance', ['IssuanceOfCapitalStock'], true),
  _Field('changeInWorkingCapital', ['ChangeInWorkingCapital'], true),
];

/// Tipos do Yahoo que provam que a data é mesmo um período (evita "períodos fantasma" de um só campo antigo).
const _coreTypes = {
  'TotalRevenue',
  'NetIncome',
  'TotalAssets',
  'OperatingCashFlow',
  'StockholdersEquity',
  'FreeCashFlow',
};

/// Séries de um pedido fundamentals-timeseries: tipo (sem prefixo) -> data (AAAA-MM-DD) -> valor.
class _Series {
  final Map<String, Map<String, double>> byType = {};
  String? currency;
  bool get isEmpty => byType.isEmpty;

  double? at(_Field f, String date) {
    for (final t in f.types) {
      final v = byType[t]?[date];
      if (v != null) return v;
    }
    return null;
  }

  /// Datas que têm pelo menos um tipo "central", por ordem cronológica.
  List<String> get periodDates {
    final s = <String>{};
    for (final t in _coreTypes) {
      final m = byType[t];
      if (m != null) s.addAll(m.keys);
    }
    return s.toList()..sort();
  }
}

class YahooMarketData {
  YahooMarketData({
    http.Client? client,
    DateTime Function()? now,
    PriceService? prices,
    MarketCache? cache,
  }) : _client = client ?? http.Client(),
       _now = now ?? DateTime.now,
       cache = cache ?? MarketCache.none() {
    _prices = prices ?? PriceService(client: _client);
  }

  final http.Client _client;
  final DateTime Function() _now;
  late final PriceService _prices;

  /// Cache das respostas JSON (preços 15 min; fundamentais e perfil 24 h).
  final MarketCache cache;

  static const _ua = 'Mozilla/5.0';
  static const _timeout = Duration(seconds: 15);

  // sessão do quoteSummary: cookie e crumb só em memória
  String? _cookie;
  String? _crumb;
  DateTime? _authFailedAt;
  static const _authRetry = Duration(minutes: 10);

  void close() {
    _client.close();
  }

  // ---------------------------------------------------------------- pedidos

  Future<Object?> _fetchJson(
    Uri uri, {
    Map<String, String> headers = const {},
  }) async {
    final http.Response r;
    try {
      r = await _client
          .get(uri, headers: {'User-Agent': _ua, ...headers})
          .timeout(_timeout);
    } on TimeoutException {
      throw const PriceException('O serviço demorou demasiado a responder.');
    } catch (_) {
      throw const PriceException('Sem ligação à internet.');
    }
    if (r.statusCode == 429) {
      throw const PriceException(
        'Limite do serviço atingido. Tenta daqui a um minuto.',
      );
    }
    if (r.statusCode == 404) {
      throw const PriceException('Símbolo não encontrado.');
    }
    if (r.statusCode != 200) {
      throw PriceException('Erro do serviço (${r.statusCode}).');
    }
    try {
      return jsonDecode(utf8.decode(r.bodyBytes));
    } catch (_) {
      throw const PriceException('Resposta inesperada do serviço.');
    }
  }

  Uri _chartUri(String symbol, String range) => Uri(
    scheme: 'https',
    host: 'query1.finance.yahoo.com',
    // pathSegments codifica uma só vez (símbolos como "^GSPC" ou "EURUSD=X")
    pathSegments: ['v8', 'finance', 'chart', symbol],
    queryParameters: {'range': range, 'interval': '1d', 'events': 'div,split'},
  );

  Future<Map> _chartResult(String symbol, String range) async {
    final j = await cache.cachedOr(
      'chart:$symbol:$range',
      MarketCache.priceTtl,
      () => _fetchJson(_chartUri(symbol, range)),
    );
    final chart = j is Map ? j['chart'] : null;
    final result = chart is Map ? chart['result'] : null;
    if (result is! List || result.isEmpty || result.first is! Map) {
      throw const PriceException('Símbolo não encontrado.');
    }
    return result.first as Map;
  }

  // ------------------------------------------------------------- utilitários

  static double? _num(Object? v) {
    if (v is num && v.isFinite) return v.toDouble();
    if (v is Map) return _num(v['raw']);
    return null;
  }

  /// Moeda de cotação normalizada e divisor da unidade menor (GBp/GBX = pence).
  static (String, double) _ccy(Object? raw) {
    final c = (raw is String && raw.isNotEmpty) ? raw : 'USD';
    switch (c) {
      case 'GBp':
      case 'GBX':
        return ('GBP', 100);
      case 'ZAc':
        return ('ZAR', 100);
      case 'ILA':
        return ('ILS', 100);
      default:
        return (c.toUpperCase(), 1);
    }
  }

  /// Dia (UTC, sem hora) da sessão a partir do carimbo do Yahoo e do desvio horário da bolsa.
  static DateTime _day(num seconds, int gmtOffset) {
    final d = DateTime.fromMillisecondsSinceEpoch(
      (seconds.toInt() + gmtOffset) * 1000,
      isUtc: true,
    );
    return DateTime.utc(d.year, d.month, d.day);
  }

  static QuoteType _quoteType(Object? t) =>
      switch ((t ?? '').toString().toUpperCase()) {
        'EQUITY' => QuoteType.equity,
        'ETF' => QuoteType.etf,
        'MUTUALFUND' => QuoteType.fund,
        'CRYPTOCURRENCY' => QuoteType.crypto,
        'INDEX' => QuoteType.marketIndex,
        _ => QuoteType.other,
      };

  // --------------------------------------------------------------- histórico

  /// Histórico diário (fecho e fecho ajustado), dividendos e splits. Pontos sem fecho são ignorados.
  /// Lança [PriceException] se o Yahoo não responder ou não conhecer o símbolo.
  Future<PriceHistory> history(String symbol, {String range = '5y'}) async {
    final r = await _chartResult(symbol, range);
    final meta = r['meta'] is Map ? r['meta'] as Map : const {};
    final (ccy, div) = _ccy(meta['currency']);
    final off = (_num(meta['gmtoffset']) ?? 0).toInt();

    final ts = r['timestamp'] is List ? r['timestamp'] as List : const [];
    final ind = r['indicators'] is Map ? r['indicators'] as Map : const {};
    List list(Object? o) => o is List ? o : const [];
    final quote = list(ind['quote']).isNotEmpty && ind['quote'][0] is Map
        ? ind['quote'][0] as Map
        : const {};
    final closes = list(quote['close']);
    final adj = list(ind['adjclose']).isNotEmpty && ind['adjclose'][0] is Map
        ? list((ind['adjclose'][0] as Map)['adjclose'])
        : const [];

    final points = <PricePoint>[];
    for (var i = 0; i < ts.length && i < closes.length; i++) {
      final t = ts[i];
      final c = _num(closes[i]);
      if (t is! num || c == null) continue; // sem fecho: ignora
      final a = i < adj.length ? _num(adj[i]) : null;
      points.add(PricePoint(_day(t, off), c / div, a == null ? null : a / div));
    }
    points.sort((a, b) => a.date.compareTo(b.date));

    final events = r['events'] is Map ? r['events'] as Map : const {};
    final dividends = <DateTime, double>{};
    final dv = events['dividends'];
    if (dv is Map) {
      for (final e in dv.values) {
        if (e is! Map) continue;
        final amount = _num(e['amount']);
        final d = _num(e['date']);
        if (amount == null || d == null) continue;
        dividends[_day(d, off)] = amount / div;
      }
    }
    final splits = <DateTime, double>{};
    final sp = events['splits'];
    if (sp is Map) {
      for (final e in sp.values) {
        if (e is! Map) continue;
        final n = _num(e['numerator']);
        final den = _num(e['denominator']);
        final d = _num(e['date']);
        if (n == null || den == null || den == 0 || d == null) continue;
        splits[_day(d, off)] = n / den;
      }
    }
    return PriceHistory(
      symbol: symbol,
      currency: ccy,
      points: points,
      dividends: Map.fromEntries(
        dividends.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      ),
      splits: Map.fromEntries(
        splits.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      ),
    );
  }

  // ----------------------------------------------------------- demonstrações

  Future<_Series> _series(String symbol, String prefix) async {
    final s = _Series();
    try {
      final types = <String>[
        for (final f in _fields)
          if (prefix != 'trailing' || f.flow)
            for (final t in f.types) '$prefix$t',
      ];
      final period2 = _now().millisecondsSinceEpoch ~/ 1000 + 86400;
      final uri = Uri(
        scheme: 'https',
        host: 'query1.finance.yahoo.com',
        pathSegments: [
          'ws',
          'fundamentals-timeseries',
          'v1',
          'finance',
          'timeseries',
          symbol,
        ],
        // query à mão: o Uri codificaria as vírgulas da lista de tipos
        query: 'type=${types.join(',')}&period1=1400000000&period2=$period2',
      );
      final j = await cache.cachedOr(
        'ts:$symbol:$prefix',
        MarketCache.fundamentalsTtl,
        () => _fetchJson(uri),
      );
      final ts = j is Map ? j['timeseries'] : null;
      final result = ts is Map ? ts['result'] : null;
      if (result is! List) return s;
      for (final item in result) {
        if (item is! Map) continue;
        final meta = item['meta'];
        final tl = meta is Map ? meta['type'] : null;
        if (tl is! List || tl.isEmpty || tl.first is! String) continue;
        final full = tl.first as String;
        if (!full.startsWith(prefix)) continue;
        final type = full.substring(prefix.length);
        final entries = item[full];
        if (entries is! List) continue;
        for (final e in entries) {
          if (e is! Map) continue; // o Yahoo pode devolver entradas nulas
          final date = e['asOfDate'];
          final v = _num(e['reportedValue']);
          if (date is! String || v == null) continue;
          (s.byType[type] ??= {})[date] = v;
          final c = e['currencyCode'];
          if (s.currency == null && c is String && c.isNotEmpty) s.currency = c;
        }
      }
    } catch (_) {
      // sem dados ou erro de rede: série vazia
    }
    return s;
  }

  /// Demonstrações financeiras (anuais, trimestrais e TTM). Nunca lança: sem dados, listas vazias.
  Future<Financials> financials(String symbol) async {
    final res = await Future.wait([
      _series(symbol, 'annual'),
      _series(symbol, 'quarterly'),
      _series(symbol, 'trailing'),
    ]);
    final annual = res[0], quarterly = res[1], trailing = res[2];
    final currency =
        annual.currency ?? quarterly.currency ?? trailing.currency ?? 'USD';

    FinPeriod build(
      DateTime end,
      bool isAnnual,
      double? Function(_Field f) get,
    ) {
      final m = <String, double?>{for (final f in _fields) f.name: get(f)};
      return FinPeriod(
        end: end,
        annual: isAnnual,
        revenue: m['revenue'],
        costOfRevenue: m['costOfRevenue'],
        grossProfit: m['grossProfit'],
        operatingIncome: m['operatingIncome'],
        ebit: m['ebit'],
        ebitda: m['ebitda'],
        netIncome: m['netIncome'],
        pretaxIncome: m['pretaxIncome'],
        taxProvision: m['taxProvision'],
        interestExpense: m['interestExpense'],
        depreciationAmortization: m['depreciationAmortization'],
        stockBasedComp: m['stockBasedComp'],
        sellingGeneralAdmin: m['sellingGeneralAdmin'],
        researchDevelopment: m['researchDevelopment'],
        netInterestIncome: m['netInterestIncome'],
        specialItems: m['specialItems'],
        impairment: m['impairment'],
        dilutedEps: m['dilutedEps'],
        dilutedShares: m['dilutedShares'],
        totalAssets: m['totalAssets'],
        currentAssets: m['currentAssets'],
        currentLiabilities: m['currentLiabilities'],
        cash: m['cash'],
        cashAndShortTermInvestments: m['cashAndShortTermInvestments'],
        receivables: m['receivables'],
        inventory: m['inventory'],
        payables: m['payables'],
        totalDebt: m['totalDebt'],
        longTermDebt: m['longTermDebt'],
        currentDebt: m['currentDebt'],
        equity: m['equity'],
        tangibleBookValue: m['tangibleBookValue'],
        retainedEarnings: m['retainedEarnings'],
        totalLiabilities: m['totalLiabilities'],
        goodwill: m['goodwill'],
        minorityInterest: m['minorityInterest'],
        sharesOutstanding: m['sharesOutstanding'],
        netPpe: m['netPpe'],
        investedCapital: m['investedCapital'],
        preferredStock: m['preferredStock'],
        leaseLiabilities: m['leaseLiabilities'],
        operatingCashFlow: m['operatingCashFlow'],
        capex: m['capex'],
        freeCashFlow: m['freeCashFlow'],
        dividendsPaid: m['dividendsPaid'],
        buybacks: m['buybacks'],
        incomeTaxPaid: m['incomeTaxPaid'],
        interestPaid: m['interestPaid'],
        acquisitions: m['acquisitions'],
        stockIssuance: m['stockIssuance'],
        changeInWorkingCapital: m['changeInWorkingCapital'],
      );
    }

    final aDates = annual.periodDates;
    final qDates = quarterly.periodDates;
    final annualPeriods = [
      for (final d in aDates)
        build(DateTime.parse(d), true, (f) => annual.at(f, d)),
    ];
    final quarterlyPeriods = [
      for (final d in qDates)
        build(DateTime.parse(d), false, (f) => quarterly.at(f, d)),
    ];

    // TTM: fluxos = `trailing*` da fonte se estiver em dia com o último trimestre; senão a soma dos últimos
    // 4 trimestres. Balanço = último trimestre (sem trimestres, o último exercício anual).
    FinPeriod? ttm;
    final last4 = qDates.length >= 4
        ? qDates.sublist(qDates.length - 4)
        : const <String>[];
    // data mais recente do `trailing` de cada campo (alguns tipos, como as ações, trazem uma série)
    String? tLatest(_Field f) {
      String? best;
      for (final t in f.types) {
        final m = trailing.byType[t];
        if (m == null || m.isEmpty) continue;
        final d = (m.keys.toList()..sort()).last;
        if (best == null || d.compareTo(best) > 0) best = d;
      }
      return best;
    }

    final allTrailing = <String>{
      for (final m in trailing.byType.values) ...m.keys,
    }.toList()..sort();
    if (qDates.isNotEmpty || allTrailing.isNotEmpty) {
      final balDate = qDates.isNotEmpty ? qDates.last : null;
      final end = DateTime.parse(balDate ?? allTrailing.last);
      ttm = build(end, true, (f) {
        if (f.flow || f.name == 'dilutedShares') {
          final td = tLatest(f);
          // o `trailing` só vale se não for anterior ao último trimestre
          if (td != null && (balDate == null || td.compareTo(balDate) >= 0)) {
            return trailing.at(f, td);
          }
          if (f.name == 'dilutedShares') {
            return balDate == null ? null : quarterly.at(f, balDate);
          }
          if (last4.isEmpty) return null;
          var sum = 0.0;
          for (final d in last4) {
            final v = quarterly.at(f, d);
            if (v == null) return null; // um trimestre em falta: não se inventa
            sum += v;
          }
          return sum;
        }
        // balanço
        if (balDate != null) return quarterly.at(f, balDate);
        return aDates.isEmpty ? null : annual.at(f, aDates.last);
      });
    }

    return Financials(
      symbol: symbol,
      currency: currency,
      annual: annualPeriods,
      quarterly: quarterlyPeriods,
      ttm: ttm,
    );
  }

  // ------------------------------------------------------ cookie e crumb

  /// Obtém cookie e crumb (à mão: o `http` do Dart não tem cookie jar). Devolve falso em qualquer falha
  /// (página de consentimento da UE, 429, resposta estranha...): a análise segue sem o perfil.
  Future<bool> _login() async {
    try {
      final r = await _client
          .get(
            Uri.https('fc.yahoo.com', '/'),
            headers: const {'User-Agent': _ua},
          )
          .timeout(_timeout);
      if (r.isRedirect || (r.statusCode >= 300 && r.statusCode < 400)) {
        return false;
      }
      final host = r.request?.url.host ?? 'fc.yahoo.com';
      if (host.contains('consent') || !host.endsWith('yahoo.com')) {
        return false; // redirecionado para a página de consentimento
      }
      final raw = r.headers['set-cookie'];
      if (raw == null || raw.isEmpty) return false;
      // vários Set-Cookie chegam juntos, separados por vírgula (as datas Expires também têm vírgulas)
      final cookies = raw
          .split(RegExp(r',(?=\s*[^;,=\s]+=)'))
          .map((c) => c.split(';').first.trim())
          .where((c) => c.contains('='))
          .toList();
      if (cookies.isEmpty) return false;
      final cookie = cookies.join('; ');

      final c = await _client
          .get(
            Uri.https('query1.finance.yahoo.com', '/v1/test/getcrumb'),
            headers: {'User-Agent': _ua, 'Cookie': cookie},
          )
          .timeout(_timeout);
      if (c.statusCode != 200) return false;
      final crumb = c.body.trim();
      if (crumb.isEmpty ||
          crumb.length > 60 ||
          crumb.contains(RegExp(r'[\s<>{}]')) ||
          crumb.contains('Too Many')) {
        return false;
      }
      _cookie = cookie;
      _crumb = crumb;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Garante uma sessão (cookie+crumb). Depois de uma falha só volta a tentar passados 10 minutos.
  Future<bool> _ensureSession({bool force = false}) async {
    if (!force && _crumb != null && _cookie != null) return true;
    final failed = _authFailedAt;
    if (!force && failed != null && _now().difference(failed) < _authRetry) {
      return false;
    }
    _cookie = null;
    _crumb = null;
    final ok = await _login();
    _authFailedAt = ok ? null : _now();
    return ok;
  }

  static const _modules =
      'assetProfile,summaryDetail,defaultKeyStatistics,majorHoldersBreakdown,price';

  /// quoteSummary (melhor esforço): o resultado ou `null`. Nunca lança.
  Future<Map?> _quoteSummary(String symbol) async {
    final key = 'qs:$symbol';
    final cached = cache.get(key, MarketCache.profileTtl);
    if (cached is Map) return cached;
    try {
      for (var attempt = 0; attempt < 2; attempt++) {
        if (!await _ensureSession(force: attempt == 1)) return null;
        final uri = Uri(
          scheme: 'https',
          host: 'query2.finance.yahoo.com',
          pathSegments: ['v10', 'finance', 'quoteSummary', symbol],
          query: 'modules=$_modules&crumb=${Uri.encodeQueryComponent(_crumb!)}',
        );
        final r = await _client
            .get(uri, headers: {'User-Agent': _ua, 'Cookie': _cookie!})
            .timeout(_timeout);
        if (r.statusCode == 401 || r.body.contains('Invalid Crumb')) {
          continue; // crumb caducado: renova uma vez
        }
        if (r.statusCode != 200) return null;
        final j = jsonDecode(utf8.decode(r.bodyBytes));
        final qs = j is Map ? j['quoteSummary'] : null;
        final res = qs is Map ? qs['result'] : null;
        if (res is List && res.isNotEmpty && res.first is Map) {
          cache.put(key, res.first);
          return res.first as Map;
        }
        return null;
      }
    } catch (_) {}
    return null;
  }

  // ---------------------------------------------------------------- snapshot

  /// Dados de mercado agora, na moeda de reporte ([reportingCurrency]; se não se souber, a de cotação).
  /// Preço, market cap, EV, dividendo por ação e 52 semanas são convertidos com o câmbio atual.
  /// Lança [PriceException] se o preço não puder ser obtido, ou se faltar o câmbio quando é preciso convertê-lo.
  Future<MarketSnapshot> snapshot(
    String symbol, {
    String? reportingCurrency,
  }) async {
    final r = await _chartResult(symbol, '1y');
    final meta = r['meta'] is Map ? r['meta'] as Map : const {};
    final (quoteCcy, div) = _ccy(meta['currency']);
    final off = (_num(meta['gmtoffset']) ?? 0).toInt();

    var type = _quoteType(meta['instrumentType']);
    // índices e cripto não têm perfil de empresa
    final qs = (type == QuoteType.marketIndex || type == QuoteType.crypto)
        ? null
        : await _quoteSummary(symbol);
    Map? sect(String k) => qs != null && qs[k] is Map ? qs[k] as Map : null;
    final profile = sect('assetProfile');
    final detail = sect('summaryDetail');
    final stats = sect('defaultKeyStatistics');
    final holders = sect('majorHoldersBreakdown');
    final priceMod = sect('price');
    if (meta['instrumentType'] == null && priceMod != null) {
      type = _quoteType(priceMod['quoteType']);
    }

    // câmbio: reporte por 1 de cotação
    final reporting = reportingCurrency == null || reportingCurrency.isEmpty
        ? quoteCcy
        : _ccy(reportingCurrency).$1;
    final fx = reporting == quoteCcy
        ? 1.0
        : await _prices.fxRate(quoteCcy, reporting);

    double? money(double? v) => v == null ? null : v / div * fx;

    final price = money(_num(meta['regularMarketPrice']));
    final high = money(
      _num(meta['fiftyTwoWeekHigh']) ?? _num(detail?['fiftyTwoWeekHigh']),
    );
    final low = money(
      _num(meta['fiftyTwoWeekLow']) ?? _num(detail?['fiftyTwoWeekLow']),
    );

    final shares =
        _num(stats?['sharesOutstanding']) ??
        _num(stats?['impliedSharesOutstanding']);
    // market cap = preço × ações (evita a ambiguidade da moeda do market cap do Yahoo em cotações cruzadas)
    final marketCap = (price != null && shares != null)
        ? price * shares
        : money(_num(priceMod?['marketCap']) ?? _num(detail?['marketCap']));
    final ev = money(_num(stats?['enterpriseValue']));

    // dividendo por ação dos últimos 12 meses, pelos eventos do gráfico (senão pelo resumo)
    var dps = 0.0;
    final divs = r['events'] is Map ? (r['events'] as Map)['dividends'] : null;
    if (divs is Map) {
      final limit = _now().subtract(const Duration(days: 365));
      for (final e in divs.values) {
        if (e is! Map) continue;
        final a = _num(e['amount']);
        final d = _num(e['date']);
        if (a == null || d == null) continue;
        if (_day(d, off).isAfter(limit)) dps += a;
      }
    }
    double? dividendPerShare = money(dps);
    if (dps == 0) {
      final rate =
          _num(detail?['trailingAnnualDividendRate']) ??
          _num(detail?['dividendRate']);
      if (rate != null && rate > 0) dividendPerShare = money(rate);
    }

    // volume médio: do resumo, senão a média das últimas ~63 sessões do gráfico
    var avgVol =
        _num(detail?['averageVolume']) ??
        _num(detail?['averageDailyVolume10Day']);
    if (avgVol == null) {
      final ind = r['indicators'] is Map ? r['indicators'] as Map : const {};
      final q = ind['quote'];
      final vols = q is List && q.isNotEmpty && q[0] is Map
          ? (q[0] as Map)['volume']
          : null;
      if (vols is List) {
        final v = vols
            .map(_num)
            .whereType<double>()
            .toList()
            .reversed
            .take(63)
            .toList();
        if (v.isNotEmpty) avgVol = v.reduce((a, b) => a + b) / v.length;
      }
    }

    final name =
        (meta['longName'] ??
                meta['shortName'] ??
                priceMod?['longName'] ??
                priceMod?['shortName'] ??
                '')
            .toString()
            .trim();

    return MarketSnapshot(
      symbol: symbol,
      name: name,
      currency: reporting,
      quoteCurrency: quoteCcy,
      fxApplied: fx,
      quoteType: type,
      price: price,
      marketCap: marketCap,
      sharesOutstanding: shares,
      enterpriseValue: ev,
      beta: _num(detail?['beta']) ?? _num(stats?['beta']),
      fiftyTwoWeekHigh: high,
      fiftyTwoWeekLow: low,
      averageVolume: avgVol,
      dividendPerShare: dividendPerShare,
      shortPercentOfFloat: _num(stats?['shortPercentOfFloat']),
      insidersPercentHeld: _num(holders?['insidersPercentHeld']),
      sector: (profile?['sector'] ?? '').toString(),
      industry: (profile?['industry'] ?? '').toString(),
    );
  }
}
