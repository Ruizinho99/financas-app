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

Notação: `t` = último período (TTM ou último anual conforme a métrica), `t-1` = período anterior (anual). "Médio" = média entre `t` e `t-1`
(se só houver `t`, usa `t`: ver `avgOf`). Taxas em fração. Qualquer divisão por zero ou dado em falta dá `null`.

**Taxa de imposto efetiva** = `taxProvision / pretaxIncome`, limitada a [0, 0,5]; se faltar ou der fora do intervalo, 21 %.

**ROIC** = `NOPAT / capital investido médio`, com NOPAT = EBIT × (1 − taxa) e capital investido = capitais próprios + dívida financeira − caixa
(a lista fala em "caixa excedentário": usa toda a caixa e equivalentes). Capital investido ≤ 0 → `null`.

**Owner earnings** = resultado líquido + D&A − capex de manutenção ± variação do fundo de maneio. Capex de manutenção
é desconhecido: usa `min(|capex|, D&A)` como aproximação (documentar na métrica). Fundo de maneio: `changeInWorkingCapital` do fluxo de caixa (já com o sinal de caixa).

**Capex de manutenção vs crescimento**: manutenção ≈ `min(|capex|, D&A)`; crescimento = `|capex| − manutenção`.

**EV** = capitalização + dívida total − caixa e equivalentes + interesses minoritários + ações preferenciais (os dados de mercado já vêm na moeda de reporte).

**P/E (TTM)** = preço / EPS TTM. Trailing = último exercício anual. Forward: não disponível (sem estimativas gratuitas). CAPE: não disponível (precisa de 10 anos).
**PEG** = P/E / (CAGR do EPS em %), com o CAGR de 3 anos dos exercícios anuais (ou 2 se só houver 3). EPS decrescente → `null`.
**Fórmula mágica** = (EBIT / EV) e ROIC; devolve ambos (a classificação por ranking exige um universo e não se faz).

**Crescimento sustentável** = ROE × (1 − payout), payout = dividendos pagos / resultado líquido.
**Alavancagem operacional** = (EBIT_t/EBIT_{t-1} − 1) / (receita_t/receita_{t-1} − 1); denominador 0 → `null`.
**CAGR** com N anos = (último / N anos antes)^(1/N) − 1, só se ambos os valores forem > 0. Disponível 3 anos (4 pontos anuais). 5 e 10 anos: `null` (sem dados gratuitos).
**Crescimento orgânico**: não disponível (sem separar aquisições nem câmbio); devolve `null`.

**Liquidez** como na lista. **Dívida líquida** = dívida financeira total − caixa e equivalentes (a lista pede "inclui locações na dívida em IFRS 16":
usa `totalDebt` da fonte, que já as inclui; `leaseLiabilities` só se `totalDebt` não as incluir, o que a fonte não indica: não somar).
**Cobertura de juros** = EBIT / juros (`interestExpense`; se faltar, `interestPaid`).

**Conversão de caixa** = CFO / resultado líquido (resultado ≤ 0 → `null`). **Sloan** = (resultado − CFO) / ativo médio.
**EPS** = `dilutedEps` (ou resultado / ações diluídas). **Diluição** = ações_t / ações_{t-1} − 1 (`sharesOutstanding`).
**BVPS** = capitais próprios / ações em circulação; **TBVPS** = valor contabilístico tangível / ações.

**Shareholder yield** = (dividendos pagos + recompras líquidas, em positivo) / capitalização.
**Anos consecutivos de aumento do dividendo** e crescimento: a partir dos dividendos por ação do histórico de preços (eventos `div`), somados por ano civil completo.

### Altman Z-Score
Original (indústria cotada): `Z = 1,2·X1 + 1,4·X2 + 3,3·X3 + 0,6·X4 + 1,0·X5`, com X1 = fundo de maneio / ativo total; X2 = resultados retidos / ativo total;
X3 = EBIT / ativo total; X4 = capitalização bolsista / passivo total; X5 = receita / ativo total. Zonas: > 2,99 segura; 1,81–2,99 cinzenta; < 1,81 risco.
Para não industriais (serviços, software, bancos, REITs) usa **Z″** (sem X5, com capitais próprios contabilísticos):
`Z″ = 3,25 + 6,56·X1 + 3,26·X2 + 6,72·X3 + 1,05·X4″`, X4″ = capitais próprios contabilísticos / passivo total. Zonas: > 2,6 segura; 1,1–2,6 cinzenta; < 1,1 risco.
A função devolve o original e o Z″; a interface mostra o adequado ao setor (industrial → original; resto → Z″).

### Piotroski F-Score (1 ponto por teste verdadeiro, total 0–9; períodos `t` e `t-1` anuais)
1. ROA > 0 (resultado líquido / ativo total).
2. CFO > 0.
3. ROA_t > ROA_{t-1}.
4. Qualidade: CFO / ativo total > ROA (os fluxos superam o resultado).
5. Alavancagem a descer: dívida de longo prazo / ativo total_t < _{t-1}.
6. Liquidez a subir: rácio corrente_t > _{t-1}.
7. Sem emissão de ações: ações em circulação_t ≤ _{t-1}.
8. Margem bruta_t > _{t-1}.
9. Rotação do ativo (receita / ativo total)_t > _{t-1}.
Se faltar um dado de um teste, esse teste não conta e o resultado indica quantos testes foram avaliáveis (`n_avaliados`).
Classificação: 8–9 forte; 0–3 fraco.

### Beneish M-Score (8 índices, anual `t` vs `t-1`)
- DSRI = (receber_t / receita_t) / (receber_{t-1} / receita_{t-1})
- GMI = margem bruta_{t-1} / margem bruta_t
- AQI = [1 − (ativo corrente_t + PPE líquido_t) / ativo total_t] / [1 − (ativo corrente_{t-1} + PPE líquido_{t-1}) / ativo total_{t-1}]
- SGI = receita_t / receita_{t-1}
- DEPI = [D&A_{t-1} / (D&A_{t-1} + PPE_{t-1})] / [D&A_t / (D&A_t + PPE_t)]
- SGAI = (SG&A_t / receita_t) / (SG&A_{t-1} / receita_{t-1})
- LVGI = [(passivo corrente_t + dívida longo prazo_t) / ativo total_t] / [(passivo corrente_{t-1} + dívida longo prazo_{t-1}) / ativo total_{t-1}]
- TATA = (resultado líquido_t − CFO_t) / ativo total_t  (versão por fluxos de caixa)
`M = −4,84 + 0,920·DSRI + 0,528·GMI + 0,404·AQI + 0,892·SGI + 0,115·DEPI − 0,172·SGAI + 4,679·TATA − 0,327·LVGI`.
Acima de −1,78 é alerta. Se faltar um índice, `null` (o modelo precisa dos 8).

### DCF
- FCFF = EBIT × (1 − t) + D&A − |capex| − ΔNWC (ΔNWC = aumento do fundo de maneio operacional = −`changeInWorkingCapital` do fluxo de caixa).
- Projeção explícita de N anos (5 por omissão) com taxa de crescimento (entrada; por omissão o CAGR de 3 anos da receita limitado a [0 %, 15 %]).
- Valor terminal de Gordon = FCF_N × (1 + g) / (WACC − g); exige WACC > g (senão `null`).
- Valor por ação = (Σ fluxos descontados + VT descontado − dívida líquida [− minoritários − preferenciais]) / ações. Desconto de fim de ano (ano i → /(1+WACC)^i).
- Ke (CAPM) = taxa sem risco + beta × prémio de risco do mercado (por omissão 4,0 % e 5,5 %, editáveis). Kd = juros / dívida média, ou 5 % se faltar.
- WACC = E/(D+E)·Ke + D/(D+E)·Kd·(1 − t), com E = capitalização e D = dívida total.
- Margem de segurança = 1 − preço / valor intrínseco. **DCF inverso**: o crescimento explícito (bisseção) que faz o valor por ação igualar o preço.
- Sensibilidade: matriz de valor por ação para WACC ±1 e ±2 pontos × g ±0,5 e ±1 ponto. Cenários: pessimista (crescimento × 0,5), base, otimista (crescimento × 1,5).

### Mercado e risco (a partir do histórico diário; 252 dias de negociação por ano)
- Retornos simples diários. **Volatilidade anualizada** = desvio-padrão amostral × √252. **Drawdown máximo** = mínimo de (preço / máximo anterior − 1).
- **Beta** = cov(ativo, mercado) / var(mercado) (datas alinhadas). Correlação de Pearson. Índice por omissão ^GSPC (ou o definido pelo utilizador).
- 52 semanas: máximo e mínimo do último ano e distância ao máximo. Retornos 1D, 1S, 1M, 3M, 6M, YTD, 1A, 3A, 5A.
- SMA 50/200, RSI(14) com médias de Wilder. **Sharpe** = (retorno anualizado − taxa sem risco) / volatilidade; **Sortino** usa o desvio só dos retornos negativos. **VaR histórico 95 %** = percentil 5 dos retornos diários.
- **XIRR**: taxa que anula o VPL dos fluxos datados, `Σ c_i / (1+r)^((d_i − d_0)/365) = 0` (bisseção). **TWR**: produto de (1 + retorno de cada sub-período entre fluxos) − 1.
- Carteira: **HHI** = Σ peso² (pesos por valor); concentração top-N; correlação média entre posições.

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
| 6 Solvência | Disponível, **exceto** maturidades da dívida e dívida de taxa variável (só nas notas do relatório): não disponível |
| 7 Fluxo de caixa | Disponível. Capex de manutenção: aproximação |
| 8 Por ação | Disponível |
| 9 Avaliação | Disponível (P/E trailing e TTM). **Forward P/E, CAPE: não disponível**; fórmula mágica sem ranking |
| 10 Dividendos | Disponível |
| 11 Scores | Altman, Piotroski, Beneish: disponíveis em empresas industriais; bancos/financeiras: campos em falta → `null` |
| 12 DCF | Disponível com premissas editáveis |
| 13 Mercado | Beta, volatilidade, drawdown, 52 semanas, volume: disponível. Short interest e insiders: melhor esforço (crumb). **Spread bid-ask: não disponível** |
| 14 Qualidade do negócio | **Não disponível** (qualitativo). Só ROIC/margens ao longo de 4 anos (a partir das secções 1 e 3) |
| 15 Gestão e governo | **Não disponível**, exceto % de insiders (quando a fonte dá) |
| 16 Por setor | Bancos: margem financeira (`netInterestIncome`) e ROTE, P/TBV. Software: regra dos 40 (crescimento + margem de FCF), SBC/receita, margem bruta. Farma: I&D/receita. Sem lucros: cash runway e diluição. **Não disponível**: NIM, CET1, NPL, LCR, combined ratio, FFO/AFFO, NAV, RAB, ARR, NRR, CAC, LFL, rNPV, SOTP |
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
