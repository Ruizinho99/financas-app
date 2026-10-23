import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import '../widgets/common.dart';
import 'accounts_screen.dart';
import 'appearance_screen.dart';
import 'analysis_screen.dart';
import 'budget_screen.dart' show BudgetScreen, showBudgetEditor;
import 'classify_screen.dart';
import 'month_cycle_screen.dart';
import 'planning_screen.dart';
import 'recurring_screen.dart';
import 'backup_screen.dart';
import 'goals_screen.dart';
import 'groups_screen.dart';
import 'import_screen.dart';
import 'transactions_screen.dart' show confirm;
import 'update_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.morMoreTitle)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.savings_outlined),
            title: Text(l.budget),
            subtitle: Text(l.morBudgetSubtitle),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BudgetScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: Text(AppLocalizations.of(context)!.monthStartTitle),
            subtitle: Text(AppLocalizations.of(context)!.monthStartSubtitle),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MonthCycleScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.event_note_outlined),
            title: Text(l.planning),
            subtitle: Text(l.morPlanningSubtitle),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlanningScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: Text(l.goals),
            subtitle: Text(l.morGoalsSubtitle),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GoalsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.insights_outlined),
            title: Text(l.analysis),
            subtitle: Text(l.morAnalysisSubtitle),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AnalysisScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.style_outlined),
            title: Text(l.morClassifyTitle),
            subtitle: Text(l.morClassifySubtitle),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClassifyScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.system_update_alt),
            title: Text(l.morUpdatesTitle),
            subtitle: Text(l.morUpdatesSubtitle),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UpdateScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l.appearanceTitle),
            subtitle: Text(l.morAppearanceSubtitle),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppearanceScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: Text(l.morAccountsTitle),
            subtitle: Text(l.morAccountsCount(s.accounts.length)),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.autorenew),
            title: Text(l.morRecurringTitle),
            subtitle: Text(l.morRecurringCount(s.recurringRules.length)),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RecurringScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: Text(l.morCategoriesTitle),
            subtitle: Text(l.morCategoriesCount(s.categories.length)),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoriesScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.hub_outlined),
            title: Text(l.morGroupsTitle),
            subtitle: Text(l.morGroupsCount(s.groups.length)),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GroupsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.rule),
            title: Text(l.morRulesTitle),
            subtitle: Text(l.morRulesCount(s.rules.length)),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RulesScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: Text(l.morImportTitle),
            subtitle: Text(l.morImportSubtitle),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ImportScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(l.morImportsHistoryTitle),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ImportsScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: Text(l.morExportTitle),
            onTap: () async {
              final b = StringBuffer(
                '﻿data;descricao;montante;categoria;nota\n',
              );
              for (final t in s.transactions.reversed) {
                String q(String v) => '"${v.replaceAll('"', '""')}"';
                b.writeln(
                  '${isoDate(t.date)};${q(t.description)};${(t.amount / 100).toStringAsFixed(2)};${t.isTransfer ? 'transferencia' : (t.amount < 0 ? 'despesa' : 'receita')};${q(t.isTransfer ? '' : s.path(t.categoryId))};${q(s.account(t.accountId)?.name ?? '')};${q(t.note)}',
                );
              }
              await FilePicker.saveFile(
                fileName: 'movimentos.csv',
                bytes: Uint8List.fromList(utf8.encode(b.toString())),
                mimeType: 'text/csv',
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: Text(l.morBackupTitle),
            subtitle: Text(l.morBackupSubtitle),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BackupScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.delete_forever_outlined,
              color: Colors.red,
            ),
            title: Text(
              l.morWipeTransactionsTitle,
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () async {
              if (await confirm(context, l.morWipeTransactionsConfirm))
                s.wipe();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
            title: Text(
              l.morWipeAllTitle,
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () async {
              if (await confirm(context, l.morWipeAllConfirm))
                s.wipe(categories: true);
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l.morPrivacyNote, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

class ImportsScreen extends StatelessWidget {
  const ImportsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = s.db.imports();
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.morImportsTitle)),
      body: list.isEmpty
          ? Center(child: Text(l.morNoImports))
          : ListView(
              children: [
                for (final i in list)
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(i.filename),
                    subtitle: Text(
                      l.morImportItemSubtitle(i.count, fmtDate(i.createdAt)),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: l.morUndoImport,
                      onPressed: () async {
                        if (await confirm(
                          context,
                          l.morRemoveImportQuestion(i.count),
                        ))
                          s.deleteImport(i.id);
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.morCategoriesScreenTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCategoryEditor(context),
        icon: const Icon(Icons.add),
        label: Text(l.morNewCategory),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 90),
        children: [
          for (final r in s.categories.where((c) => c.parentId == null)) ...[
            _tile(context, s, r, 0),
            for (final k in s.categories.where((c) => c.parentId == r.id))
              _tile(context, s, k, 1),
          ],
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, AppState s, Categoria c, int depth) {
    final l = AppLocalizations.of(context)!;
    final count = s.transactions.where((t) => t.categoryId == c.id).length;
    final now = s.currentMonthKey;
    final ended = c.activeTo != null && now.compareTo(c.activeTo!) > 0;
    final future = c.activeFrom != null && now.compareTo(c.activeFrom!) < 0;
    String m(String k) => '${k.substring(5, 7)}/${k.substring(0, 4)}';
    final dates = !c.hasDates
        ? null
        : '${c.activeFrom == null ? l.morFromStart : l.morFromMonth(m(c.activeFrom!))} ${c.activeTo == null ? l.morOpenEnded : l.morToMonth(m(c.activeTo!))}${ended ? ' · ${l.morEnded}' : (future ? ' · ${l.morFuture}' : '')}';
    return Opacity(
      opacity: (ended || c.archived) ? 0.55 : 1,
      child: ListTile(
        contentPadding: EdgeInsets.only(left: 16.0 + depth * 32, right: 8),
        leading: CatBadge(c, size: depth == 0 ? 24 : 20),
        title: Text(
          c.name,
          style: TextStyle(
            fontWeight: depth == 0 ? FontWeight.w700 : null,
            decoration: c.archived ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          [
            if (c.isIncome) l.morIncomeKind,
            if (c.isInvestment) l.morInvestmentKind,
            if (c.both) l.morBothKinds,
            if (dates != null) dates,
            l.morTxnCount(count),
            if (s.rangesOf(c.id).isNotEmpty)
              l.morMandatoryPeriods(s.rangesOf(c.id).length),
            if (c.description.isNotEmpty) c.description,
          ].join(' · '),
        ),
        onTap: () => showCategoryEditor(context, edit: c),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'sub') showCategoryEditor(context, parentId: c.id);
            if (v == 'budget') showBudgetEditor(context, c);
            if (v == 'archive')
              s.updateCategory(c.copyWith(archived: !c.archived));
            if (v == 'dup') {
              final id = s.duplicateForNextYear(c);
              if (context.mounted)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l.morCreatedCategory('${s.cat(id)?.name}')),
                  ),
                );
            }
            if (v == 'delete') {
              if (await confirm(
                    context,
                    l.morDeleteCategoryQuestion(
                      c.name,
                      count,
                      depth == 0 ? l.morSubcategoriesDeleted : '',
                    ),
                  ) &&
                  context.mounted) {
                s.deleteCategory(c.id);
              }
            }
          },
          itemBuilder: (_) => [
            if (depth == 0)
              PopupMenuItem(value: 'sub', child: Text(l.morNewSubcategory)),
            PopupMenuItem(value: 'budget', child: Text(l.budget)),
            if (c.hasDates)
              PopupMenuItem(value: 'dup', child: Text(l.morDuplicateNextYear)),
            PopupMenuItem(
              value: 'archive',
              child: Text(c.archived ? l.morReactivate : l.morArchive),
            ),
            PopupMenuItem(value: 'delete', child: Text(l.delete)),
          ],
        ),
      ),
    );
  }
}
