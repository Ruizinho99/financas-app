import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import '../util/receipts.dart';
import '../widgets/common.dart';
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
      text: widget.edit == null ? '' : (widget.edit!.amount.abs() / 100).toStringAsFixed(2).replaceAll('.', ','));
  late final desc = TextEditingController(text: widget.edit?.description ?? '');
  late int? categoryId = widget.edit?.categoryId;
  late int? accountId = widget.edit?.accountId;
  int? toAccountId;
  late int? investId = widget.edit?.investAccountId; // transferência para/de uma plataforma de investimento
  late String? receipt = widget.edit?.receiptPath;
  late bool transferIn = (widget.edit?.amount ?? -1) > 0; // só ao editar uma transferência
  bool newReceipt = false; // recibo anexado nesta sessão (apagar se não guardar)
  bool saved = false;
  String? error;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    type = e == null ? _Type.expense : (e.isTransfer ? _Type.transfer : (e.amount > 0 ? _Type.income : _Type.expense));
  }

  @override
  void dispose() {
    if (!saved && newReceipt) Receipts.delete(receipt);
    super.dispose();
  }

  void _setType(_Type t, AppState s) => setState(() {
        type = t;
        if (t == _Type.transfer) categoryId = null;
        final c = s.cat(categoryId);
        if (c != null && c.isIncome != (t == _Type.income)) categoryId = null;
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
    if (v != null) setState(() => amount.text = (v.abs() / 100).toStringAsFixed(2).replaceAll('.', ','));
  }

  Future<void> _receiptMenu() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 8), child: Align(alignment: Alignment.centerLeft, child: Text('Recibo', style: Theme.of(ctx).textTheme.titleLarge))),
          if (receipt != null) ListTile(leading: const Icon(Icons.visibility_outlined), title: const Text('Ver recibo'), onTap: () => Navigator.pop(ctx, 'view')),
          ListTile(leading: const Icon(Icons.photo_camera_outlined), title: const Text('Tirar foto'), onTap: () => Navigator.pop(ctx, 'camera')),
          ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Escolher da galeria'), onTap: () => Navigator.pop(ctx, 'gallery')),
          ListTile(leading: const Icon(Icons.attach_file), title: const Text('Escolher ficheiro (PDF ou imagem)'), onTap: () => Navigator.pop(ctx, 'file')),
          if (receipt != null) ListTile(leading: const Icon(Icons.delete_outline), title: const Text('Remover recibo'), onTap: () => Navigator.pop(ctx, 'remove')),
          const SizedBox(height: 8),
        ]),
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
          final x = await ImagePicker().pickImage(source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery, imageQuality: 85);
          if (x != null) name = await Receipts.saveBytes(x.name, await x.readAsBytes());
        case 'file':
          final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp']);
          if (files.isNotEmpty) name = await Receipts.saveBytes(files.first.name, await files.first.readAsBytes());
      }
      if (name != null) {
        if (newReceipt) Receipts.delete(receipt);
        setState(() {
          receipt = name;
          newReceipt = true;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível anexar o recibo: $e')));
    }
  }

  Future<void> _viewReceipt() async {
    final f = Receipts.file(receipt);
    if (f == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ficheiro do recibo não encontrado.')));
      return;
    }
    if (Receipts.isImage(receipt!)) {
      await showDialog(
        context: context,
        builder: (ctx) => Dialog(
          clipBehavior: Clip.antiAlias,
          child: Stack(children: [
            InteractiveViewer(child: Image.file(f)),
            Positioned(top: 4, right: 4, child: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx))),
          ]),
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
        _Type.transfer => toAccountId != null ? 'Transferência para ${s.account(toAccountId)?.name ?? ''}'.trim() : 'Transferência',
        _ => c?.name ?? (type == _Type.income ? 'Receita' : 'Despesa'),
      };
    }
    final e = widget.edit;
    saved = true;
    if (e == null) {
      if (type == _Type.transfer && investId != null) {
        // entrega a uma plataforma de investimento: um só movimento, associado à plataforma
        s.addManual(date: date, description: d, amount: -cents, accountId: accountId, isTransfer: true, receiptPath: receipt, investAccountId: investId);
      } else if (type == _Type.transfer) {
        s.addTransfer(date: date, description: d, amount: cents, fromAccount: accountId, toAccount: toAccountId, receiptPath: receipt);
      } else {
        s.addManual(
          date: date,
          description: d,
          amount: type == _Type.expense ? -cents : cents,
          categoryId: categoryId,
          accountId: accountId,
          receiptPath: receipt,
        );
      }
    } else {
      final signed = type == _Type.expense ? -cents : (type == _Type.income ? cents : (transferIn ? cents : -cents));
      s.updateTxn(Txn(
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
      ));
      if (e.receiptPath != null && e.receiptPath != receipt) Receipts.delete(e.receiptPath);
    }
    Navigator.pop(context);
  }

  Widget _chip(_Type t, IconData icon, String label, AppState s) {
    final sel = type == t;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(sel ? Icons.check : icon, size: 18),
        label: Text(label),
        selected: sel,
        showCheckmark: false,
        onSelected: (_) => _setType(t, s),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.edit != null;
    final acc = s.account(accountId);
    final toAcc = s.account(toAccountId);
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar movimento' : 'Novo movimento'),
        actions: [
          if (!isEdit)
            IconButton(
              tooltip: 'Importar extrato',
              icon: const Icon(Icons.note_add_outlined),
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ImportScreen())),
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
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
        SizedBox(
          height: 48,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            _chip(_Type.expense, Icons.arrow_downward, 'Despesas', s),
            _chip(_Type.income, Icons.arrow_upward, 'Receitas', s),
            _chip(_Type.transfer, Icons.swap_horiz, 'Transferências', s),
          ]),
        ),
        const SizedBox(height: 8),
        FormCard(children: [
          const FieldLabel('Montante').withTopZero(),
          TextField(
            controller: amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: Theme.of(context).textTheme.titleLarge,
            onChanged: (_) => setState(() => error = null),
            decoration: InputDecoration(
              hintText: '0,00',
              prefixIcon: Padding(padding: const EdgeInsets.only(left: 16, right: 8), child: Align(widthFactor: 1, child: Text(baseSym, style: const TextStyle(fontSize: 22)))),
              suffixIcon: IconButton(tooltip: 'Calculadora', icon: const Icon(Icons.calculate_outlined), onPressed: _calculator),
              errorText: error,
            ),
          ),
          const FieldLabel('Data'),
          TileField(
            icon: Icons.event,
            text: fmtDate(date),
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2000), lastDate: DateTime(2100));
              if (d != null) setState(() => date = d);
            },
          ),
          if (type != _Type.transfer)
            CategorySelector(form: true, income: type == _Type.income, when: DateTimeRange(start: date, end: date), value: categoryId, onChanged: (v) => setState(() => categoryId = v)),
          const FieldLabel('Descrição', optional: true),
          BoxField(icon: Icons.notes, controller: desc, hint: 'Adiciona uma descrição (opcional)', maxLength: 120),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, c) {
            final contaTile = TileField(
              icon: Icons.account_balance_wallet_outlined,
              title: type == _Type.transfer && !isEdit ? 'Da conta' : 'Conta',
              text: acc == null ? 'Seleciona uma conta' : '${acc.emoji} ${acc.name}'.trim(),
              isHint: acc == null,
              onTap: () async {
                final id = await pickAccount(context, selected: accountId, title: 'Conta');
                if (id != null) setState(() => accountId = id == -1 ? null : id);
              },
            );
            final reciboTile = TileField(
              icon: Icons.receipt_long_outlined,
              titleWidget: Text.rich(TextSpan(style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), children: [
                const TextSpan(text: 'Recibo'),
                TextSpan(text: ' (opcional)', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w400)),
              ])),
              text: receipt == null ? 'Tira ou adiciona um ficheiro' : Receipts.displayName(receipt!),
              isHint: receipt == null,
              trailing: Icons.attach_file,
              onTap: _receiptMenu,
            );
            // lado a lado em ecrãs largos; empilhados num telemóvel para o texto caber
            if (c.maxWidth >= 440) {
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: contaTile), const SizedBox(width: 12), Expanded(child: reciboTile)]);
            }
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [contaTile, const SizedBox(height: 12), reciboTile]);
          }),
          if (type == _Type.transfer && s.investAccounts.isNotEmpty) ...[
            const FieldLabel('Plataforma de investimento', optional: true),
            TileField(
              icon: Icons.trending_up,
              text: s.investAccount(investId) == null ? 'Seleciona se for para investir' : '${s.investAccount(investId)!.emoji} ${s.investAccount(investId)!.name}'.trim(),
              isHint: s.investAccount(investId) == null,
              onTap: () async {
                final id = await showModalBottomSheet<int>(
                  context: context,
                  useSafeArea: true,
                  builder: (ctx) => SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 8), child: Align(alignment: Alignment.centerLeft, child: Text('Plataforma de investimento', style: Theme.of(ctx).textTheme.titleLarge))),
                      for (final a in s.investAccounts) ListTile(leading: Text(a.emoji.isEmpty ? '🏦' : a.emoji, style: const TextStyle(fontSize: 22)), title: Text(a.name), selected: a.id == investId, onTap: () => Navigator.pop(ctx, a.id)),
                      if (investId != null) ListTile(leading: const Icon(Icons.close), title: const Text('Nenhuma'), onTap: () => Navigator.pop(ctx, -1)),
                      const SizedBox(height: 8),
                    ]),
                  ),
                );
                if (id != null) setState(() => investId = id == -1 ? null : id);
              },
            ),
          ],
          if (type == _Type.transfer && !isEdit && investId == null) ...[
            const FieldLabel('Para a conta', optional: true),
            TileField(
              icon: Icons.account_balance_outlined,
              text: toAcc == null ? 'Seleciona a conta de destino' : '${toAcc.emoji} ${toAcc.name}'.trim(),
              isHint: toAcc == null,
              onTap: () async {
                final id = await pickAccount(context, selected: toAccountId, exclude: accountId, title: 'Conta de destino');
                if (id != null) setState(() => toAccountId = id == -1 ? null : id);
              },
            ),
          ],
          if (type == _Type.transfer && isEdit) ...[
            const FieldLabel('Sentido'),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Saída'), icon: Icon(Icons.north_east)),
                ButtonSegment(value: true, label: Text('Entrada'), icon: Icon(Icons.south_west)),
              ],
              selected: {transferIn},
              onSelectionChanged: (v) => setState(() => transferIn = v.first),
            ),
          ],
          if (type == _Type.transfer)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Transferências entre as tuas contas não contam como despesa nem receita na Análise.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 20),
          FilledButton(onPressed: () => _save(s), child: const Text('Guardar')),
        ]),
      ]),
    );
  }
}

extension on FieldLabel {
  /// O primeiro rótulo do cartão não precisa do espaço extra de cima.
  Widget withTopZero() => Transform.translate(offset: const Offset(0, -6), child: this);
}
