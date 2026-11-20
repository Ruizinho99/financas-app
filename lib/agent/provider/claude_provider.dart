import 'dart:convert';

import 'package:http/http.dart' as http;

import 'llm_provider.dart';

/// Fornecedor Claude (API Messages da Anthropic) com a chave do utilizador.
class ClaudeProvider implements LlmProvider {
  static const defaultModel = 'claude-sonnet-5-5';
  static final _endpoint = Uri.parse('https://api.anthropic.com/v1/messages');

  final String apiKey;
  final String model;
  final http.Client _client;

  ClaudeProvider({
    required this.apiKey,
    this.model = defaultModel,
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  Future<AgentTurn> send({
    required String system,
    required List<AgentMessage> messages,
    required List<ToolSpec> tools,
  }) async {
    final body = jsonEncode({
      'model': model,
      'max_tokens': 2048,
      'system': system,
      'messages': [for (final m in messages) encodeMessage(m)],
      if (tools.isNotEmpty)
        'tools': [
          for (final t in tools)
            {
              'name': t.name,
              'description': t.description,
              'input_schema': t.inputSchema,
            },
        ],
    });
    final http.Response res;
    try {
      res = await _client
          .post(
            _endpoint,
            headers: {
              'x-api-key': apiKey,
              'anthropic-version': '2023-06-01',
              'content-type': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 60));
    } on Exception catch (e) {
      throw LlmException('network: $e');
    }
    if (res.statusCode != 200) {
      throw LlmException(_errorMessage(res), statusCode: res.statusCode);
    }
    return parseResponse(utf8.decode(res.bodyBytes));
  }

  static Map<String, dynamic> encodeMessage(AgentMessage m) {
    final blocks = <Map<String, dynamic>>[
      if (m.text.isNotEmpty) {'type': 'text', 'text': m.text},
      for (final c in m.toolCalls)
        {'type': 'tool_use', 'id': c.id, 'name': c.name, 'input': c.input},
      for (final r in m.toolResults)
        {
          'type': 'tool_result',
          'tool_use_id': r.callId,
          'content': r.content,
          if (r.isError) 'is_error': true,
        },
    ];
    return {'role': m.role.name, 'content': blocks};
  }

  static AgentTurn parseResponse(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final text = StringBuffer();
    final calls = <ToolCall>[];
    for (final b in (json['content'] as List? ?? const [])) {
      final block = b as Map<String, dynamic>;
      switch (block['type']) {
        case 'text':
          text.write(block['text'] ?? '');
        case 'tool_use':
          calls.add(
            ToolCall(
              id: block['id'] as String,
              name: block['name'] as String,
              input: Map<String, dynamic>.from(block['input'] as Map? ?? {}),
            ),
          );
      }
    }
    return AgentTurn(text: text.toString(), toolCalls: calls);
  }

  static String _errorMessage(http.Response res) {
    try {
      final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final msg = (j['error'] as Map?)?['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    } on Object {
      // corpo que não é JSON: cai na mensagem genérica
    }
    return 'HTTP ${res.statusCode}';
  }
}
