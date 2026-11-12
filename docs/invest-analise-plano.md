# Plano: análise fundamental e investimentos profissionais

Objetivo: a app calcula sozinha, a partir de dados gratuitos, as métricas de análise fundamental (lista do utilizador,
17 secções) para qualquer ticker e para os ativos da carteira; e liga investimentos a categorias, planeamento e orçamento.

## Fontes de dados (decidido: Yahoo sem chave + Finnhub opcional)
Verificado com pedidos reais:
- **Preços e eventos**: `GET https://query1.finance.yahoo.com/v8/finance/chart/{sym}?range=5y&interval=1d&events=div,split` (sem chave).
- **Demonstrações**: `GET https://query1.finance.yahoo.com/ws/fundamentals-timeseries/v1/finance/timeseries/{sym}?type=annualTotalRevenue,...&period1=1400000000&period2=1790000000`
  (sem chave). Prefixos `annual`, `quarterly`, `trailing`. 44–45 de 46 campos em empresas industriais; ~4 anos anuais e ~5 trimestres.
  Bancos (JPM) não têm CostOfRevenue, EBIT, CurrentAssets... Tickers locais podem não ter dados (AMZN.DE): mapear para o primário (AMZN).
- **Perfil e estatísticas**: `quoteSummary` precisa de cookie+crumb: `GET https://fc.yahoo.com` (cookie) e
  `GET https://query1.finance.yahoo.com/v1/test/getcrumb` (com o cookie); depois
  `https://query2.finance.yahoo.com/v10/finance/quoteSummary/{sym}?modules=assetProfile,summaryDetail,defaultKeyStatistics,financialData,majorHoldersBreakdown&crumb=...`
  (setor, indústria, beta, ações, EV, short % do float, % de insiders). Melhor esforço: se falhar, a análise segue sem estes campos.
- **Finnhub** (opcional, chave do utilizador nas definições): peers, crescimento a 5/10 anos, insiders. Fase posterior.
- Cripto: CoinGecko (já existe).
Sem histórico de 10 anos no Yahoo: CAGR a 3 anos com os dados anuais; 5/10 anos só com Finnhub (campo opcional).

## Arquitetura (lib/invest/)
- `metrics/financials.dart` — CONTRATO PARTILHADO (FinPeriod, MarketSnapshot, Financials, Metric, MetricKind, safeDiv, avgOf). Já escrito; não alterar sem avisar o orquestrador.
- `metrics/*.dart` — fórmulas PURAS (sem rede, sem Flutter): recebem `Financials`/`MarketSnapshot`/histórico e devolvem `List<Metric>`.
  Valor `null` quando falta um dado. Percentagens em fração. Uma função por métrica, com comentário da fórmula em português.
- `data/*.dart` — clientes HTTP (Yahoo), cache em SQLite (tabela `market_cache`, migração v23), conversão para o contrato.
- Ecrãs: Análise de um ticker; análise da carteira; ligação investimento↔categoria↔planeamento↔orçamento (fase 2, com mock aprovado).

## Fórmulas (fase 1) — um ficheiro por grupo, cada um com testes em test/metrics/
| Ficheiro | Secções da lista do utilizador |
|---|---|
| `profitability_growth.dart` | 1 Rentabilidade (margens bruta, EBITDA, operacional, líquida, FCF); 2 Crescimento (YoY, CAGR, sustentável, alavancagem operacional); 3 Retorno (ROE, ROA, ROIC, spread vs WACC, ROTE, DuPont); 4 Eficiência (rotação do ativo, DSO, DIO, DPO, ciclo de caixa, rotação de inventários) |
| `liquidity_solvency_cash.dart` | 5 Liquidez; 6 Solvência (dívida líquida, /EBITDA, /capitais, cobertura de juros, /FCF); 7 Fluxo de caixa e qualidade (FCF, FCF-SBC, owner earnings, conversão de caixa, accruals de Sloan, capex/receita, capex/D&A); 8 Por ação (EPS, FCF/ação, BVPS, TBVPS, DPS, diluição) |
| `valuation_dividends.dart` | 9 Avaliação (market cap, EV, P/E, earnings yield, PEG, P/B, P/TBV, P/S, P/FCF, FCF yield, EV/EBIT, EV/EBITDA, EV/Receita, EV/FCF, fórmula mágica, CAPE quando houver); 10 Dividendos (yield, payout, payout de FCF, crescimento, anos de aumento, recompras/cap, shareholder yield) |
| `risk_scores.dart` | 11 Altman Z, Piotroski F (0–9), Beneish M (8 variáveis) |
| `dcf.dart` | 12 FCFF, WACC, Ke (CAPM), valor terminal de Gordon, valor por ação, margem de segurança, DCF inverso, sensibilidade WACC×g, 3 cenários |
| `market_risk.dart` | 13 (a partir do histórico de preços: beta vs índice, volatilidade anualizada, drawdown máximo, 52 semanas e distância ao máximo, volume médio, retornos 1D–5A, médias móveis 50/200, RSI) + carteira (XIRR, TWR, correlação, VaR histórico, HHI) |
| `sector_redflags.dart` | 16 Específicas por setor (bancos, seguradoras, REITs, utilities, petróleo, SaaS, retalho, farma, holdings, sem lucros) com o que houver nos dados e `null` no resto; 17 Alertas (red flags) a partir das outras métricas |
| `data/yahoo_market_data.dart` + `data/market_cache.dart` | cliente Yahoo (chart, timeseries, quoteSummary com crumb), mapeamento de símbolos (XTB `NVD.DE` -> dados; `AMZN.DE` -> `AMZN` se vazio), cache com validade (preços 15 min, fundamentais 24 h), conversão para o contrato; testes com respostas gravadas |

## Regras para todos os agentes
- Sem rede nas fórmulas. Testes com números conhecidos (exemplos de manual) e casos `null`/divisão por zero.
- Nomes de métricas = chaves estáveis em inglês snake_case (`gross_margin`, `roic`, `altman_z`...); a interface traduz.
- Comentários em português, como o resto do projeto. Pacote `financas`. `flutter analyze --no-fatal-infos` com código 0 e `flutter test`.
- O flutter reescreve `analysis_options.yaml`: reverter antes do commit. Nunca dados pessoais.
- Um agente por ficheiro; não editar ficheiros de outros agentes. Sem PR nem merge; sem mexer na versão.

## Fases
1. Fórmulas + dados (agentes em paralelo) → revisão por agentes dedicados → integração.
2. Ecrãs (mock aprovado): análise de ticker; carteira; investimento↔categoria↔planeamento↔orçamento; data e hora das compras.
