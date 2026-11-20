import 'package:financas/agent/provider/llm_provider.dart';
import 'package:financas/agent/provider/on_device_provider.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart' as edge;
import 'package:flutter_test/flutter_test.dart';

class _FakeChat implements OnDeviceChat {
  final List<edge.ModelResponse> reply;
  final Object? failOnGenerate;
  List<edge.Message>? replayed;
  edge.Message? added;
  bool closed = false;
  _FakeChat(this.reply, {this.failOnGenerate});
  @override
  Future<void> replay(List<edge.Message> history) async => replayed = history;
  @override
  Future<void> add(edge.Message message) async => added = message;
  @override
  Stream<edge.ModelResponse> generate() async* {
    if (failOnGenerate != null) throw failOnGenerate!;
    for (final r in reply) {
      yield r;
    }
  }

  @override
  Future<void> close() async => closed = true;
}

const _tools = [
  ToolSpec(
    name: 'saldo_conta',
    description: 'Saldo',
    inputSchema: {
      'type': 'object',
      'properties': {
        'conta_id': {'type': 'integer'},
      },
    },
  ),
];

final _convo = [
  const AgentMessage.user('quanto tenho?'),
  const AgentMessage(
    role: AgentRole.assistant,
    toolCalls: [
      ToolCall(id: 'c1', name: 'saldo_conta', input: {'conta_id': 2}),
    ],
  ),
  const AgentMessage(
    role: AgentRole.user,
    toolResults: [ToolResult(callId: 'c1', content: '{"saldo":"5.00"}')],
  ),
];

void main() {
  group('histórico para o motor', () {
    test('pedido, chamada e resultado ligam-se pelo nome da ferramenta', () {
      final ms = OnDeviceProvider.toEdgeMessages(_convo);
      expect(ms, hasLength(3));
      expect(ms[0].text, 'quanto tenho?');
      expect(ms[0].isUser, isTrue);
      expect(ms[1].toolCalls.single.name, 'saldo_conta');
      expect(ms[1].toolCalls.single.args, {'conta_id': 2});
      expect(ms[2].toolName, 'saldo_conta');
      expect(ms[2].text, contains('"saldo":"5.00"'));
    });

    test(
      'resultados que são listas, erros e texto simples ficam em objetos',
      () {
        final ms = OnDeviceProvider.toEdgeMessages([
          const AgentMessage(
            role: AgentRole.assistant,
            toolCalls: [
              ToolCall(id: 'a', name: 'listar_contas', input: {}),
              ToolCall(id: 'b', name: 'saldo_conta', input: {}),
              ToolCall(id: 'c', name: 'x', input: {}),
            ],
          ),
          const AgentMessage(
            role: AgentRole.user,
            toolResults: [
              ToolResult(callId: 'a', content: '[{"id":1}]'),
              ToolResult(
                callId: 'b',
                content: 'conta inexistente',
                isError: true,
              ),
              ToolResult(callId: 'c', content: 'texto'),
            ],
          ),
        ]);
        expect(ms[1].text, '{"result":[{"id":1}]}');
        expect(ms[2].text, '{"error":"conta inexistente"}');
        expect(ms[3].text, '{"result":"texto"}');
      },
    );

    test(
      'mensagens do assistente só com texto vão como resposta do modelo',
      () {
        final ms = OnDeviceProvider.toEdgeMessages([
          const AgentMessage.user('olá'),
          const AgentMessage(role: AgentRole.assistant, text: 'Olá!'),
          const AgentMessage(role: AgentRole.assistant),
        ]);
        expect(ms, hasLength(2));
        expect(ms[1].isUser, isFalse);
      },
    );
  });

  group('OnDeviceProvider.send', () {
    OnDeviceProvider providerWith(_FakeChat chat) => OnDeviceProvider(
      opener: ({
        required String system,
        required List<edge.Tool> tools,
      }) async => chat,
    );

    test(
      'repõe o histórico menos a última mensagem, junta texto e chamadas',
      () async {
        final chat = _FakeChat([
          const edge.ThinkingResponse('hmm'),
          const edge.TextResponse('Vou '),
          const edge.TextResponse('ver.'),
          const edge.FunctionCallResponse(
            name: 'saldo_conta',
            args: {'conta_id': 3},
          ),
          const edge.ParallelFunctionCallResponse(
            calls: [
              edge.FunctionCallResponse(name: 'a', args: {}, id: 'x'),
              edge.FunctionCallResponse(name: 'b', args: {}),
            ],
          ),
        ]);
        final turn = await providerWith(chat)
            .send(system: 'sys', messages: _convo, tools: _tools);
        expect(chat.replayed, hasLength(2));
        expect(chat.added!.toolName, 'saldo_conta'); // a última: o resultado
        expect(chat.closed, isTrue);
        expect(turn.text, 'Vou ver.');
        expect(turn.toolCalls.map((c) => c.name), ['saldo_conta', 'a', 'b']);
        expect(turn.toolCalls[1].id, 'x');
        expect(turn.toolCalls[0].id, isNotEmpty);
        expect(turn.toolCalls[0].input, {'conta_id': 3});
      },
    );

    test('uma só mensagem não repõe histórico', () async {
      final chat = _FakeChat([const edge.TextResponse('ok')]);
      await providerWith(chat).send(
        system: '',
        messages: const [AgentMessage.user('olá')],
        tools: const [],
      );
      expect(chat.replayed, isNull);
      expect(chat.added!.text, 'olá');
    });

    test('sem modelo instalado dá no-model', () async {
      final p = OnDeviceProvider(
        opener: ({
          required String system,
          required List<edge.Tool> tools,
        }) async => throw StateError('no active model'),
      );
      await expectLater(
        p.send(system: '', messages: _convo, tools: _tools),
        throwsA(
          isA<LlmException>().having((e) => e.message, 'msg', 'no-model'),
        ),
      );
    });

    test(
      'erro do motor fecha a conversa e sai com o prefixo local-model',
      () async {
        final chat = _FakeChat(
          const [],
          failOnGenerate: Exception('sem memória'),
        );
        await expectLater(
          providerWith(chat).send(system: '', messages: _convo, tools: _tools),
          throwsA(
            isA<LlmException>().having(
              (e) => e.message,
              'msg',
              startsWith('local-model:'),
            ),
          ),
        );
        expect(chat.closed, isTrue);
      },
    );
  });
}
