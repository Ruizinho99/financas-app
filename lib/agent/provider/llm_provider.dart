/// Camada comum aos fornecedores de modelos (Claude, e mais tarde OpenAI, Gemini e local).
library;

/// Uma ferramenta que o modelo pode pedir para chamar.
class ToolSpec {
  final String name;
  final String description;

  /// Esquema JSON dos argumentos (`type: object`).
  final Map<String, dynamic> inputSchema;
  const ToolSpec({
    required this.name,
    required this.description,
    required this.inputSchema,
  });
}

/// Pedido do modelo para correr uma ferramenta.
class ToolCall {
  final String id;
  final String name;
  final Map<String, dynamic> input;

  /// Dados que o fornecedor quer de volta na mensagem seguinte (por exemplo a
  /// assinatura de raciocínio do Gemini). A app não os interpreta.
  final Object? meta;
  const ToolCall({
    required this.id,
    required this.name,
    required this.input,
    this.meta,
  });
}

/// Resultado de uma ferramenta, devolvido ao modelo.
class ToolResult {
  final String callId;
  final String content;
  final bool isError;
  const ToolResult({
    required this.callId,
    required this.content,
    this.isError = false,
  });
}

enum AgentRole { user, assistant }

/// Mensagem da conversa. Uma mensagem do utilizador pode transportar resultados
/// de ferramentas; uma do assistente pode transportar pedidos de ferramentas.
class AgentMessage {
  final AgentRole role;
  final String text;
  final List<ToolCall> toolCalls;
  final List<ToolResult> toolResults;
  const AgentMessage({
    required this.role,
    this.text = '',
    this.toolCalls = const [],
    this.toolResults = const [],
  });

  const AgentMessage.user(String text) : this(role: AgentRole.user, text: text);
}

/// Uma resposta do modelo: texto e/ou pedidos de ferramentas.
class AgentTurn {
  final String text;
  final List<ToolCall> toolCalls;
  const AgentTurn({this.text = '', this.toolCalls = const []});
}

/// Erro de um fornecedor, com mensagem já legível para o utilizador.
class LlmException implements Exception {
  final String message;
  final int? statusCode;
  const LlmException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

abstract class LlmProvider {
  Future<AgentTurn> send({
    required String system,
    required List<AgentMessage> messages,
    required List<ToolSpec> tools,
  });
}
