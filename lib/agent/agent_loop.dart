import 'provider/llm_provider.dart';
import 'tools/read_tools.dart';

/// Instruções fixas do agente. Na fase 1 só há leitura.
const agentSystemPrompt =
    'És o assistente de uma app de finanças pessoais. Responde na língua do '
    'utilizador, de forma curta. Usa as ferramentas para consultar os dados; '
    'nunca inventes saldos, ids ou movimentos. Nesta versão só podes consultar '
    'dados: se o utilizador pedir para alterar algo (transferir, apagar, '
    'classificar…), explica que ainda não podes fazer alterações.';

/// Corre a conversa com o modelo: pede, executa as ferramentas de leitura que o
/// modelo chamar, devolve-lhe os resultados e repete até haver resposta final.
class AgentLoop {
  final LlmProvider provider;
  final List<ReadTool> tools;
  final int maxRounds;
  AgentLoop({required this.provider, required this.tools, this.maxRounds = 6});

  /// [history] já inclui a última mensagem do utilizador. Devolve as mensagens
  /// novas (assistente e resultados de ferramentas), pela ordem; a última é a
  /// resposta final do assistente.
  Future<List<AgentMessage>> run(List<AgentMessage> history) async {
    final byName = {for (final t in tools) t.spec.name: t};
    final specs = [for (final t in tools) t.spec];
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
      if (turn.toolCalls.isEmpty) return added;
      final results = <ToolResult>[];
      for (final call in turn.toolCalls) {
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
