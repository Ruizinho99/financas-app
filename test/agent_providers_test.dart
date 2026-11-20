import 'dart:convert';

import 'package:financas/agent/provider/claude_provider.dart';
import 'package:financas/agent/provider/gemini_provider.dart';
import 'package:financas/agent/provider/llm_provider.dart';
import 'package:financas/agent/provider/openai_provider.dart';
import 'package:financas/agent/provider/provider_kind.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _tools = [
  ToolSpec(
    name: 'listar_contas',
    description: 'Lista contas',
    inputSchema: {'type': 'object', 'properties': {}},
  ),
  ToolSpec(
    name: 'saldo_conta',
    description: 'Saldo',
    inputSchema: {
      'type': 'object',
      'properties': {
        'conta_id': {'type': 'integer'},
      },
      'required': ['conta_id'],
    },
  ),
];

/// Conversa com um pedido de ferramenta e o respetivo resultado.
final _convo = [
  const AgentMessage.user('quanto tenho?'),
  const AgentMessage(
    role: AgentRole.assistant,
    text: 'Vou ver.',
    toolCalls: [
      ToolCall(
        id: 'c1',
        name: 'saldo_conta',
        input: {'conta_id': 2},
        meta: 'sig',
      ),
    ],
  ),
  const AgentMessage(
    role: AgentRole.user,
    toolResults: [ToolResult(callId: 'c1', content: '{"saldo":"5.00"}')],
  ),
];

void main() {
  group('OpenAI', () {
    test(
      'pede com Bearer, sistema, ferramentas e mensagens codificadas',
      () async {
        late http.Request sent;
        final p = OpenAiProvider(
          apiKey: 'sk-o',
          client: MockClient((r) async {
            sent = r;
            return http.Response(
              jsonEncode({
                'choices': [
                  {
                    'message': {
                      'content': null,
                      'tool_calls': [
                        {
                          'id': 'call_9',
                          'type': 'function',
                          'function': {
                            'name': 'saldo_conta',
                            'arguments': '{"conta_id": 3}',
                          },
                        },
                      ],
                    },
                  },
                ],
              }),
              200,
            );
          }),
        );
        final turn = await p.send(
          system: 'sys',
          messages: _convo,
          tools: _tools,
        );
        expect(sent.headers['authorization'], 'Bearer sk-o');
        final body = jsonDecode(sent.body) as Map;
        expect(body['model'], OpenAiProvider.defaultModel);
        final msgs = body['messages'] as List;
        expect(msgs[0], {'role': 'system', 'content': 'sys'});
        expect(msgs[1], {'role': 'user', 'content': 'quanto tenho?'});
        final asst = msgs[2] as Map;
        expect(asst['role'], 'assistant');
        expect(
          asst['tool_calls'][0]['function']['arguments'],
          '{"conta_id":2}',
        );
        expect(msgs[3], {
          'role': 'tool',
          'tool_call_id': 'c1',
          'content': '{"saldo":"5.00"}',
        });
        expect((body['tools'] as List).first['type'], 'function');
        expect(turn.toolCalls.single.input, {'conta_id': 3});
        expect(turn.toolCalls.single.id, 'call_9');
        expect(turn.text, '');
      },
    );

    test('argumentos inválidos dão entrada vazia em vez de falhar', () {
      final t = OpenAiProvider.parseResponse(
        jsonEncode({
          'choices': [
            {
              'message': {
                'tool_calls': [
                  {
                    'id': 'x',
                    'type': 'function',
                    'function': {'name': 'listar_contas', 'arguments': '{oops'},
                  },
                ],
              },
            },
          ],
        }),
      );
      expect(t.toolCalls.single.input, isEmpty);
    });

    test('erro devolve a mensagem da API e o código', () async {
      final p = OpenAiProvider(
        apiKey: 'k',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'error': {'message': 'Incorrect API key'},
            }),
            401,
          ),
        ),
      );
      await expectLater(
        p.send(system: '', messages: _convo, tools: []),
        throwsA(
          isA<LlmException>()
              .having((e) => e.statusCode, 'status', 401)
              .having((e) => e.message, 'msg', 'Incorrect API key'),
        ),
      );
    });
  });

  group('Gemini', () {
    test(
      'pede com chave no cabeçalho, modelo no caminho e partes codificadas',
      () async {
        late http.Request sent;
        final p = GeminiProvider(
          apiKey: 'g-key',
          client: MockClient((r) async {
            sent = r;
            return http.Response(
              jsonEncode({
                'candidates': [
                  {
                    'content': {
                      'parts': [
                        {'text': 'a pensar', 'thought': true},
                        {
                          'functionCall': {
                            'name': 'listar_contas',
                            'args': <String, dynamic>{},
                          },
                          'thoughtSignature': 'abc',
                        },
                        {'text': 'Olá'},
                      ],
                    },
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        );
        final turn = await p.send(
          system: 'sys',
          messages: _convo,
          tools: _tools,
        );
        expect(sent.headers['x-goog-api-key'], 'g-key');
        expect(
          sent.url.path,
          endsWith('/models/gemini-2.5-flash:generateContent'),
        );
        expect(sent.url.query, isEmpty); // a chave nunca vai no URL
        final body = jsonDecode(sent.body) as Map;
        expect(body['system_instruction']['parts'][0]['text'], 'sys');
        final contents = body['contents'] as List;
        expect(contents.map((c) => c['role']), ['user', 'model', 'user']);
        final modelParts = contents[1]['parts'] as List;
        expect(modelParts[1]['functionCall'], {
          'name': 'saldo_conta',
          'args': {'conta_id': 2},
        });
        expect(modelParts[1]['thoughtSignature'], 'sig');
        expect(contents[2]['parts'][0]['functionResponse'], {
          'name': 'saldo_conta',
          'response': {'result': '{"saldo":"5.00"}'},
        });
        final decls = body['tools'][0]['functionDeclarations'] as List;
        expect(decls[0].containsKey('parameters'), isFalse); // sem argumentos
        expect(decls[1].containsKey('parameters'), isTrue);
        expect(turn.text, 'Olá'); // o texto de raciocínio fica de fora
        expect(turn.toolCalls.single.name, 'listar_contas');
        expect(turn.toolCalls.single.meta, 'abc');
      },
    );

    test('chave inválida (400) é tratada como 401', () async {
      final p = GeminiProvider(
        apiKey: 'k',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'error': {
                'message': 'API key not valid. Please pass a valid API key.',
              },
            }),
            400,
          ),
        ),
      );
      await expectLater(
        p.send(system: '', messages: _convo, tools: []),
        throwsA(isA<LlmException>().having((e) => e.statusCode, 'status', 401)),
      );
    });

    test('resposta sem candidatos dá turno vazio', () {
      expect(GeminiProvider.parseResponse('{}').text, '');
    });
  });

  group('Servidor local', () {
    test(
      'usa o endereço indicado, sem chave não manda Authorization',
      () async {
        late http.Request sent;
        final p = AgentProviderKind.local.build(
          apiKey: '',
          model: 'llama3.1',
          baseUrl: 'http://192.168.1.10:11434/v1/',
          client: MockClient((r) async {
            sent = r;
            return http.Response(
              jsonEncode({
                'choices': [
                  {
                    'message': {'content': 'Olá'},
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        );
        final turn = await p.send(system: 's', messages: _convo, tools: _tools);
        expect(
          sent.url.toString(),
          'http://192.168.1.10:11434/v1/chat/completions',
        );
        expect(sent.headers.containsKey('authorization'), isFalse);
        expect((jsonDecode(sent.body) as Map)['model'], 'llama3.1');
        expect(turn.text, 'Olá');
      },
    );

    test('com chave manda Bearer', () async {
      late http.Request sent;
      final p = AgentProviderKind.local.build(
        apiKey: 'abc',
        model: 'm',
        baseUrl: 'https://llm.casa.pt/v1',
        client: MockClient((r) async {
          sent = r;
          return http.Response('{"choices":[]}', 200);
        }),
      );
      await p.send(system: '', messages: _convo, tools: []);
      expect(sent.headers['authorization'], 'Bearer abc');
    });

    test('normalizeBaseUrl aceita http(s) e recusa o resto', () {
      expect(
        normalizeBaseUrl(' http://pc.local:1234/v1// '),
        'http://pc.local:1234/v1',
      );
      expect(normalizeBaseUrl('https://x.pt'), 'https://x.pt');
      expect(normalizeBaseUrl(''), isNull);
      expect(normalizeBaseUrl(null), isNull);
      expect(normalizeBaseUrl('192.168.1.10:11434'), isNull);
      expect(normalizeBaseUrl('ftp://x.pt'), isNull);
      expect(normalizeBaseUrl('http://x.pt/v1?a=1'), isNull);
    });

    test('construir sem endereço válido falha', () {
      expect(
        () => AgentProviderKind.local.build(
          apiKey: '',
          model: 'm',
          baseUrl: 'xx',
        ),
        throwsArgumentError,
      );
    });
  });

  test(
    'AgentProviderKind constrói o fornecedor certo com o modelo por omissão',
    () {
      expect(
        AgentProviderKind.claude.build(apiKey: 'k'),
        isA<ClaudeProvider>(),
      );
      expect(
        AgentProviderKind.openai.build(apiKey: 'k'),
        isA<OpenAiProvider>(),
      );
      final g = AgentProviderKind.gemini.build(apiKey: 'k', model: ' ');
      expect(g, isA<GeminiProvider>());
      expect((g as GeminiProvider).model, GeminiProvider.defaultModel);
    },
  );
}
