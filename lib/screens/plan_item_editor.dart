import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../planning/planning.dart';
import '../state/app_state.dart';
import '../util/format.dart';

class PlanValue {
  final int cents;
  final bool mandatory;
  const PlanValue(this.cents, this.mandatory);
}

/// Valor e tipo (obrigatória/opcional) de uma despesa planeada. Devolve nulo se for cancelado.
Future<PlanValue?> showPlanItemEditor(
  BuildContext context,
  AppState s,
  String month, {
  required int categoryId,
  required String title,
  PlannedItem? current,
}) {
  final l = AppLocalizations.of(context)!;
  final ctrl = TextEditingController(
    text: current == null
        ? ''
        : (current.cents / 100).toStringAsFixed(2).replaceAll('.', ','),
  );
  var mandatory = current?.mandatory ?? false;
  return showDialog<PlanValue>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l.bpPlannedAmount(baseSym),
                prefixText: '$baseSym  ',
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: true, label: Text(l.bpMandatoryType)),
                ButtonSegment(value: false, label: Text(l.bpOptionalType)),
              ],
              selected: {mandatory},
              onSelectionChanged: (v) => set(() => mandatory = v.first),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () {
              final v = (parseCents(ctrl.text) ?? 0).abs();
              if (v <= 0) return;
              Navigator.pop(ctx, PlanValue(v, mandatory));
            },
            child: Text(l.bpSave),
          ),
        ],
      ),
    ),
  );
  // sem dispose: o controlador ainda é usado durante a animação de saída do diálogo
}
