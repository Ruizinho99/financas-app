# Finanças

App Android (Flutter) para importar extratos bancários (PDF, CSV, Excel), classificar movimentos, definir orçamento e analisar despesas. **Tudo fica guardado localmente no telemóvel** (SQLite). A internet só é usada, a pedido, para atualizar preços de investimentos (é enviado apenas o símbolo do ativo).

## Funcionalidades
- **Movimentos**: lista, pesquisa, filtros (despesas, receitas, transferências, por conta), seleção múltipla. Novo movimento em ecrã completo com contas, recibos (foto ou ficheiro) e transferências entre contas.
- **Importação**: PDF (com texto), CSV e Excel `.xlsx`, com deteção/ajuste de colunas e deteção de duplicados.
- **Classificar**: um cartão por nome de movimento, com dropdowns ligados de categoria → subcategoria; mover todos, memorizar regras, nomes amigáveis e notas.
- **Grupos de títulos**: juntar vários títulos (ex.: “TRANS …” e “MB WAY …” do mesmo restaurante) sob um nome e uma categoria; aplicado automaticamente nas próximas importações.
- **Categorias com emoji**, obrigatórias por período (mês a mês), modo escuro e cores personalizáveis.
- **Orçamento**: salário líquido, alocação por valor ou % do salário, cada categoria/subcategoria como *Limite* ou *Objetivo*, com barras de progresso.
- **Análise**: mês, ano, YTD ou intervalo à escolha, com filtros (tipo, categorias, contas, valor, texto) e comparação com o período anterior. Quatro separadores: visão geral (ritmo, projeção, orçamento), gastos (por categoria, subcategoria, comerciante ou conta, com detalhe), poupar (potencial, simulador, sugestões, pagamentos recorrentes) e evolução (mês a mês).

## Como correr
Requer Flutter e o SDK Android.

```bash
flutter pub get
flutter test
flutter run            # num emulador ou telemóvel ligado
flutter build apk --release
```

Os APKs estão na secção **Releases** do GitHub.

- **Carteira (investimentos)**: plataformas (XTB, exchange…), ativos com preço médio de compra e posição inicial, compras, vendas e dividendos, dinheiro por alocar (standby), transferências do banco associadas a cada plataforma (e lembradas nas próximas importações) e atualização de preços por APIs gratuitas sem chave (Yahoo Finance e CoinGecko), convertidos para euros. Ativos em dólares (ou outras moedas): o preço de compra fica na moeda do ativo com o câmbio de cada compra, e vês o ganho em USD e em EUR. A posição inicial pode ser reaberta e é substituída ao guardar. Importação de compras, vendas e dividendos a partir de PDF (com texto), CSV ou Excel da corretora: colunas reconhecidas automaticamente (e ajustáveis), ativos ligados aos que já tens ou criados, câmbio por moeda e deteção de operações já importadas. As importações (extratos e operações) podem ser restringidas a um intervalo de datas. Cada transferência para uma plataforma pode ser ligada às compras que financiou; o que sobra fica em espera.

## Notas
- Cada banco tem um layout de PDF diferente; o parser (`lib/import/parsers.dart`) é genérico e pode precisar de ajustes. CSV/Excel são mais fiáveis.
- A leitura de PDF usa `syncfusion_flutter_pdf`, sujeita à licença Community da Syncfusion (gratuita para uso pessoal/pequenas empresas). Verifica os termos antes de redistribuir comercialmente.
- O APK de lançamento é assinado com a chave de depuração; serve para testes, não para a Play Store.

## Licença
MIT – ver `LICENSE`.

## Conta Google e cópia na nuvem

Em **Mais › Conta e cópia na nuvem** podes ligar a tua conta Google e guardar/restaurar uma cópia de todos os dados no Google Drive, numa pasta privada da app (`appDataFolder`, invisível no teu Drive e só acessível por esta app). Não inclui as fotos dos recibos. A internet só é usada quando carregas nos botões.

A Google exige um projeto próprio (grátis): ativa a *Google Drive API*, configura o ecrã de consentimento OAuth (Externo, com o teu email como utilizador de teste) e cria dois IDs de cliente OAuth: um **Android** (pacote `pt.financas.financas` e a impressão digital SHA-1 do certificado com que a app foi assinada, que o ecrã da app mostra) e um **Web**, cujo ID colas na app. Nada disto fica no código.

A camada é modular (`lib/cloud/`): `CloudProvider` é a interface comum; `GoogleProvider` usa o Drive; `AppleProvider` é um lugar reservado para o iCloud (só fará sentido numa versão para iPhone).
