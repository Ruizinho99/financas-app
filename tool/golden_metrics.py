#!/usr/bin/env python3
"""Valores de referência (golden) das métricas fundamentais, calculados de forma INDEPENDENTE do código Dart.

Lê as respostas gravadas do Yahoo em test/fixtures/yahoo e escreve test/fixtures/golden_aapl.json.
As fórmulas seguem os manuais (e docs/metricas-fundamentais.md). Os testes Dart têm de bater com estes números:
se o implementador calculasse ele próprio os valores esperados, os testes não provariam nada.
Uso: python3 tool/golden_metrics.py
"""
import json, math, datetime as dt
from pathlib import Path

D = Path(__file__).resolve().parent.parent / "test" / "fixtures" / "yahoo"


def series(sym, pre):
    j = json.load(open(D / f"ts_{sym}_{pre}.json"))
    out = {}
    for r in j["timeseries"]["result"]:
        k = r["meta"]["type"][0]
        if k not in r:
            continue
        name = k[len(pre):]
        out[name] = {p["asOfDate"]: p["reportedValue"]["raw"] for p in r[k] if p and p.get("reportedValue")}
    return out


def at(s, name, date):
    return s.get(name, {}).get(date)


def main():
    s = series("AAPL", "annual")
    dates = sorted(s["TotalRevenue"])
    t, p = dates[-1], dates[-2]  # último exercício e o anterior
    g = {"_periodo": t, "_periodo_anterior": p}
    v = lambda n, d=t: at(s, n, d)
    rev, rev0 = v("TotalRevenue"), v("TotalRevenue", p)
    g["gross_margin"] = v("GrossProfit") / rev
    g["ebitda_margin"] = v("EBITDA") / rev
    g["operating_margin"] = v("OperatingIncome") / rev
    g["net_margin"] = v("NetIncome") / rev
    g["fcf_margin"] = v("FreeCashFlow") / rev
    g["revenue_growth"] = rev / rev0 - 1
    g["net_income_growth"] = v("NetIncome") / v("NetIncome", p) - 1
    n = len(dates) - 1
    g["revenue_cagr_3y"] = (rev / at(s, "TotalRevenue", dates[-4])) ** (1 / 3) - 1 if len(dates) >= 4 else None
    avg = lambda name: (v(name) + v(name, p)) / 2
    g["roe"] = v("NetIncome") / avg("StockholdersEquity")
    g["roa"] = v("NetIncome") / avg("TotalAssets")
    # ROIC = NOPAT / capital investido; taxa = imposto / resultado antes de impostos; capital = CP + dívida - caixa (média)
    tax_rate = v("TaxProvision") / v("PretaxIncome")
    nopat = v("OperatingIncome") * (1 - tax_rate)
    ic = lambda d: at(s, "StockholdersEquity", d) + at(s, "TotalDebt", d) - at(s, "CashAndCashEquivalents", d)
    g["tax_rate"] = tax_rate
    g["roic"] = nopat / ((ic(t) + ic(p)) / 2)
    g["asset_turnover"] = rev / avg("TotalAssets")
    g["dso"] = v("AccountsReceivable") / rev * 365
    g["dio"] = v("Inventory") / v("CostOfRevenue") * 365
    g["dpo"] = v("AccountsPayable") / v("CostOfRevenue") * 365
    g["cash_conversion_cycle"] = g["dso"] + g["dio"] - g["dpo"]
    g["inventory_turnover"] = v("CostOfRevenue") / avg("Inventory")
    g["current_ratio"] = v("CurrentAssets") / v("CurrentLiabilities")
    g["cash_ratio"] = v("CashAndCashEquivalents") / v("CurrentLiabilities")
    g["working_capital"] = v("CurrentAssets") - v("CurrentLiabilities")
    g["net_debt"] = v("TotalDebt") - v("CashAndCashEquivalents")
    g["net_debt_to_ebitda"] = g["net_debt"] / v("EBITDA")
    g["debt_to_equity"] = v("TotalDebt") / v("StockholdersEquity")
    g["interest_coverage"] = v("EBIT") / v("InterestExpense") if v("InterestExpense") else None
    g["net_debt_to_fcf"] = g["net_debt"] / v("FreeCashFlow")
    g["fcf"] = v("OperatingCashFlow") - abs(v("CapitalExpenditure"))
    g["fcf_reported"] = v("FreeCashFlow")
    g["fcf_after_sbc"] = v("FreeCashFlow") - v("StockBasedCompensation")
    g["cash_conversion"] = v("OperatingCashFlow") / v("NetIncome")
    g["sloan_accruals"] = (v("NetIncome") - v("OperatingCashFlow")) / avg("TotalAssets")
    g["capex_to_revenue"] = abs(v("CapitalExpenditure")) / rev
    g["capex_to_da"] = abs(v("CapitalExpenditure")) / v("DepreciationAndAmortization")
    g["eps"] = v("DilutedEPS")
    g["bvps"] = v("StockholdersEquity") / v("OrdinarySharesNumber")
    g["fcf_per_share"] = v("FreeCashFlow") / v("DilutedAverageShares")
    g["share_dilution"] = v("OrdinarySharesNumber") / v("OrdinarySharesNumber", p) - 1
    g["payout_ratio"] = abs(v("CashDividendsPaid")) / v("NetIncome")
    # --- Piotroski F-score (9 testes)
    roa = lambda d: at(s, "NetIncome", d) / at(s, "TotalAssets", d)
    gm = lambda d: at(s, "GrossProfit", d) / at(s, "TotalRevenue", d)
    at_ = lambda d: at(s, "TotalRevenue", d) / at(s, "TotalAssets", d)
    cr = lambda d: at(s, "CurrentAssets", d) / at(s, "CurrentLiabilities", d)
    lev = lambda d: (at(s, "LongTermDebt", d) or 0) / at(s, "TotalAssets", d)
    tests = [
        roa(t) > 0,
        v("OperatingCashFlow") > 0,
        roa(t) > roa(p),
        v("OperatingCashFlow") / v("TotalAssets") > roa(t),
        lev(t) < lev(p),
        cr(t) > cr(p),
        v("OrdinarySharesNumber") <= v("OrdinarySharesNumber", p),
        gm(t) > gm(p),
        at_(t) > at_(p),
    ]
    g["piotroski_tests"] = [bool(x) for x in tests]
    g["piotroski_f"] = sum(tests)
    # --- Beneish M-score
    dep = lambda d: at(s, "DepreciationAndAmortization", d)
    ppe = lambda d: at(s, "NetPPE", d)
    sga = lambda d: at(s, "SellingGeneralAndAdministration", d)
    dsri = (at(s, "AccountsReceivable", t) / rev) / (at(s, "AccountsReceivable", p) / rev0)
    gmi = gm(p) / gm(t)
    aqi = (1 - (at(s, "CurrentAssets", t) + ppe(t)) / at(s, "TotalAssets", t)) / (1 - (at(s, "CurrentAssets", p) + ppe(p)) / at(s, "TotalAssets", p))
    sgi = rev / rev0
    depi = (dep(p) / (dep(p) + ppe(p))) / (dep(t) / (dep(t) + ppe(t)))
    sgai = (sga(t) / rev) / (sga(p) / rev0)
    lvgi = ((at(s, "CurrentLiabilities", t) + (at(s, "LongTermDebt", t) or 0)) / at(s, "TotalAssets", t)) / ((at(s, "CurrentLiabilities", p) + (at(s, "LongTermDebt", p) or 0)) / at(s, "TotalAssets", p))
    tata = (v("NetIncome") - v("OperatingCashFlow")) / v("TotalAssets")
    m = -4.84 + 0.920 * dsri + 0.528 * gmi + 0.404 * aqi + 0.892 * sgi + 0.115 * depi - 0.172 * sgai + 4.679 * tata - 0.327 * lvgi
    g["beneish"] = {"dsri": dsri, "gmi": gmi, "aqi": aqi, "sgi": sgi, "depi": depi, "sgai": sgai, "tata": tata, "lvgi": lvgi}
    g["beneish_m"] = m
    # --- Altman Z (original) com uma capitalização de mercado fixa de 3.000.000.000.000 (entrada do teste)
    mcap = 3.0e12
    ta = v("TotalAssets")
    z = (1.2 * (v("CurrentAssets") - v("CurrentLiabilities")) / ta + 1.4 * v("RetainedEarnings") / ta
         + 3.3 * v("EBIT") / ta + 0.6 * mcap / v("TotalLiabilitiesNetMinorityInterest") + 1.0 * rev / ta)
    g["altman_z_market_cap"] = mcap
    g["altman_z"] = z
    # --- DCF de teste: FCF0=100, crescimento explícito 10 % durante 5 anos, g=2,5 %, WACC=9 %, dívida líquida 50, 10 ações
    fcf0, gr, g_t, wacc, nd, shares = 100.0, 0.10, 0.025, 0.09, 50.0, 10.0
    f = [fcf0 * (1 + gr) ** i for i in range(1, 6)]
    pv = sum(x / (1 + wacc) ** i for i, x in enumerate(f, 1))
    tv = f[-1] * (1 + g_t) / (wacc - g_t)
    pv_tv = tv / (1 + wacc) ** 5
    g["dcf_teste"] = {"fcf0": fcf0, "crescimento": gr, "g": g_t, "wacc": wacc, "divida_liquida": nd, "acoes": shares,
                      "soma_vp_fluxos": pv, "valor_terminal": tv, "vp_valor_terminal": pv_tv,
                      "valor_por_acao": (pv + pv_tv - nd) / shares}
    # --- WACC e CAPM de teste
    ke = 0.04 + 1.2 * 0.055
    kd, tx, E, Dd = 0.05, 0.21, 800.0, 200.0
    g["capm_ke"] = ke
    g["wacc_teste"] = E / (E + Dd) * ke + Dd / (E + Dd) * kd * (1 - tx)
    # --- XIRR de teste: -1000 em 2024-01-01, -500 em 2024-07-01, +1700 em 2025-01-01
    flows = [(dt.date(2024, 1, 1), -1000.0), (dt.date(2024, 7, 1), -500.0), (dt.date(2025, 1, 1), 1700.0)]
    def npv(r):
        return sum(c / (1 + r) ** ((d - flows[0][0]).days / 365.0) for d, c in flows)
    lo, hi = -0.99, 10.0
    for _ in range(200):
        mid = (lo + hi) / 2
        if npv(mid) > 0: lo = mid
        else: hi = mid
    g["xirr_teste"] = (lo + hi) / 2
    # --- risco de mercado a partir do gráfico gravado (2 anos, AAPL)
    j = json.load(open(D / "chart_AAPL_2y.json"))["chart"]["result"][0]
    closes = [c for c in j["indicators"]["quote"][0]["close"]]
    ts = j["timestamp"]
    pairs = [(a, b) for a, b in zip(ts, closes) if b is not None]
    px = [b for _, b in pairs]
    rets = [px[i] / px[i - 1] - 1 for i in range(1, len(px))]
    mean = sum(rets) / len(rets)
    sd = math.sqrt(sum((r - mean) ** 2 for r in rets) / (len(rets) - 1))
    g["n_precos"] = len(px)
    g["volatilidade_anualizada"] = sd * math.sqrt(252)
    peak, mdd = px[0], 0.0
    for x in px:
        peak = max(peak, x)
        mdd = min(mdd, x / peak - 1)
    g["drawdown_maximo"] = mdd
    g["retorno_total_periodo"] = px[-1] / px[0] - 1
    g["ultimo_preco"] = px[-1]
    # RSI(14) simples (médias de Wilder)
    gains = [max(r, 0) for r in rets]; losses = [max(-r, 0) for r in rets]
    ag = sum(gains[:14]) / 14; al = sum(losses[:14]) / 14
    for i in range(14, len(rets)):
        ag = (ag * 13 + gains[i]) / 14; al = (al * 13 + losses[i]) / 14
    g["rsi14"] = 100 - 100 / (1 + ag / al) if al else 100.0
    g["sma50"] = sum(px[-50:]) / 50
    g["sma200"] = sum(px[-200:]) / 200
    # beta vs S&P 500 (retornos diários alinhados por data)
    jm = json.load(open(D / "chart_GSPC_2y.json"))["chart"]["result"][0]
    mp = {a: b for a, b in zip(jm["timestamp"], jm["indicators"]["quote"][0]["close"]) if b is not None}
    common = [(a, b) for a, b in pairs if a in mp]
    ra = [common[i][1] / common[i - 1][1] - 1 for i in range(1, len(common))]
    rm = [mp[common[i][0]] / mp[common[i - 1][0]] - 1 for i in range(1, len(common))]
    ma, mm = sum(ra) / len(ra), sum(rm) / len(rm)
    cov = sum((x - ma) * (y - mm) for x, y in zip(ra, rm)) / (len(ra) - 1)
    var = sum((y - mm) ** 2 for y in rm) / (len(rm) - 1)
    g["beta_sp500"] = cov / var
    g["correlacao_sp500"] = cov / math.sqrt(var * sum((x - ma) ** 2 for x in ra) / (len(ra) - 1))
    outp = D.parent / "golden_aapl.json"
    json.dump(g, open(outp, "w"), indent=2, ensure_ascii=False)
    print(f"escrito {outp} ({len(g)} chaves)")
    for k in ["gross_margin", "roe", "roic", "piotroski_f", "beneish_m", "altman_z", "dcf_teste", "wacc_teste", "xirr_teste", "beta_sp500", "volatilidade_anualizada", "drawdown_maximo"]:
        print(f"  {k}: {g[k]}")


main()
