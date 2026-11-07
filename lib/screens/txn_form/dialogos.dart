import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../goals/goals.dart';
import '../../l10n/app_localizations.dart';
import '../../models.dart';
import '../../state/app_state.dart';
import '../../util/format.dart';
import '../../widgets/form_kit.dart' show evalExpression;

/// Cêntimos como texto editável ("12,50").
String centsText(int cents) =>
    (cents.abs() / 100).toStringAsFixed(2).replaceAll('.', ',');

/// Valor de uma associação entre um movimento e um objetivo (diálogo com o seu próprio controlador).
class AssociarDialog extends StatefulWidget {
  final String titulo;
  final List<Goal> opcoes;
  final int? goalId;
  final int disponivel;
  final int inicial;
  final String confirmar;
  final bool escolherObjetivo;
  const AssociarDialog({
    required this.titulo,
    required this.opcoes,
    required this.goalId,
    required this.disponivel,
    required this.inicial,
    required this.confirmar,
    required this.escolherObjetivo,
  });
  @override
  State<AssociarDialog> createState() => AssociarDialogState();
}

class AssociarDialogState extends State<AssociarDialog> {
  late int? goalId = widget.goalId;
  late final ctrl = TextEditingController(text: centsText(widget.inicial));

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final v = (parseCents(ctrl.text) ?? 0).abs();
    final excede = v > widget.disponivel;
    final gid = goalId;
    final ok = gid != null && v > 0 && !excede;
    return AlertDialog(
      title: Text(widget.titulo),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.escolherObjetivo) ...[
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final g in widget.opcoes)
                  ChoiceChip(
                    selected: g.id == goalId,
                    showCheckmark: false,
                    label: Text(g.name),
                    onSelected: (_) => setState(() => goalId = g.id),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l.frmAmountCurrency(baseSym),
              prefixText: '$baseSym  ',
              helperText: l.frmToAllocate(fmtMoney(widget.disponivel)),
              errorText: excede
                  ? l.frmOnlyLeftToAllocate(fmtMoney(widget.disponivel))
                  : null,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: ok ? () => Navigator.pop(context, (gid, v)) : null,
          child: Text(widget.confirmar),
        ),
      ],
    );
  }
}

/// Texto do motivo por que o valor de um movimento não pode ser corrigido para o valor pedido.
String amountIssueText(AppLocalizations l, AmountIssue issue, int cents) =>
    switch (issue) {
      AmountIssue.belowAllocated => l.frmAllocatedToGoals(fmtMoney(cents)),
      AmountIssue.belowReversed => l.edvBelowReversed(fmtMoney(cents)),
      AmountIssue.hasReversals => l.edvHasReversals(fmtMoney(cents)),
      AmountIssue.belowOwnReversal => l.edvBelowOwnReversal(fmtMoney(cents)),
    };

/// Ação rápida: corrige só o valor e o sinal de um movimento (despesa/receita, ou saída/entrada
/// numa transferência), sem abrir o formulário completo. Devolve true se guardou.
Future<bool> corrigirValor(BuildContext context, Txn t) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (_) => ChangeNotifierProvider<AppState>.value(
      value: context.read<AppState>(),
      child: _CorrigirValorDialog(t: t),
    ),
  );
  return r ?? false;
}

class _CorrigirValorDialog extends StatefulWidget {
  final Txn t;
  const _CorrigirValorDialog({required this.t});
  @override
  State<_CorrigirValorDialog> createState() => _CorrigirValorDialogState();
}

class _CorrigirValorDialogState extends State<_CorrigirValorDialog> {
  late bool entrada = widget.t.amount > 0;
  late final ctrl = TextEditingController(text: centsText(widget.t.amount));
  String? erro;

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  void _guardar() {
    final l = AppLocalizations.of(context)!;
    final s = context.read<AppState>();
    final v = centsFromText(ctrl.text);
    if (v == null || v == 0) {
      setState(() => erro = l.frmEnterValidAmount);
      return;
    }
    final issue = s.setAmount(widget.t, entrada ? v : -v);
    if (issue != null) {
      setState(() => erro = amountIssueText(l, issue.$1, issue.$2));
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tr = widget.t.isTransfer;
    return AlertDialog(
      title: Text(l.edvFixAmount),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: false,
                label: Text(tr ? l.frmOutgoing : l.frmExpense),
              ),
              ButtonSegment(
                value: true,
                label: Text(tr ? l.frmIncoming : l.frmIncome),
              ),
            ],
            selected: {entrada},
            onSelectionChanged: (v) => setState(() {
              entrada = v.first;
              erro = null;
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() => erro = null),
            decoration: InputDecoration(
              labelText: l.frmAmountCurrency(baseSym),
              prefixText: '$baseSym  ',
              errorText: erro,
              errorMaxLines: 4,
              helperText: widget.t.originalAmount == null
                  ? null
                  : l.edvOriginalValue(fmtMoney(widget.t.originalAmount!)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.cancel),
        ),
        FilledButton(onPressed: _guardar, child: Text(l.frmSave)),
      ],
    );
  }
}

/// Valor em cêntimos (sempre positivo) de um texto que pode ser uma conta ("12,50 + 11"). Uma conta
/// avalia-se antes de ler como número, porque senão os operadores eram ignorados e os dígitos juntados.
int? centsFromText(String text) {
  final t = text.trim();
  if (t.isEmpty) return null;
  if (RegExp(r'\d\s*[+\-*/×÷x]\s*[\d(]').hasMatch(t)) {
    final e = evalExpression(
      t.replaceAll(RegExp(r'(?<=\d)\s*x\s*(?=[\d(])'), '*'),
    );
    if (e != null) return (e * 100).round().abs();
  }
  final v = parseCents(t);
  if (v != null) return v.abs();
  final e = evalExpression(t);
  return e == null ? null : (e * 100).round().abs();
}
