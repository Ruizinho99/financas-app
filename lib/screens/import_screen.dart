import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../import/parsers.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import '../widgets/common.dart';
import '../widgets/form_kit.dart';
import 'accounts_screen.dart';

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
  List<String> skipped = []; // linhas com data que não foram reconhecidas
  Set<int> excluded = {};
  final cats = <String, int?>{}; // chave do grupo -> categoria escolhida
  final noRemember = <String>{};
  final names = <String, String>{}; // chave do grupo -> nome amigável
  int? accountId; // conta de onde vem o extrato (quando o ficheiro não indica contas)
  bool detectTransfers = true;
  // nome de conta detetado no PDF -> conta da app (0 = criar nova, -1 = sem conta)
  final accountMap = <String, int>{};

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
      skipped = [];
      accountMap.clear();
      excluded = {};
      if (ext == 'pdf') {
        pdfRaw = pdfText(bytes);
        final det = parseStatementDetailed(pdfRaw!);
        rows = det.rows;
        skipped = det.skipped;
        _afterParse();
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

  /// Contas que o extrato indica e deteção de transferências entre elas.
  void _afterParse() {
    final st = context.read<AppState>();
    final names = rows.map((r) => r.account).whereType<String>().toSet();
    accountMap.clear();
    for (final n in names) {
      final ex = st.accounts.where((a) => a.name.toLowerCase() == n.toLowerCase());
      accountMap[n] = ex.isNotEmpty ? ex.first.id : 0;
    }
    _markTransfers();
  }

  void _markTransfers() {
    if (detectTransfers && accountMap.length >= 2) {
      markTransfers(rows);
    } else {
      for (final r in rows) {
        r.isTransfer = false;
      }
    }
  }

  List<ParsedRow> get finalRows => [
        for (var i = 0; i < rows.length; i++)
          if (!excluded.contains(i)) invert ? rows[i].copy(amount: -rows[i].amount) : rows[i]
      ];

  @override
  Widget build(BuildContext context) {
    final fr = finalRows;
    final st0 = context.watch<AppState>();
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
        if (filename != null && rows.isNotEmpty && accountMap.isNotEmpty) _accountsCard(st0),
        if (filename != null && rows.isNotEmpty && accountMap.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TileField(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Conta deste extrato',
              text: st0.account(accountId) == null ? 'Seleciona uma conta (opcional)' : '${st0.account(accountId)!.emoji} ${st0.account(accountId)!.name}'.trim(),
              isHint: st0.account(accountId) == null,
              onTap: () async {
                final id = await pickAccount(context, selected: accountId);
                if (id != null) setState(() => accountId = id == -1 ? null : id);
              },
            ),
          ),
        if (skipped.isNotEmpty) _skippedCard(),
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
                          // contas detetadas no extrato: usa a escolhida ou cria uma nova com o nome do banco
                          final byName = <String, int>{};
                          for (final e in accountMap.entries) {
                            if (e.value == -1) continue;
                            byName[e.key] = e.value == 0 ? st.addAccount(e.key) : e.value;
                          }
                          final (added, dup) = st.importRows(filename!, source, fr,
                              accountId: accountId, accountsByName: byName, categories: chosen, names: {for (final e in names.entries) if (!noRemember.contains(e.key)) e.key: e.value}, remember: chosen.keys.where((k) => chosen[k] != null && !noRemember.contains(k)).toSet());
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
      if (rows[i].isTransfer) continue; // transferências entre contas não se classificam
      groups.putIfAbsent(merchantKey(rows[i].description), () => []).add(i);
    }
    final keys = groups.keys.toList()..sort((a, b) => groups[b]!.length.compareTo(groups[a]!.length));
    final classified = keys.where((k) => (cats[k] ?? st.ruleFor(k)?.categoryId) != null).length;
    return [
      if (rows.any((r) => r.isTransfer)) _transfersCard(),
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
          CategorySelector(
            value: value,
            compact: true,
            when: DateTimeRange(start: idx.map((i) => rows[i].date).reduce((a, b) => a.isBefore(b) ? a : b), end: idx.map((i) => rows[i].date).reduce((a, b) => a.isAfter(b) ? a : b)),
            onChanged: (v) => setState(() => cats[key] = v),
          ),
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

  Widget _accountsCard(AppState st) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Contas neste extrato', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('${accountMap.length} ${accountMap.length == 1 ? 'conta' : 'contas'} detetadas. Escolhe a que corresponde a cada uma na app.', style: Theme.of(context).textTheme.bodySmall),
            for (final name in accountMap.keys) ...[
              const SizedBox(height: 14),
              Text('${name}  ·  ${rows.where((r) => r.account == name).length} movimentos', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                key: ValueKey('acc-$name-${accountMap[name]}-${st.accounts.length}'),
                initialValue: accountMap[name],
                isExpanded: true,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.account_balance_wallet_outlined)),
                items: [
                  DropdownMenuItem(value: 0, child: Text('➕  Criar conta “$name”')),
                  for (final a in st.accounts) DropdownMenuItem(value: a.id, child: Text('${a.emoji} ${a.name}'.trim())),
                  const DropdownMenuItem(value: -1, child: Text('Sem conta')),
                ],
                onChanged: (v) => setState(() => accountMap[name] = v ?? 0),
              ),
            ],
            if (accountMap.length >= 2)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Detetar transferências entre estas contas'),
                subtitle: const Text('Saída numa conta e entrada noutra, do mesmo valor, não contam como despesa nem receita.'),
                value: detectTransfers,
                onChanged: (v) => setState(() {
                  detectTransfers = v;
                  _markTransfers();
                }),
              ),
          ]),
        ),
      );

  Widget _transfersCard() {
    final list = [for (var i = 0; i < rows.length; i++) if (rows[i].isTransfer) i];
    return Card(
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const Icon(Icons.swap_horiz),
        title: Text('${list.length} transferências entre contas', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Não precisam de categoria e ficam fora das despesas e receitas.'),
        children: [
          for (final i in list)
            ListTile(
              dense: true,
              title: Text(rows[i].description, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text('${fmtDate(rows[i].date)} · ${rows[i].account ?? ''}'),
              trailing: MoneyText(invert ? -rows[i].amount : rows[i].amount, colored: false),
            ),
        ],
      ),
    );
  }

  Widget _skippedCard() => Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.onErrorContainer),
          title: Text(
            '${skipped.length} ${skipped.length == 1 ? 'linha parece' : 'linhas parecem'} movimentos mas não ${skipped.length == 1 ? 'foi reconhecida' : 'foram reconhecidas'}',
            style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer, fontWeight: FontWeight.w600),
          ),
          subtitle: Text('Lidos: ${rows.length}. Toca para ver as linhas ignoradas.', style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
          children: [
            for (final l in skipped.take(30)) ListTile(dense: true, title: Text(l, maxLines: 2, overflow: TextOverflow.ellipsis)),
            if (skipped.length > 30) Padding(padding: const EdgeInsets.all(12), child: Text('… e mais ${skipped.length - 30}')),
            const Padding(padding: EdgeInsets.fromLTRB(16, 4, 16, 12), child: Text('Se for um extrato do teu banco, exporta em CSV/Excel no homebanking ou envia-me um exemplo (com os dados tapados) para eu ajustar o leitor.')),
          ],
        ),
      );

  Widget _pdfOptions() => Card(
        child: ListTile(
          title: const Text('Ano das datas sem ano'),
          subtitle: const Text('Só afeta datas escritas como dd-mm'),
          trailing: DropdownButton<int>(
            value: year,
            items: [for (var y = DateTime.now().year + 1; y >= 2015; y--) DropdownMenuItem(value: y, child: Text('$y'))],
            onChanged: (v) => setState(() {
              year = v!;
              final det = parseStatementDetailed(pdfRaw!, defaultYear: year);
              rows = det.rows;
              skipped = det.skipped;
              _afterParse();
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
            decoration: InputDecoration(labelText: title, isDense: true),
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
