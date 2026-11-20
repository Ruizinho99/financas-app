import 'dart:convert';

import 'package:financas/agent/agent_loop.dart';
import 'package:financas/agent/agent_screen.dart';
import 'package:financas/agent/provider/claude_provider.dart';
import 'package:financas/agent/provider/llm_provider.dart';
import 'package:financas/agent/tools/read_tools.dart';
import 'package:financas/db/database.dart';
import 'package:financas/l10n/app_localizations.dart';
import 'package:financas/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'support/fonts.dart';

/// Fornecedor de teste: devolve respostas pré-definidas, pela ordem.
class FakeProvider implements LlmProvider {
  final List<AgentTurn> script;
  final List<List<AgentMessage>> seen = [];
  int i = 0;
  FakeProvider(this.script);
  @override
  Future<AgentTurn> send({
    required String system,
    required List<AgentMessage> messages,
    required List<ToolSpec> tools,
  }) async {
    seen.add(List.of(messages));
    return script[i++];
  }
}

AppState _state() {
  final s = AppState(Db.memory());
  final a = s.addAccount('Conta 1', openingCents: 10000);
  s.addAccount('Conta 2', openingCents: 500);
  s.addManual(
    date: DateTime(2026, 10, 3),
    description: 'Supermercado',
    amount: -2550,
    accountId: a,
  );
  s.addTransfer(
    date: DateTime(2026, 10, 4),
    description: 'Transferência',
    amount: 1000,
    fromAccount: a,
    toAccount: s.accounts.last.id,
  );
  return s;
}

ReadTool _tool(AppState s, String name) =>
    buildReadTools(s).firstWhere((t) => t.spec.name == name);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_PT');
    await loadRoboto();
  });

  group('ferramentas de leitura', () {
    test('listar_contas devolve saldos em euros', () {
      final s = _state();
      final out = jsonDecode(_tool(s, 'listar_contas').run({})) as List;
      expect(out[0]['nome'], 'Conta 1');
      expect(out[0]['saldo'], '64.50'); // 100 - 25,50 - 10
      expect(out[1]['saldo'], '15.00');
    });

    test('saldo_conta recusa conta inexistente', () {
      final s = _state();
      expect(
        () => _tool(s, 'saldo_conta').run({'conta_id': 999}),
        throwsArgumentError,
      );
    });

    test('procurar_movimentos filtra por texto e ignora transferências', () {
      final s = _state();
      final out = jsonDecode(
        _tool(s, 'procurar_movimentos').run({'texto': 'super'}),
      ) as List;
      expect(out, hasLength(1));
      expect(out.single['valor'], '-25.50');
      final all = jsonDecode(_tool(s, 'procurar_movimentos').run({})) as List;
      expect(all, hasLength(1)); // a transferência não aparece
    });
  });

  group('AgentLoop', () {
    test('corre a ferramenta pedida e devolve o resultado ao modelo', () async {
      final s = _state();
      final p = FakeProvider([
        const AgentTurn(
          toolCalls: [ToolCall(id: 't1', name: 'listar_contas', input: {})],
        ),
        const AgentTurn(text: 'Tens 2 contas.'),
      ]);
      final added = await AgentLoop(
        provider: p,
        tools: buildReadTools(s),
      ).run([const AgentMessage.user('que contas tenho?')]);
      expect(added.last.text, 'Tens 2 contas.');
      final result = p.seen[1].last.toolResults.single;
      expect(result.callId, 't1');
      expect(result.content, contains('Conta 2'));
      expect(result.isError, isFalse);
    });

    test(
      'ferramenta desconhecida ou com erro volta como erro ao modelo',
      () async {
        final s = _state();
        final p = FakeProvider([
          const AgentTurn(
            toolCalls: [
              ToolCall(id: 'a', name: 'apagar_tudo', input: {}),
              ToolCall(id: 'b', name: 'saldo_conta', input: {'conta_id': 99}),
            ],
          ),
          const AgentTurn(text: 'ok'),
        ]);
        await AgentLoop(
          provider: p,
          tools: buildReadTools(s),
        ).run([const AgentMessage.user('x')]);
        final results = p.seen[1].last.toolResults;
        expect(results.map((r) => r.isError), [true, true]);
      },
    );

    test('pára com erro se o modelo nunca termina', () async {
      final s = _state();
      final call = const AgentTurn(
        toolCalls: [ToolCall(id: 'x', name: 'listar_contas', input: {})],
      );
      final p = FakeProvider(List.filled(10, call));
      expect(
        AgentLoop(
          provider: p,
          tools: buildReadTools(s),
          maxRounds: 3,
        ).run([const AgentMessage.user('x')]),
        throwsA(isA<LlmException>()),
      );
    });
  });

  group('ClaudeProvider', () {
    test('envia chave, versão, ferramentas e lê texto e tool_use', () async {
      late http.Request sent;
      final client = MockClient((req) async {
        sent = req;
        return http.Response(
          jsonEncode({
            'content': [
              {'type': 'text', 'text': 'Vou ver.'},
              {
                'type': 'tool_use',
                'id': 'tu1',
                'name': 'listar_contas',
                'input': {},
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final p = ClaudeProvider(apiKey: 'sk-test', client: client);
      final turn = await p.send(
        system: 'sys',
        messages: const [AgentMessage.user('olá')],
        tools: buildReadTools(_state()).map((t) => t.spec).toList(),
      );
      expect(sent.headers['x-api-key'], 'sk-test');
      expect(sent.headers['anthropic-version'], '2023-06-01');
      final body = jsonDecode(sent.body) as Map;
      expect(body['model'], ClaudeProvider.defaultModel);
      expect(body['system'], 'sys');
      expect((body['tools'] as List).first['input_schema'], isA<Map>());
      expect(turn.text, 'Vou ver.');
      expect(turn.toolCalls.single.id, 'tu1');
    });

    test('codifica resultados de ferramentas e erros', () {
      final m = ClaudeProvider.encodeMessage(
        const AgentMessage(
          role: AgentRole.user,
          toolResults: [ToolResult(callId: 'a', content: 'x', isError: true)],
        ),
      );
      final block = (m['content'] as List).single as Map;
      expect(block['type'], 'tool_result');
      expect(block['tool_use_id'], 'a');
      expect(block['is_error'], true);
    });

    test('erro HTTP usa a mensagem da API e guarda o código', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {'message': 'invalid x-api-key'},
          }),
          401,
        ),
      );
      final p = ClaudeProvider(apiKey: 'k', client: client);
      await expectLater(
        p.send(system: '', messages: const [AgentMessage.user('x')], tools: []),
        throwsA(
          isA<LlmException>()
              .having((e) => e.statusCode, 'status', 401)
              .having((e) => e.message, 'msg', 'invalid x-api-key'),
        ),
      );
    });
  });

  testWidgets('ecrã: pergunta, ferramenta e resposta final', (tester) async {
    final s = _state();
    final p = FakeProvider([
      const AgentTurn(
        toolCalls: [ToolCall(id: 't1', name: 'listar_contas', input: {})],
      ),
      const AgentTurn(text: 'A Conta 1 tem 64,50 €.'),
    ]);
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: s,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('pt', 'PT'),
          home: AgentScreen(provider: p),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('só consulta dados'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'quanto tenho?');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(find.text('quanto tenho?'), findsOneWidget);
    expect(find.text('A Conta 1 tem 64,50 €.'), findsOneWidget);
  });

  testWidgets('ecrã: erro do fornecedor mostra mensagem e repõe o texto', (
    tester,
  ) async {
    final s = _state();
    final p = _FailingProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: s,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('pt', 'PT'),
          home: AgentScreen(provider: p),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'olá');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(find.textContaining('chave foi recusada'), findsOneWidget);
    expect(find.text('olá'), findsOneWidget); // voltou à caixa de texto
  });
}

class _FailingProvider implements LlmProvider {
  @override
  Future<AgentTurn> send({
    required String system,
    required List<AgentMessage> messages,
    required List<ToolSpec> tools,
  }) async => throw const LlmException('bad key', statusCode: 401);
}
