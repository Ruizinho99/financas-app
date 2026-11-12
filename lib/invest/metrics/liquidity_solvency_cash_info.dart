/// Fichas das métricas de liquidez, solvência, fluxo de caixa e por ação (ver `liquidity_solvency_cash.dart`).
/// Uma ficha por cada `Metric.key` devolvida, incluindo as "não disponível" (com `MetricAvailability.unavailable`).
library;

import 'metric_info.dart';

const List<MetricInfo> liquiditySolvencyCashInfo = [
  // ------------------------------------------------------------ 5. Liquidez
  MetricInfo(
    key: 'current_ratio',
    namePt: 'Rácio corrente',
    nameEn: 'Current ratio',
    formula: 'Ativo corrente / Passivo corrente',
    meaningPt:
        'Quantas vezes o ativo de curto prazo cobre o passivo de curto prazo.',
    meaningEn: 'How many times short-term assets cover short-term liabilities.',
    readPt:
        'Acima de 1 a empresa cobre as obrigações de curto prazo com ativos de curto prazo. Muito abaixo de 1 pede atenção, '
        'mas o normal depende do setor (retalho e restauração operam com valores baixos) e compara-se com pares.',
    readEn:
        'Above 1, short-term assets cover short-term obligations. Well below 1 calls for attention, but normal values depend on the '
        'sector (retail and restaurants run low) and should be compared with peers.',
    cautionPt: 'Inclui inventários, que podem não ser líquidos. Para a liquidez imediata, ver o rácio rápido. Não aplicável a bancos e financeiras: dá null (sem custo das vendas, resultado operacional nem ativo corrente, a métrica não tem o mesmo significado). Usa o balanço do último trimestre e os fluxos dos últimos 12 meses (TTM) quando existem, senão o último exercício anual.',
    cautionEn: 'Includes inventories, which may not be liquid. For immediate liquidity, see the quick ratio. Not applicable to banks and financial companies: it is null (without cost of sales, operating income or current assets the metric does not have the same meaning). Uses the latest quarter balance sheet and the last 12 months of flows (TTM) when available, otherwise the last fiscal year.',
  ),
  MetricInfo(
    key: 'quick_ratio',
    namePt: 'Rácio rápido',
    nameEn: 'Quick ratio',
    formula: '(Caixa + Investimentos de curto prazo + Contas a receber) / Passivo corrente',
    meaningPt:
        'Capacidade de pagar o passivo de curto prazo sem vender inventários.',
    meaningEn:
        'Ability to pay short-term liabilities without selling inventory.',
    readPt:
        'Acima de 1 a empresa paga o passivo corrente só com dinheiro e créditos a receber. Abaixo de 1 não é necessariamente mau '
        'em negócios com fluxos de caixa previsíveis e passivo de curto prazo rolado (como a grande distribuição).',
    readEn:
        'Above 1, the company can pay current liabilities with cash and receivables alone. Below 1 is not necessarily bad in businesses '
        'with predictable cash flows and rolling short-term debt (such as large retailers).',
    cautionPt: 'Usa o caixa e os investimentos de curto prazo tal como a fonte os reporta. Não aplicável a bancos e financeiras: dá null (sem custo das vendas, resultado operacional nem ativo corrente, a métrica não tem o mesmo significado). Usa o balanço do último trimestre e os fluxos dos últimos 12 meses (TTM) quando existem, senão o último exercício anual.',
    cautionEn:
        'Uses cash and short-term investments as the source reports them. Not applicable to banks and financial companies: it is null (without cost of sales, operating income or current assets the metric does not have the same meaning). Uses the latest quarter balance sheet and the last 12 months of flows (TTM) when available, otherwise the last fiscal year.',
  ),
  MetricInfo(
    key: 'cash_ratio',
    namePt: 'Rácio de caixa',
    nameEn: 'Cash ratio',
    formula: 'Caixa / Passivo corrente',
    meaningPt: 'Parte do passivo de curto prazo que se pagaria só com caixa e equivalentes.',
    meaningEn: 'Share of short-term liabilities that could be paid with cash and equivalents alone.',
    readPt:
        'O valor mais conservador da liquidez. Valores típicos ficam entre 0,2 e 0,5; muito baixos num setor cíclico são um sinal de alerta. '
        'Depende muito do setor e compara-se com pares.',
    readEn:
        'The most conservative liquidity measure. Typical values are between 0.2 and 0.5; very low values in a cyclical sector are a warning sign. '
        'It depends heavily on the sector and should be compared with peers.',
    cautionPt: 'Não penaliza uma empresa que tenha linhas de crédito disponíveis e não usadas, que a fonte não reporta. Não aplicável a bancos e financeiras: dá null (sem custo das vendas, resultado operacional nem ativo corrente, a métrica não tem o mesmo significado). Usa o balanço do último trimestre e os fluxos dos últimos 12 meses (TTM) quando existem, senão o último exercício anual.',
    cautionEn: 'Does not credit undrawn credit lines, which the source does not report. Not applicable to banks and financial companies: it is null (without cost of sales, operating income or current assets the metric does not have the same meaning). Uses the latest quarter balance sheet and the last 12 months of flows (TTM) when available, otherwise the last fiscal year.',
  ),
  MetricInfo(
    key: 'working_capital',
    namePt: 'Fundo de maneio',
    nameEn: 'Working capital',
    formula: 'Ativo corrente − Passivo corrente',
    meaningPt: 'Montante do ativo de curto prazo que sobra depois de pagar o passivo de curto prazo.',
    meaningEn:
        'Amount of short-term assets left after paying short-term liabilities.',
    readPt:
        'Positivo: folga de liquidez. Negativo: a empresa financia-se com o passivo de curto prazo, o que é normal em alguns modelos '
        '(grande distribuição, software com receitas antecipadas). Lê-se em relação à receita.',
    readEn:
        'Positive: liquidity cushion. Negative: the company is financed by short-term liabilities, which is normal in some models '
        '(large retail, software with upfront billing). Read it relative to revenue.',
    cautionPt: 'Valor absoluto na moeda de reporte: não é comparável entre empresas de dimensões diferentes sem normalizar. Não aplicável a bancos e financeiras: dá null (sem custo das vendas, resultado operacional nem ativo corrente, a métrica não tem o mesmo significado). Usa o balanço do último trimestre e os fluxos dos últimos 12 meses (TTM) quando existem, senão o último exercício anual.',
    cautionEn: 'Absolute value in the reporting currency: not comparable across companies of different sizes without normalising. Not applicable to banks and financial companies: it is null (without cost of sales, operating income or current assets the metric does not have the same meaning). Uses the latest quarter balance sheet and the last 12 months of flows (TTM) when available, otherwise the last fiscal year.',
  ),

  // ------------------------------------------------------------ 6. Solvência e dívida
  MetricInfo(
    key: 'net_debt',
    namePt: 'Dívida líquida',
    nameEn: 'Net debt',
    formula: 'Dívida financeira − Caixa e equivalentes',
    meaningPt: 'Dívida que sobra depois de descontar o caixa.',
    meaningEn: 'Debt remaining after deducting cash.',
    readPt: 'Negativa significa caixa líquida (a empresa tem mais caixa do que dívida). Positiva, lê-se com EBITDA e FCF.',
    readEn: 'Negative means net cash (more cash than debt). Positive is read together with EBITDA and FCF.',
    cautionPt:
        'A dívida financeira vem do Yahoo tal como está. As locações (IFRS 16) entram nalguns anos e noutros não: não se somam à mão, '
        'para não contar duas vezes. Não aplicável a bancos e financeiras: dá null (sem custo das vendas, resultado operacional nem ativo corrente, a métrica não tem o mesmo significado). Usa o balanço do último trimestre e os fluxos dos últimos 12 meses (TTM) quando existem, senão o último exercício anual.',
    cautionEn:
        'Financial debt comes from Yahoo as reported. Leases (IFRS 16) are included in some years and not in others: they are not added by hand, '
        'to avoid double counting. Not applicable to banks and financial companies: it is null (without cost of sales, operating income or current assets the metric does not have the same meaning). Uses the latest quarter balance sheet and the last 12 months of flows (TTM) when available, otherwise the last fiscal year.',
  ),
  MetricInfo(
    key: 'net_debt_to_ebitda',
    namePt: 'Dívida líquida / EBITDA',
    nameEn: 'Net debt / EBITDA',
    formula: 'Dívida líquida / EBITDA',
    meaningPt:
        'Quantos anos de EBITDA seriam precisos para pagar a dívida líquida.',
    meaningEn: 'How many years of EBITDA would be needed to repay net debt.',
    readPt:
        'Acima de 3 a 4 exige cautela, exceto em utilities e infraestruturas, cuja dívida é estável e contratada a longo prazo. '
        'Negativo significa caixa líquida.',
    readEn:
        'Above 3 to 4 calls for caution, except for utilities and infrastructure, whose debt is stable and long-term. '
        'Negative means net cash.',
    cautionPt: 'Com EBITDA negativo dá null: o rácio não tem significado. Não aplicável a bancos e financeiras: dá null (sem custo das vendas, resultado operacional nem ativo corrente, a métrica não tem o mesmo significado). Usa o balanço do último trimestre e os fluxos dos últimos 12 meses (TTM) quando existem, senão o último exercício anual. O EBITDA é EBIT + amortizações e depreciações, e não o campo EBITDA do Yahoo (inclui resultados não operacionais, e dava margens EBITDA acima da margem operacional + D&A); esse campo só é usado se faltar a D&A.',
    cautionEn: 'With negative EBITDA it is null: the ratio has no meaning. Not applicable to banks and financial companies: it is null (without cost of sales, operating income or current assets the metric does not have the same meaning). Uses the latest quarter balance sheet and the last 12 months of flows (TTM) when available, otherwise the last fiscal year. EBITDA is EBIT + depreciation and amortisation, not the Yahoo EBITDA field (it includes non-operating items and gave EBITDA margins above operating margin + D&A); that field is only used if D&A is missing.',
  ),
  MetricInfo(
    key: 'debt_to_equity',
    namePt: 'Dívida / Capitais próprios',
    nameEn: 'Debt / Equity',
    formula: 'Dívida financeira / Capitais próprios',
    meaningPt: 'Quanto da empresa é financiado por dívida comparado com os acionistas.',
    meaningEn: 'How much of the company is financed by debt compared with shareholders.',
    readPt:
        'Valores baixos (abaixo de 1) indicam uma estrutura conservadora. Valores altos são normais em empresas que recompram ações '
        'com dívida, e em bancos. Depende do setor.',
    readEn:
        'Low values (below 1) indicate a conservative structure. High values are normal for companies that buy back shares with debt, '
        'and for banks. It depends on the sector.',
    cautionPt: 'Capitais próprios negativos (muitas recompras ou prejuízos acumulados) dão null: o rácio deixa de ser interpretável. Não aplicável a bancos e financeiras: dá null (sem custo das vendas, resultado operacional nem ativo corrente, a métrica não tem o mesmo significado). Usa o balanço do último trimestre e os fluxos dos últimos 12 meses (TTM) quando existem, senão o último exercício anual.',
    cautionEn: 'Negative equity (heavy buybacks or accumulated losses) gives null: the ratio stops being interpretable. Not applicable to banks and financial companies: it is null (without cost of sales, operating income or current assets the metric does not have the same meaning). Uses the latest quarter balance sheet and the last 12 months of flows (TTM) when available, otherwise the last fiscal year.',
  ),
  MetricInfo(
    key: 'interest_coverage',
    namePt: 'Cobertura de juros',
    nameEn: 'Interest coverage',
    formula: 'EBIT / Juros (despesa de juros da demonstração de resultados; se faltar, juros pagos)',
    meaningPt:
        'Quantas vezes o resultado operacional cobre os juros da dívida.',
    meaningEn: 'How many times operating income covers interest on debt.',
    readPt: 'Abaixo de 1,5 a 2 o serviço da dívida fica apertado; acima de 5 há folga. Lê-se com a estabilidade dos resultados.',
    readEn: 'Below 1.5 to 2 debt service is tight; above 5 there is room. Read it with the stability of earnings.',
    cautionPt:
        'Usa os juros da demonstração de resultados e, se faltarem, os juros pagos. Sem juros na fonte (ou zero) dá null, '
        'o que não quer dizer que a empresa não tenha dívida. Usa o balanço do último trimestre e os fluxos dos últimos 12 meses (TTM) quando existem, senão o último exercício anual.',
    cautionEn:
        'Uses interest from the income statement and, if missing, interest paid. Without interest in the source (or zero) it is null, '
        'which does not mean the company has no debt. Uses the latest quarter balance sheet and the last 12 months of flows (TTM) when available, otherwise the last fiscal year.',
  ),
  MetricInfo(
    key: 'net_debt_to_fcf',
    namePt: 'Dívida líquida / FCF',
    nameEn: 'Net debt / FCF',
    formula: 'Dívida líquida / (CFO − Capex)',
    meaningPt:
        'Anos de fluxo de caixa livre necessários para pagar a dívida líquida.',
    meaningEn: 'Years of free cash flow needed to repay net debt.',
    readPt: 'Abaixo de 3 anos a dívida é facilmente paga com o FCF atual. Acima de 5 anos merece atenção.',
    readEn: 'Below 3 years, debt is easily repaid from current FCF. Above 5 years deserves attention.',
    cautionPt: 'Com FCF negativo ou nulo dá null (não há anos de FCF para pagar a dívida). Não aplicável a bancos e financeiras: dá null (sem custo das vendas, resultado operacional nem ativo corrente, a métrica não tem o mesmo significado). Usa o balanço do último trimestre e os fluxos dos últimos 12 meses (TTM) quando existem, senão o último exercício anual.',
    cautionEn: 'With zero or negative FCF it is null (there are no years of FCF to repay the debt). Not applicable to banks and financial companies: it is null (without cost of sales, operating income or current assets the metric does not have the same meaning). Uses the latest quarter balance sheet and the last 12 months of flows (TTM) when available, otherwise the last fiscal year.',
  ),
  MetricInfo(
    key: 'debt_maturities',
    namePt: 'Maturidades da dívida',
    nameEn: 'Debt maturities',
    formula: '',
    meaningPt: 'Calendário de vencimento da dívida, ano a ano.',
    meaningEn: 'Repayment schedule of the debt, year by year.',
    readPt: 'Não disponível com dados gratuitos. Está nas notas às demonstrações financeiras (relatório anual), que a fonte gratuita não traz.',
    readEn: 'Not available with free data. It is in the notes to the financial statements (annual report), which the free source does not provide.',
    availability: MetricAvailability.unavailable,
  ),
  MetricInfo(
    key: 'variable_rate_debt',
    namePt: 'Dívida a taxa variável',
    nameEn: 'Variable-rate debt',
    formula: '',
    meaningPt: 'Parte da dívida cujo juro acompanha as taxas de mercado.',
    meaningEn: 'Share of debt whose interest follows market rates.',
    readPt: 'Não disponível com dados gratuitos. Está nas notas às demonstrações financeiras (relatório anual).',
    readEn: 'Not available with free data. It is in the notes to the financial statements (annual report).',
    availability: MetricAvailability.unavailable,
  ),

  // ------------------------------------------------------------ 7. Fluxo de caixa e qualidade dos lucros
  MetricInfo(
    key: 'cfo',
    namePt: 'Fluxo de caixa operacional (CFO)',
    nameEn: 'Operating cash flow (CFO)',
    formula: '',
    meaningPt:
        'Dinheiro gerado pela atividade principal da empresa no período.',
    meaningEn: 'Cash generated by the main business activity in the period.',
    readPt: 'Deve ser positivo e crescer ao ritmo dos resultados. Um CFO fraco com lucros fortes é um sinal de alerta.',
    readEn: 'Should be positive and grow in line with earnings. Weak CFO with strong profits is a warning sign.',
    cautionPt: 'Valor absoluto na moeda de reporte.',
    cautionEn: 'Absolute value in the reporting currency.',
  ),
  MetricInfo(
    key: 'capex',
    namePt: 'Capex (investimento em ativos fixos)',
    nameEn: 'Capex (capital expenditure)',
    formula: '|Capex reportado|',
    meaningPt: 'Dinheiro gasto em ativos fixos (instalações, equipamento, software capitalizado).',
    meaningEn: 'Cash spent on fixed assets (facilities, equipment, capitalised software).',
    readPt:
        'Mostra-se em valor positivo (o que se gastou). Capex alto é normal em indústria e telecomunicações; em software e serviços, '
        'baixo.',
    readEn: 'Shown as a positive value (what was spent). High capex is normal in industry and telecoms; low in software and services.',
  ),
  MetricInfo(
    key: 'fcf',
    namePt: 'Fluxo de caixa livre (FCF)',
    nameEn: 'Free cash flow (FCF)',
    formula: 'CFO − Capex',
    meaningPt: 'Dinheiro que sobra depois do investimento em ativos fixos, disponível para dividendos, recompras ou dívida.',
    meaningEn: 'Cash left after capital investment, available for dividends, buybacks or debt.',
    readPt: 'Quanto mais positivo e crescente, melhor. Com FCF negativo, a empresa depende de dívida ou de capital novo.',
    readEn: 'The more positive and growing, the better. With negative FCF, the company relies on debt or new capital.',
    cautionPt: 'Se faltar o CFO ou o capex, usa-se o FCF reportado pela fonte. Não aplicável a bancos e financeiras: dá null (sem custo das vendas, resultado operacional nem ativo corrente, a métrica não tem o mesmo significado).',
    cautionEn:
        'If CFO or capex is missing, the FCF reported by the source is used. Not applicable to banks and financial companies: it is null (without cost of sales, operating income or current assets the metric does not have the same meaning).',
  ),
  MetricInfo(
    key: 'fcf_reported',
    namePt: 'FCF reportado pela fonte',
    nameEn: 'FCF as reported by the source',
    formula: '',
    meaningPt: 'O FCF que a fonte de dados publica, para comparar com o FCF calculado.',
    meaningEn: 'The FCF published by the data source, to compare with the calculated FCF.',
    readPt: 'Igual ao FCF calculado quando a fonte tem os dados completos. Diferenças indicam uma definição diferente da fonte.',
    readEn: 'Equal to the calculated FCF when the source has complete data. Differences point to a different definition at the source.',
  ),
  MetricInfo(
    key: 'fcf_after_sbc',
    namePt: 'FCF ajustado de remuneração em ações',
    nameEn: 'FCF after stock-based compensation',
    formula: 'FCF − Remuneração em ações (SBC)',
    meaningPt: 'FCF tratando a remuneração em ações como custo real.',
    meaningEn: 'FCF treating stock-based compensation as a real cost.',
    readPt: 'Em empresas tecnológicas a SBC pode ser grande. Se o FCF ajustado for muito inferior ao FCF, grande parte do FCF paga funcionários com ações.',
    readEn: 'In tech companies SBC can be large. If adjusted FCF is far below FCF, much of the FCF goes to paying staff in shares.',
    cautionPt: 'Não aplicável a bancos e financeiras: dá null (sem custo das vendas, resultado operacional nem ativo corrente, a métrica não tem o mesmo significado).',
    cautionEn: 'Not applicable to banks and financial companies: it is null (without cost of sales, operating income or current assets the metric does not have the same meaning).',
  ),
  MetricInfo(
    key: 'owner_earnings',
    namePt: 'Owner earnings (Buffett)',
    nameEn: 'Owner earnings (Buffett)',
    formula: 'Resultado líquido + D&A − Capex de manutenção ± Variação do fundo de maneio',
    meaningPt: 'Lucro que pode ser distribuído ao dono sem reduzir a capacidade da empresa de se manter.',
    meaningEn: 'Earnings that can be paid out to the owner without reducing the company’s ability to sustain itself.',
    readPt: 'Deve ser positivo e aproximar-se do resultado líquido. Muito abaixo do resultado indica investimento ou capital circulante pesado.',
    readEn: 'Should be positive and close to net income. Far below net income indicates heavy investment or working capital.',
    cautionPt: 'É uma aproximação: o capex de manutenção não é reportado, usa-se o mínimo entre capex e D&A. Não aplicável a bancos e financeiras: dá null (sem custo das vendas, resultado operacional nem ativo corrente, a métrica não tem o mesmo significado).',
    cautionEn: 'It is an approximation: maintenance capex is not reported, so the lower of capex and D&A is used. Not applicable to banks and financial companies: it is null (without cost of sales, operating income or current assets the metric does not have the same meaning).',
    availability: MetricAvailability.partial,
  ),
  MetricInfo(
    key: 'maintenance_capex',
    namePt: 'Capex de manutenção (aproximado)',
    nameEn: 'Maintenance capex (approximate)',
    formula: 'min(|Capex|, D&A)',
    meaningPt:
        'Parte do investimento que serve para manter a capacidade atual.',
    meaningEn: 'Part of the investment needed to maintain current capacity.',
    readPt: 'Aproximação: se o capex é inferior às amortizações, o capex de manutenção é o próprio capex.',
    readEn: 'Approximation: if capex is below depreciation, maintenance capex is the capex itself.',
    cautionPt: 'A empresa pode reportar o capex de manutenção em comunicados, que a fonte não tem. Usa-se a aproximação.',
    cautionEn: 'The company may disclose maintenance capex in its reports, which the source does not have. The approximation is used.',
    availability: MetricAvailability.partial,
  ),
  MetricInfo(
    key: 'growth_capex',
    namePt: 'Capex de crescimento (aproximado)',
    nameEn: 'Growth capex (approximate)',
    formula: '|Capex| − Capex de manutenção',
    meaningPt: 'Parte do investimento que visa expansão.',
    meaningEn: 'Part of the investment aimed at expansion.',
    readPt: 'Capex de crescimento alto é bom se o retorno do investimento for elevado; sem retorno, é destruição de valor.',
    readEn: 'High growth capex is good if the return on investment is high; without returns it destroys value.',
    cautionPt: 'Aproximação derivada do capex de manutenção aproximado.',
    cautionEn: 'Approximation derived from the approximate maintenance capex.',
    availability: MetricAvailability.partial,
  ),
  MetricInfo(
    key: 'cash_conversion',
    namePt: 'Conversão de caixa',
    nameEn: 'Cash conversion',
    formula: 'CFO / Resultado líquido',
    meaningPt: 'Quanto do lucro contabilístico se transforma em dinheiro.',
    meaningEn: 'How much of accounting profit turns into cash.',
    readPt: 'Perto de 100 % ou mais é saudável. Consistentemente abaixo de 80 % merece investigação.',
    readEn: 'Close to 100 % or more is healthy. Consistently below 80 % deserves investigation.',
    cautionPt: 'Com resultado líquido zero ou negativo dá null: o rácio não é interpretável. Não aplicável a bancos e financeiras: dá null (sem custo das vendas, resultado operacional nem ativo corrente, a métrica não tem o mesmo significado). Usa o balanço do último trimestre e os fluxos dos últimos 12 meses (TTM) quando existem, senão o último exercício anual.',
    cautionEn: 'With zero or negative net income it is null: the ratio is not interpretable. Not applicable to banks and financial companies: it is null (without cost of sales, operating income or current assets the metric does not have the same meaning). Uses the latest quarter balance sheet and the last 12 months of flows (TTM) when available, otherwise the last fiscal year.',
  ),
  MetricInfo(
    key: 'sloan_accruals',
    namePt: 'Accruals de Sloan',
    nameEn: 'Sloan accruals',
    formula: '(Resultado líquido − CFO) / Ativo total médio',
    meaningPt:
        'Quanto do lucro não está ainda em dinheiro, em proporção do ativo.',
    meaningEn: 'How much of earnings is not yet in cash, as a share of assets.',
    readPt: 'Valores altos (positivos e grandes) são sinal de alerta: lucro sem caixa tende a reverter. Valores perto de zero ou negativos são preferíveis.',
    readEn: 'High positive values are a warning sign: earnings without cash tend to reverse. Values near zero or negative are preferable.',
    cautionPt: 'Versão por fluxos de caixa (Hribar e Collins, 2002), não a de Sloan (1996), que usava o balanço. Usa o balanço do último trimestre e os fluxos dos últimos 12 meses (TTM) quando existem, senão o último exercício anual.',
    cautionEn: 'Cash-flow version (Hribar and Collins, 2002), not Sloan’s (1996) balance-sheet version. Uses the latest quarter balance sheet and the last 12 months of flows (TTM) when available, otherwise the last fiscal year.',
  ),
  MetricInfo(
    key: 'capex_to_revenue',
    namePt: 'Capex / Receita',
    nameEn: 'Capex / Revenue',
    formula: '|Capex| / Receita',
    meaningPt: 'Quanto da receita é reinvestida em ativos fixos.',
    meaningEn: 'How much of revenue is reinvested in fixed assets.',
    readPt: 'Baixo em negócios leves (software, serviços); alto em indústria, energia e telecomunicações. Compara-se com pares.',
    readEn: 'Low in asset-light businesses (software, services); high in industry, energy and telecoms. Compare with peers.',
    cautionPt: 'Usa o balanço do último trimestre e os fluxos dos últimos 12 meses (TTM) quando existem, senão o último exercício anual.',
    cautionEn: 'Uses the latest quarter balance sheet and the last 12 months of flows (TTM) when available, otherwise the last fiscal year.',
  ),
  MetricInfo(
    key: 'capex_to_da',
    namePt: 'Capex / Amortizações e depreciações',
    nameEn: 'Capex / D&A',
    formula: '|Capex| / D&A',
    meaningPt:
        'Quanto se investe em relação ao desgaste contabilístico dos ativos.',
    meaningEn:
        'How much is invested relative to the accounting wear of assets.',
    readPt: 'Acima de 1 a empresa investe mais do que o desgaste contabilístico (cresce ou moderniza). Abaixo de 1 pode estar a consumir os ativos.',
    readEn: 'Above 1 the company invests more than the accounting wear (growing or modernising). Below 1 it may be consuming its assets.',
    cautionPt: 'Com amortizações nulas dá null. Usa o balanço do último trimestre e os fluxos dos últimos 12 meses (TTM) quando existem, senão o último exercício anual.',
    cautionEn: 'With zero depreciation it is null. Uses the latest quarter balance sheet and the last 12 months of flows (TTM) when available, otherwise the last fiscal year.',
  ),

  // ------------------------------------------------------------ 8. Métricas por ação
  MetricInfo(
    key: 'eps',
    namePt: 'EPS (resultado por ação)',
    nameEn: 'EPS (earnings per share)',
    formula: 'EPS diluído da fonte; se faltar, Resultado líquido / Ações diluídas',
    meaningPt: 'Lucro atribuível a cada ação diluída.',
    meaningEn: 'Earnings attributable to each diluted share.',
    readPt: 'Interessa sobretudo a evolução ao longo dos anos. Lê-se com o preço para obter o P/E.',
    readEn: 'The trend over the years matters most. Read it together with the price to get the P/E.',
    cautionPt: 'Na moeda de reporte; itens não recorrentes alteram o valor. Um EPS negativo (prejuízo) mantém-se tal como é, de propósito; só os múltiplos (P/E, PEG) o tratam como não aplicável.',
    cautionEn:
        'In the reporting currency; non-recurring items change the value. A negative EPS (loss) is kept as is, on purpose; only the multiples (P/E, PEG) treat it as not applicable.',
  ),
  MetricInfo(
    key: 'fcf_per_share',
    namePt: 'FCF por ação',
    nameEn: 'FCF per share',
    formula: 'FCF / Ações diluídas',
    meaningPt: 'Fluxo de caixa livre atribuível a cada ação diluída.',
    meaningEn: 'Free cash flow attributable to each diluted share.',
    readPt: 'Crescente e acima do dividendo por ação é sinal de capacidade de devolver capital. Compara-se com o preço (yield de FCF).',
    readEn: 'Rising and above the dividend per share signals capacity to return capital. Compare with the price (FCF yield).',
    cautionPt: 'Não aplicável a bancos e financeiras: dá null (sem custo das vendas, resultado operacional nem ativo corrente, a métrica não tem o mesmo significado).',
    cautionEn: 'Not applicable to banks and financial companies: it is null (without cost of sales, operating income or current assets the metric does not have the same meaning).',
  ),
  MetricInfo(
    key: 'bvps',
    namePt: 'Valor contabilístico por ação (BVPS)',
    nameEn: 'Book value per share (BVPS)',
    formula: 'Capitais próprios / Ações em circulação',
    meaningPt: 'Valor contabilístico do capital próprio por ação.',
    meaningEn: 'Accounting value of equity per share.',
    readPt: 'Lê-se com o preço (P/B). Muito útil em bancos e seguros; em empresas com recompras e ativos intangíveis perde significado.',
    readEn: 'Read it with the price (P/B). Very useful for banks and insurers; loses meaning in companies with buybacks and intangible assets.',
    cautionPt: 'Com capitais próprios negativos o valor é negativo e não serve de referência. Se as ações do snapshot de mercado (por exemplo, equivalentes ADR) e as das demonstrações estiverem em bases diferentes (TSM: 1 ADR = 5 ações), dá null: o BVPS saía 5 vezes fora. Só se verifica quando se passa o snapshot de mercado.',
    cautionEn: 'With negative equity the value is negative and not a useful reference. If the market snapshot shares (for example ADR equivalents) and the financial statement shares are on different bases (TSM: 1 ADR = 5 shares), it is null: the value came out 5 times off. Only checked when the market snapshot is passed.',
  ),
  MetricInfo(
    key: 'tbvps',
    namePt: 'Valor contabilístico tangível por ação',
    nameEn: 'Tangible book value per share',
    formula: 'Valor contabilístico tangível / Ações em circulação',
    meaningPt:
        'Valor contabilístico por ação sem goodwill nem outros intangíveis.',
    meaningEn: 'Book value per share without goodwill or other intangibles.',
    readPt: 'Mais conservador que o BVPS. Relevante em bancos (P/TBV) e em empresas com muitas aquisições.',
    readEn: 'More conservative than BVPS. Relevant for banks (P/TBV) and for companies with many acquisitions.',
    cautionPt: 'Se as ações do snapshot de mercado (por exemplo, equivalentes ADR) e as das demonstrações estiverem em bases diferentes (TSM: 1 ADR = 5 ações), dá null: o valor saía 5 vezes fora. Só se verifica quando se passa o snapshot de mercado.',
    cautionEn: 'If the market snapshot shares (for example ADR equivalents) and the financial statement shares are on different bases (TSM: 1 ADR = 5 shares), it is null: the value came out 5 times off. Only checked when the market snapshot is passed.',
  ),
  MetricInfo(
    key: 'dps',
    namePt: 'Dividendo por ação (DPS)',
    nameEn: 'Dividend per share (DPS)',
    formula: 'Dividendos dos últimos 12 meses / Ação',
    meaningPt: 'Dividendo pago por ação nos últimos 12 meses.',
    meaningEn: 'Dividend paid per share over the last 12 months.',
    readPt: 'Lê-se com o preço (dividend yield) e com o FCF por ação: um dividendo maior do que o FCF por ação não é sustentável sem dívida.',
    readEn: 'Read it with the price (dividend yield) and FCF per share: a dividend above FCF per share is not sustainable without debt.',
    cautionPt: 'Vem da cotação (dados de mercado) e não das demonstrações; sem dados de mercado dá null.',
    cautionEn: 'Comes from the market data, not the financial statements; without market data it is null.',
    availability: MetricAvailability.partial,
  ),
  MetricInfo(
    key: 'share_dilution',
    namePt: 'Diluição (variação anual das ações)',
    nameEn: 'Share dilution (annual change in shares)',
    formula: 'Ações em fim de ano / Ações do ano anterior − 1',
    meaningPt: 'Variação anual do número de ações em circulação.',
    meaningEn: 'Annual change in the number of shares outstanding.',
    readPt: 'Positiva significa diluição (emissão de ações, por exemplo por SBC). Negativa significa recompras, que aumentam a parte de cada acionista.',
    readEn: 'Positive means dilution (share issuance, for example from SBC). Negative means buybacks, which increase each shareholder’s stake.',
    cautionPt:
        'Usa o número de ações de fim de ano (fonte), não a média diluída.',
    cautionEn:
        'Uses year-end shares outstanding (source), not the diluted average.',
  ),
];
