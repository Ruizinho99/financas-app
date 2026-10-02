# Finanças

App Android (Flutter) para importar extratos bancários (PDF, CSV, Excel), classificar movimentos, definir orçamento e analisar despesas. **Tudo fica guardado localmente no telemóvel** (SQLite); não usa internet.

## Funcionalidades
- **Movimentos**: lista, pesquisa, filtros, inserção manual, seleção múltipla.
- **Importação**: PDF (com texto), CSV e Excel `.xlsx`, com deteção/ajuste de colunas e deteção de duplicados.
- **Classificar**: um cartão por nome de movimento, com dropdowns ligados de categoria → subcategoria; mover todos, memorizar regras, nomes amigáveis e notas.
- **Grupos de títulos**: juntar vários títulos (ex.: “TRANS …” e “MB WAY …” do mesmo restaurante) sob um nome e uma categoria; aplicado automaticamente nas próximas importações.
- **Categorias com emoji**, obrigatórias por período (mês a mês), modo escuro e cores personalizáveis.
- **Orçamento**: salário líquido, alocação por valor ou % do salário, cada categoria/subcategoria como *Limite* ou *Objetivo*, com barras de progresso.
- **Análise**: mês, vários meses, ano ou vários anos; obrigatórias vs opcionais, evolução, alertas de limites/objetivos.

## Como correr
Requer Flutter e o SDK Android.

```bash
flutter pub get
flutter test
flutter run            # num emulador ou telemóvel ligado
flutter build apk --release
```

Os APKs estão na secção **Releases** do GitHub.

## Notas
- Cada banco tem um layout de PDF diferente; o parser (`lib/import/parsers.dart`) é genérico e pode precisar de ajustes. CSV/Excel são mais fiáveis.
- A leitura de PDF usa `syncfusion_flutter_pdf`, sujeita à licença Community da Syncfusion (gratuita para uso pessoal/pequenas empresas). Verifica os termos antes de redistribuir comercialmente.
- O APK de lançamento é assinado com a chave de depuração; serve para testes, não para a Play Store.

## Licença
MIT – ver `LICENSE`.
