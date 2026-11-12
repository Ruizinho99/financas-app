# Métricas fundamentais: especificação

Este documento é a fonte de verdade das fórmulas. Partes:
1. A lista do utilizador (verbatim).
2. Definições exatas a implementar (inclui as que a lista só nomeia).
3. Disponibilidade dos dados gratuitos (o que se calcula, o que não).
4. Regras transversais (moeda, símbolo, tipo de ativo, TTM, testes).

Os valores de referência dos testes (`test/fixtures/golden_aapl.json`) foram calculados por `tool/golden_metrics.py`,
um script independente do código Dart. Os testes têm de bater com eles.

---

## Parte 1: a lista do utilizador (verbatim)

MÉTRICAS DE ANÁLISE FUNDAMENTAL DE AÇÕES

Nota: os valores de referência dependem do setor. Compara sempre com concorrentes e com a história da própria empresa, e nunca uses uma métrica isolada.

1. RENTABILIDADE (MARGENS)
- Margem bruta = (Receita - Custo das vendas) / Receita. Mede o poder de preços.
- Margem EBITDA = EBITDA / Receita. EBITDA = EBIT + Amortizações e depreciações.
- Margem operacional = EBIT / Receita. EBIT = resultado operacional.
- Margem líquida = Resultado líquido / Receita.
- Margem de FCF = Free cash flow / Receita.

2. CRESCIMENTO
- Crescimento anual da receita, do resultado e do FCF = Valor atual / Valor anterior - 1.
- CAGR (taxa de crescimento anual composta) = (Valor final / Valor inicial)^(1/anos) - 1. Usa 3, 5 e 10 anos.
- Crescimento orgânico = crescimento sem aquisições nem efeito cambial.
- Crescimento sustentável = ROE x (1 - payout).
- Alavancagem operacional = variação % do EBIT / variação % da receita.

3. RETORNO SOBRE O CAPITAL
- ROE = Resultado líquido / Capitais próprios médios. Atenção: a dívida e as recompras inflacionam-no.
- ROA = Resultado líquido / Ativo total médio.
- ROIC = NOPAT / Capital investido. NOPAT = EBIT x (1 - taxa de imposto). Capital investido = Capitais próprios + Dívida financeira - Caixa excedentário.
- Spread de criação de valor = ROIC - WACC. Se for positivo e persistente, há moat.
- ROTE = Resultado líquido / Capitais próprios tangíveis (para bancos).
- DuPont: ROE = Margem líquida x Rotação do ativo x Alavancagem financeira (Ativo / Capitais próprios).

4. EFICIÊNCIA E CICLO DE CAIXA
- Rotação do ativo = Receita / Ativo médio.
- DSO (dias de vendas por receber) = Contas a receber / Receita x 365.
- DIO (dias de inventário) = Inventários / Custo das vendas x 365.
- DPO (dias de pagamento a fornecedores) = Contas a pagar / Custo das vendas x 365.
- Ciclo de conversão de caixa = DSO + DIO - DPO. Negativo significa que os fornecedores financiam a empresa.
- Rotação de inventários = Custo das vendas / Inventário médio.

5. LIQUIDEZ
- Rácio corrente = Ativo corrente / Passivo corrente.
- Rácio rápido = (Caixa + Investimentos de curto prazo + Contas a receber) / Passivo corrente.
- Rácio de caixa = Caixa / Passivo corrente.
- Fundo de maneio = Ativo corrente - Passivo corrente.

6. SOLVÊNCIA E DÍVIDA
- Dívida líquida = Dívida financeira - Caixa e equivalentes.
- Dívida líquida / EBITDA. Acima de 3 a 4 exige cautela, exceto em utilities e infraestruturas.
- Dívida / Capitais próprios.
- Cobertura de juros = EBIT / Juros pagos.
- Dívida líquida / FCF = anos de FCF para pagar a dívida.
- Maturidades da dívida e dívida de taxa variável (ver notas do relatório).
- Locações (leases): inclui-as na dívida em IFRS 16.

7. FLUXO DE CAIXA E QUALIDADE DOS LUCROS
- CFO (fluxo operacional) e Capex (investimento em ativos fixos).
- FCF = CFO - Capex.
- FCF ajustado de SBC = FCF - Remuneração em ações.
- Owner earnings (Buffett) = Resultado líquido + D&A - Capex de manutenção +/- Fundo de maneio.
- Conversão de caixa = CFO / Resultado líquido. Perto de 100% ou mais é saudável.
- Accruals de Sloan = (Resultado líquido - CFO) / Ativo médio. Valores altos são sinal de alerta.
- Capex / Receita e Capex / Amortizações.
- Capex de manutenção vs capex de crescimento.

8. MÉTRICAS POR AÇÃO
- EPS (resultado por ação) = Resultado líquido / Ações diluídas.
- FCF por ação.
- Valor contabilístico por ação (BVPS) = Capitais próprios / Ações.
- Valor contabilístico tangível por ação.
- Dividendo por ação (DPS).
- Diluição = variação anual do número de ações. Negativa significa recompras.

9. AVALIAÇÃO (MÚLTIPLOS)
- Capitalização bolsista = Preço x Ações em circulação.
- EV (valor da empresa) = Capitalização + Dívida - Caixa + Interesses minoritários + Preferenciais.
- P/E = Preço / EPS. Versões: último exercício (trailing), TTM, esperado (forward) e normalizado (CAPE).
- Earnings yield = EPS / Preço (inverso do P/E).
- PEG = P/E / Crescimento anual do EPS em %.
- P/B = Preço / BVPS. P/TBV = Preço / Valor contabilístico tangível (para bancos).
- P/S = Capitalização / Receita.
- P/FCF = Capitalização / FCF. FCF yield = FCF / Capitalização.
- EV/EBIT, EV/EBITDA, EV/Receita, EV/FCF.
- Fórmula mágica (Greenblatt): rendimento do EV/EBIT + ROIC.
- CAPE de Shiller = Preço / Média dos lucros reais dos últimos 10 anos.
- Compara sempre com pares, com a média histórica da própria empresa e com o mercado.

10. DIVIDENDOS E RETORNO AOS ACIONISTAS
- Dividend yield = DPS / Preço.
- Payout = Dividendos / Resultado líquido. Payout de FCF = Dividendos / FCF.
- Crescimento do dividendo e anos consecutivos de aumento.
- Recompras / Capitalização.
- Shareholder yield = (Dividendos + Recompras líquidas) / Capitalização.

11. SCORES DE RISCO E QUALIDADE
- Altman Z-Score (risco de falência). Original: Z = 1,2 x (Fundo de maneio/Ativo) + 1,4 x (Resultados retidos/Ativo) + 3,3 x (EBIT/Ativo) + 0,6 x (Capitalização/Passivo total) + 1,0 x (Receita/Ativo). Acima de 2,99 é segura e abaixo de 1,81 é de risco.
- Piotroski F-Score (0 a 9). 9 critérios de rentabilidade, alavancagem e eficiência. 8 a 9 é forte e 0 a 3 é fraco.
- Beneish M-Score (probabilidade de manipulação de resultados). Acima de -1,78 é sinal de alerta. Usa 8 variáveis: DSRI, GMI, AQI, SGI, DEPI, SGAI, TATA, LVGI.

12. VALOR INTRÍNSECO (DCF)
- FCFF = EBIT x (1 - t) + D&A - Capex - Variação do fundo de maneio.
- WACC = E/(D+E) x Ke + D/(D+E) x Kd x (1 - t).
- Ke (custo dos capitais próprios, CAPM) = Taxa sem risco + Beta x Prémio de risco do mercado.
- Valor terminal (Gordon) = FCF x (1 + g) / (WACC - g).
- Valor por ação = (Soma dos fluxos descontados + Valor terminal descontado - Dívida líquida) / Ações.
- Margem de segurança = 1 - Preço / Valor intrínseco.
- DCF inverso = o crescimento que o preço atual já assume.
- Análise de sensibilidade WACC x g e cenários (pessimista, base, otimista).

13. MERCADO E RISCO
- Beta = sensibilidade ao mercado.
- Máximo e mínimo das últimas 52 semanas e distância ao máximo.
- Drawdown máximo (maior queda do pico ao vale).
- Volatilidade anualizada.
- Volume médio e liquidez (spread, valor negociado por dia).
- Short interest (percentagem das ações vendidas a descoberto).
- Compras e vendas de insiders (administradores).

14. QUALIDADE DO NEGÓCIO (QUALITATIVO E QUANTITATIVO)
- ROIC elevado e estável durante 10 anos.
- Margens estáveis ou a subir (poder de fixação de preços).
- Quota de mercado e crescimento face ao setor.
- Receita recorrente (% de receita recorrente, churn, retenção).
- Concentração de clientes e fornecedores.
- Fontes de moat: marca, custos de mudança, efeitos de rede, vantagem de custo, escala eficiente.

15. GESTÃO E GOVERNO SOCIETÁRIO
- Alocação de capital: retorno das aquisições, recompras a preços razoáveis.
- Remuneração ligada a ROIC e FCF, e não só a EPS.
- Percentagem de ações detidas pelos administradores.
- Independência do conselho e estrutura de classes de ações.
- Troca de auditor, reservas do auditor e atrasos nas contas.

16. MÉTRICAS ESPECÍFICAS POR SETOR
- Bancos: margem financeira (NII e NIM), cost-to-income, custo do risco, rácio CET1, NPL e cobertura, LCR, ROTE, P/TBV.
- Seguradoras: combined ratio, float, reservas, ROE, P/B.
- Imobiliário (REITs): FFO, AFFO, NAV, cap rate, LTV, ocupação, dividend yield.
- Utilities e infraestruturas: base de ativos regulados (RAB), retorno regulado, dívida líquida/EBITDA, payout.
- Petróleo e matérias-primas: preço de equilíbrio, reservas e custo de produção, FCF ao longo do ciclo, normalização de resultados.
- Software e SaaS: ARR, net revenue retention, regra dos 40 (crescimento + margem FCF), CAC payback, margem bruta, SBC / Receita.
- Retalho: vendas comparáveis (like-for-like), vendas por m2, rotação de inventários, margem por loja.
- Farmacêuticas e biotecnologia: pipeline, patent cliff, valor ponderado por probabilidade (rNPV), I&D / Receita.
- Holdings: soma das partes (SOTP) e desconto de holding.
- Empresas sem lucros: receita, margem bruta, cash runway (caixa / queima mensal), diluição.

17. ALERTAS (RED FLAGS)
- Lucros a subir e fluxo de caixa operacional a descer.
- DSO e inventários a crescer mais depressa do que as vendas.
- Capitalização agressiva de custos.
- Resultados ajustados (non-GAAP) cada vez mais distantes do GAAP.
- Itens "não recorrentes" todos os anos.
- Goodwill elevado e imparidades.
- Dívida e caixa elevados ao mesmo tempo.
- Mudanças de políticas contabilísticas.
- Imposto pago muito abaixo do lucro reportado.
- Aquisições em série a esconder crescimento orgânico fraco.

---

## Parte 2: definições exatas a implementar

### 2.0 Convenções (valem para todas as métricas)

- Taxas em fração (0,25 = 25 %). Qualquer divisão por zero ou dado em falta dá `null` (usar `safeDiv`). As exceções a esta regra estão escritas
  explicitamente na métrica, sob a forma "`null` → 0".
- **Base temporal.** Cada função recebe explicitamente `cur` (período corrente) e, quando precisa, `prev` (período um ano antes). Não há escolha implícita:
  | Grupo | `cur` / `prev` |
  |---|---|
  | Margens, retorno (ROE, ROA, ROIC, ROTE, DuPont), eficiência, liquidez, solvência, fluxo de caixa, por ação, múltiplos, dividendos/payout, Altman, FCFF₀ do DCF | `cur = fin.latest` (TTM se existir, senão último anual). `prev` = só para médias (ver "médio") |
  | Crescimento YoY, CAGR, alavancagem operacional, diluição, PEG (crescimento do EPS), Piotroski, Beneish | sempre **anuais**: `t = annual.last`, `t-1 = annual[len-2]`, `t-2 = annual[len-3]` |
  Os testes golden (`golden_aapl.json`) usam **`cur = annual.last` e `prev = annual[len-2]`** para tudo (passados explicitamente); não usar o TTM nesses testes.
- **"Médio"** = `avgOf(saldo_cur, saldo_prev)` (se faltar `prev`, só `cur`). Se `cur` é anual, `prev` é o anual anterior. Se `cur` é o TTM
  (balanço = último trimestre), `prev` é o período (trimestral, ou anual se não houver trimestral) cujo `end` está entre 320 e 410 dias antes de `cur.end`;
  se não houver nenhum, `prev = null`.
- Saldos de balanço "sem média" (DSO, DIO, DPO, liquidez, dívida, BVPS, Altman, Beneish) usam o **saldo do fecho** de `cur`.
- **EBIT** = `operatingIncome ?? ebit` (resultado operacional, como a Parte 1 define). **Atenção**: o getter `FinPeriod.ebitOrOperating` do contrato
  tem a prioridade inversa (`ebit ?? operatingIncome`); não o usar nas fórmulas (o `EBIT` do Yahoo inclui resultados não operacionais). Na AAPL os dois coincidem,
  pelo que os testes golden não detetam a troca: há que respeitar esta regra.
- **FCF** = `operatingCashFlow − |capex|`; se faltar um dos dois, `freeCashFlow` da fonte.
- **Taxa de imposto efetiva** `t`:
  ```
  if (pretaxIncome == null || taxProvision == null || pretaxIncome <= 0) t = 0.21
  else { r = taxProvision / pretaxIncome; t = (r >= 0 && r <= 0.5) ? r : 0.21 }
  ```
  (é um fallback, não um clamp: 0,7 dá 0,21 e não 0,5). Não usar o campo `TaxRateForCalcs` do Yahoo.

### 2.1 Sinais dos campos (como o Yahoo os reporta) e mapeamento

| Campo `FinPeriod` | Chave Yahoo (`annual*`/`quarterly*`/`trailing*`) | Sinal na fonte | Uso nas fórmulas |
|---|---|---|---|
| `capex` | `CapitalExpenditure` | negativo (saída) | sempre `|capex|` (`capexSpent`) |
| `dividendsPaid` | `CashDividendsPaid` | negativo (saída) | sempre `|dividendsPaid|` |
| `buybacks` | `RepurchaseOfCapitalStock` | negativo (saída); **bruto** (sem emissões) | ver recompras líquidas |
| `stockIssuance` | `IssuanceOfCapitalStock` (muitas vezes ausente) | positivo (entrada) | `null` → 0 nas recompras líquidas |
| `acquisitions` | `PurchaseOfBusiness` | negativo (saída) | `|acquisitions|` |
| `changeInWorkingCapital` | `ChangeInWorkingCapital` | **sinal de caixa**: negativo = o fundo de maneio aumentou e consumiu caixa | entra **somado tal como vem** (FCFF, owner earnings) |
| `interestExpense` | `InterestExpense` | positivo = despesa | |
| `taxProvision` | `TaxProvision` | positivo = despesa | |
| `totalDebt` | `TotalDebt` | positivo | ver dívida e locações |
| `totalLiabilities` | `TotalLiabilitiesNetMinorityInterest` | positivo | |
| `equity` | `StockholdersEquity` | pode ser negativo | |
| `sharesOutstanding` | `OrdinarySharesNumber` (fecho do período) | | |
| `dilutedShares` | `DilutedAverageShares` (média do período) | | |
| `depreciationAmortization` | `DepreciationAndAmortization` | positivo | |

**Recompras líquidas** (positivo = dinheiro devolvido): `netBuybacks = −buybacks − (stockIssuance ?? 0)`; se `buybacks == null` → `null`.
Pode ser negativo (emissão líquida). **Não** usar `buybacksPositive` (o `abs` trocaria o sinal de uma emissão líquida).

### 2.2 Rentabilidade, crescimento, retorno, eficiência

- Margens: bruta = `grossProfit / revenue` (se faltar `grossProfit`: `(revenue − costOfRevenue) / revenue`); EBITDA = `ebitda / revenue`;
  operacional = EBIT / receita; líquida = `netIncome / revenue`; FCF = FCF / receita.
- **YoY** = `x_t / x_{t-1} − 1`, só se `x_{t-1} > 0` (senão `null`).
- **CAGR** com N anos = `(x_t / x_{t-N})^(1/N) − 1`, só se ambos > 0. N = 3 (exige 4 anuais). 5 e 10 anos: `null` (sem dados gratuitos).
- **Crescimento orgânico**: `null` (não disponível).
- **Crescimento sustentável** = ROE × (1 − payout), payout = `|dividendsPaid| / netIncome` (`null` se resultado ≤ 0; dividendos `null` → payout 0).
- **Alavancagem operacional** = `(EBIT_t/EBIT_{t-1} − 1) / (receita_t/receita_{t-1} − 1)`; `null` se EBIT_{t-1} ≤ 0 ou denominador 0.
- **ROE** = resultado / capitais próprios médios; média ≤ 0 → `null`. **ROA** = resultado / ativo total médio.
- **ROIC** = NOPAT / capital investido médio. NOPAT = EBIT × (1 − t). Capital investido (por período) = `equity + totalDebt − cash`
  (a lista fala em "caixa excedentário": usa-se toda a caixa e equivalentes, `cash`, sem os investimentos de curto prazo). Média ≤ 0 → `null`.
  **Não** usar o campo `investedCapital` do Yahoo (é capitais próprios + dívida, sem deduzir a caixa).
- **Spread** = ROIC − WACC (WACC da secção DCF).
- **ROTE** = resultado / média de `tangibleBookValue`; média ≤ 0 → `null`.
- **DuPont**: margem líquida (resultado/receita) × rotação (receita / ativo médio) × alavancagem (ativo médio / capitais próprios médios). Com as mesmas médias o
  produto é exatamente o ROE.
- **Eficiência**: rotação do ativo = receita / ativo médio; DSO = `receivables / revenue × 365`; DIO = `inventory / costOfRevenue × 365`;
  DPO = `payables / costOfRevenue × 365` (saldos de fecho; com `cur` TTM a receita/custo são os TTM); ciclo = DSO + DIO − DPO
  (se faltar inventário, DIO `null` e ciclo `null`); rotação de inventários = custo das vendas / inventário médio.

### 2.3 Liquidez, solvência, fluxo de caixa, por ação

- Rácio corrente = AC / PC. **Rácio rápido** = `(cashAndShortTermInvestments + receivables) / currentLiabilities`. Rácio de caixa = `cash / currentLiabilities`.
  Fundo de maneio = AC − PC.
- **Dívida líquida** = `totalDebt − cash`. **Locações (IFRS 16)**: usa `totalDebt` tal como vem e **nunca** lhe somes `leaseLiabilities`. O Yahoo não é
  consistente: na AAPL, `TotalDebt` 2022 = LongTermDebt + CurrentDebt + CapitalLeaseObligations, mas em 2023 = só LongTermDebt + CurrentDebt
  (apesar de `CapitalLeaseObligations` vir reportado). A inclusão das locações **não é garantida pela fonte** (ver Parte 3).
- Dívida líquida / EBITDA (EBITDA ≤ 0 → `null`; dívida líquida negativa = caixa líquida, mostra-se o valor negativo). Dívida / capitais próprios
  (capitais próprios ≤ 0 → `null`). **Cobertura de juros** = EBIT / juros, juros = `interestExpense ?? interestPaid` (ambos `null` ou 0 → `null`).
  Dívida líquida / FCF (FCF ≤ 0 → `null`).
- **FCF ajustado de SBC** = FCF − `stockBasedComp`.
- **Owner earnings** (aproximação, documentar na interface):
  ```
  maint = min(|capex|, depreciationAmortization)
  ownerEarnings = netIncome + depreciationAmortization − maint + changeInWorkingCapital   // changeInWorkingCapital com o sinal da fonte
  ```
  Capex de manutenção ≈ `maint`; capex de crescimento = `|capex| − maint`.
- **Conversão de caixa** = CFO / resultado (resultado ≤ 0 → `null`).
- **Accruals de Sloan** (versão por fluxos de caixa) = `(netIncome − operatingCashFlow) / ativo total médio`. Sloan (1996) usava accruals de balanço;
  a versão por fluxos é a usada desde Hribar e Collins (2002).
- Capex / receita e capex / D&A com `|capex|`.
- **EPS** = `dilutedEps ?? netIncome / dilutedShares`. **FCF por ação** = FCF / `dilutedShares`. **BVPS** = `equity / sharesOutstanding`;
  **TBVPS** = `tangibleBookValue / sharesOutstanding`. **Diluição** = `sharesOutstanding_t / sharesOutstanding_{t-1} − 1` (anuais). **DPS** = `MarketSnapshot.dividendPerShare`.

### 2.4 Avaliação e retorno aos acionistas

Capitalização `mcap = MarketSnapshot.marketCap ?? price × MarketSnapshot.sharesOutstanding`. `shares = MarketSnapshot.sharesOutstanding ?? cur.sharesOutstanding`.

- **EV** = `mcap + totalDebt − cash + (minorityInterest ?? 0) + (preferredStock ?? 0)` (minoritários/preferenciais `null` → 0; `totalDebt` ou `cash` `null` → EV `null`).
  Calcula-se sempre assim (não usar `MarketSnapshot.enterpriseValue`, que mistura moedas e definições).
- **P/E TTM** = preço / EPS TTM; **P/E trailing** = preço / EPS do último anual. EPS ≤ 0 → `null`. Earnings yield = EPS / preço.
- **PEG** = P/E TTM / (g × 100), com g = CAGR do EPS diluído anual de 3 anos (`dilutedEps` de `annual.last` vs `annual[len-4]`); se só houver 3 anuais,
  CAGR de 2 anos. `null` se algum EPS ≤ 0, se g ≤ 0 ou se o P/E for `null`.
- P/B = preço / BVPS; P/TBV = preço / TBVPS (denominador ≤ 0 → `null`). P/S = mcap / receita. P/FCF = mcap / FCF (FCF ≤ 0 → `null`);
  FCF yield = FCF / mcap. EV/EBIT, EV/EBITDA, EV/receita, EV/FCF (denominador ≤ 0 → `null`).
- **Fórmula mágica (Greenblatt, 2005)**: devolve os dois componentes (o ranking exige um universo e não se faz):
  ```
  earningsYield = EBIT / EV
  nwc = (currentAssets − cash) − (currentLiabilities − (currentDebt ?? 0))
  roc = EBIT / (max(nwc, 0) + netPpe)          // "return on capital" de Greenblatt, NÃO o ROIC
  ```
- **CAPE**: `null` (exige 10 anos de lucros reais).
- **Dividend yield** = DPS / preço. **Payout** = `|dividendsPaid| / netIncome` (resultado ≤ 0 → `null`); **payout de FCF** = `|dividendsPaid| / FCF` (FCF ≤ 0 → `null`).
- **Recompras / capitalização** = `netBuybacks / mcap`. **Shareholder yield** = `(|dividendsPaid ?? 0| + netBuybacks) / mcap` (pode ser negativo).
- **Crescimento do dividendo e anos consecutivos de aumento**: DPS por ano civil = soma dos eventos `div` do histórico de preços (pedido com `range=max`,
  `events=div`), **só anos civis completos** (exclui o ano corrente). Crescimento = DPS_y/DPS_{y−1} − 1 do último ano completo. Anos consecutivos =
  número de anos y, a contar para trás a partir do último ano completo, com DPS_y > DPS_{y−1} (para no primeiro que falhe).

### 2.5 Altman Z-Score

Saldos e fluxos de `cur`. `TA = totalAssets`, `TL = totalLiabilities`.
```
X1 = (currentAssets − currentLiabilities) / TA
X2 = retainedEarnings / TA
X3 = EBIT / TA
X4 = mcap / TL                 // valor de MERCADO dos capitais próprios / passivo total contabilístico
X5 = revenue / TA
Z  = 1.2*X1 + 1.4*X2 + 3.3*X3 + 0.6*X4 + 1.0*X5           // Altman (1968); zonas: > 2,99 segura; 1,81–2,99 cinzenta; < 1,81 risco
X4b = equity / TL              // valor CONTABILÍSTICO dos capitais próprios / passivo total
Z2 = 6.56*X1 + 3.26*X2 + 6.72*X3 + 1.05*X4b                // Z″ (Altman 1995/2000), SEM constante; zonas: > 2,6 segura; 1,1–2,6 cinzenta; < 1,1 risco
```
A variante "EM Score" (Altman, Hartzell e Peck 1995) é `Z2 + 3,25`; a constante desloca a escala para a tabela de equivalência de ratings
(≈ 5,85 corresponde a BBB) e **não** se usa com as zonas 2,6 / 1,1. Não a implementar.
Que valor a interface destaca (setor do Yahoo, `MarketSnapshot.sector`):
- `Industrials`, `Basic Materials`, `Energy`, `Consumer Cyclical`, `Consumer Defensive` → Z original;
- `Financial Services`, `Real Estate` → ambos `null` ("não aplicável": Altman exclui financeiras; os bancos nem têm ativo corrente);
- qualquer outro setor (incluindo vazio) → Z″.
A função devolve sempre os dois valores calculáveis; a escolha é só da interface.

### 2.6 Piotroski F-Score (Piotroski 2000)

Anuais `t`, `t-1`, `t-2`. `TA(x)` = ativo total no fecho de x. Um ponto por teste verdadeiro; teste com dado em falta não é avaliado (não conta e
não penaliza). Devolve `f` (0–9), a lista de 9 resultados (`true`/`false`/`null`) e `n_avaliados`.
```
ROA(x)   = netIncome(x) / TA(x−1)                         // ativo no INÍCIO do ano
LEV(x)   = longTermDebt(x) / ((TA(x) + TA(x−1)) / 2)        // dívida LP / ativo MÉDIO
CR(x)    = currentAssets(x) / currentLiabilities(x)
GM(x)    = grossProfit(x) / revenue(x)
TURN(x)  = revenue(x) / TA(x−1)
1  ROA(t) > 0
2  CFO(t) > 0
3  ROA(t) > ROA(t−1)                                       // precisa de TA(t−2)
4  CFO(t) > netIncome(t)                                   // = CFO/TA(t−1) > ROA(t): accruals negativos
5  LEV(t) < LEV(t−1)                                       // precisa de TA(t−2); longTermDebt null → teste não avaliado
6  CR(t) > CR(t−1)
7  sharesOutstanding(t) <= sharesOutstanding(t−1)          // aproximação: o artigo usa "não emitiu ações ordinárias"
8  GM(t) > GM(t−1)
9  TURN(t) > TURN(t−1)                                     // precisa de TA(t−2)
```
Classificação: 8–9 forte; 0–3 fraco (só se `n_avaliados == 9`; caso contrário mostra "f de n").

### 2.7 Beneish M-Score (modelo de 8 variáveis, Beneish 1999)

Anuais `t` e `t-1`, saldos de fecho. `GM(x) = grossProfit(x)/revenue(x)`.
```
DSRI = (receivables_t / revenue_t) / (receivables_{t−1} / revenue_{t−1})
GMI  = GM(t−1) / GM(t)
AQI  = (1 − (currentAssets_t + netPpe_t) / TA_t) / (1 − (currentAssets_{t−1} + netPpe_{t−1}) / TA_{t−1})
SGI  = revenue_t / revenue_{t−1}
DEPI = (DA_{t−1} / (DA_{t−1} + netPpe_{t−1})) / (DA_t / (DA_t + netPpe_t))       // DA = depreciationAmortization
SGAI = (sga_t / revenue_t) / (sga_{t−1} / revenue_{t−1})                         // sga = sellingGeneralAdmin
LVGI = ((currentLiabilities_t + longTermDebt_t) / TA_t) / ((currentLiabilities_{t−1} + longTermDebt_{t−1}) / TA_{t−1})
TATA = (netIncome_t − operatingCashFlow_t) / TA_t
M = −4.84 + 0.920*DSRI + 0.528*GMI + 0.404*AQI + 0.892*SGI + 0.115*DEPI − 0.172*SGAI + 4.679*TATA − 0.327*LVGI
```
Alerta se `M > −1,78` (Parte 1; Beneish, Lee e Nichols 2013). As fontes secundárias divergem sobre o limiar do artigo de 1999 (−1,78 vs −2,22)
e sobre o do modelo de 5 variáveis; não usar −2,22. Se faltar qualquer dado de qualquer índice (incluindo `longTermDebt`), `M = null`
(o modelo precisa dos 8; nada de `?? 0`). Aproximações a documentar: o artigo usa depreciação (não D&A) no DEPI e accruals de balanço no TATA
(a versão por fluxos de caixa é a de Beneish, Lee e Nichols 2013); os campos gratuitos não têm impostos a pagar para a versão de balanço.

### 2.8 DCF

```
t     = taxa de imposto efetiva de cur (2.0)
FCFF0 = EBIT*(1 − t) + depreciationAmortization − |capex| + changeInWorkingCapital      // cur = fin.latest; changeInWorkingCapital com o sinal da fonte
        // (= ... − ΔNWC, com ΔNWC = −changeInWorkingCapital). Qualquer termo null → FCFF0 null. FCFF0 <= 0 → DCF null.
gr    = crescimento explícito: entrada; por omissão o CAGR de 3 anos da receita limitado a [0; 0,15] (CAGR null → 0,05)
g     = crescimento terminal: entrada; por omissão 0,025
N     = 5 anos (entrada)
FCF_i = FCFF0 * (1 + gr)^i,  i = 1..N
PV    = Σ_{i=1..N} FCF_i / (1 + WACC)^i                        // desconto de fim de ano
TV    = FCF_N * (1 + g) / (WACC − g)                           // exige WACC > g, senão null
PV_TV = TV / (1 + WACC)^N
equityValue = PV + PV_TV − (totalDebt − cash) − (minorityInterest ?? 0) − (preferredStock ?? 0)
valorPorAcao = equityValue / shares                            // shares = MarketSnapshot.sharesOutstanding ?? cur.sharesOutstanding
margemSeguranca = 1 − preco / valorPorAcao                      // valorPorAcao <= 0 → null
```
- **Ke (CAPM)** = `rf + beta × MRP`, rf = 0,04 e MRP = 0,055 por omissão (editáveis); `beta = MarketSnapshot.beta ?? beta calculado (2.9) ?? 1.0`.
- **Kd** = juros / dívida média, com juros = `interestExpense ?? interestPaid`; se não houver juros ou dívida, ou se o resultado estiver fora de [0; 0,20], Kd = 0,05.
- **WACC** = `E/(D+E)·Ke + D/(D+E)·Kd·(1 − t)`, E = mcap, D = `totalDebt` (valor contabilístico; `null` → 0).
- **DCF inverso**: o `gr` que faz `valorPorAcao(gr) == preco`, por bisseção em `[−0,5; 1,0]`, 100 iterações ou |Δ| < 1e-7. Se
  `valorPorAcao(−0,5) − preco` e `valorPorAcao(1,0) − preco` tiverem o mesmo sinal → `null`. (Com FCFF0 > 0 a função é crescente em `gr`.)
- **Sensibilidade**: matriz 5 × 5, linhas WACC + {−0,02; −0,01; 0; +0,01; +0,02}, colunas g + {−0,01; −0,005; 0; +0,005; +0,01}; célula com WACC ≤ g → `null`.
- **Cenários**: pessimista `gr × 0,5`, base `gr`, otimista `gr × 1,5` (mesmos WACC e g).

### 2.9 Mercado e risco (histórico diário)

Série = a lista inteira passada à função (a app pede `range=2y`, `interval=1d`), por ordem cronológica, sem os dias com `close == null`. Preço = `close`
do gráfico do Yahoo (já ajustado a splits, **não** a dividendos; não usar `adjclose`, para os golden baterem). 252 sessões por ano.
- Retornos simples diários `r_i = P_i / P_{i−1} − 1`. **Volatilidade anualizada** = desvio-padrão amostral (n − 1) dos `r_i` × √252.
- **Drawdown máximo** = mínimo de `P_i / max(P_0..P_i) − 1` (≤ 0).
- **Beta** = cov(r_ativo, r_mercado) / var(r_mercado), ambos amostrais (n − 1), com as séries **alinhadas por data de calendário local da bolsa**
  (`timestamp + meta.gmtoffset`, em UTC → data), não pelo timestamp bruto (NVD.DE e ^GSPC nunca têm o mesmo timestamp). Retornos calculados entre datas
  comuns consecutivas. Correlação de Pearson com as mesmas séries. Índice por omissão ^GSPC.
- **52 semanas**: `MarketSnapshot.fiftyTwoWeekHigh/Low` (máximos/mínimos intradiários da fonte, na moeda de reporte) e distância ao máximo =
  `MarketSnapshot.price / fiftyTwoWeekHigh − 1`. Se faltarem, máximo/mínimo dos `close` do gráfico com data ≥ última data − 365 dias e distância =
  **último `close` do gráfico** / máximo − 1. Nunca misturar o preço do snapshot (moeda de reporte) com closes do gráfico (moeda de cotação; NVD.DE: EUR vs USD).
- **Retornos 1D, 1S, 1M, 3M, 6M, 1A, 3A, 5A**: `P_last / P_ref − 1`, com `P_ref` o último `close` com data ≤ data do último − (1, 7 dias; 1, 3, 6 meses; 1, 3, 5 anos);
  se não houver → `null`. **YTD**: `P_ref` = último `close` do ano civil anterior.
- **SMA 50/200** = média dos últimos 50/200 `close` (menos pontos → `null`).
- **RSI(14) de Wilder**, sobre **variações de preço** (não retornos): `c_i = P_i − P_{i−1}`, `ganho_i = max(c_i, 0)`, `perda_i = max(−c_i, 0)`;
  `ag = média(ganho_1..ganho_14)`, `al = média(perda_1..perda_14)`; para i ≥ 15: `ag = (ag·13 + ganho_i)/14`, `al = (al·13 + perda_i)/14`;
  `RSI = al == 0 ? 100 : 100 − 100/(1 + ag/al)`. Menos de 15 preços → `null`.
- **Sharpe** = `(média(r)·252 − rf) / (sd(r)·√252)`, rf = 0,04 (a mesma taxa sem risco do CAPM).
- **Sortino** = `(média(r)·252 − rf) / (DD·√252)`, com `DD = sqrt( Σ_{todos os i} min(r_i, 0)² / N )`: N = número **total** de retornos e alvo (MAR) = 0
  (Sortino e Price 1994). **Não** é o desvio-padrão dos retornos negativos. DD = 0 → `null`.
- **VaR histórico 95 %** (1 dia) = percentil 5 dos `r_i` com interpolação linear (`pos = 0,05·(n−1)`, interpola entre `sorted[floor(pos)]` e o seguinte;
  = numpy `linear` = Excel `PERCENTIL.INC`). Devolve-se o retorno (negativo, p. ex. −0,027); a interface mostra-o como perda.
- **Volume médio** = `MarketSnapshot.averageVolume` (média de 3 meses da fonte); se faltar, média dos últimos 63 volumes.
- **XIRR**: `r` tal que `Σ c_i / (1+r)^((d_i − d_0)/365) = 0` (base 365 dias, como o Excel), `d_0` = data do primeiro fluxo. Bisseção em `[−0,9999; 10]`,
  200 iterações; se o VPL não mudar de sinal no intervalo → `null` (exige pelo menos um fluxo negativo e um positivo).
- **TWR**: sub-períodos delimitados pelos fluxos externos. Com `V_i⁻` = valor imediatamente antes do fluxo `CF_i` (no fim do sub-período i) e
  `CF_0` = valor inicial: `r_i = V_i⁻ / (V_{i−1}⁻ + CF_{i−1}) − 1` (com `V_0⁻ = 0`), e `TWR = Π(1 + r_i) − 1`. Exemplo golden: 1000 → 1100, entra 500, → 1500:
  `(1100/1000)·(1500/1600) − 1 = 0,03125`.
- **Carteira**: HHI = Σ peso² (pesos por valor de mercado, soma 1); concentração top-N = soma dos N maiores pesos; correlação média = média das correlações de
  Pearson de todos os pares de posições (retornos diários alinhados por data).

---

## Parte 3: disponibilidade dos dados gratuitos

Fonte: Yahoo sem chave (preços, eventos, demonstrações ~4 anos anuais + trimestres + TTM, perfil via crumb). Finnhub só com chave do utilizador.

| Secção | Estado |
|---|---|
| 1 Margens | Disponível |
| 2 Crescimento | YoY e CAGR 3 anos: disponível. CAGR 5/10 anos e crescimento orgânico: **não disponível** (Finnhub poderia dar 5 anos) |
| 3 Retorno | ROE, ROA, ROIC, DuPont, ROTE: disponível. WACC: calculado com premissas editáveis |
| 4 Eficiência | Disponível (bancos: n/a) |
| 5 Liquidez | Disponível (bancos: n/a, sem ativo/passivo corrente) |
| 6 Solvência | Disponível, **exceto** maturidades da dívida e dívida de taxa variável (só nas notas do relatório): não disponível. **Locações (IFRS 16): não garantido**: `TotalDebt` do Yahoo inclui-as nalguns anos e noutros não (ver 2.3); não se somam à mão |
| 7 Fluxo de caixa | Disponível. Capex de manutenção e owner earnings: aproximação |
| 8 Por ação | Disponível |
| 9 Avaliação | Disponível (P/E trailing e TTM). **Forward P/E: melhor esforço** (estimativa de analistas da fonte, `quoteSummary.defaultKeyStatistics.forwardEps`/`forwardPE`, via crumb, como o short interest; exige acrescentar `forwardEps` a `MarketSnapshot`: alteração do contrato partilhado, a decidir pelo orquestrador; até lá `null`). **CAPE: não disponível**. Fórmula mágica sem ranking (ROC de Greenblatt e earnings yield calculáveis) |
| 10 Dividendos | Disponível. Anos consecutivos de aumento e crescimento do dividendo exigem o histórico longo de eventos (`range=max`, `events=div`), não o gráfico de 2 anos |
| 11 Scores | Altman (original e Z″), Piotroski, Beneish: disponíveis em não financeiras. Bancos/financeiras/imobiliário: Altman "não aplicável"; Piotroski parcial (testes 6 e 8 sem dados → "f de n"); Beneish `null` (sem margem bruta) |
| 12 DCF | Disponível com premissas editáveis |
| 13 Mercado | Beta, volatilidade, drawdown, 52 semanas, volume, RSI, Sharpe, Sortino, VaR: disponível. Short interest e insiders: melhor esforço (crumb). **Spread bid-ask: não disponível** (o contrato não tem bid/ask) |
| 14 Qualidade do negócio | **Não disponível** (qualitativo). Só ROIC/margens ao longo de 4 anos (a partir das secções 1 e 3) |
| 15 Gestão e governo | **Não disponível**, exceto % de insiders (quando a fonte dá) |
| 16 Por setor | Bancos: margem financeira (`netInterestIncome`, valor absoluto) e ROTE, P/TBV. Software: regra dos 40 = crescimento YoY da receita + margem de FCF (em pontos %), SBC/receita, margem bruta. Farma: I&D/receita. Sem lucros: cash runway (meses) = `cashAndShortTermInvestments / (−FCF_TTM / 12)` se FCF_TTM < 0 (senão "não aplicável"), e diluição. **Não disponível**: NIM, cost-to-income, custo do risco, CET1, NPL, LCR, combined ratio, float, FFO/AFFO, NAV, cap rate, LTV, RAB, ARR, NRR, CAC, LFL, vendas/m², rNPV, SOTP |
| 17 Alertas | Calculáveis a partir das outras métricas (ver `sector_redflags.dart`); "mudanças de políticas contabilísticas" e "aquisições em série" só pelo indício `acquisitions` |

Métricas **não disponíveis** devem existir na interface como "não disponível com dados gratuitos", nunca com um valor inventado nem uma aproximação escondida.

---

## Parte 4: regras transversais

- **Moeda**: as demonstrações estão na moeda de reporte; os dados de mercado (`MarketSnapshot`) são convertidos pela camada de dados para essa mesma moeda
  (`fxApplied`). As fórmulas nunca convertem moeda. Há teste com um título cruzado (NVD.DE: cota em EUR, reporta em USD).
- **Símbolo de análise**: nunca se corta o sufixo à sorte (`APC.DE` não é `APC`). Resolve-se por (1) o símbolo da posição, se devolver dados;
  (2) pesquisa por ISIN ou nome e confirmação de que o nome devolvido corresponde; (3) o utilizador confirma ou edita um "símbolo de análise" por ativo.
- **Tipo de ativo**: só `QuoteType.equity` tem análise fundamental. ETFs, fundos, índices e cripto só têm métricas de mercado e de risco.
- **TTM**: fluxos = soma dos últimos 4 trimestres (ou `trailing*` da fonte); balanço = último trimestre.
- **Bancos e financeiras**: não têm custo das vendas, EBIT, ativo/passivo corrente; as métricas que dependem destes dão `null` (não são erros).
- **Testes**: valores esperados vêm de `test/fixtures/golden_aapl.json` (script independente) e de manuais; fixtures reais em `test/fixtures/yahoo/`.

---

## Revisão (verificação técnica das fórmulas, 2026-11)

Erros corrigidos (o texto anterior levava a resultados errados):
1. **Altman Z″**: estava `3,25 + 6,56·X1 + …` com as zonas 2,6 / 1,1. As zonas 2,6 / 1,1 são do Z″ **sem** constante (Altman 1995; Altman 2000,
   "Predicting financial distress of companies: revisiting the Z-score and ZETA models"). A constante 3,25 é a do "EM Score" (Altman, Hartzell e Peck 1995),
   que tem outra escala (equivalência a ratings, ≈ 5,85 = BBB). Com a constante e estas zonas, toda a empresa ficaria 3,25 pontos mais "segura". Corrigido para Z″ sem constante.
2. **Altman em bancos/REITs**: o texto mandava usar Z″ em bancos e REITs, contra a Parte 3 e contra Altman (os modelos excluem financeiras). Agora "não aplicável",
   com um mapeamento explícito setor → modelo.
3. **Sortino**: "desvio só dos retornos negativos" é o erro clássico. O downside deviation de Sortino e Price (1994) é `sqrt(Σ min(r−MAR,0)²/N)` sobre **todos** os N retornos. Fixado MAR = 0.
4. **RSI no script golden**: era calculado sobre retornos percentuais. O RSI de Wilder (1978) usa variações absolutas de preço. Corrigido; `rsi14` passou de 60,61 para 60,21.
5. **Locações (IFRS 16)**: o texto dizia que `totalDebt` "já as inclui". Nos dados AAPL isso só acontece em 2022 (132 480 = 98 959 + 21 110 + 12 411). Em 2023,
   111 088 = 95 281 + 15 807, sem os 12 842 de `CapitalLeaseObligations`. Agora "não garantido pela fonte" e proibido somar `leaseLiabilities` à mão (dupla contagem em anos como 2022).
6. **Forward P/E**: a Parte 3 dizia "não disponível". O `quoteSummary` (crumb) tem `forwardEps`/`forwardPE` (ver `test/fixtures/yahoo/quotesummary_NVDA.json`).
   Agora "melhor esforço", mas só depois de acrescentar `forwardEps` ao `MarketSnapshot` (alteração do contrato: decisão do orquestrador).
7. **Taxa de imposto**: o texto dizia "limitada a [0; 0,5]" (um clamp) e, ao mesmo tempo, "fora do intervalo → 21 %" (um fallback). Fica o fallback, com pseudo-código (também quando o resultado antes de impostos é ≤ 0).
   O script agora aplica a mesma regra. A AAPL (15,6 %) não muda.
8. **Fórmula mágica**: o texto devolvia o ROIC, mas Greenblatt (2005, *The Little Book That Beats the Market*) usa o ROC = EBIT / (fundo de maneio líquido + imobilizado líquido),
   com o fundo de maneio negativo tratado como zero. Este é calculável com os campos do contrato.
9. **Recompras líquidas**: "em positivo" com `abs` trocaria o sinal de uma emissão líquida. Além disso, `RepurchaseOfCapitalStock` é bruto. Agora
   `netBuybacks = −buybacks − (stockIssuance ?? 0)`, que pode ser negativo.

Ambiguidades resolvidas (os implementadores divergiriam):
10. **Piotroski (2000)**: o ROA, o CFO, os accruals e a rotação usam o ativo do **início** do ano, e a alavancagem usa a dívida de LP / ativo **médio**
    (artigo: "change in the ratio of total long-term debt to average total assets"). O teste 4 (accruals) é equivalente a CFO > resultado líquido. O teste 7 é uma aproximação
    (o artigo testa a emissão de ações ordinárias). O script segue agora o artigo. Os 9 resultados da AAPL não mudam (F = 8, falha só o teste 4, porque CFO 111,5 < resultado 112,0 mil M).
11. **Beneish (1999)**: os coeficientes e as definições de DSRI, GMI, AQI (versão 1999, sem títulos), SGI, DEPI, SGAI e LVGI estão corretos. O limiar fica em −1,78
    (Parte 1; Beneish, Lee e Nichols 2013). As fontes secundárias divergem sobre qual dos dois, −1,78 ou −2,22, é o do artigo de 1999; o −2,22 não se usa. O TATA por fluxos de caixa é a variante de Beneish, Lee e Nichols (2013);
    o artigo de 1999 usa accruals de balanço, para os quais faltam campos (impostos a pagar). Sem `?? 0` na dívida LP (o script tinha `or 0`): dado em falta → `null`.
12. **Sinal de `changeInWorkingCapital`** no FCFF e nas owner earnings: escrito como "+ changeInWorkingCapital tal como vem" (o sinal de caixa do Yahoo), para evitar uma dupla negação.
    Na AAPL 2025 o valor é −25 000 M (FCFF 86,3 mil M).
13. **DCF**: faltavam vários elementos, que ficam agora fixados: a base FCFF₀ (`fin.latest`; ≤ 0 → `null`), o g terminal por omissão (2,5 %, o do teste), o crescimento explícito por omissão quando o CAGR é `null`
    (5 %, escolha nova), o número de ações, os minoritários e preferenciais (subtraídos, `null` → 0), o Kd com fallback, os limites da bisseção do DCF inverso [−50 %; 100 %] e a matriz 5×5 com as células WACC ≤ g a `null`.
14. **Base TTM vs anual e "médio"**: há agora uma tabela que diz que métricas usam `fin.latest` e quais as anuais, a regra do período anterior para médias com TTM
    (fecho 320–410 dias antes) e a indicação de que os testes golden usam `annual.last`/`annual[len-2]`.
15. **EBIT**: a Parte 1 define EBIT = resultado operacional, mas o getter `ebitOrOperating` do contrato prefere o `EBIT` do Yahoo (que inclui itens não operacionais).
    Fixado `operatingIncome ?? ebit`. O script usava `OperatingIncome` nas margens e no ROIC e `EBIT` no Altman e na cobertura de juros. Foi uniformizado (na AAPL os dois coincidem).
16. **Mercado**: o beta passa a ser alinhado por data local da bolsa (com timestamps brutos, NVD.DE × ^GSPC não teria nenhuma data comum). Ficam também fixados o `close` (não o `adjclose`) em todas as métricas,
    a anualização do Sharpe, o método do percentil e o sinal do VaR, a fórmula do TWR (com exemplo golden), a janela das 52 semanas e as datas de referência dos retornos 1D–5A/YTD.
17. **Dividendos**: os anos consecutivos de aumento exigem o histórico `range=max` de eventos e só anos civis completos.

Verificado sem alterações: Altman original (coeficientes 1,2/1,4/3,3/0,6/1,0; X4 = capitalização / passivo total contabilístico; zonas 2,99/1,81), WACC, CAPM, Gordon, desconto de fim de ano,
CAGR, Sloan por fluxos de caixa, conversão de caixa, PEG, EV, XIRR (base 365, como o Excel), volatilidade (desvio amostral × √252), beta (cov/var amostrais), RSI com médias de Wilder (inicialização por média simples), drawdown.

Script `tool/golden_metrics.py`: foram aplicadas as correções 4, 7, 10, 11, 15 e 16, e acrescentados valores golden para o rácio rápido, FCFF, owner earnings, ROC de Greenblatt, Z″, EV,
earnings yield, shareholder yield, Sharpe, Sortino, VaR 95 % e TWR. Ordens de grandeza da AAPL (FY2025): margem bruta 46,9 %; ROE 171 % (capitais próprios encolhidos pelas recompras);
ROIC 83 %; Piotroski 8/9; Beneish −2,29 (abaixo de −1,78, sem alerta); Z 8,6 (com capitalização de 3 biliões); Z″ 2,31 (zona cinzenta, por causa do fundo de maneio e dos resultados retidos negativos,
um efeito conhecido das recompras); beta 1,07; volatilidade 29 %.
18. **52 semanas, moeda**: o fallback a partir dos closes do gráfico (moeda de cotação) não pode usar o preço do `MarketSnapshot` (moeda de reporte, Parte 4).
    A distância ao máximo usa agora o par coerente: snapshot com snapshot, ou gráfico com gráfico.

### Resolução posterior (orquestrador)
- O getter `FinPeriod.ebitOrOperating` do contrato já usa `operatingIncome ?? ebit` (ordem da especificação), pelo que as notas das secções 2.0 e Revisão (ponto 15) sobre a prioridade inversa estão ultrapassadas.
- `FinPeriod` tem `netBuybacks` (= `-buybacks - stockIssuance`), `MarketSnapshot` tem `forwardEps`, e `Financials.currency` vem vazia quando a fonte não tem dados.
