/// Helpers partilhados pelos módulos de fórmulas, para todos usarem a MESMA definição
/// (a revisão independente encontrou três cópias divergentes).
library;

import 'financials.dart';

/// Capitalização bolsista (spec 2.4): `marketCap`, ou preço × ações se faltar. Na moeda de reporte.
double? mcapOf(MarketSnapshot m) {
  if (m.marketCap != null) return m.marketCap;
  if (m.price != null && m.sharesOutstanding != null) {
    return m.price! * m.sharesOutstanding!;
  }
  return null;
}

/// EBITDA coerente com a Parte 1 da especificação: EBIT + D&A, com EBIT = resultado operacional (ou `ebit`).
/// O campo `ebitda` do Yahoo só serve de último recurso: inclui resultados não operacionais.
double? ebitdaOf(FinPeriod p) {
  final ebit = p.ebitOrOperating;
  final da = p.depreciationAmortization;
  if (ebit != null && da != null) return ebit + da;
  return p.ebitda;
}

/// Período anterior de `cur` para as médias de balanço (Parte 2.0).
/// Exercício anual: o exercício anual imediatamente anterior. TTM ou trimestre: o período cujo fecho
/// está entre 320 e 410 dias antes de `cur.end`, primeiro nos trimestrais e depois nos anuais; `null` se não houver.
FinPeriod? previousPeriodFor(Financials f, FinPeriod cur) {
  final i = f.annual.indexWhere((p) => identical(p, cur));
  if (i >= 0) return i > 0 ? f.annual[i - 1] : null;
  bool naJanela(FinPeriod p) {
    final dias = cur.end.difference(p.end).inDays;
    return dias >= 320 && dias <= 410;
  }

  for (final p in f.quarterly.reversed) {
    if (naJanela(p)) return p;
  }
  for (final p in f.annual.reversed) {
    if (naJanela(p)) return p;
  }
  return null;
}

/// Bancos e financeiras: sem custo das vendas, resultado operacional nem ativo corrente. As métricas
/// industriais (DSO, rotação do ativo, EV, FCF, dívida líquida, WACC...) não têm o mesmo significado
/// e devem dar `null` em vez de números enganadores.
bool isFinancialLike(FinPeriod? p) =>
    p != null &&
    p.costOfRevenue == null &&
    p.operatingIncome == null &&
    p.currentAssets == null;

/// Razão entre as ações do snapshot (por exemplo, equivalentes ADR) e as das demonstrações
/// (`sharesOutstanding` do último período). Fora de ~1 (ADRs: 1 ADR = N ações), as métricas por ação
/// calculadas com as ações das demonstrações (BVPS, P/B, P/TBV...) ficam na base errada.
double? sharesBasisRatio(Financials f, MarketSnapshot m) {
  final a = m.sharesOutstanding;
  final b = f.latest?.sharesOutstanding;
  if (a == null || b == null || b == 0) return null;
  return a / b;
}

/// As ações do snapshot e das demonstrações estão em bases diferentes (ADR)?
bool sharesBasisMismatch(Financials f, MarketSnapshot m) {
  final r = sharesBasisRatio(f, m);
  return r != null && (r < 0.8 || r > 1.25);
}
