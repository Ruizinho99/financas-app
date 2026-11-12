# Instruções comuns aos agentes das fórmulas

Contexto: análise fundamental na app Finanças (Flutter/Dart, pacote `financas`). Lê, por esta ordem:
1. `docs/invest-analise-plano.md` (arquitetura e regras).
2. `docs/metricas-fundamentais.md`: **a Parte 2 é a fonte de verdade** (2.0 convenções, 2.1 sinais, e a tua secção), incluindo a secção "Revisão" no fim,
   que corrige erros; a Parte 1 é a lista do utilizador (verbatim) e a Parte 3 diz o que NÃO é calculável com dados gratuitos.
3. `lib/invest/metrics/financials.dart` (CONTRATO: `FinPeriod`, `Financials`, `MarketSnapshot`, `Metric`, `MetricKind`, `safeDiv`, `avgOf`; não o alteres)
   e `lib/invest/metrics/metric_info.dart` (`MetricInfo`, `MetricAvailability`).

## O que entregas
- `lib/invest/metrics/<ficheiro>.dart`: funções PURAS (sem rede, sem Flutter, sem estado) que devolvem `List<Metric>`.
  Chaves `snake_case` em inglês; usa as chaves de `test/fixtures/golden_aapl.json` quando existirem (para os testes compararem diretamente).
  Valor `null` quando falta um dado ou a divisão é por zero; percentagens em fração. Uma função pequena por métrica, com a fórmula em comentário (português).
  Nunca inventes proxies: se a Parte 3 diz "não disponível", devolve a métrica com `null` e explica-o na ficha.
- `lib/invest/metrics/<ficheiro>_info.dart`: `const List<MetricInfo> <nome>Info = [...]` com uma ficha por CADA chave que as tuas funções devolvem
  (incluindo as sem dados, com `MetricAvailability.unavailable` e a razão). Textos PT e EN não vazios: o que mede, fórmula curta (igual nas duas línguas),
  como ler (valores típicos e a ressalva de que depende do setor e de comparar com pares) e armadilhas. Usa as frases e os limiares da lista do utilizador.
- `test/metrics/<ficheiro>_test.dart`: (a) valores do AAPL batem com `golden_aapl.json` (carrega o JSON; tolerância relativa 1e-9; para `Financials` real usa as
  fixtures em `test/fixtures/yahoo/` via `YahooMarketData` com `MockClient`, ver `test/invest_data/support.dart`); (b) casos pequenos com números de manual feitos à mão
  (constrói `FinPeriod` diretamente); (c) dados em falta e divisão por zero dão `null`, sem exceções; (d) cobertura: cada `Metric.key` devolvida (mesmo com valor `null`)
  tem `MetricInfo`, sem chaves duplicadas e com todos os textos preenchidos.

## Regras
- Relatório final em português; comentários em português; sem dados pessoais; ignora a pasta não versionada `extratos/`.
- Só tocas nos teus ficheiros. Não alteres o contrato nem ficheiros de outros agentes.
- `flutter analyze --no-fatal-infos; echo $?` tem de dar 0 e `flutter test` tem de passar. O flutter reescreve `analysis_options.yaml`: `git checkout analysis_options.yaml` antes do commit.
- Commit com o trailer `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>` e `git push -u origin <o teu ramo>`. SEM PR, SEM merge, SEM mexer na versão.
- Se a especificação for ambígua ou o contrato não chegar, NÃO inventes: segue o mais conservador (`null`) e diz no relatório.
