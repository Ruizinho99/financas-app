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

  /// Apaga dados: o plano mostra-a a vermelho.
  final bool destructive;
  const PlannedAction({
    required this.describe,
    required this.apply,
    this.destructive = false,
  });
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
  WriteTool(
    const ToolSpec(
      name: 'criar_categoria',
      description:
          'Propõe uma categoria nova (de despesa por omissão), opcionalmente '
          'dentro de outra (mae_id). Só fica no plano.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'nome': {'type': 'string'},
          'mae_id': {'type': 'integer'},
          'receita': {'type': 'boolean'},
        },
        'required': ['nome'],
      },
    ),
    (input) {
      final name = (input['nome'] as String?)?.trim() ?? '';
      if (name.isEmpty || name.length > 60) {
        throw ArgumentError('nome inválido (1 a 60 caracteres)');
      }
      final parentId = input['mae_id'];
      final parent = parentId == null
          ? null
          : s.cat(parentId is int ? parentId : null);
      if (parentId != null && parent == null) {
        throw ArgumentError('mae_id: categoria inexistente');
      }
      final clash = s.categories.any(
        (c) =>
            c.parentId == parent?.id &&
            c.name.toLowerCase() == name.toLowerCase(),
      );
      if (clash) {
        throw ArgumentError('já existe uma categoria com esse nome aí');
      }
      final income = input['receita'] == true;
      return [
        PlannedAction(
          describe: (l) => parent == null
              ? l.agPlanCategory(name)
              : l.agPlanSubcategory(name, parent.name),
          apply: (st) => st.addCategory(
            Categoria(
              id: 0,
              name: name,
              parentId: parent?.id,
              isIncome: income,
            ),
          ),
        ),
      ];
    },
  ),
  WriteTool(
    const ToolSpec(
      name: 'criar_objetivo',
      description:
          'Propõe um objetivo de poupança com um valor alvo em euros, dentro '
          'de uma categoria existente (categoria_mae_id). Data de fim '
          'opcional em AAAA-MM-DD. Só fica no plano.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'nome': {'type': 'string'},
          'montante': {'type': 'number'},
          'categoria_mae_id': {'type': 'integer'},
          'data_fim': {'type': 'string'},
        },
        'required': ['nome', 'montante', 'categoria_mae_id'],
      },
    ),
    (input) {
      final name = (input['nome'] as String?)?.trim() ?? '';
      if (name.isEmpty || name.length > 60) {
        throw ArgumentError('nome inválido (1 a 60 caracteres)');
      }
      final cents = _cents(input['montante']);
      if (cents < 0) throw ArgumentError('o montante tem de ser positivo');
      final pid = input['categoria_mae_id'];
      final parent = pid is int ? s.cat(pid) : null;
      if (parent == null) {
        throw ArgumentError('categoria_mae_id: categoria inexistente');
      }
      final raw = input['data_fim'] as String?;
      DateTime? end;
      if (raw != null && raw.isNotEmpty) {
        end = DateTime.tryParse(raw);
        if (end == null) throw ArgumentError('data_fim inválida (AAAA-MM-DD)');
      }
      return [
        PlannedAction(
          describe: (l) => l.agPlanGoal(name, fmtMoney(cents)),
          apply: (st) => st.addGoal(
            name: name,
            parentCategoryId: parent.id,
            targetCents: cents,
            endDate: end,
          ),
        ),
      ];
    },
  ),
  WriteTool(
    const ToolSpec(
      name: 'definir_salario',
      description:
          'Propõe o salário mensal em euros. Com mes (AAAA-MM) só esse mês; '
          'sem mes, o salário por omissão. Só fica no plano.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'montante': {'type': 'number'},
          'mes': {'type': 'string'},
        },
        'required': ['montante'],
      },
    ),
    (input) {
      final cents = _cents(input['montante']);
      if (cents < 0) throw ArgumentError('o montante tem de ser positivo');
      final month = input['mes'] as String?;
      if (month != null &&
          month.isNotEmpty &&
          !RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(month)) {
        throw ArgumentError('mes inválido (usa AAAA-MM)');
      }
      final all = month == null || month.isEmpty;
      return [
        PlannedAction(
          describe: (l) => all
              ? l.agPlanSalaryDefault(fmtMoney(cents))
              : l.agPlanSalary(month, fmtMoney(cents)),
          apply: (st) =>
              all ? st.setDefaultSalary(cents) : st.setSalary(month, cents),
        ),
      ];
    },
  ),
  WriteTool(
    const ToolSpec(
      name: 'apagar_movimentos',
      description:
          'Propõe apagar movimentos (ids de procurar_movimentos). Usa só se '
          'o utilizador pediu mesmo para apagar. Não apaga transferências. '
          'Só fica no plano.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'movimento_ids': {
            'type': 'array',
            'items': {'type': 'integer'},
          },
        },
        'required': ['movimento_ids'],
      },
    ),
    (input) {
      final ids = input['movimento_ids'];
      if (ids is! List || ids.isEmpty) {
        throw ArgumentError('movimento_ids em falta');
      }
      if (ids.length > 50) {
        throw ArgumentError('no máximo 50 movimentos de cada vez');
      }
      final byId = {for (final t in s.transactions) t.id: t};
      final found = <Txn>[];
      for (final id in ids.toSet()) {
        final t = id is int ? byId[id] : null;
        if (t == null) throw ArgumentError('movimento $id inexistente');
        if (t.isTransfer) {
          throw ArgumentError(
            'movimento $id é uma transferência: não se apaga por aqui',
          );
        }
        found.add(t);
      }
      final txnIds = [for (final t in found) t.id];
      final summary = found.take(3).map((t) => t.description).join(', ');
      return [
        PlannedAction(
          destructive: true,
          describe: (l) => l.agPlanDelete(
            txnIds.length,
            found.length > 3 ? '$summary…' : summary,
          ),
          apply: (st) => st.deleteTxns(txnIds),
        ),
      ];
    },
  ),
];
