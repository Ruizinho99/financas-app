import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../db/database.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import '../widgets/common.dart';
import 'appearance_screen.dart';
import 'budget_screen.dart' show showBudgetEditor;
import 'classify_screen.dart';
import 'import_screen.dart';
import 'transactions_screen.dart' show confirm;

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Mais')),
      body: ListView(children: [
        ListTile(leading: const Icon(Icons.palette_outlined), title: const Text('Aparência'), subtitle: const Text('Modo escuro e cores'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppearanceScreen()))),
        ListTile(leading: const Icon(Icons.category_outlined), title: const Text('Categorias e subcategorias'), subtitle: Text('${s.categories.length} categorias'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen()))),
        ListTile(leading: const Icon(Icons.rule), title: const Text('Regras memorizadas'), subtitle: Text('${s.rules.length} regras'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RulesScreen()))),
        ListTile(leading: const Icon(Icons.upload_file), title: const Text('Importar extrato'), subtitle: const Text('PDF, CSV ou Excel'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportScreen()))),
        ListTile(leading: const Icon(Icons.history), title: const Text('Histórico de importações'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportsScreen()))),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.file_download_outlined),
          title: const Text('Exportar movimentos (CSV)'),
          onTap: () async {
            final b = StringBuffer('﻿data;descricao;montante;categoria;nota\n');
            for (final t in s.transactions.reversed) {
              String q(String v) => '"${v.replaceAll('"', '""')}"';
              b.writeln('${isoDate(t.date)};${q(t.description)};${(t.amount / 100).toStringAsFixed(2)};${q(s.path(t.categoryId))};${q(t.note)}');
            }
            await FilePicker.saveFile(fileName: 'movimentos.csv', bytes: Uint8List.fromList(utf8.encode(b.toString())), mimeType: 'text/csv');
          },
        ),
        ListTile(
          leading: const Icon(Icons.backup_outlined),
          title: const Text('Cópia de segurança (base de dados)'),
          subtitle: const Text('Guarda um ficheiro com todos os teus dados'),
          onTap: () async {
            final f = await Db.dbFile();
            await FilePicker.saveFile(fileName: 'financas-backup.db', bytes: await f.readAsBytes());
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
          title: const Text('Apagar todos os movimentos', style: TextStyle(color: Colors.red)),
          onTap: () async {
            if (await confirm(context, 'Apagar TODOS os movimentos, regras e salários? As categorias mantêm-se. Não é possível desfazer.')) s.wipe();
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
          title: const Text('Apagar tudo, incluindo categorias', style: TextStyle(color: Colors.red)),
          onTap: () async {
            if (await confirm(context, 'Apagar TUDO: movimentos, categorias, orçamentos, regras e salários? Não é possível desfazer.')) s.wipe(categories: true);
          },
        ),
        const Padding(padding: EdgeInsets.all(16), child: Text('Todos os dados ficam guardados apenas neste telemóvel. A app não usa internet.', textAlign: TextAlign.center)),
      ]),
    );
  }
}

class ImportsScreen extends StatelessWidget {
  const ImportsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = s.db.imports();
    return Scaffold(
      appBar: AppBar(title: const Text('Importações')),
      body: list.isEmpty
          ? const Center(child: Text('Ainda sem importações.'))
          : ListView(children: [
              for (final i in list)
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(i.filename),
                  subtitle: Text('${fmtDate(i.createdAt)} · ${i.count} movimentos'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Desfazer importação',
                    onPressed: () async {
                      if (await confirm(context, 'Remover os ${i.count} movimentos desta importação?')) s.deleteImport(i.id);
                    },
                  ),
                ),
            ]),
    );
  }
}

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Categorias')),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => showCategoryEditor(context), icon: const Icon(Icons.add), label: const Text('Categoria')),
      body: ListView(padding: const EdgeInsets.only(bottom: 90), children: [
        for (final r in s.categories.where((c) => c.parentId == null)) ...[
          _tile(context, s, r, 0),
          for (final k in s.categories.where((c) => c.parentId == r.id)) _tile(context, s, k, 1),
        ],
      ]),
    );
  }

  Widget _tile(BuildContext context, AppState s, Categoria c, int depth) {
    final count = s.transactions.where((t) => t.categoryId == c.id).length;
    return ListTile(
      contentPadding: EdgeInsets.only(left: 16.0 + depth * 32, right: 8),
      leading: Dot(c.color, size: depth == 0 ? 14 : 10),
      title: Text(c.name, style: TextStyle(fontWeight: depth == 0 ? FontWeight.w700 : null, decoration: c.archived ? TextDecoration.lineThrough : null)),
      subtitle: Text([if (c.isIncome) 'Rendimento', '$count mov.', if (s.rangesOf(c.id).isNotEmpty) 'Obrigatória em ${s.rangesOf(c.id).length} período(s)', if (c.description.isNotEmpty) c.description].join(' · ')),
      onTap: () => showCategoryEditor(context, edit: c),
      trailing: PopupMenuButton<String>(
        onSelected: (v) async {
          if (v == 'sub') showCategoryEditor(context, parentId: c.id);
          if (v == 'budget') showBudgetEditor(context, c);
          if (v == 'archive') s.updateCategory(Categoria(id: c.id, name: c.name, parentId: c.parentId, isIncome: c.isIncome, color: c.color, description: c.description, budgetType: c.budgetType, budgetPercent: c.budgetPercent, budgetValue: c.budgetValue, hasBudget: c.hasBudget, archived: !c.archived));
          if (v == 'delete') {
            if (await confirm(context, 'Apagar “${c.name}”? Os $count movimentos ficam sem categoria${depth == 0 ? ' e as subcategorias são apagadas' : ''}.') && context.mounted) {
              s.deleteCategory(c.id);
            }
          }
        },
        itemBuilder: (_) => [
          if (depth == 0) const PopupMenuItem(value: 'sub', child: Text('Nova subcategoria')),
          const PopupMenuItem(value: 'budget', child: Text('Orçamento')),
          PopupMenuItem(value: 'archive', child: Text(c.archived ? 'Reativar' : 'Arquivar')),
          const PopupMenuItem(value: 'delete', child: Text('Apagar')),
        ],
      ),
    );
  }
}
