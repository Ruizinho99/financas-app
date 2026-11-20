import 'dart:convert';

import 'package:http/http.dart' as http;

import 'llm_provider.dart';

/// Fornecedor Gemini (API generateContent da Google) com a chave do utilizador.
class GeminiProvider implements LlmProvider {
  static const defaultModel = 'gemini-2.5-flash';

  final String apiKey;
  final String model;
  final http.Client _client;

  GeminiProvider({
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
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '${Uri.encodeComponent(model)}:generateContent',
    );
    final body = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': system},
        ],
      },
      'contents': encodeMessages(messages),
      if (tools.isNotEmpty)
        'tools': [
          {
            'functionDeclarations': [for (final t in tools) encodeTool(t)],
          },
        ],
    });
    final http.Response res;
    try {
      res = await _client
          .post(
            uri,
            headers: {
              'x-goog-api-key': apiKey,
              'content-type': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 60));
    } on Exception catch (e) {
      throw LlmException('network: $e');
    }
    if (res.statusCode != 200) {
      throw LlmException(_errorMessage(res), statusCode: _status(res));
    }
    return parseResponse(utf8.decode(res.bodyBytes));
  }

  /// O Gemini não aceita `parameters` vazios: ferramentas sem argumentos não os levam.
  static Map<String, dynamic> encodeTool(ToolSpec t) {
    final props = t.inputSchema['properties'];
    final hasParams = props is Map && props.isNotEmpty;
    return {
      'name': t.name,
      'description': t.description,
      if (hasParams) 'parameters': t.inputSchema,
    };
  }

  /// O Gemini não tem ids de chamada: as respostas ligam-se pelo nome da
  /// ferramenta, que se procura nos pedidos anteriores.
  static List<Map<String, dynamic>> encodeMessages(List<AgentMessage> ms) {
    final nameOf = {
      for (final m in ms)
        for (final c in m.toolCalls) c.id: c.name,
    };
    return [
      for (final m in ms)
        {
          'role': m.role == AgentRole.assistant ? 'model' : 'user',
          'parts': [
            if (m.text.isNotEmpty) {'text': m.text},
            for (final c in m.toolCalls)
              {
                'functionCall': {'name': c.name, 'args': c.input},
                if (c.meta != null) 'thoughtSignature': c.meta,
              },
            for (final r in m.toolResults)
              {
                'functionResponse': {
                  'name': nameOf[r.callId] ?? 'ferramenta',
                  'response': r.isError
                      ? {'error': r.content}
                      : {'result': r.content},
                },
              },
          ],
        },
    ];
  }

  static AgentTurn parseResponse(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final candidates = json['candidates'] as List? ?? const [];
    if (candidates.isEmpty) return const AgentTurn();
    final parts =
        ((candidates.first as Map)['content'] as Map?)?['parts'] as List? ??
        const [];
    final text = StringBuffer();
    final calls = <ToolCall>[];
    for (final p in parts) {
      final part = p as Map<String, dynamic>;
      final call = part['functionCall'];
      if (call is Map) {
        calls.add(
          ToolCall(
            id: 'g${calls.length}_${call['name']}',
            name: call['name'] as String,
            input: Map<String, dynamic>.from(call['args'] as Map? ?? {}),
            meta: part['thoughtSignature'],
          ),
        );
      } else if (part['text'] is String && part['thought'] != true) {
        text.write(part['text']);
      }
    }
    return AgentTurn(text: text.toString(), toolCalls: calls);
  }

  /// Uma chave inválida vem como 400; trata-se como 401 para a app a explicar bem.
  static int _status(http.Response res) {
    if (res.statusCode == 400 && _errorMessage(res).contains('API key')) {
      return 401;
    }
    return res.statusCode;
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
