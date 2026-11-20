import 'provider/llm_provider.dart';
import 'tools/read_tools.dart';
import 'tools/write_tools.dart';

/// Instruções fixas do agente.
const agentSystemPrompt =
    'És o assistente de uma app de finanças pessoais. Responde na língua do '
    'utilizador, de forma curta. Usa as ferramentas de consulta para ver os '
    'dados; nunca inventes saldos, ids ou movimentos. As ferramentas que '
    'alteram dados (transferir, mover_tudo_para, adicionar_movimento, '
    'classificar, criar_categoria, criar_objetivo, definir_salario, '
    'apagar_movimentos) NÃO executam nada: só juntam ações a um plano que a app '
    'mostra ao utilizador, e ele confirma ou cancela. Depois de juntares as '
    'ações, diz em uma ou duas frases o que propões e que ele tem de '
    'confirmar; não digas que já foi feito. "Todas as contas" quer dizer as '
    'contas listadas por listar_contas. Se faltar informação, pergunta. Se '
    'uma ferramenta devolver erro, corrige o pedido ou explica o problema. '
    'Só uses apagar_movimentos se o utilizador pediu claramente para apagar, '
    'e procura antes os movimentos para confirmares quais são.';

/// Resultado de um pedido: mensagens novas e o plano a confirmar (pode estar vazio).
class AgentRun {
  final List<AgentMessage> messages;
  final List<PlannedAction> plan;
  const AgentRun(this.messages, this.plan);
}

/// Corre a conversa com o modelo: pede, executa as ferramentas de leitura que o
/// modelo chamar, devolve-lhe os resultados e repete até haver resposta final.
class AgentLoop {
  final LlmProvider provider;
  final List<ReadTool> tools;
  final List<WriteTool> writeTools;
  final int maxRounds;
  AgentLoop({
    required this.provider,
    required this.tools,
    this.writeTools = const [],
    this.maxRounds = 6,
  });

  /// [history] já inclui a última mensagem do utilizador. Devolve as mensagens
  /// novas (assistente e resultados de ferramentas), pela ordem; a última é a
  /// resposta final do assistente. As ferramentas de escrita só juntam ações ao
  /// plano devolvido; nada é executado aqui.
  Future<AgentRun> run(List<AgentMessage> history) async {
    final byName = {for (final t in tools) t.spec.name: t};
    final writeByName = {for (final t in writeTools) t.spec.name: t};
    final specs = [
      for (final t in tools) t.spec,
      for (final t in writeTools) t.spec,
    ];
    final plan = <PlannedAction>[];
    final convo = [...history];
    final added = <AgentMessage>[];
    for (var i = 0; i < maxRounds; i++) {
      final turn = await provider.send(
        system: agentSystemPrompt,
        messages: convo,
        tools: specs,
      );
      final assistant = AgentMessage(
        role: AgentRole.assistant,
        text: turn.text,
        toolCalls: turn.toolCalls,
      );
      convo.add(assistant);
      added.add(assistant);
      if (turn.toolCalls.isEmpty) return AgentRun(added, plan);
      final results = <ToolResult>[];
      for (final call in turn.toolCalls) {
        final writer = writeByName[call.name];
        if (writer != null) {
          try {
            final actions = writer.plan(call.input);
            if (plan.length + actions.length > maxPlanActions) {
              throw ArgumentError(
                'o plano não pode ter mais de $maxPlanActions ações',
              );
            }
            plan.addAll(actions);
            results.add(
              ToolResult(
                callId: call.id,
                content:
                    'Registado no plano (${actions.length} ação/ões, '
                    '${plan.length} no total). Ainda NÃO foi executado: o '
                    'utilizador tem de confirmar.',
              ),
            );
          } on Object catch (e) {
            results.add(
              ToolResult(callId: call.id, content: '$e', isError: true),
            );
          }
          continue;
        }
        final tool = byName[call.name];
        if (tool == null) {
          results.add(
            ToolResult(
              callId: call.id,
              content: 'Ferramenta desconhecida: ${call.name}',
              isError: true,
            ),
          );
          continue;
        }
        try {
          results.add(
            ToolResult(callId: call.id, content: tool.run(call.input)),
          );
        } on Object catch (e) {
          results.add(
            ToolResult(callId: call.id, content: '$e', isError: true),
          );
        }
      }
      final reply = AgentMessage(role: AgentRole.user, toolResults: results);
      convo.add(reply);
      added.add(reply);
    }
    throw const LlmException('too-many-steps');
  }
}
