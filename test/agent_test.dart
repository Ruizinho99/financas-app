import 'dart:convert';

import 'package:financas/agent/agent_loop.dart';
import 'package:financas/agent/agent_screen.dart';
import 'package:financas/agent/provider/claude_provider.dart';
import 'package:financas/agent/provider/llm_provider.dart';
import 'package:financas/agent/tools/read_tools.dart';
import 'package:financas/agent/tools/write_tools.dart';
import 'package:financas/db/database.dart';
import 'package:financas/l10n/app_localizations.dart';
import 'package:financas/models.dart';
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
      expect(added.messages.last.text, 'Tens 2 contas.');
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

  group('ferramentas de escrita e plano', () {
    WriteTool w(AppState s, String n) =>
        buildWriteTools(s).firstWhere((t) => t.spec.name == n);

    test('chamar a ferramenta não altera nada', () {
      final s = _state();
      final before = s.transactions.length;
      final plan = w(s, 'transferir').plan({
        'de_conta_id': s.accounts[0].id,
        'para_conta_id': s.accounts[1].id,
        'montante': 10.0,
      });
      expect(plan, hasLength(1));
      expect(s.transactions.length, before);
    });

    test(
      'mover_tudo_para: uma transferência por conta com saldo positivo',
      () async {
        final s = _state();
        final c3 = s.addAccount('Conta 3', openingCents: 3000);
        s.addAccount('Vazia');
        final b1 = s.accountBalance(s.accounts[0].id);
        final dest = s.accounts[1].id;
        final plan = w(s, 'mover_tudo_para').plan({'conta_destino_id': dest});
        expect(plan, hasLength(2)); // Conta 1 e Conta 3; a Vazia fica de fora
        final destBefore = s.accountBalance(dest);
        await executePlan(s, plan);
        expect(s.accountBalance(s.accounts[0].id), 0);
        expect(s.accountBalance(c3), 0);
        expect(s.accountBalance(dest), destBefore + b1 + 3000);
      },
    );

    test('valida contas, montantes, categorias e movimentos', () {
      final s = _state();
      final a = s.accounts[0].id, b = s.accounts[1].id;
      expect(
        () => w(
          s,
          'transferir',
        ).plan({'de_conta_id': a, 'para_conta_id': a, 'montante': 1}),
        throwsArgumentError,
      );
      expect(
        () => w(
          s,
          'transferir',
        ).plan({'de_conta_id': a, 'para_conta_id': 999, 'montante': 1}),
        throwsArgumentError,
      );
      expect(
        () => w(
          s,
          'transferir',
        ).plan({'de_conta_id': a, 'para_conta_id': b, 'montante': -5}),
        throwsArgumentError,
      );
      expect(
        () => w(
          s,
          'transferir',
        ).plan({'de_conta_id': a, 'para_conta_id': b, 'montante': 0}),
        throwsArgumentError,
      );
      expect(
        () => w(
          s,
          'adicionar_movimento',
        ).plan({'descricao': 'x', 'montante': 1, 'data': 'ontem'}),
        throwsArgumentError,
      );
      expect(
        () => w(
          s,
          'adicionar_movimento',
        ).plan({'descricao': 'x', 'montante': 1, 'categoria_id': 999}),
        throwsArgumentError,
      );
      expect(
        () => w(s, 'classificar').plan({
          'movimento_ids': [99999],
          'categoria_id': 1,
        }),
        throwsArgumentError,
      );
      final catId = s.addCategory(
        const Categoria(id: 0, name: 'X', parentId: null, isIncome: false),
      );
      final transferId = s.transactions.firstWhere((t) => t.isTransfer).id;
      expect(
        () => w(s, 'classificar').plan({
          'movimento_ids': [transferId],
          'categoria_id': catId,
        }),
        throwsArgumentError,
      );
    });

    test(
      'adicionar_movimento e classificar executam depois de confirmados',
      () async {
        final s = _state();
        final cat = s.addCategory(
          const Categoria(
            id: 0,
            name: 'Mercearia',
            parentId: null,
            isIncome: false,
          ),
        );
        final plan = [
          ...w(s, 'adicionar_movimento').plan({
            'descricao': 'Café',
            'montante': -1.5,
            'conta_id': s.accounts[0].id,
            'data': '2026-11-02',
          }),
          ...w(s, 'classificar').plan({
            'movimento_ids': [
              s.transactions
                  .firstWhere((t) => t.description == 'Supermercado')
                  .id,
            ],
            'categoria_id': cat,
          }),
        ];
        await executePlan(s, plan);
        final cafe = s.transactions.firstWhere((t) => t.description == 'Café');
        expect(cafe.amount, -150);
        expect(cafe.date, DateTime(2026, 11, 2));
        expect(
          s.transactions
              .firstWhere((t) => t.description == 'Supermercado')
              .categoryId,
          cat,
        );
      },
    );

    test(
      'Desfazer repõe os dados; falha a meio não deixa nada alterado',
      () async {
        final s = _state();
        final bal = s.accountBalance(s.accounts[0].id);
        final n = s.transactions.length;
        final plan = w(
          s,
          'mover_tudo_para',
        ).plan({'conta_destino_id': s.accounts[1].id});
        final snap = await executePlan(s, plan);
        expect(s.accountBalance(s.accounts[0].id), 0);
        await s.restoreBackup(snap);
        expect(s.accountBalance(s.accounts[0].id), bal);
        expect(s.transactions.length, n);

        final failing = [
          ...plan,
          PlannedAction(
            describe: (_) => 'x',
            apply: (_) => throw StateError('falhou'),
          ),
        ];
        await expectLater(executePlan(s, failing), throwsStateError);
        expect(s.accountBalance(s.accounts[0].id), bal);
        expect(s.transactions.length, n);
      },
    );

    test('criar_categoria, criar_objetivo e definir_salario', () async {
      final s = _state();
      final root = s.addCategory(
        const Categoria(
          id: 0,
          name: 'Poupança',
          parentId: null,
          isIncome: false,
        ),
      );
      final plan = [
        ...w(s, 'criar_categoria').plan({'nome': 'Café', 'mae_id': root}),
        ...w(
          s,
          'criar_objetivo',
        ).plan({'nome': 'Férias', 'montante': 1500, 'categoria_mae_id': root}),
        ...w(s, 'definir_salario').plan({'montante': 1800, 'mes': '2026-11'}),
        ...w(s, 'definir_salario').plan({'montante': 1700}),
      ];
      expect(plan.every((a) => !a.destructive), isTrue);
      await executePlan(s, plan);
      expect(
        s.categories.any((c) => c.name == 'Café' && c.parentId == root),
        isTrue,
      );
      expect(s.goals.single.name, 'Férias');
      expect(s.salaryFor('2026-11'), 180000);
      expect(s.defaultSalary, 170000);
    });

    test('validação das ferramentas novas', () {
      final s = _state();
      final root = s.addCategory(
        const Categoria(id: 0, name: 'Casa', parentId: null, isIncome: false),
      );
      expect(
        () => w(s, 'criar_categoria').plan({'nome': ' '}),
        throwsArgumentError,
      );
      expect(
        () => w(s, 'criar_categoria').plan({'nome': 'casa'}),
        throwsArgumentError,
      ); // já existe
      expect(
        () => w(s, 'criar_categoria').plan({'nome': 'X', 'mae_id': 999}),
        throwsArgumentError,
      );
      expect(
        () => w(
          s,
          'criar_objetivo',
        ).plan({'nome': 'A', 'montante': 10, 'categoria_mae_id': 999}),
        throwsArgumentError,
      );
      expect(
        () => w(s, 'criar_objetivo').plan({
          'nome': 'A',
          'montante': 10,
          'categoria_mae_id': root,
          'data_fim': 'amanhã',
        }),
        throwsArgumentError,
      );
      expect(
        () => w(s, 'definir_salario').plan({'montante': 100, 'mes': '2026-13'}),
        throwsArgumentError,
      );
      expect(
        () => w(s, 'definir_salario').plan({'montante': -1}),
        throwsArgumentError,
      );
      expect(
        () => w(s, 'apagar_movimentos').plan({'movimento_ids': []}),
        throwsArgumentError,
      );
      expect(
        () => w(s, 'apagar_movimentos').plan({
          'movimento_ids': [99999],
        }),
        throwsArgumentError,
      );
      final transferId = s.transactions.firstWhere((t) => t.isTransfer).id;
      expect(
        () => w(s, 'apagar_movimentos').plan({
          'movimento_ids': [transferId],
        }),
        throwsArgumentError,
      );
    });

    test(
      'apagar_movimentos fica marcado como destrutivo e o Desfazer repõe',
      () async {
        final s = _state();
        final id = s.transactions
            .firstWhere((t) => t.description == 'Supermercado')
            .id;
        final n = s.transactions.length;
        final plan = w(s, 'apagar_movimentos').plan({
          'movimento_ids': [id],
        });
        expect(plan.single.destructive, isTrue);
        expect(s.transactions.length, n); // planear não apaga
        final snap = await executePlan(s, plan);
        expect(s.transactions.length, n - 1);
        await s.restoreBackup(snap);
        expect(s.transactions.length, n);
      },
    );

    test(
      'o laço regista o plano sem executar e devolve erros ao modelo',
      () async {
        final s = _state();
        final n = s.transactions.length;
        final p = FakeProvider([
          AgentTurn(
            toolCalls: [
              ToolCall(
                id: 'a',
                name: 'mover_tudo_para',
                input: {'conta_destino_id': s.accounts[1].id},
              ),
              const ToolCall(
                id: 'b',
                name: 'transferir',
                input: {'de_conta_id': 1, 'para_conta_id': 1, 'montante': 1},
              ),
            ],
          ),
          const AgentTurn(text: 'Proponho isto.'),
        ]);
        final run = await AgentLoop(
          provider: p,
          tools: buildReadTools(s),
          writeTools: buildWriteTools(s),
        ).run([const AgentMessage.user('passa tudo')]);
        expect(run.plan, hasLength(1));
        expect(s.transactions.length, n); // nada executado
        final results = p.seen[1].last.toolResults;
        expect(results[0].isError, isFalse);
        expect(results[0].content, contains('NÃO foi executado'));
        expect(results[1].isError, isTrue);
      },
    );
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
    expect(find.textContaining('mostra um plano'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'quanto tenho?');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(find.text('quanto tenho?'), findsOneWidget);
    expect(find.text('A Conta 1 tem 64,50 €.'), findsOneWidget);
  });

  testWidgets('ecrã: plano, confirmar e botão Desfazer', (tester) async {
    final s = _state();
    final dest = s.accounts[1].id;
    final b1 = s.accountBalance(s.accounts[0].id);
    final p = FakeProvider([
      AgentTurn(
        toolCalls: [
          ToolCall(
            id: 'm',
            name: 'mover_tudo_para',
            input: {'conta_destino_id': dest},
          ),
        ],
      ),
      const AgentTurn(text: 'Proponho mover o saldo. Confirma?'),
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
    await tester.enterText(find.byType(TextField), 'passa tudo para a conta 2');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(find.textContaining('Plano · 1 ação'), findsOneWidget);
    expect(find.textContaining('Transferir'), findsOneWidget);
    expect(s.accountBalance(s.accounts[0].id), b1); // ainda nada feito
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(s.accountBalance(s.accounts[0].id), 0);
    expect(find.textContaining('Feito'), findsOneWidget);
    // o botão Desfazer aparece; a reposição em si (cópia da base de dados, com
    // E/S real) é testada acima, fora do ecrã, porque o relógio simulado dos
    // testes de widgets não a deixa terminar
    expect(find.text('Desfazer'), findsOneWidget);
  });

  testWidgets('ecrã: cancelar não altera nada', (tester) async {
    final s = _state();
    final b1 = s.accountBalance(s.accounts[0].id);
    final p = FakeProvider([
      AgentTurn(
        toolCalls: [
          ToolCall(
            id: 'm',
            name: 'mover_tudo_para',
            input: {'conta_destino_id': s.accounts[1].id},
          ),
        ],
      ),
      const AgentTurn(text: 'Confirma?'),
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
    await tester.enterText(find.byType(TextField), 'x');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(s.accountBalance(s.accounts[0].id), b1);
    expect(find.text('Plano cancelado.'), findsOneWidget);
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
