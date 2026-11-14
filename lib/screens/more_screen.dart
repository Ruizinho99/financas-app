import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../update/update_checker.dart';

import '../l10n/app_localizations.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import '../widgets/category_editor.dart';
import '../widgets/category_merge.dart';
import '../widgets/common.dart';
import 'accounts_screen.dart';
import 'appearance_screen.dart';
import 'analysis_screen.dart';
import 'budget_screen.dart' show BudgetScreen, showBudgetEditor;
import 'classify_screen.dart';
import 'month_cycle_screen.dart';
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
            title: Text(
              Localizations.localeOf(context).languageCode == 'en'
                  ? 'Planning and budget'
                  : 'Planeamento e orçamento',
            ),
            subtitle: Text(
              Localizations.localeOf(context).languageCode == 'en'
                  ? 'Plan each month and follow what you spend, by type'
                  : 'Planeia cada mês e acompanha o que gastas, por tipo',
            ),
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
          if (selfUpdateSupported)
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
            subtitle: Text(
              isIosPlatform ? l.iosBackupSubtitle : l.morBackupSubtitle,
            ),
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

/// Árvore de categorias com profundidade ilimitada: cada ramo expande/recolhe.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  // ramos recolhidos (estado local); por omissão a árvore aparece toda aberta
  final collapsed = <int>{};

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final l = AppLocalizations.of(context)!;
    // filhas diretas, incluindo as arquivadas (aparecem esbatidas)
    final kids = <int?, List<Categoria>>{};
    for (final c in s.categories) {
      (kids[c.parentId] ??= []).add(c);
    }
    final tiles = <Widget>[];
    final seen = <int>{};
    void walk(Categoria c, int depth) {
      if (!seen.add(c.id)) return;
      final sub = kids[c.id] ?? const <Categoria>[];
      tiles.add(_tile(context, s, c, depth, sub.length));
      if (!collapsed.contains(c.id)) {
        for (final k in sub) {
          walk(k, depth + 1);
        }
      }
    }

    for (final r in kids[null] ?? const <Categoria>[]) {
      walk(r, 0);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(l.morCategoriesScreenTitle),
        actions: [
          IconButton(
            tooltip: l.ctcCopyTooltip,
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: s.categories.isEmpty
                ? null
                : () async {
                    await Clipboard.setData(
                      ClipboardData(text: s.categoryTreeText()),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.ctcCopied(s.categories.length))),
                    );
                  },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCategoryEditor(context),
        icon: const Icon(Icons.add),
        label: Text(l.morNewCategory),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 90),
        children: tiles,
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    AppState s,
    Categoria c,
    int depth,
    int kidCount,
  ) {
    final l = AppLocalizations.of(context)!;
    final count = s.transactions.where((t) => t.categoryId == c.id).length;
    final now = s.currentMonthKey;
    final ended = c.activeTo != null && now.compareTo(c.activeTo!) > 0;
    final future = c.activeFrom != null && now.compareTo(c.activeFrom!) < 0;
    String m(String k) => '${k.substring(5, 7)}/${k.substring(0, 4)}';
    final dates = !c.hasDates
        ? null
        : '${c.activeFrom == null ? l.morFromStart : l.morFromMonth(m(c.activeFrom!))} ${c.activeTo == null ? l.morOpenEnded : l.morToMonth(m(c.activeTo!))}${ended ? ' · ${l.morEnded}' : (future ? ' · ${l.morFuture}' : '')}';
    final isCollapsed = collapsed.contains(c.id);
    // a indentação para de crescer a partir de certa profundidade, para não esmagar o nome
    final indent = (depth > 6 ? 6 : depth) * 20.0;
    return Opacity(
      key: ValueKey('cat-tile-${c.id}'),
      opacity: (ended || c.archived) ? 0.55 : 1,
      child: ListTile(
        contentPadding: EdgeInsets.only(left: 8.0 + indent, right: 4),
        // seta para expandir/recolher (espaço reservado nas folhas, para alinhar)
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              child: kidCount == 0
                  ? null
                  : IconButton(
                      key: ValueKey('cat-toggle-${c.id}'),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      tooltip: isCollapsed ? l.ctbExpand : l.ctbCollapse,
                      icon: Icon(
                        isCollapsed ? Icons.chevron_right : Icons.expand_more,
                      ),
                      onPressed: () => setState(() {
                        if (!collapsed.remove(c.id)) collapsed.add(c.id);
                      }),
                    ),
            ),
            CatBadge(c, size: depth == 0 ? 24 : 20),
          ],
        ),
        title: Text(
          c.name,
          style: TextStyle(
            fontWeight: depth == 0 ? FontWeight.w700 : null,
            decoration: c.archived ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          [
            if (kidCount > 0) l.ctbSubCount(kidCount),
            if (c.isInvestment) l.morInvestmentKind,
            if (c.isSavings) (Localizations.localeOf(context).languageCode == 'en' ? 'Savings' : 'Poupança'),
            if (dates != null) dates,
            l.morTxnCount(count),
            if (s.rangesOf(c.id).isNotEmpty)
              l.morMandatoryPeriods(s.rangesOf(c.id).length),
            if (c.description.isNotEmpty) c.description,
          ].join(' · '),
        ),
        onTap: () => showCategoryEditor(context, edit: c),
        trailing: PopupMenuButton<String>(
          key: ValueKey('cat-menu-${c.id}'),
          onSelected: (v) async {
            if (v == 'sub') {
              await showCategoryEditor(context, parentId: c.id);
              // a nova filha fica à vista
              if (mounted) setState(() => collapsed.remove(c.id));
            }
            if (v == 'move') await moveCategoryFlow(context, s, c);
            if (v == 'merge') await mergeCategoryFlow(context, s, c);
            if (v == 'edit') showCategoryEditor(context, edit: c);
            if (v == 'budget') showBudgetEditor(context, c);
            if (v == 'archive') {
              s.updateCategory(c.copyWith(archived: !c.archived));
            }
            if (v == 'dup') {
              final id = s.duplicateForNextYear(c);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l.morCreatedCategory('${s.cat(id)?.name}')),
                  ),
                );
              }
            }
            if (v == 'delete') {
              // apagar leva a subárvore toda; os movimentos de todas ficam sem categoria
              final sub = s.subtreeIds(c.id);
              final subs = sub.length - 1;
              final txns = s.transactions
                  .where((t) => sub.contains(t.categoryId))
                  .length;
              if (await confirm(
                    context,
                    l.ctbDeleteQuestion(c.name, subs, txns),
                  ) &&
                  context.mounted) {
                s.deleteCategory(c.id);
              }
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'sub', child: Text(l.morNewSubcategory)),
            PopupMenuItem(value: 'move', child: Text(l.ctbMoveMenu)),
            PopupMenuItem(value: 'merge', child: Text(l.mrgMenu)),
            PopupMenuItem(value: 'edit', child: Text(l.bpEdit)),
            PopupMenuItem(value: 'budget', child: Text(l.budget)),
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
