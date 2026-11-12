/// Cálculos comuns a `profitability_growth.dart`, `liquidity_solvency_cash.dart` e `valuation_dividends.dart`
/// (a revisão independente encontrou cópias divergentes em cada módulo). Funções puras.
/// O EBITDA, a capitalização, o período anterior e os bancos estão em `shared.dart`.
library;

import 'financials.dart';

/// EBIT para as fórmulas: resultado operacional e, se faltar, o campo `ebit` (Parte 2.0).
/// (Mesma ordem que `FinPeriod.ebitOrOperating`.)
double? ebitOf(FinPeriod p) => p.operatingIncome ?? p.ebit;

/// FCF = CFO − |capex|; se faltar um dos dois, o `freeCashFlow` da fonte.
double? fcfOf(FinPeriod p) {
  final cfo = p.operatingCashFlow;
  final capex = p.capexSpent;
  if (cfo != null && capex != null) return cfo - capex;
  return p.freeCashFlow;
}

/// Capital investido de um período: capitais próprios + dívida financeira − caixa e equivalentes.
/// (Não se usa o `investedCapital` do Yahoo, que não deduz a caixa.)
double? investedCapitalOf(FinPeriod p) {
  if (p.equity == null || p.totalDebt == null || p.cash == null) return null;
  return p.equity! + p.totalDebt! - p.cash!;
}

/// Taxa de imposto efetiva `t` (Parte 2.0): `taxProvision / pretaxIncome` se estiver em [0; 0,5] e o
/// resultado antes de impostos for positivo; senão 21 %. É um fallback, não um clamp.
double taxRateOf(FinPeriod p) {
  final pt = p.pretaxIncome;
  final tx = p.taxProvision;
  if (pt == null || tx == null || pt <= 0) return 0.21;
  final r = tx / pt;
  return (r >= 0 && r <= 0.5) ? r : 0.21;
}
