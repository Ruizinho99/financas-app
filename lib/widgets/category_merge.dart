import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import 'category_editor.dart' show pickCategoryInTree;

/// Unificar [c] noutra categoria: escolhe o destino, mostra o que vai acontecer (e, se as duas
/// tiverem orçamento, pergunta se se somam ou qual se mantém) e, se confirmar, unifica.
Future<void> mergeCategoryFlow(
  BuildContext context,
  AppState s,
  Categoria c,
) async {
  final l = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final r = await pickCategoryInTree(
    context,
    excludeSubtreeOf: c.id,
    allowNone: false,
    title: l.mrgMergeInto(c.name),
  );
  final targetId = r?.id;
  if (targetId == null || !context.mounted) return;
  final target = s.cat(targetId);
  if (target == null) return;
  final err = s.canMergeCategories(c.id, targetId);
  if (err != null) {
    messenger.showSnackBar(SnackBar(content: Text(l.mrgCannot)));
    return;
  }
  final pv = s.previewMerge(c.id, targetId);
  final mode = await showDialog<BudgetMerge>(
    context: context,
    builder: (_) => _MergeDialog(source: c, target: target, preview: pv, s: s),
  );
  if (mode == null) return;
  final e2 = s.mergeCategories(c.id, targetId, budget: mode);
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        e2 == null ? l.mrgDone(c.name, s.path(targetId)) : l.mrgCannot,
      ),
    ),
  );
}

class _MergeDialog extends StatefulWidget {
  final Categoria source, target;
  final MergePreview preview;
  final AppState s;
  const _MergeDialog({
    required this.source,
    required this.target,
    required this.preview,
    required this.s,
  });
  @override
  State<_MergeDialog> createState() => _MergeDialogState();
}

class _MergeDialogState extends State<_MergeDialog> {
  BudgetMerge mode = BudgetMerge.sum;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final pv = widget.preview;
    final from = widget.source.name, to = widget.target.name;
    return AlertDialog(
      title: Text(l.mrgTitle(from, to)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.mrgTransactions(pv.transactions, to)),
            if (pv.subcategories > 0) ...[
              const SizedBox(height: 6),
              Text(l.mrgSubcategories(pv.subcategories, to)),
            ],
            if (pv.clashes > 0) ...[
              const SizedBox(height: 6),
              Text(l.mrgClashes(pv.clashes)),
            ],
            const SizedBox(height: 6),
            Text(l.mrgAlsoMoves),
            if (pv.bothBudgets) ...[
              const SizedBox(height: 14),
              Text(
                l.mrgBothBudgets,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              RadioGroup<BudgetMerge>(
                groupValue: mode,
                onChanged: (v) => setState(() => mode = v ?? mode),
                child: Column(
                  children: [
                    RadioListTile<BudgetMerge>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: BudgetMerge.sum,
                      title: Text(
                        l.mrgBudgetSum(
                          fmtMoney(pv.sourceBudget),
                          fmtMoney(pv.targetBudget),
                          fmtMoney(pv.sumBudget),
                        ),
                      ),
                    ),
                    RadioListTile<BudgetMerge>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: BudgetMerge.keepTarget,
                      title: Text(
                        l.mrgBudgetKeep(to, fmtMoney(pv.targetBudget)),
                      ),
                    ),
                    RadioListTile<BudgetMerge>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: BudgetMerge.keepSource,
                      title: Text(
                        l.mrgBudgetKeep(from, fmtMoney(pv.sourceBudget)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              l.mrgWarning(from),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, mode),
          child: Text(l.mrgConfirm),
        ),
      ],
    );
  }
}
