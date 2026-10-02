import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../import/parsers.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import '../widgets/common.dart';

/// Importação de extratos PDF, CSV e Excel (tudo processado no telemóvel).
class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});
  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  String? filename;
  String source = '';
  List<List<String>>? table;
  ColumnMapping mapping = ColumnMapping();
  List<ParsedRow> rows = [];
  bool busy = false;
  bool invert = false;
  String? error;
  int year = DateTime.now().year;
  String? pdfRaw;
  Set<int> excluded = {};
  final cats = <String, int?>{}; // chave do grupo -> categoria escolhida
  final noRemember = <String>{};
  final names = <String, String>{}; // chave do grupo -> nome amigável

  Future<void> pick() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'csv', 'xlsx', 'txt']);
      if (files.isEmpty) {
        setState(() => busy = false);
        return;
      }
      final f = files.first;
      final bytes = await f.readAsBytes();
      final ext = f.name.split('.').last.toLowerCase();
      filename = f.name;
      source = ext == 'pdf' ? 'pdf' : (ext == 'xlsx' ? 'xlsx' : 'csv');
      table = null;
      pdfRaw = null;
      excluded = {};
      if (ext == 'pdf') {
        pdfRaw = pdfText(bytes);
        rows = parseStatementText(pdfRaw!);
        if (rows.isNotEmpty) year = rows.first.date.year;
      } else {
        table = ext == 'xlsx' ? parseXlsx(bytes) : parseCsv(decodeText(bytes));
        mapping = guessMapping(table!);
        _rebuild();
      }
      if (rows.isEmpty) {
        error = ext == 'pdf'
            ? 'Não encontrei movimentos neste PDF. Pode ser um PDF digitalizado (imagem) ou um formato diferente. Tenta exportar CSV/Excel no homebanking.'
            : 'Não consegui ler movimentos. Ajusta as colunas abaixo.';
      }
    } catch (e) {
      error = 'Erro ao ler o ficheiro: $e';
      rows = [];
    }
    setState(() => busy = false);
  }

  void _rebuild() {
    rows = rowsFromTable(table!, mapping, defaultYear: year);
    excluded = {};
  }

  List<ParsedRow> get finalRows => [
        for (var i = 0; i < rows.length; i++)
          if (!excluded.contains(i)) invert ? ParsedRow(rows[i].date, rows[i].description, -rows[i].amount, rows[i].balance) : rows[i]
      ];

  @override
  Widget build(BuildContext context) {
    final fr = finalRows;
    final income = fr.where((r) => r.amount > 0).fold(0, (s, r) => s + r.amount);
    final expense = fr.where((r) => r.amount < 0).fold(0, (s, r) => s + r.amount);
    return Scaffold(
      appBar: AppBar(title: const Text('Importar extrato')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Formatos suportados: PDF (com texto), CSV e Excel (.xlsx). O ficheiro é lido apenas no telemóvel e nunca sai daqui.'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: busy ? null : pick,
                icon: const Icon(Icons.upload_file),
                label: Text(filename == null ? 'Escolher ficheiro' : 'Escolher outro ficheiro'),
              ),
              if (filename != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Ficheiro: $filename')),
            ]),
          ),
        ),
        if (busy) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
        if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Card(color: Theme.of(context).colorScheme.errorContainer, child: Padding(padding: const EdgeInsets.all(12), child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)))),
          ),
        if (table != null) _mappingCard(),
        if (filename != null && source == 'pdf' && rows.isNotEmpty) _pdfOptions(),
        if (rows.isNotEmpty) ...[
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${fr.length} movimentos', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('Entradas ${fmtMoney(income)}   ·   Saídas ${fmtMoney(expense)}'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Inverter sinais'),
                  subtitle: const Text('Usa se as despesas aparecem como positivas'),
                  value: invert,
                  onChanged: (v) => setState(() => invert = v),
                ),
              ]),
            ),
          ),
          ..._groupCards(context),
          const SizedBox(height: 80),
        ],
      ]),
      bottomNavigationBar: rows.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: Text('Importar ${fr.length} movimentos'),
                  onPressed: fr.isEmpty
                      ? null
                      : () {
                          final st = context.read<AppState>();
                          final chosen = Map<String, int?>.of(cats);
                          final (added, dup) = st.importRows(filename!, source, fr,
                              categories: chosen, names: {for (final e in names.entries) if (!noRemember.contains(e.key)) e.key: e.value}, remember: chosen.keys.where((k) => chosen[k] != null && !noRemember.contains(k)).toSet());
                          final unclassified = context.read<AppState>().unclassifiedGroups().length;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('$added importados, $dup duplicados ignorados. $unclassified grupos por classificar.')));
                        },
                ),
              ),
            ),
    );
  }

  List<Widget> _groupCards(BuildContext context) {
    final st = context.watch<AppState>();
    final groups = <String, List<int>>{};
    for (var i = 0; i < rows.length; i++) {
      groups.putIfAbsent(merchantKey(rows[i].description), () => []).add(i);
    }
    final keys = groups.keys.toList()..sort((a, b) => groups[b]!.length.compareTo(groups[a]!.length));
    final classified = keys.where((k) => (cats[k] ?? st.ruleFor(k)?.categoryId) != null).length;
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
        child: Text('Classificação: $classified de ${keys.length} grupos', style: Theme.of(context).textTheme.titleMedium),
      ),
      const Padding(
        padding: EdgeInsets.fromLTRB(4, 0, 4, 4),
        child: Text('Movimentos com o mesmo nome estão juntos. Escolhe a categoria e a subcategoria de cada grupo (ou deixa por classificar). As regras já memorizadas vêm preenchidas.'),
      ),
      for (final k in keys) _importGroup(context, st, k, groups[k]!),
    ];
  }

  Widget _importGroup(BuildContext context, AppState st, String key, List<int> idx) {
    final rule = st.ruleFor(key);
    final value = cats.containsKey(key) ? cats[key] : rule?.categoryId;
    final active = idx.where((i) => !excluded.contains(i)).toList();
    final total = active.fold(0, (a, i) => a + (invert ? -rows[i].amount : rows[i].amount));
    final isNewRule = value != null && (rule == null || rule.categoryId != value);
    final shownName = names.containsKey(key) ? names[key]! : (rule?.label ?? '');
    final byName = st.groupByName(shownName);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text(shownName.isNotEmpty ? shownName : key, style: const TextStyle(fontWeight: FontWeight.w700))),
            MoneyText(total),
          ]),
          Text('Original: ${rows[idx.first].description}', maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
          Text('${active.length} de ${idx.length} movimentos${rule != null ? ' · regra memorizada' : ''}', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          Autocomplete<String>(
            key: ValueKey('name-$key'),
            initialValue: TextEditingValue(text: shownName),
            optionsBuilder: (v) {
              final q = v.text.trim().toLowerCase();
              if (q.isEmpty) return const Iterable<String>.empty();
              return st.groups.map((g) => g.name).where((n) => n.toLowerCase().contains(q) && n.toLowerCase() != q);
            },
            onSelected: (n) => setState(() {
              names[key] = n;
              final g = st.groupByName(n);
              if (g?.categoryId != null) cats[key] = g!.categoryId;
            }),
            fieldViewBuilder: (ctx, controller, focus, _) => TextField(
              controller: controller,
              focusNode: focus,
              decoration: InputDecoration(
                labelText: 'Nome ou grupo (opcional)',
                hintText: 'Ex.: Ginásio, Restaurante Arminda…',
                prefixIcon: const Icon(Icons.label_outline),
                border: const OutlineInputBorder(),
                isDense: true,
                helperText: byName != null ? 'Junta-se ao grupo “${byName.name}” (${st.rulesOfGroup(byName.id).length} títulos)' : null,
              ),
              onChanged: (v) => setState(() {
                names[key] = v;
                final g = st.groupByName(v);
                if (g?.categoryId != null && !cats.containsKey(key)) cats[key] = g!.categoryId;
              }),
            ),
          ),
          const SizedBox(height: 10),
          CategorySelector(value: value, compact: true, onChanged: (v) => setState(() => cats[key] = v)),
          if (isNewRule || (names[key]?.trim().isNotEmpty ?? false))
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Memorizar nome e categoria para o futuro'),
              value: !noRemember.contains(key),
              onChanged: (v) => setState(() => v! ? noRemember.remove(key) : noRemember.add(key)),
            ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            shape: const Border(),
            collapsedShape: const Border(),
            title: const Text('Ver movimentos'),
            children: [
              for (final i in idx)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: !excluded.contains(i),
                  onChanged: (v) => setState(() => v! ? excluded.remove(i) : excluded.add(i)),
                  title: Text(rows[i].description, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(fmtDate(rows[i].date)),
                  secondary: MoneyText(invert ? -rows[i].amount : rows[i].amount),
                ),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _pdfOptions() => Card(
        child: ListTile(
          title: const Text('Ano das datas sem ano'),
          subtitle: const Text('Só afeta datas escritas como dd-mm'),
          trailing: DropdownButton<int>(
            value: year,
            items: [for (var y = DateTime.now().year + 1; y >= 2015; y--) DropdownMenuItem(value: y, child: Text('$y'))],
            onChanged: (v) => setState(() {
              year = v!;
              rows = parseStatementText(pdfRaw!, defaultYear: year);
            }),
          ),
        ),
      );

  Widget _mappingCard() {
    final t = table!;
    final cols = t.fold(0, (a, r) => r.length > a ? r.length : a);
    final header = mapping.headerRow >= 0 && mapping.headerRow < t.length ? t[mapping.headerRow] : <String>[];
    String label(int c) => header.length > c && header[c].trim().isNotEmpty ? header[c].trim() : 'Coluna ${c + 1}';
    Widget dd(String title, int? value, void Function(int?) set, {bool optional = true}) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: DropdownButtonFormField<int?>(
            initialValue: value,
            decoration: InputDecoration(labelText: title, border: const OutlineInputBorder(), isDense: true),
            items: [
              if (optional) const DropdownMenuItem(value: null, child: Text('— não usar —')),
              for (var c = 0; c < cols; c++)
                DropdownMenuItem(value: c, child: Text('${label(c)}  ·  ${t.length > mapping.headerRow + 1 && c < t[mapping.headerRow + 1 < t.length ? mapping.headerRow + 1 : 0].length ? t[mapping.headerRow + 1 < t.length ? mapping.headerRow + 1 : 0][c] : ''}', overflow: TextOverflow.ellipsis)),
            ],
            isExpanded: true,
            onChanged: (v) => setState(() {
              set(v);
              _rebuild();
            }),
          ),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Colunas do ficheiro', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          dd('Linha de cabeçalho', mapping.headerRow, (v) => mapping.headerRow = v ?? -1, optional: false),
          dd('Data', mapping.date, (v) => mapping.date = v),
          dd('Descrição', mapping.description, (v) => mapping.description = v),
          dd('Montante (com sinal)', mapping.amount, (v) => mapping.amount = v),
          if (mapping.amount == null) ...[
            dd('Débito (saídas)', mapping.debit, (v) => mapping.debit = v),
            dd('Crédito (entradas)', mapping.credit, (v) => mapping.credit = v),
          ],
          dd('Saldo (opcional)', mapping.balance, (v) => mapping.balance = v),
        ]),
      ),
    );
  }
}
