# Agente dentro da app — plano (rascunho para aprovação)

Estado: fase 1 (v1.38.0) e fase 2 (v1.39.0) feitas. A fase 2 inclui `transferir`, `mover_tudo_para`, `adicionar_movimento` e `classificar`, com plano, confirmação, snapshot e Desfazer; "todas as contas" são só as contas normais (as de investimento ficam de fora). A fase 3 (v1.40.0) acrescenta OpenAI e Gemini, com escolha do fornecedor e uma chave por fornecedor. A fase 4 (v1.41.0) acrescenta `criar_categoria`, `criar_objetivo`, `definir_salario` e `apagar_movimentos` (a vermelho no plano; não apaga transferências). A fase 5 (v1.42.0) acrescenta o **servidor local** (ver abaixo).

## Ideia

Um ecrã de conversa onde o utilizador escreve um pedido em texto ("passa o dinheiro de todas as contas para a conta 2"). O agente lê, interpreta, **mostra um plano** e só executa depois de o utilizador confirmar. Depois da execução há **Desfazer**.

## Decisões já tomadas

- Vários fornecedores: Claude (chave Anthropic do utilizador), OpenAI e Gemini (chave própria) e modelo local no telemóvel. Escolha nas definições.
- Execução sempre com plano + confirmação.

## Arquitetura

```
lib/agent/
  provider/         interface LlmProvider { Future<AgentTurn> send(msgs, tools) }
                    claude_provider.dart, openai_provider.dart, gemini_provider.dart, local_provider.dart
  tools/            uma "ferramenta" por ação, com nome, esquema JSON e função
  planner.dart      pede ao modelo um plano; valida; devolve List<PlannedAction>
  executor.dart     executa o plano na AppState, dentro de um snapshot para Desfazer
  agent_screen.dart conversa + cartão de plano + Confirmar / Cancelar / Desfazer
  agent_settings.dart fornecedor, chave, modelo local
```

### Princípio de segurança: o modelo nunca toca na base de dados

O modelo só **propõe chamadas a ferramentas** (JSON). O código da app valida cada chamada (ids existem, montantes são inteiros em cêntimos, contas distintas) e só depois a executa através dos métodos já existentes de `AppState` (`addTransfer`, `addManual`, `updateTxn`, `deleteTxns`, `addCategory`, `addGoal`, `setSalary`, …). Assim as regras atuais (reembolsos, ligações, orçamento) continuam a valer e não há SQL gerado por IA.

### Ferramentas da primeira versão

| Ferramenta | Usa | Tipo |
|---|---|---|
| `listar_contas`, `saldo_conta`, `listar_categorias`, `procurar_movimentos` | leitura de `AppState` | leitura (corre logo, sem confirmação) |
| `transferir(de, para, montante)` | `addTransfer` | escrita |
| `mover_tudo_para(conta_destino)` | várias `addTransfer`, uma por conta com saldo > 0 | escrita (expande em N passos no plano) |
| `adicionar_movimento(...)` | `addManual` | escrita |
| `classificar(movimentos, categoria)` | `updateTxn` | escrita |
| `criar_categoria`, `criar_objetivo`, `definir_salario` | métodos existentes | escrita |
| `apagar_movimentos(ids)` | `deleteTxns` | escrita, destacada a vermelho no plano |

Fica de fora na v1: importar extratos, investimentos, apagar contas/categorias (pedem passos extra de segurança).

### Fluxo

1. Utilizador escreve o pedido.
2. A app envia ao modelo: o pedido, o esquema das ferramentas e um **resumo mínimo** (nomes e ids das contas e categorias; saldos só se a ferramenta de leitura for chamada).
3. O modelo responde com chamadas a ferramentas. Leituras correm logo; escritas ficam num plano.
4. A app mostra o plano em linguagem simples ("Transferir 120,00 € da Conta 1 para a Conta 2") e o total do impacto.
5. **Confirmar** → `executor` guarda um snapshot da BD (reutiliza o backup que já existe, `restoreBytes`), executa, mostra o resultado e o botão **Desfazer** (repõe o snapshot).
6. Se o modelo não percebe ou falta informação, pergunta de volta em vez de adivinhar.

### Privacidade

- Por defeito só vão ao modelo nomes de contas/categorias e o que a ferramenta de leitura devolver para aquele pedido. Nunca o histórico completo.
- Chaves guardadas com `flutter_secure_storage` (nova dependência), não em `shared_preferences`.
- Com modelo local nada sai do telemóvel.
- Aviso claro nas definições: com Claude/OpenAI/Gemini o texto do pedido e os dados lidos vão para esse fornecedor.

### Modelo local

É a parte mais incerta. Opções: `flutter_gemma` / llama.cpp via FFI, com modelo pequeno descarregado dentro da app (centenas de MB a ~2 GB). Modelos pequenos falham muito em chamadas de ferramentas, por isso: **fase 2**, atrás de um aviso ("pode errar mais"), e o plano + confirmação protege de erros.

## Fases (cada uma é um PR + release, como a regra do projeto)

1. Esqueleto: ecrã de conversa, definições, `LlmProvider` com **Claude**, ferramentas de leitura. (Sem escrita.)
2. Escrita com plano, confirmação, snapshot e Desfazer; ferramentas `transferir`, `mover_tudo_para`, `adicionar_movimento`, `classificar`.
3. OpenAI e Gemini.
4. Restantes ferramentas (categorias, objetivos, salário, apagar).
5. Modelo local.

## Decisões abertas

1. Onde entra o agente na navegação: botão flutuante em todos os ecrãs, ou entrada em "Mais"?
2. "Todas as contas" inclui contas de investimento/corretora ou só as normais? (Proposta: só as normais; as de investimento exigem pedido explícito.)
3. Idioma das respostas: seguir o idioma da app (proposta).
4. Para a fase 5, qual o limite de tamanho aceitável para o modelo local?

## Testes

- Cada ferramenta com testes unitários (validação e efeito na `AppState`).
- Um `FakeProvider` que devolve chamadas pré-definidas, para testar planner/executor/Desfazer sem rede.
- Teste do pedido de exemplo: contas A, B, C com saldos → plano com 2 transferências para B → executar → saldos certos → Desfazer repõe.

## Fase 5: modelo local (feito como servidor local)

Em vez de embutir um motor na app, o fornecedor "Servidor local" fala com qualquer servidor compatível com a API da OpenAI (Ollama, LM Studio, llama.cpp, vLLM), no PC ou na rede de casa. Reutiliza o fornecedor OpenAI com outro endereço; a chave é opcional.

Porquê não embutir (flutter_edge_ai, LiteRT-LM, testado em 2026-11-20): obriga a `minSdk 30` e só arm64 (deixa de servir Android 10 e anteriores), traz um motor nativo grande, pede pods estáticos e permissões no iOS, e não dá para verificar num telemóvel daqui. Foi depois feito na fase 6 (v1.43.0), a pedido do utilizador, ver abaixo.

Exemplo com Ollama no PC: `OLLAMA_HOST=0.0.0.0 ollama serve`, `ollama pull llama3.1`, e nas definições do agente: endereço `http://<IP do PC>:11434/v1`, modelo `llama3.1`.

Custos: Android passa a permitir tráfego http (`usesCleartextTraffic`) e o iOS `NSAllowsLocalNetworking`, porque estes servidores costumam estar em http na rede de casa; o resto da app usa https no código. Modelos pequenos falham mais em chamadas de ferramentas; o plano com confirmação continua a proteger os dados.

## Fase 6: modelo dentro da app (v1.43.0)

Pedido do utilizador: ter o modelo integrado na app, com descarga e arranque feitos pela própria app.

- Motor: `flutter_edge_ai` + `flutter_edge_ai_litertlm` (LiteRT-LM), carregado só quando se usa o agente (`OnDeviceModels.ensureInitialized`).
- Fornecedor "Modelo no telemóvel" (`OnDeviceProvider`): abre uma conversa no motor por pedido, repõe o histórico (que o laço do agente já envia inteiro) e devolve o texto e os pedidos de ferramentas; o laço, o plano e a confirmação são os mesmos.
- Definições: lista tirada do catálogo do motor, só modelos que chamam ferramentas e correm neste aparelho (sem FunctionGemma, que não conversa), do mais pequeno para o maior. Descarregar com progresso, Usar, Apagar. Os tamanhos vêm do catálogo (de ~0,6 GB a vários GB).
- Custos: `minSdk 30` (Android 11) e só arm64 (`abiFilters`); APK de release passa de ~80 MB para ~111 MB; iOS com pods estáticos. Não se acrescentaram entitlements de memória no iOS, porque o `.ipa` não assinado é instalado por sideload e isso pode falhar com contas gratuitas: modelos grandes podem ser fechados por falta de memória num iPhone.
- Contexto de 4096 tokens, resposta até 1024, temperatura 0,2.
- Não testado: descarga e geração num aparelho real (só compila e os testes usam um motor simulado).
