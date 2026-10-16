import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import '../util/receipts.dart';
import '../widgets/category_picker.dart';
import '../widgets/form_kit.dart';
import 'accounts_screen.dart';
import 'import_screen.dart';
import 'transactions_screen.dart' show confirm;

enum _Type { expense, income, transfer }

/// Novo movimento / editar movimento (ecrã completo).
class TxnFormScreen extends StatefulWidget {
  final Txn? edit;
  const TxnFormScreen({super.key, this.edit});
  @override
  State<TxnFormScreen> createState() => _TxnFormScreenState();
}

class _TxnFormScreenState extends State<TxnFormScreen> {
  late _Type type;
  late DateTime date = widget.edit?.date ?? DateTime.now();
  late final amount = TextEditingController(
    text: widget.edit == null
        ? ''
        : (widget.edit!.amount.abs() / 100)
              .toStringAsFixed(2)
              .replaceAll('.', ','),
  );
  late final desc = TextEditingController(text: widget.edit?.description ?? '');
  late int? categoryId = widget.edit?.categoryId;
  late int? accountId = widget.edit?.accountId;
  int? toAccountId;
  late int? investId = widget
      .edit
      ?.investAccountId; // transferência para/de uma plataforma de investimento
  // receita que anula (total ou parcialmente) uma despesa
  late int? reversesId = widget.edit?.reversesId;
  late final reversedCtrl = TextEditingController(
    text: (widget.edit?.reversedCents ?? 0) > 0
        ? _centsText(widget.edit!.reversedCents)
        : '',
  );
  late String? receipt = widget.edit?.receiptPath;
  late bool transferIn =
      (widget.edit?.amount ?? -1) > 0; // só ao editar uma transferência
  bool newReceipt =
      false; // recibo anexado nesta sessão (apagar se não guardar)
  bool saved = false;
  String? error;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    type = e == null
        ? _Type.expense
        : (e.isTransfer
              ? _Type.transfer
              : (e.amount > 0 ? _Type.income : _Type.expense));
  }

  @override
  void dispose() {
    if (!saved && newReceipt) Receipts.delete(receipt);
    reversedCtrl.dispose();
    super.dispose();
  }

  static String _centsText(int cents) =>
      (cents.abs() / 100).toStringAsFixed(2).replaceAll('.', ',');

  /// Despesa pelo id (nulo se já não existir).
  Txn? _expenseById(AppState s, int? id) {
    if (id == null) return null;
    for (final t in s.transactions) {
      if (t.id == id) return t;
    }
    return null;
  }

  void _setType(_Type t, AppState s) => setState(() {
    type = t;
    if (t != _Type.income) reversesId = null;
    if (t == _Type.transfer) categoryId = null;
    final c = s.cat(categoryId);
    if (c != null && !c.both && c.isIncome != (t == _Type.income))
      categoryId = null;
  });

  int? _cents() {
    final t = amount.text.trim();
    if (t.isEmpty) return null;
    final v = parseCents(t);
    if (v != null) return v.abs();
    final e = evalExpression(t);
    return e == null ? null : (e * 100).round().abs();
  }

  Future<void> _calculator() async {
    final v = await showCalculator(context, initial: amount.text);
    if (v != null)
      setState(
        () => amount.text = (v.abs() / 100)
            .toStringAsFixed(2)
            .replaceAll('.', ','),
      );
  }

  Future<void> _receiptMenu() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recibo',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
              ),
            ),
            if (receipt != null)
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: const Text('Ver recibo'),
                onTap: () => Navigator.pop(ctx, 'view'),
              ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tirar foto'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Escolher ficheiro (PDF ou imagem)'),
              onTap: () => Navigator.pop(ctx, 'file'),
            ),
            if (receipt != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remover recibo'),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    try {
      String? name;
      switch (choice) {
        case 'view':
          await _viewReceipt();
          return;
        case 'remove':
          if (newReceipt) Receipts.delete(receipt);
          setState(() {
            receipt = null;
            newReceipt = false;
          });
          return;
        case 'camera':
        case 'gallery':
          final x = await ImagePicker().pickImage(
            source: choice == 'camera'
                ? ImageSource.camera
                : ImageSource.gallery,
            imageQuality: 85,
          );
          if (x != null)
            name = await Receipts.saveBytes(x.name, await x.readAsBytes());
        case 'file':
          final files = await FilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
          );
          if (files.isNotEmpty)
            name = await Receipts.saveBytes(
              files.first.name,
              await files.first.readAsBytes(),
            );
      }
      if (name != null) {
        if (newReceipt) Receipts.delete(receipt);
        setState(() {
          receipt = name;
          newReceipt = true;
        });
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível anexar o recibo: $e')),
        );
    }
  }

  Future<void> _viewReceipt() async {
    final f = Receipts.file(receipt);
    if (f == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ficheiro do recibo não encontrado.')),
      );
      return;
    }
    if (Receipts.isImage(receipt!)) {
      await showDialog(
        context: context,
        builder: (ctx) => Dialog(
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              InteractiveViewer(child: Image.file(f)),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      await OpenFilex.open(f.path);
    }
  }

  void _save(AppState s) {
    final cents = _cents();
    if (cents == null || cents == 0) {
      setState(() => error = 'Indica um montante válido.');
      return;
    }
    final c = s.cat(categoryId);
    var d = desc.text.trim();
    if (d.isEmpty) {
      d = switch (type) {
        _Type.transfer =>
          toAccountId != null
              ? 'Transferência para ${s.account(toAccountId)?.name ?? ''}'
                    .trim()
              : 'Transferência',
        _ => c?.name ?? (type == _Type.income ? 'Receita' : 'Despesa'),
      };
    }
    // anulação de uma despesa (só numa receita)
    int? revId;
    var revCents = 0;
    if (type == _Type.income && reversesId != null) {
      final exp = _expenseById(s, reversesId);
      revCents = (parseCents(reversedCtrl.text) ?? 0).abs();
      if (exp == null) {
        setState(() => error = 'A despesa anulada já não existe.');
        return;
      }
      if (revCents <= 0) {
        setState(() => error = 'Indica quanto da despesa é anulado.');
        return;
      }
      if (revCents > cents) {
        setState(() => error = 'A anulação não pode ser maior que a receita.');
        return;
      }
      final left = s.reversibleLeft(exp, exceptTxnId: widget.edit?.id);
      if (revCents > left) {
        setState(
          () =>
              error = 'Só faltam ${fmtMoney(left)} para anular nesta despesa.',
        );
        return;
      }
      revId = exp.id;
    }
    final e = widget.edit;
    saved = true;
    if (e == null) {
      if (type == _Type.transfer && investId != null) {
        // entrega a uma plataforma de investimento: um só movimento, associado à plataforma
        s.addManual(
          date: date,
          description: d,
          amount: -cents,
          accountId: accountId,
          isTransfer: true,
          receiptPath: receipt,
          investAccountId: investId,
        );
      } else if (type == _Type.transfer) {
        s.addTransfer(
          date: date,
          description: d,
          amount: cents,
          fromAccount: accountId,
          toAccount: toAccountId,
          receiptPath: receipt,
        );
      } else {
        s.addManual(
          date: date,
          description: d,
          amount: type == _Type.expense ? -cents : cents,
          categoryId: categoryId,
          accountId: accountId,
          receiptPath: receipt,
          reversesId: revId,
          reversedCents: revCents,
        );
      }
    } else {
      final signed = type == _Type.expense
          ? -cents
          : (type == _Type.income ? cents : (transferIn ? cents : -cents));
      s.updateTxn(
        Txn(
          id: e.id,
          date: date,
          description: d,
          amount: signed,
          balance: e.balance,
          categoryId: type == _Type.transfer ? null : categoryId,
          note: e.note,
          source: e.source,
          merchantKey: e.merchantKey,
          importId: e.importId,
          accountId: accountId,
          isTransfer: type == _Type.transfer,
          receiptPath: receipt,
          investAccountId: type == _Type.transfer ? investId : null,
          reversesId: revId,
          reversedCents: revCents,
        ),
      );
      if (e.receiptPath != null && e.receiptPath != receipt)
        Receipts.delete(e.receiptPath);
    }
    Navigator.pop(context);
  }

  /// As categorias mais usadas neste tipo de movimento, para escolher com um toque.
  List<Categoria> _suggestions(AppState s) {
    final count = <int, int>{};
    for (final t in s.transactions) {
      final id = t.categoryId;
      if (id == null || t.isTransfer) continue;
      if ((type == _Type.income) != (t.amount > 0)) continue;
      count[id] = (count[id] ?? 0) + 1;
    }
    final ids = count.keys.toList()
      ..sort((a, b) => count[b]!.compareTo(count[a]!));
    return [
      for (final id in ids.take(4))
        if (s.cat(id) != null) s.cat(id)!,
    ];
  }

  String? _reversalHelp(AppState s) {
    final exp = _expenseById(s, reversesId);
    if (exp == null) return null;
    final left = s.reversibleLeft(exp, exceptTxnId: widget.edit?.id);
    return 'Ainda se pode anular ${fmtMoney(left)} desta despesa. A parte anulada não conta como gasto nem como receita na Análise.';
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => date = d);
  }

  Future<void> _pickCategory(AppState s) async {
    final id = await chooseCategory(
      context,
      selected: categoryId,
      income: type == _Type.income,
      when: DateTimeRange(start: date, end: date),
    );
    if (id == null) return;
    setState(() => categoryId = id == -1 ? null : id);
  }

  /// Escolhe a despesa que esta receita anula. Mostra as despesas recentes que ainda têm valor por anular.
  Future<void> _pickExpense(AppState s) async {
    final id = await showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        var q = '';
        return StatefulBuilder(
          builder: (ctx, set) {
            final query = q.trim().toLowerCase();
            final list =
                [
                      for (final t in s.transactions)
                        if (t.amount < 0 &&
                            !t.isTransfer &&
                            t.id != widget.edit?.id &&
                            (t.id == reversesId ||
                                s.reversibleLeft(
                                      t,
                                      exceptTxnId: widget.edit?.id,
                                    ) >
                                    0))
                          t,
                    ]
                    .where(
                      (t) =>
                          query.isEmpty ||
                          '${s.displayName(t)} ${t.description}'
                              .toLowerCase()
                              .contains(query),
                    )
                    .take(200)
                    .toList();
            return SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.75,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Procurar despesa',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                      onChanged: (v) => set(() => q = v),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.close),
                          title: const Text('Não anula nenhuma despesa'),
                          onTap: () => Navigator.pop(ctx, -1),
                        ),
                        for (final t in list)
                          ListTile(
                            selected: t.id == reversesId,
                            title: Text(
                              s.displayName(t),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${fmtDate(t.date)} · ${fmtMoney(-t.amount)}'
                              ' · por anular ${fmtMoney(s.reversibleLeft(t, exceptTxnId: widget.edit?.id))}',
                            ),
                            onTap: () => Navigator.pop(ctx, t.id),
                          ),
                        if (list.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: Text('Nenhuma despesa para anular.'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (id == null) return;
    setState(() {
      reversesId = id == -1 ? null : id;
      error = null;
      final exp = _expenseById(s, reversesId);
      if (exp != null && reversedCtrl.text.trim().isEmpty) {
        final left = s.reversibleLeft(exp, exceptTxnId: widget.edit?.id);
        final inc = _cents() ?? 0;
        final v = left < inc ? left : inc;
        if (v > 0) reversedCtrl.text = _centsText(v);
      }
    });
  }

  Future<void> _pickInvest(AppState s) async {
    final id = await showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Plataforma de investimento',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
              ),
            ),
            for (final a in s.investAccounts)
              ListTile(
                leading: Text(
                  a.emoji.isEmpty ? '🏦' : a.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
                title: Text(a.name),
                selected: a.id == investId,
                onTap: () => Navigator.pop(ctx, a.id),
              ),
            if (investId != null)
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Nenhuma'),
                onTap: () => Navigator.pop(ctx, -1),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (id != null) setState(() => investId = id == -1 ? null : id);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.edit != null;
    final isTransfer = type == _Type.transfer;
    final acc = s.account(accountId);
    final toAcc = s.account(toAccountId);
    final cat = s.cat(categoryId);
    final today = DateTime.now();
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final sugg = isTransfer ? <Categoria>[] : _suggestions(s);
    final openExtras =
        receipt != null || (!isTransfer && accountId != null && isEdit);

    Widget accountTile({String? title}) => TileField(
      icon: Icons.account_balance_wallet_outlined,
      title: title ?? 'Conta',
      text: acc == null
          ? 'Seleciona uma conta'
          : '${acc.emoji} ${acc.name}'.trim(),
      isHint: acc == null,
      onTap: () async {
        final id = await pickAccount(
          context,
          selected: accountId,
          title: 'Conta',
        );
        if (id != null) setState(() => accountId = id == -1 ? null : id);
      },
    );

    final reciboTile = TileField(
      icon: Icons.receipt_long_outlined,
      title: 'Recibo',
      text: receipt == null
          ? 'Tira uma foto ou escolhe um ficheiro'
          : Receipts.displayName(receipt!),
      isHint: receipt == null,
      trailing: Icons.attach_file,
      onTap: _receiptMenu,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar movimento' : 'Novo movimento'),
        actions: [
          if (!isEdit)
            IconButton(
              tooltip: 'Importar extrato',
              icon: const Icon(Icons.note_add_outlined),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ImportScreen()),
              ),
            ),
          if (isEdit)
            IconButton(
              tooltip: 'Apagar',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                if (await confirm(context, 'Apagar este movimento?')) {
                  saved = true;
                  s.deleteTxns([widget.edit!.id]);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          SegmentedButton<_Type>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: _Type.expense, label: Text('Despesa')),
              ButtonSegment(value: _Type.income, label: Text('Receita')),
              ButtonSegment(
                value: _Type.transfer,
                label: Text('Transferência'),
              ),
            ],
            selected: {type},
            onSelectionChanged: (v) => _setType(v.first, s),
          ),
          const SizedBox(height: 22),
          // montante em destaque
          TextField(
            controller: amount,
            autofocus: !isEdit,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: tt.displaySmall?.copyWith(fontWeight: FontWeight.w800),
            onChanged: (_) => setState(() => error = null),
            decoration: InputDecoration(
              hintText: '0,00',
              prefixText: '$baseSym  ',
              prefixStyle: tt.headlineSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              suffixIcon: IconButton(
                tooltip: 'Calculadora',
                icon: const Icon(Icons.calculate_outlined),
                onPressed: _calculator,
              ),
              errorText: error,
            ),
          ),
          const SizedBox(height: 18),
          if (!isTransfer) ...[
            TileField(
              icon: Icons.sell_outlined,
              title: 'Categoria',
              text: cat == null
                  ? 'Escolher categoria'
                  : '${cat.emoji.isEmpty ? '' : '${cat.emoji} '}${s.path(cat.id)}',
              isHint: cat == null,
              onTap: () => _pickCategory(s),
            ),
            if (sugg.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 0,
                  children: [
                    for (final c in sugg)
                      ChoiceChip(
                        selected: c.id == categoryId,
                        showCheckmark: false,
                        avatar: c.emoji.isEmpty ? null : Text(c.emoji),
                        label: Text(c.name),
                        onSelected: (_) => setState(() => categoryId = c.id),
                      ),
                  ],
                ),
              ),
            if (type == _Type.income) ...[
              const SizedBox(height: 12),
              TileField(
                icon: Icons.undo,
                title: 'Anula uma despesa (reembolso, devolução)',
                text: () {
                  if (reversesId == null) return 'Nenhuma';
                  final x = _expenseById(s, reversesId);
                  return x == null ? 'Despesa já não existe' : s.displayName(x);
                }(),
                isHint: reversesId == null,
                onTap: () => _pickExpense(s),
              ),
              if (reversesId != null) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: reversedCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() => error = null),
                  decoration: InputDecoration(
                    labelText: 'Valor anulado ($baseSym)',
                    prefixText: '$baseSym  ',
                    helperMaxLines: 3,
                    helperText: _reversalHelp(s),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 14),
          ],
          TextField(
            controller: desc,
            maxLength: 120,
            buildCounter: (
              _, {
              required currentLength,
              required isFocused,
              maxLength,
            }) => null,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.notes),
              hintText: 'Descrição (opcional)',
            ),
          ),
          const SizedBox(height: 14),
          // data: Hoje / Ontem / outra
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Hoje'),
                selected: _sameDay(date, today),
                showCheckmark: false,
                onSelected: (_) => setState(() => date = today),
              ),
              ChoiceChip(
                label: const Text('Ontem'),
                selected: _sameDay(date, yesterday),
                showCheckmark: false,
                onSelected: (_) => setState(() => date = yesterday),
              ),
              ChoiceChip(
                avatar: const Icon(Icons.event, size: 18),
                label: Text(
                  _sameDay(date, today) || _sameDay(date, yesterday)
                      ? 'Outra data'
                      : fmtDate(date),
                ),
                selected: !_sameDay(date, today) && !_sameDay(date, yesterday),
                showCheckmark: false,
                onSelected: (_) => _pickDate(),
              ),
            ],
          ),
          if (isTransfer) ...[
            const SizedBox(height: 14),
            accountTile(title: isEdit ? 'Conta' : 'Da conta'),
            if (!isEdit && investId == null) ...[
              const SizedBox(height: 12),
              TileField(
                icon: Icons.account_balance_outlined,
                title: 'Para a conta',
                text: toAcc == null
                    ? 'Seleciona a conta de destino'
                    : '${toAcc.emoji} ${toAcc.name}'.trim(),
                isHint: toAcc == null,
                onTap: () async {
                  final id = await pickAccount(
                    context,
                    selected: toAccountId,
                    exclude: accountId,
                    title: 'Conta de destino',
                  );
                  if (id != null)
                    setState(() => toAccountId = id == -1 ? null : id);
                },
              ),
            ],
            if (s.investAccounts.isNotEmpty) ...[
              const SizedBox(height: 12),
              TileField(
                icon: Icons.trending_up,
                title: 'Para investir (opcional)',
                text: s.investAccount(investId) == null
                    ? 'Plataforma de investimento'
                    : '${s.investAccount(investId)!.emoji} ${s.investAccount(investId)!.name}'
                          .trim(),
                isHint: s.investAccount(investId) == null,
                onTap: () => _pickInvest(s),
              ),
            ],
            if (isEdit) ...[
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Saída'),
                    icon: Icon(Icons.north_east),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Entrada'),
                    icon: Icon(Icons.south_west),
                  ),
                ],
                selected: {transferIn},
                onSelectionChanged: (v) => setState(() => transferIn = v.first),
              ),
            ],
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Não conta como despesa nem receita na Análise.',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ],
          Material(
            key: const ValueKey('mais-opcoes'),
            type: MaterialType.transparency,
            child: Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                key: ValueKey('mais-$isTransfer'),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                initiallyExpanded: openExtras,
                title: Text(
                  isTransfer ? 'Recibo' : 'Mais opções (conta, recibo)',
                  style: tt.titleSmall,
                ),
                children: [
                  if (!isTransfer) ...[
                    accountTile(),
                    const SizedBox(height: 12),
                  ],
                  reciboTile,
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: () => _save(s), child: const Text('Guardar')),
        ],
      ),
    );
  }
}

