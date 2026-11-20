import 'dart:convert';

import 'package:flutter_edge_ai/flutter_edge_ai.dart' as edge;

import '../ondevice/on_device_models.dart';
import 'llm_provider.dart';

/// Uma conversa no motor, reduzida ao que o fornecedor usa (assim testa-se sem o motor).
abstract class OnDeviceChat {
  Future<void> replay(List<edge.Message> history);
  Future<void> add(edge.Message message);
  Stream<edge.ModelResponse> generate();
  Future<void> close();
}

typedef OnDeviceChatOpener = Future<OnDeviceChat> Function({
  required String system,
  required List<edge.Tool> tools,
});

class _EdgeChat implements OnDeviceChat {
  final edge.InferenceChat chat;
  _EdgeChat(this.chat);
  @override
  Future<void> replay(List<edge.Message> history) =>
      chat.clearHistory(replayHistory: history);
  @override
  Future<void> add(edge.Message message) => chat.addQueryChunk(message);
  @override
  Stream<edge.ModelResponse> generate() => chat.generateChatResponseAsync();
  @override
  Future<void> close() => chat.close();
}

Future<OnDeviceChat> _openWithEngine({
  required String system,
  required List<edge.Tool> tools,
}) async =>
    _EdgeChat(await OnDeviceModels.openChat(system: system, tools: tools));

/// Fornecedor que corre o modelo dentro do telemóvel. O motor guarda a sua
/// própria conversa; aqui abre-se uma por pedido e repõe-se o histórico, que o
/// laço do agente já envia inteiro.
class OnDeviceProvider implements LlmProvider {
  final OnDeviceChatOpener _open;
  final Duration timeout;
  OnDeviceProvider({
    OnDeviceChatOpener? opener,
    this.timeout = const Duration(minutes: 5),
  }) : _open = opener ?? _openWithEngine;

  @override
  Future<AgentTurn> send({
    required String system,
    required List<AgentMessage> messages,
    required List<ToolSpec> tools,
  }) async {
    final history = toEdgeMessages(messages);
    if (history.isEmpty) throw const LlmException('local-model: empty');
    final OnDeviceChat chat;
    try {
      chat = await _open(
        system: system,
        tools: [for (final t in tools) toEdgeTool(t)],
      );
    } on StateError {
      throw const LlmException('no-model');
    } on Object catch (e) {
      throw LlmException('local-model: $e');
    }
    try {
      if (history.length > 1) {
        await chat.replay(history.sublist(0, history.length - 1));
      }
      await chat.add(history.last);
      return await collectTurn(chat.generate()).timeout(timeout);
    } on LlmException {
      rethrow;
    } on Object catch (e) {
      throw LlmException('local-model: $e');
    } finally {
      try {
        await chat.close();
      } on Object {
        // fechar uma conversa já terminada não deve estragar a resposta
      }
    }
  }

  static edge.Tool toEdgeTool(ToolSpec t) => edge.Tool(
    name: t.name,
    description: t.description,
    parameters: t.inputSchema,
  );

  /// O histórico da app no formato do motor. Cada resultado de ferramenta vira
  /// uma mensagem própria, ligada pelo nome da ferramenta (o motor emparelha
  /// pedido e resposta por nome, pela ordem).
  static List<edge.Message> toEdgeMessages(List<AgentMessage> ms) {
    final nameOf = {
      for (final m in ms)
        for (final c in m.toolCalls) c.id: c.name,
    };
    final out = <edge.Message>[];
    for (final m in ms) {
      if (m.role == AgentRole.assistant) {
        if (m.toolCalls.isNotEmpty) {
          out.add(
            edge.Message.toolCall(
              calls: [
                for (final c in m.toolCalls)
                  edge.FunctionCallResponse(
                    name: c.name,
                    args: c.input,
                    id: c.id,
                  ),
              ],
            ),
          );
        } else if (m.text.isNotEmpty) {
          out.add(edge.Message(text: m.text, isUser: false));
        }
        continue;
      }
      for (final r in m.toolResults) {
        out.add(
          edge.Message.toolResponse(
            toolName: nameOf[r.callId] ?? 'ferramenta',
            toolCallId: r.callId,
            response: _asMap(r),
          ),
        );
      }
      if (m.text.isNotEmpty) out.add(edge.Message(text: m.text, isUser: true));
    }
    return out;
  }

  static Map<String, dynamic> _asMap(ToolResult r) {
    if (r.isError) return {'error': r.content};
    try {
      final v = jsonDecode(r.content);
      if (v is Map<String, dynamic>) return v;
      return {'result': v};
    } on FormatException {
      return {'result': r.content};
    }
  }

  /// Junta o texto e os pedidos de ferramentas que o motor emite.
  static Future<AgentTurn> collectTurn(Stream<edge.ModelResponse> s) async {
    final text = StringBuffer();
    final calls = <ToolCall>[];
    ToolCall conv(edge.FunctionCallResponse c) => ToolCall(
      id: c.id ?? 'local${calls.length}_${c.name}',
      name: c.name,
      input: Map<String, dynamic>.from(c.args),
    );
    await for (final r in s) {
      switch (r) {
        case edge.TextResponse(:final token):
          text.write(token);
        case edge.FunctionCallResponse():
          calls.add(conv(r));
        case edge.ParallelFunctionCallResponse():
          for (final c in r.calls) {
            calls.add(conv(c));
          }
        case edge.ThinkingResponse():
          break;
      }
    }
    return AgentTurn(text: text.toString().trim(), toolCalls: calls);
  }
}
