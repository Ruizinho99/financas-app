import 'dart:convert';

import '../../state/app_state.dart';
import '../provider/llm_provider.dart';

/// Ferramenta de leitura: corre logo, sem confirmação, e nunca altera dados.
class ReadTool {
  final ToolSpec spec;
  final String Function(Map<String, dynamic> input) run;
  const ReadTool(this.spec, this.run);
}

String _eur(int cents) => (cents / 100).toStringAsFixed(2);

/// As ferramentas de leitura da fase 1. Os montantes vão em euros com sinal
/// (negativo = saída); os ids são os da app.
List<ReadTool> buildReadTools(AppState s) => [
  ReadTool(
    const ToolSpec(
      name: 'listar_contas',
      description:
          'Lista as contas do utilizador com id, nome e saldo atual em euros.',
      inputSchema: {'type': 'object', 'properties': {}},
    ),
    (_) => jsonEncode([
      for (final a in s.accounts)
        {'id': a.id, 'nome': a.name, 'saldo': _eur(s.accountBalance(a.id))},
    ]),
  ),
  ReadTool(
    const ToolSpec(
      name: 'saldo_conta',
      description: 'Saldo atual, em euros, de uma conta.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'conta_id': {'type': 'integer'},
        },
        'required': ['conta_id'],
      },
    ),
    (input) {
      final id = input['conta_id'];
      final a = id is int ? s.account(id) : null;
      if (a == null) throw ArgumentError('Conta inexistente');
      return jsonEncode({
        'id': a.id,
        'nome': a.name,
        'saldo': _eur(s.accountBalance(a.id)),
      });
    },
  ),
  ReadTool(
    const ToolSpec(
      name: 'listar_categorias',
      description:
          'Lista as categorias com id, nome, categoria-mãe e se é de receita.',
      inputSchema: {'type': 'object', 'properties': {}},
    ),
    (_) => jsonEncode([
      for (final c in s.categories)
        {
          'id': c.id,
          'nome': c.name,
          if (c.parentId != null) 'mae_id': c.parentId,
          'receita': c.isIncome,
        },
    ]),
  ),
  ReadTool(
    const ToolSpec(
      name: 'procurar_movimentos',
      description:
          'Procura movimentos (sem transferências) por texto na descrição, '
          'conta e/ou categoria. Devolve no máximo 30, os mais recentes primeiro.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'texto': {'type': 'string'},
          'conta_id': {'type': 'integer'},
          'categoria_id': {'type': 'integer'},
        },
      },
    ),
    (input) {
      final text = (input['texto'] as String?)?.toLowerCase().trim();
      final acc = input['conta_id'];
      final cat = input['categoria_id'];
      final found = s.transactions.where((t) {
        if (t.isTransfer) return false;
        if (acc is int && t.accountId != acc) return false;
        if (cat is int && t.categoryId != cat) return false;
        if (text != null &&
            text.isNotEmpty &&
            !t.description.toLowerCase().contains(text)) {
          return false;
        }
        return true;
      }).toList()..sort((a, b) => b.date.compareTo(a.date));
      return jsonEncode([
        for (final t in found.take(30))
          {
            'id': t.id,
            'data': t.date.toIso8601String().substring(0, 10),
            'descricao': t.description,
            'valor': _eur(t.amount),
            if (t.accountId != null) 'conta_id': t.accountId,
            if (t.categoryId != null) 'categoria_id': t.categoryId,
          },
      ]);
    },
  ),
];
