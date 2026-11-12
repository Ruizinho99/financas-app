/// Análise da carteira: retorno (XIRR), risco (estimado com os pesos atuais), concentração e dividendos.
library;

import '../data/price_history.dart';
import '../invest.dart';
import '../metrics/financials.dart';
import '../metrics/market_risk.dart';

class PortfolioWeight {
  final Position position;
  final double weight; // 0..1 do valor investido
  const PortfolioWeight(this.position, this.weight);
}

class PortfolioReport {
  final int valueCents; // valor investido atual (posições abertas)
  final int costCents;
  final double? xirr; // anualizado, com as datas das operações
  final List<PortfolioWeight> weights; // do maior para o menor
  final List<Metric> concentration; // hhi, top_n_concentration
  final List<Metric> risk; // volatilidade, drawdown, beta, Sharpe... (vazio sem histórico)
  final Map<String, double> byCurrency; // moeda → peso
  final double? yieldOnCost; // dividendos recebidos / custo atual
  final int dividendsCents;
  final int riskCovered; // quantas posições entram no risco
  const PortfolioReport({
    required this.valueCents,
    required this.costCents,
    required this.xirr,
    required this.weights,
    required this.concentration,
    required this.risk,
    required this.byCurrency,
    required this.yieldOnCost,
    required this.dividendsCents,
    required this.riskCovered,
  });

  int get plCents => valueCents - costCents;
  double? get plPct => costCents > 0 ? plCents / costCents : null;
  Metric? riskMetric(String key) {
    for (final m in risk) {
      if (m.key == key) return m;
    }
    return null;
  }
}

/// Fluxos do XIRR: compras e posições iniciais saem (negativo), vendas e dividendos entram (positivo),
/// e o valor atual entra como se vendesses hoje. Operações de dinheiro ficam de fora.
List<({DateTime date, double amount})> xirrFlows(
  List<InvestOp> ops,
  int valueCents,
  DateTime now,
) {
  final out = <({DateTime date, double amount})>[];
  for (final o in ops) {
    switch (o.type) {
      case OpType.buy:
      case OpType.initial:
        out.add((date: o.date, amount: -o.amount / 100));
      case OpType.sell:
      case OpType.dividend:
        out.add((date: o.date, amount: o.amount / 100));
      case OpType.cash:
        break;
    }
  }
  if (valueCents > 0) out.add((date: now, amount: valueCents / 100));
  return out;
}

PortfolioReport buildPortfolioReport({
  required Portfolio portfolio,
  required List<InvestOp> ops,
  Map<String, PriceHistory> histories = const {},
  PriceHistory? benchmark,
  DateTime? now,
}) {
  final hoje = now ?? DateTime.now();
  final abertas = portfolio.positions;
  final valor = portfolio.investedValue;
  final pesos =
      [
        for (final p in abertas)
          PortfolioWeight(p, valor > 0 ? p.valueCents / valor : 0),
      ]..sort((a, b) => b.weight.compareTo(a.weight));

  final byCcy = <String, double>{};
  for (final w in pesos) {
    byCcy.update(
      w.position.holding.currency,
      (v) => v + w.weight,
      ifAbsent: () => w.weight,
    );
  }

  final fluxos = xirrFlows(ops, valor, hoje);
  final conc = portfolioMetrics(
    flows: fluxos,
    weights: [for (final w in pesos) w.weight],
  );

  // Risco: retornos diários ponderados pelos pesos atuais, nas datas comuns às posições com histórico.
  final cobertas = [
    for (final w in pesos)
      if ((histories[w.position.holding.symbol]?.points.length ?? 0) > 30) w,
  ];
  var risco = <Metric>[];
  if (cobertas.isNotEmpty) {
    final soma = cobertas.fold<double>(0, (a, w) => a + w.weight);
    var datas = histories[cobertas.first.position.holding.symbol]!.points
        .map((p) => p.date)
        .toSet();
    for (final w in cobertas.skip(1)) {
      datas = datas.intersection(
        histories[w.position.holding.symbol]!.points.map((p) => p.date).toSet(),
      );
    }
    final ordenadas = datas.toList()..sort();
    if (soma > 0 && ordenadas.length > 30) {
      final precos = <List<double>>[
        for (final w in cobertas)
          () {
            final m = {
              for (final p in histories[w.position.holding.symbol]!.points)
                p.date: p.close,
            };
            return [for (final d in ordenadas) m[d]!];
          }(),
      ];
      final fechos = <double>[100];
      for (var i = 1; i < ordenadas.length; i++) {
        var r = 0.0;
        for (var k = 0; k < cobertas.length; k++) {
          final a = precos[k][i - 1];
          if (a == 0) continue;
          r += (cobertas[k].weight / soma) * (precos[k][i] / a - 1);
        }
        fechos.add(fechos.last * (1 + r));
      }
      risco = marketRiskMetrics(
        ordenadas,
        fechos,
        benchDates: benchmark == null
            ? null
            : [for (final p in benchmark.points) p.date],
        benchCloses: benchmark == null
            ? null
            : [for (final p in benchmark.points) p.close],
      );
    }
  }

  final divs = portfolio.dividends;
  final custo = portfolio.costBasis;
  return PortfolioReport(
    valueCents: valor,
    costCents: custo,
    xirr: conc.firstWhere((m) => m.key == 'xirr').value,
    weights: pesos,
    concentration: conc.where((m) => m.key != 'xirr').toList(),
    risk: risco,
    byCurrency: byCcy,
    yieldOnCost: custo > 0 ? divs / custo : null,
    dividendsCents: divs,
    riskCovered: cobertas.length,
  );
}
