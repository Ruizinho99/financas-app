import 'dart:convert';

import 'package:http/http.dart' as http;

import 'llm_provider.dart';

/// Fornecedor OpenAI (Chat Completions) com a chave do utilizador.
class OpenAiProvider implements LlmProvider {
  static const defaultModel = 'gpt-4.1';
  static const defaultBaseUrl = 'https://api.openai.com/v1';

  /// Chave; vazia nos servidores locais que não a pedem.
  final String apiKey;
  final String model;

  /// Raiz da API, sem a barra final (por omissão a da OpenAI). Qualquer servidor
  /// compatível serve: Ollama, LM Studio, llama.cpp, vLLM…
  final String baseUrl;
  final Duration timeout;
  final http.Client _client;

  OpenAiProvider({
    required this.apiKey,
    this.model = defaultModel,
    this.baseUrl = defaultBaseUrl,
    this.timeout = const Duration(seconds: 60),
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
      'messages': [
        {'role': 'system', 'content': system},
        for (final m in messages) ...encodeMessage(m),
      ],
      if (tools.isNotEmpty)
        'tools': [
          for (final t in tools)
            {
              'type': 'function',
              'function': {
                'name': t.name,
                'description': t.description,
                'parameters': t.inputSchema,
              },
            },
        ],
    });
    final http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse('$baseUrl/chat/completions'),
            headers: {
              if (apiKey.isNotEmpty) 'authorization': 'Bearer $apiKey',
              'content-type': 'application/json',
            },
            body: body,
          )
          .timeout(timeout);
    } on Exception catch (e) {
      throw LlmException('network: $e');
    }
    if (res.statusCode != 200) {
      throw LlmException(_errorMessage(res), statusCode: res.statusCode);
    }
    return parseResponse(utf8.decode(res.bodyBytes));
  }

  /// Uma mensagem nossa pode dar várias da OpenAI: cada resultado de
  /// ferramenta é uma mensagem `tool` própria.
  static List<Map<String, dynamic>> encodeMessage(AgentMessage m) {
    if (m.role == AgentRole.assistant) {
      return [
        {
          'role': 'assistant',
          'content': m.text.isEmpty ? null : m.text,
          if (m.toolCalls.isNotEmpty)
            'tool_calls': [
              for (final c in m.toolCalls)
                {
                  'id': c.id,
                  'type': 'function',
                  'function': {
                    'name': c.name,
                    'arguments': jsonEncode(c.input),
                  },
                },
            ],
        },
      ];
    }
    return [
      // as respostas às ferramentas têm de vir logo a seguir ao pedido
      for (final r in m.toolResults)
        {
          'role': 'tool',
          'tool_call_id': r.callId,
          'content': r.isError ? 'Erro: ${r.content}' : r.content,
        },
      if (m.text.isNotEmpty) {'role': 'user', 'content': m.text},
    ];
  }

  static AgentTurn parseResponse(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final choices = json['choices'] as List? ?? const [];
    if (choices.isEmpty) return const AgentTurn();
    final msg = (choices.first as Map)['message'] as Map? ?? const {};
    final calls = <ToolCall>[];
    for (final c in (msg['tool_calls'] as List? ?? const [])) {
      final call = c as Map<String, dynamic>;
      final fn = call['function'] as Map<String, dynamic>;
      Map<String, dynamic> input;
      try {
        final raw = fn['arguments'];
        final decoded = (raw is String && raw.isNotEmpty)
            ? jsonDecode(raw)
            : {};
        input = Map<String, dynamic>.from(decoded as Map);
      } on Object {
        // argumentos que não são JSON válido: a ferramenta recusa-os por faltarem campos
        input = {};
      }
      calls.add(
        ToolCall(
          id: call['id'] as String,
          name: fn['name'] as String,
          input: input,
        ),
      );
    }
    return AgentTurn(text: (msg['content'] as String?) ?? '', toolCalls: calls);
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
