import 'dart:typed_data';

import '../../l10n/app_localizations.dart';
import '../../models.dart';
import '../../state/app_state.dart';
import '../../util/format.dart';
import '../provider/llm_provider.dart';

/// Uma ação do plano: descreve-se ao utilizador e só se aplica depois de confirmada.
class PlannedAction {
  final String Function(AppLocalizations l) describe;
  final void Function(AppState s) apply;
  const PlannedAction({required this.describe, required this.apply});
}

/// Ferramenta de escrita: valida o pedido do modelo e devolve ações para o plano.
/// Nunca altera dados ao ser chamada; lança [ArgumentError] se o pedido for inválido.
class WriteTool {
  final ToolSpec spec;
  final List<PlannedAction> Function(Map<String, dynamic> input) plan;
  const WriteTool(this.spec, this.plan);
}

/// Máximo de ações num só plano.
const maxPlanActions = 20;

/// Corre o plano. Guarda antes uma cópia dos dados; se uma ação falhar repõe-na
/// e relança o erro (nada fica alterado). Devolve a cópia, para o Desfazer.
Future<Uint8List> executePlan(AppState s, List<PlannedAction> plan) async {
  final snapshot = s.backupBytes();
  try {
    for (final a in plan) {
      a.apply(s);
    }
  } on Object {
    await s.restoreBackup(snapshot);
    rethrow;
  }
  return snapshot;
}

int _cents(Object? euros) {
  if (euros is! num || !euros.isFinite) {
    throw ArgumentError('montante inválido');
  }
  final c = (euros * 100).round();
  if (c == 0 || c.abs() > 100000000000) {
    throw ArgumentError('montante inválido');
  }
  return c;
}

Conta _account(AppState s, Object? id, String field) {
  final a = id is int ? s.account(id) : null;
  if (a == null) throw ArgumentError('$field: conta inexistente');
  return a;
}

String _name(Conta a) => a.name;

/// Transferência entre duas contas, hoje.
PlannedAction _transfer(
  AppState s,
  Conta from,
  Conta to,
  int cents,
  String description,
) {
  return PlannedAction(
    describe: (l) => l.agPlanTransfer(fmtMoney(cents), _name(from), _name(to)),
    apply: (st) => st.addTransfer(
      date: DateTime.now(),
      description: description,
      amount: cents,
      fromAccount: from.id,
      toAccount: to.id,
    ),
  );
}

List<WriteTool> buildWriteTools(AppState s) => [
  WriteTool(
    const ToolSpec(
      name: 'transferir',
      description:
          'Propõe uma transferência entre duas contas. O montante é em euros '
          'e positivo. Só fica no plano; o utilizador confirma depois.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'de_conta_id': {'type': 'integer'},
          'para_conta_id': {'type': 'integer'},
          'montante': {'type': 'number'},
          'descricao': {'type': 'string'},
        },
        'required': ['de_conta_id', 'para_conta_id', 'montante'],
      },
    ),
    (input) {
      final from = _account(s, input['de_conta_id'], 'de_conta_id');
      final to = _account(s, input['para_conta_id'], 'para_conta_id');
      if (from.id == to.id) {
        throw ArgumentError('as contas têm de ser diferentes');
      }
      final cents = _cents(input['montante']);
      if (cents < 0) throw ArgumentError('o montante tem de ser positivo');
      final d = (input['descricao'] as String?)?.trim();
      return [
        _transfer(
          s,
          from,
          to,
          cents,
          (d == null || d.isEmpty) ? 'Transferência' : d,
        ),
      ];
    },
  ),
  WriteTool(
    const ToolSpec(
      name: 'mover_tudo_para',
      description:
          'Propõe passar o saldo positivo de todas as outras contas para a '
          'conta de destino (uma transferência por conta). Contas com saldo '
          'zero ou negativo ficam de fora. Só fica no plano.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'conta_destino_id': {'type': 'integer'},
        },
        'required': ['conta_destino_id'],
      },
    ),
    (input) {
      final to = _account(s, input['conta_destino_id'], 'conta_destino_id');
      final actions = <PlannedAction>[
        for (final a in s.accounts)
          if (a.id != to.id && s.accountBalance(a.id) > 0)
            _transfer(s, a, to, s.accountBalance(a.id), 'Transferência'),
      ];
      if (actions.isEmpty) {
        throw ArgumentError('nenhuma outra conta tem saldo positivo');
      }
      return actions;
    },
  ),
  WriteTool(
    const ToolSpec(
      name: 'adicionar_movimento',
      description:
          'Propõe um movimento novo. Montante em euros com sinal (negativo = '
          'despesa, positivo = receita). Data opcional em AAAA-MM-DD (por '
          'omissão hoje). Só fica no plano.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'descricao': {'type': 'string'},
          'montante': {'type': 'number'},
          'conta_id': {'type': 'integer'},
          'categoria_id': {'type': 'integer'},
          'data': {'type': 'string'},
        },
        'required': ['descricao', 'montante'],
      },
    ),
    (input) {
      final desc = (input['descricao'] as String?)?.trim() ?? '';
      if (desc.isEmpty) throw ArgumentError('descricao em falta');
      final cents = _cents(input['montante']);
      final account = input['conta_id'] == null
          ? null
          : _account(s, input['conta_id'], 'conta_id');
      final catId = input['categoria_id'];
      final cat = catId == null ? null : s.cat(catId is int ? catId : null);
      if (catId != null && cat == null) {
        throw ArgumentError('categoria_id: categoria inexistente');
      }
      final raw = input['data'] as String?;
      final date = raw == null ? DateTime.now() : DateTime.tryParse(raw);
      if (date == null) throw ArgumentError('data inválida (usa AAAA-MM-DD)');
      final day = DateTime(date.year, date.month, date.day);
      return [
        PlannedAction(
          describe: (l) => l.agPlanAddTxn(
            desc,
            fmtMoney(cents),
            account == null ? '—' : _name(account),
          ),
          apply: (st) => st.addManual(
            date: day,
            description: desc,
            amount: cents,
            categoryId: cat?.id,
            accountId: account?.id,
          ),
        ),
      ];
    },
  ),
  WriteTool(
    const ToolSpec(
      name: 'classificar',
      description:
          'Propõe pôr movimentos (ids de procurar_movimentos) numa categoria. '
          'Só fica no plano.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'movimento_ids': {
            'type': 'array',
            'items': {'type': 'integer'},
          },
          'categoria_id': {'type': 'integer'},
        },
        'required': ['movimento_ids', 'categoria_id'],
      },
    ),
    (input) {
      final ids = input['movimento_ids'];
      final catId = input['categoria_id'];
      final cat = catId is int ? s.cat(catId) : null;
      if (cat == null) {
        throw ArgumentError('categoria_id: categoria inexistente');
      }
      if (ids is! List || ids.isEmpty) {
        throw ArgumentError('movimento_ids em falta');
      }
      final byId = {for (final t in s.transactions) t.id: t};
      final txnIds = <int>[];
      for (final id in ids) {
        final t = id is int ? byId[id] : null;
        if (t == null) throw ArgumentError('movimento $id inexistente');
        if (t.isTransfer) {
          throw ArgumentError('movimento $id é uma transferência');
        }
        txnIds.add(t.id);
      }
      return [
        PlannedAction(
          describe: (l) => l.agPlanClassify(txnIds.length, cat.name),
          apply: (st) {
            // volta a ler os movimentos: o plano pode ter mexido neles
            final now = {for (final t in st.transactions) t.id: t};
            st.assign([
              for (final id in txnIds)
                if (now[id] != null) now[id]!,
            ], cat.id);
          },
        ),
      ];
    },
  ),
];
