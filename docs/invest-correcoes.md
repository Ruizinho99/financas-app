# Correções após a revisão independente

Origem: 3 relatórios de revisores (recálculo em Python a partir das fixtures reais AAPL, NVD.DE, JPM e pedidos reais ao Yahoo).
Cada agente só toca nos SEUS ficheiros. Para cada correção: primeiro escreve um teste que falha (com o caso dado), depois corrige.
Usa os helpers de `lib/invest/metrics/shared.dart` (`mcapOf`, `ebitdaOf`, `previousPeriodFor`, `isFinancialLike`, `sharesBasisMismatch`), já testados.
Mantém todos os testes existentes a passar (adapta os que codificavam o comportamento errado e explica no relatório) e atualiza as fichas `*_info.dart` onde o comportamento ou o texto mudar.

## F1 — profitability_growth.dart, liquidity_solvency_cash.dart, valuation_dividends.dart (+ *_info.dart e testes respetivos)
- **E1 EBITDA**: usar `ebitdaOf(p)` em `ebitda_margin`, `net_debt_to_ebitda`, `ev_ebitda` (o EBITDA do Yahoo inclui resultados não operacionais; NVD.DE TTM dava margem EBITDA 77 % > margem operacional + D&A). Na AAPL dá o mesmo; acrescenta teste à mão com `ebitda` do Yahoo ≠ `operatingIncome + D&A`.
- **R1 bancos**: com `isFinancialLike(período)` devolver `null` em `dso`, `dio`, `dpo`, `asset_turnover`, `cash_conversion`, `fcf_margin`, `fcf_yield`, `fcf_per_share`, `p_fcf`, `ev_fcf`, `net_debt`, `net_debt_to_*`, `debt_to_equity`, `ev`, `ev_*`, `fcf`, `fcf_after_sbc`, `owner_earnings` e `current_ratio` & co. (JPM TTM dava DSO 337, FCF −83 %, EV 944 mil M). Mantém ROE, ROA, ROTE, P/B, P/TBV, EPS, BVPS, dividendos. Atualiza as fichas a dizer "não aplicável a bancos".
- **R2 período anterior**: apagar as 3 cópias (`periodoAnterior` em profitability, `_periodoAnterior` em liquidity e valuation) e usar `previousPeriodFor` de shared.dart em todo o lado; idem cópias de `_ebit`, `_fcf`, taxa de imposto e capital investido se forem idênticas (extrai para um ficheiro privado `lib/invest/metrics/common_calcs.dart` seu, se necessário). Teste com o caso: TTM a fechar em 2026-09-30, 1 trimestral, anuais 2025-09-30 e 2026-06-30, ativo total 100→300: ROA, Sloan, ROIC e `magic_formula_roic` têm de usar a MESMA média.
- **R3 dividendos**: o primeiro ano do histórico pode ser parcial (range=max): excluí-lo do crescimento e dos anos consecutivos (eventos 2021-12=0,1 e 2022..2025 = 0,4;0,5;0,6;0,7 → 3 anos, não 4), salvo se o histórico começar em janeiro.
- **R4**: `roic_wacc_spread` devolve sempre a chave (valor `null` sem WACC).
- **E2 ADR**: se `sharesBasisMismatch(f, m)`, as métricas por ação com ações das demonstrações (`bvps`, `tbvps` onde recebam o snapshot, `pb`, `p_tbv`) dão `null` e a ficha explica (TSM: 1 ADR = 5 ações; P/B saía 5× fora). `perShareMetrics` já aceita `market` opcional.
- **E1 forwardEps** (valuation): só usar `m.forwardEps` se `m.currency == m.quoteCurrency` (no ADR TSM o EPS esperado vem em USD e as demonstrações em TWD → P/E esperado errado por uma ordem de grandeza); senão `null` e a ficha diz porquê.
- Estilo: "industria"→"indústria" (profitability_growth_info 3 sítios); fórmulas das fichas `interest_coverage` (usa `interestExpense ?? interestPaid`) e `eps` (prioridade a `dilutedEps`) iguais ao código; fichas a dizerem que margens, ROE/ROA/ROIC, rotações e rácios são TTM; `cash_conversion_cycle` é nulo também se faltar DSO ou DPO; `operating_leverage` com ressalva para variações negativas (receita −5 %, EBIT −50 % dá 10 e o EBIT cai mais depressa); comentário que o EPS negativo é intencional.
- `mcapOf(m)` em vez de `m.marketCap` onde a capitalização é usada.

## F2 — dcf.dart, risk_scores.dart, market_risk.dart (+ *_info.dart e testes respetivos)
- **Capitalização**: usar `mcapOf(m)` no WACC/DCF (`dcf.dart` ~364/104) e no Altman (`risk_scores.dart` ~102) (hoje ficam `null` se só houver preço e ações).
- **Kd**: juros = 0 conta como ausente (`(ie == null || ie == 0) ? interestPaid : ie`); se continuar 0 → 5 %.
- **Cenários**: com crescimento negativo os cenários invertem-se: pessimista = `gr − 0,5·|gr|`, otimista = `gr + 0,5·|gr|` (ou ordenar), e o teste com gr = −10 % tem de dar pessimista < base < otimista.
- **TWR**: sub-período que começa em 0 e acaba em 0 conta fator 1; `null` só se começa em 0 e acaba ≠ 0 (casos: `[(0,1000),(1200,−1200),(0,500),(550,0)]` → 0,32; `[(0,0),(0,1000),(1100,0)]` → 0,10).
- **Beta**: exigir ≥ 60 retornos alinhados, senão `null` (hoje 3 preços dão beta 10,05); acrescentar `betaDimson(...)` (soma dos coeficientes contemporâneo e com desfasamento 1, para cotações cruzadas com fechos assíncronos, ex.: NVD.DE vs ^GSPC 0,89 vs ~1,3) e a ficha do beta/correlação a avisar de cotações cruzadas, fechos assíncronos e câmbio.
- **Ligar o beta ao DCF**: `DcfAssumptions.beta` é o que o utilizador escreve; acrescentar parâmetro SEPARADO `computedBeta` (em `dcfMetrics`), ordem `a.beta ?? m.beta ?? computedBeta ?? 1,0`; e a mesma taxa sem risco nos dois módulos (uma só constante partilhada, `marketRiskMetrics(riskFree: …)` recebe a de `DcfAssumptions`). Corrige o comentário de dcf.dart:27.
- **HHI/top-N**: pesos negativos → `null`. **XIRR**: alargar o intervalo (limite superior 1e3 ou Newton com fallback): −1000 e +1300 trinta dias depois dá ≈ 23,34, não `null`. **averageCorrelation**: alinhar preços por par como o beta (um par com poucas datas não anula tudo). **retornosSimples**: fecho 0 → `null`/ignorar, sem Infinity/NaN.
- **Piotroski teste 5**: quando a dívida de longo prazo é 0 nos dois anos conta como cumprido (`<=`). **Bancos**: `ke`, `wacc` e os sub-índices do Beneish (`beneish_dsri`, `sgi`, `depi`, `sgai`, `tata`…) a `null` com `isFinancialLike` (JPM mostrava WACC 12 % com Kd 19 %).
- **Fichas**: o Sortino NÃO é "acima do Sharpe indica volatilidade de subida" (com DD sobre os N retornos o Sortino ≈ √2×Sharpe); `retorno_3a` parcial; `volume_medio` com `MetricKind.count`; `spread_bid_ask` com fórmula; `beneish_sgai`/`wacc`/`fcff` "não se aplicam a bancos"; Altman com TTM muda de zona por sazonalidade do balanço (dizer na ficha, AAPL Z″ 3,23 TTM vs 2,31 anual); `dcf_value_per_share` sem remeter para a matriz (não é Metric); estilo: comentário "pontos base" → "pontos percentuais".
- **Fichas em falta** (e as funções passam a devolver `Metric`): `xirr`, `twr`, `hhi`, `top_n_concentration`, `average_correlation` via uma função `portfolioMetrics(...)` com fichas em `market_risk_info.dart`.

## F3 — camada de dados: lib/invest/data/*.dart, lib/invest/price_service.dart, migração v23 em lib/db/database.dart (+ testes de test/invest_data/)
- **E1 forwardEps**: só preencher `forwardEps` do snapshot se moeda de reporte == moeda de cotação; senão `null` (TSM: cota USD, reporta TWD).
- **R1 rede vs vazio**: erro de rede/429/timeout NÃO pode parecer "sem dados": `Financials(failed: true)` (campo já existe no contrato); o resolver propaga o erro em vez de passar à pesquisa por nome.
- **R2**: resposta válida mas vazia (todas as séries vazias) não fica 24 h em cache (não guardar, ou TTL curto).
- **R3 cache**: purga ao abrir (`DELETE … WHERE fetched_at < agora−7 dias`), excluir `market_cache` do backup (`snapshotBytes`/`VACUUM INTO`) e esvaziá-la no "apagar tudo de investimentos".
- **R4**: dividendo a 12 meses: a ex-data de Nov/2025 caía fora da janela do gráfico 1y (AAPL 0,80 vs 1,06): pedir 2y para os eventos, ou usar o maior entre a soma e `trailingAnnualDividendRate`.
- **R5 EV**: validar `0,3 < EV/marketCap < 3` (TSM: 6,6×, base diferente); fora disso `enterpriseValue = null`.
- **R6 TTM**: exigir 4 trimestres consecutivos (intervalo `last − first` ≈ 250–290 dias, espaços ≈ 3 meses); senão `null`.
- **R7**: a deteção de consentimento da UE é código morto (`IOClient` devolve o pedido original): apaga-a e documenta que a falha do crumb cobre o caso (perfil vazio sem lançar).
- **R8 resolver**: falsos positivos com nome prefixo (Xtrackers MSCI World vs …Information Technology / …ex USA; Ford vs FORD OTOSAN; Coca-Cola vs Consolidated/Europacific; Apple vs Apple Hospitality REIT; Tesla/Microsoft vs futuros `=F`) e falsos negativos (`UCITS ETF 1C`, `TOTAL ENERGIES SE` vs TotalEnergies, `EDP - Energias de Portugal`): acrescentar `ucits`, `etf`, `acc`, `dist`, `1c`, `class a/b`… ao ruído (mas "class" distingue BRK-A de BRK-B), `SymbolHit.quoteType` (acrescentar em price_service.dart) e excluir FUTURE/OPTION/INDEX e símbolos com `=F`; para ETFs exigir igualdade (m=2), não prefixo. A pesquisa envia nome e ISIN ao Yahoo: corrige o comentário de `PriceService`.
- **R9 migração v23**: o `catch (_)` do `ALTER` engole erros: verificar `PRAGMA table_info(holdings)` antes e correr o bloco em `inTransaction`.
- **R13**: duas chamadas simultâneas de `_quoteSummary` fazem dois `_login`: memoriza o `Future<bool>` do login em curso.
- Estilo: `docs/invest-analise-plano.md` diz `financialData`, o código usa `price` (corrige o doc); comentário de `_series` sobre `dilutedShares` no `trailing` (código morto).

## F4 — sector_redflags.dart (+ sector_redflags_info.dart e testes)
- **E3 `sectorGroupOf`**: tirar a regra por nome (`holding` apanha ASML Holding, Booking Holdings): usar só a indústria (`conglomerates`, `financial conglomerates`) e `sector == 'Financial Services'`; melhorar: "Discount Stores", "Grocery Stores", "Department Stores" → retalho; "Specialty Chemicals" e outros de Basic Materials fora de `commodities` (só petróleo, gás, mineração, metais, agricultura); sem indústria, "Real Estate" → REITs e "Financial Services" → financeiras.
- **E4**: `flag_dso_rising`/`flag_dio_rising` disparam no limiar exato por vírgula flutuante (42/40−1 = 0,05000000000000004): comparar com tolerância `1e-9`.
- **R10**: `nolp_cash_runway_months` usa `MetricKind.years`: passar a `MetricKind.months` (já existe no contrato).
- **R11 `flag_serial_acquisitions`**: limiar de materialidade (|aquisições| ≥ 1 % da receita) e campo em falta conta como 0 (como `flag_impairments`) — hoje NVD.DE dispara com 0,18 % e AAPL fica `null`.
- **R12**: `flag_dso_rising`, `flag_dio_rising`, `flag_debt_and_cash_high` devolvem `null` para bancos e seguradoras (JPM dava DSO 0,0).
- `bank_rote` usa `netIncome` e não o atribuível aos ordinários: documentar na ficha.
