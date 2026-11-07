import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';

import '../goals/goals.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import '../util/receipts.dart';
import '../widgets/category_picker.dart';
import '../widgets/common.dart' show CatBadge;
import '../widgets/form_kit.dart';
import 'accounts_screen.dart';
import 'import_screen.dart';
import 'transactions_screen.dart' show confirm;
import 'txn_form/dialogos.dart';
import 'txn_form/widgets.dart';

// A API pública (corrigirValor, amountIssueText) mantém-se neste ficheiro.
export 'txn_form/dialogos.dart' show corrigirValor, amountIssueText;

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
  int? accountId; // ao criar, a última conta usada (ver initState)
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
  late final noteCtrl = TextEditingController(text: widget.edit?.note ?? '');
  final amountFocus = FocusNode();
  // a categoria/conta foram escolhidas à mão: as sugestões já não lhes mexem
  late bool catManual = widget.edit?.categoryId != null;
  bool catSuggested =
      false; // categoria sugerida pelo nome (ainda não confirmada)
  late bool accountManual = widget.edit?.accountId != null;
  bool descApplied = false; // sugestão de descrição escolhida: esconde a lista
  late bool advOpen;
  late bool noteOpen = (widget.edit?.note ?? '').trim().isNotEmpty;
  late bool goalsOpen;
  String? importFile; // nome do ficheiro de onde veio o movimento importado

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    final s = context.read<AppState>();
    accountId = e != null ? e.accountId : s.lastUsedAccountId;
    if (e != null && e.importId != null) {
      try {
        importFile = s.db
            .imports()
            .where((i) => i.id == e.importId)
            .firstOrNull
            ?.filename;
      } catch (_) {}
    }
    final alocado = e == null ? 0 : s.allocatedOf(e.id);
    goalsOpen = alocado > 0;
    // o bloco Avançado abre sozinho se algum dos campos já tem valor
    advOpen =
        e != null &&
        (e.receiptPath != null ||
            e.note.trim().isNotEmpty ||
            e.linkGroup != null ||
            alocado > 0 ||
            (e.isTransfer && e.investAccountId != null));
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
    noteCtrl.dispose();
    amountFocus.dispose();
    desc.dispose();
    amount.dispose();
    super.dispose();
  }

  static String _centsText(int cents) => centsText(cents);

  /// O movimento em edição, como está guardado agora (o valor pode ter sido corrigido entretanto).
  Txn? _orig(AppState s) {
    final e = widget.edit;
    if (e == null) return null;
    return s.transactions.where((t) => t.id == e.id).firstOrNull ?? e;
  }

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
    if (t == _Type.transfer) {
      categoryId = null;
      catManual = false;
      catSuggested = false;
    }
    // a categoria mantém-se ao trocar entre despesa e receita: é a mesma para os dois
  });

  /// Valor em cêntimos de um texto: número simples ou conta ("12,50 + 11"). Nulo se inválido.
  /// Uma conta tem de ser avaliada primeiro: o leitor de números ignora os sinais e juntaria os dígitos.
  static int? _centsOf(String text) {
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

  int? _cents() => _centsOf(amount.text);

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
    final l = AppLocalizations.of(context)!;
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
                  l.frmReceipt,
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
              ),
            ),
            if (receipt != null)
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: Text(l.frmViewReceipt),
                onTap: () => Navigator.pop(ctx, 'view'),
              ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l.frmTakePhoto),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l.frmChooseFromGallery),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: Text(l.frmChooseFile),
              onTap: () => Navigator.pop(ctx, 'file'),
            ),
            if (receipt != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(l.frmRemoveReceipt),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.frmReceiptAttachError('$e'))));
    }
  }

  Future<void> _viewReceipt() async {
    final l = AppLocalizations.of(context)!;
    final f = Receipts.file(receipt);
    if (f == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.frmReceiptFileNotFound)));
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

  void _save(AppState s, {bool again = false}) {
    final l = AppLocalizations.of(context)!;
    final cents = _cents();
    if (cents == null || cents == 0) {
      setState(() => error = l.frmEnterValidAmount);
      return;
    }
    // o valor novo não pode ficar abaixo do que está associado a objetivos nem do que já foi anulado
    final original = _orig(s);
    if (original != null) {
      final novo = type == _Type.expense
          ? -cents
          : (type == _Type.income ? cents : (transferIn ? cents : -cents));
      final issue = s.amountEditIssue(original, novo);
      if (issue != null) {
        setState(() => error = amountIssueText(l, issue.$1, issue.$2));
        return;
      }
    }
    final c = s.cat(categoryId);
    var d = desc.text.trim();
    if (d.isEmpty) {
      d = switch (type) {
        _Type.transfer =>
          toAccountId != null
              ? l.frmTransferTo(s.account(toAccountId)?.name ?? '').trim()
              : l.frmTransfer,
        _ => c?.name ?? (type == _Type.income ? l.frmIncome : l.frmExpense),
      };
    }
    // anulação de uma despesa (só numa receita)
    int? revId;
    var revCents = 0;
    if (type == _Type.income && reversesId != null) {
      final exp = _expenseById(s, reversesId);
      revCents = (parseCents(reversedCtrl.text) ?? 0).abs();
      if (exp == null) {
        setState(() => error = l.frmReversedGone);
        return;
      }
      if (revCents <= 0) {
        setState(() => error = l.frmEnterReversedAmount);
        return;
      }
      if (revCents > cents) {
        setState(() => error = l.frmReversalTooBig);
        return;
      }
      final left = s.reversibleLeft(exp, exceptTxnId: widget.edit?.id);
      if (revCents > left) {
        setState(() => error = l.frmOnlyLeftToReverse(fmtMoney(left)));
        return;
      }
      revId = exp.id;
    }
    final e = _orig(s);
    final nota = noteCtrl.text.trim();
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
          note: nota,
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
          note: nota,
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
    if (again && e == null) {
      _resetForNew(l);
      return;
    }
    Navigator.pop(context);
  }

  /// "Guardar e novo": limpa valor, descrição, categoria e extras; mantém tipo, data e conta.
  void _resetForNew(AppLocalizations l) {
    setState(() {
      saved = false;
      newReceipt = false;
      receipt = null;
      amount.clear();
      desc.clear();
      noteCtrl.clear();
      noteOpen = false;
      categoryId = null;
      catManual = false;
      catSuggested = false;
      descApplied = false;
      reversesId = null;
      reversedCtrl.clear();
      error = null;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l.frm2Saved),
          duration: const Duration(seconds: 2),
        ),
      );
    amountFocus.requestFocus();
  }

  /// Corrige só o valor/sinal (diálogo rápido) e traz o resultado para o formulário.
  Future<void> _fixAmount(AppState s) async {
    final cur = _orig(s);
    if (cur == null) return;
    final ok = await corrigirValor(context, cur);
    if (!ok || !mounted) return;
    final n = _orig(context.read<AppState>());
    if (n == null) return;
    setState(() {
      amount.text = centsText(n.amount);
      type = n.isTransfer
          ? _Type.transfer
          : (n.amount > 0 ? _Type.income : _Type.expense);
      transferIn = n.amount > 0;
      if (n.reversesId == null) {
        reversesId = null;
        reversedCtrl.clear();
      }
      error = null;
    });
  }

  /// Ao escrever a descrição: sugere a categoria pelo nome, enquanto não foi escolhida à mão.
  void _onDescChanged(AppState s) {
    setState(() {
      descApplied = false;
      if (catManual || type == _Type.transfer) return;
      final sc = s.suggestCategoryFor(desc.text);
      if (sc != null) {
        categoryId = sc;
        catSuggested = true;
      } else if (catSuggested) {
        categoryId = null;
        catSuggested = false;
      }
    });
  }

  /// Toque numa sugestão de descrição: preenche também a categoria e a conta, se ainda não foram escolhidas.
  void _applySuggestion(AppState s, DescSuggestion g) {
    setState(() {
      desc.value = TextEditingValue(
        text: g.text,
        selection: TextSelection.collapsed(offset: g.text.length),
      );
      descApplied = true;
      if (!catManual && g.categoryId != null && s.cat(g.categoryId) != null) {
        categoryId = g.categoryId;
        catSuggested = false;
      }
      if (!accountManual &&
          g.accountId != null &&
          s.account(g.accountId) != null) {
        accountId = g.accountId;
      }
    });
  }

  /// As categorias mais usadas neste tipo de movimento (saídas ou entradas), para escolher com um toque.
  /// Sem uso recente, olha para todo o histórico.
  List<int> _mostUsed(AppState s) {
    final inc = type == _Type.income;
    final ids = s.mostUsedCategoryIds(limit: 5, income: inc);
    return ids.isNotEmpty
        ? ids
        : s.mostUsedCategoryIds(limit: 5, income: inc, days: 36500);
  }

  /// Ligação a outros movimentos (ex.: enviei 10 e recebi 11): o grupo conta pelo líquido.
  /// Liga e desliga logo, sem esperar pelo botão de guardar.
  Widget _linkDetails(
    AppState s,
    AppLocalizations l,
    Txn cur,
    List<Txn> others,
  ) {
    final net = cur.linkGroup == null ? 0 : s.linkNet(cur.linkGroup!);
    return Padding(
      padding: const EdgeInsets.only(left: 56, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            net < 0
                ? l.lnkResultExpense(fmtMoney(-net))
                : net > 0
                ? l.lnkResultIncome(fmtMoney(net))
                : l.lnkResultZero,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 2),
          Text(
            l.lnkRepHint(s.displayName(s.linkRep(cur.linkGroup!)!)),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.link_off, size: 18),
              label: Text(l.lnkUnlink),
              onPressed: () {
                s.unlinkTxn(cur.id);
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Escolhe o movimento a ligar: primeiro os de sinal oposto até 30 dias de distância, depois os outros.
  Future<void> _pickLink(AppState s, Txn cur) async {
    final l = AppLocalizations.of(context)!;
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
            int dist(Txn t) => t.date.difference(cur.date).inDays.abs();
            final all =
                [
                  for (final t in s.transactions)
                    if (t.id != cur.id &&
                        !t.isTransfer &&
                        !(cur.linkGroup != null &&
                            t.linkGroup == cur.linkGroup))
                      t,
                ].where(
                  (t) =>
                      query.isEmpty ||
                      '${s.displayName(t)} ${t.description}'
                          .toLowerCase()
                          .contains(query),
                );
            final list = all.toList()
              ..sort((a, b) => dist(a).compareTo(dist(b)));
            bool sugg(Txn t) =>
                (t.amount > 0) != (cur.amount > 0) && dist(t) <= 30;
            final near = list.where(sugg).take(50).toList();
            final rest = list.where((t) => !sugg(t)).take(150).toList();
            Widget tile(Txn t) => ListTile(
              title: Text(
                s.displayName(t),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text('${fmtDate(t.date)} · ${fmtMoney(t.amount)}'),
              onTap: () => Navigator.pop(ctx, t.id),
            );
            return SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.75,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: l.lnkSearch,
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                      ),
                      onChanged: (v) => set(() => q = v),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        if (near.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                            child: Text(
                              l.lnkSuggested,
                              style: Theme.of(ctx).textTheme.labelLarge,
                            ),
                          ),
                        for (final t in near) tile(t),
                        if (rest.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                            child: Text(
                              l.lnkOthers,
                              style: Theme.of(ctx).textTheme.labelLarge,
                            ),
                          ),
                        for (final t in rest) tile(t),
                        if (near.isEmpty && rest.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(child: Text(l.lnkNoCandidates)),
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
    if (id == null || !mounted) return;
    if (s.linkTxns(cur.id, id)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.lnkLinked)));
    }
    setState(() {});
  }

  String? _reversalHelp(AppState s) {
    final l = AppLocalizations.of(context)!;
    final exp = _expenseById(s, reversesId);
    if (exp == null) return null;
    final left = s.reversibleLeft(exp, exceptTxnId: widget.edit?.id);
    return l.frmReversalHelp(fmtMoney(left));
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
    setState(() {
      categoryId = id == -1 ? null : id;
      catManual = true;
      catSuggested = false;
    });
  }

  /// Escolhe a despesa que esta receita anula. Mostra as despesas recentes que ainda têm valor por anular.
  Future<void> _pickExpense(AppState s) async {
    final l = AppLocalizations.of(context)!;
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
                      decoration: InputDecoration(
                        hintText: l.frmSearchExpense,
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
                          title: Text(l.frmNoReversal),
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
                              l.frmToReverseSubtitle(
                                fmtDate(t.date),
                                fmtMoney(-t.amount),
                                fmtMoney(
                                  s.reversibleLeft(
                                    t,
                                    exceptTxnId: widget.edit?.id,
                                  ),
                                ),
                              ),
                            ),
                            onTap: () => Navigator.pop(ctx, t.id),
                          ),
                        if (list.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(child: Text(l.frmNoExpenseToReverse)),
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
    final l = AppLocalizations.of(context)!;
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
                  l.frmInvestPlatform,
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
                title: Text(l.frmNone),
                onTap: () => Navigator.pop(ctx, -1),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (id != null) setState(() => investId = id == -1 ? null : id);
  }

  /// Valor absoluto guardado do movimento (o do formulário só conta depois de guardar).
  int _valorGuardado(AppState s, Txn e) {
    for (final t in s.transactions) {
      if (t.id == e.id) return t.amount.abs();
    }
    return e.amount.abs();
  }

  String _nomeObjetivo(AppState s, int goalId) {
    final l = AppLocalizations.of(context)!;
    for (final g in s.goals) {
      if (g.id == goalId) return g.name;
    }
    return l.goalFallback;
  }

  /// Objetivos ativos a que este movimento ainda não está associado.
  List<Goal> _objetivosDisponiveis(AppState s, int txnId) {
    final usados = {
      for (final a in s.goalAllocations)
        if (a.txnId == txnId) a.goalId,
    };
    return [
      for (final g in s.goals)
        if (!g.archived && !usados.contains(g.id)) g,
    ];
  }

  /// Diálogo para associar um valor a um objetivo, ou para alterar o valor de uma associação
  /// existente ([existente]). Devolve (objetivo, valor) ou nulo se cancelado.
  Future<(int, int)?> _associar(
    AppState s,
    Txn e, {
    GoalAllocation? existente,
    required int disponivel,
  }) {
    final l = AppLocalizations.of(context)!;
    final opcoes = existente == null
        ? _objetivosDisponiveis(s, e.id)
        : <Goal>[];
    return showDialog<(int, int)>(
      context: context,
      builder: (ctx) => AssociarDialog(
        titulo: existente == null
            ? l.frmSplitByGoal
            : _nomeObjetivo(s, existente.goalId),
        opcoes: opcoes,
        goalId:
            existente?.goalId ?? (opcoes.length == 1 ? opcoes.first.id : null),
        disponivel: disponivel,
        inicial: existente?.cents ?? disponivel,
        confirmar: existente == null ? l.frmAllocate : l.frmSave,
        escolherObjetivo: existente == null,
      ),
    );
  }

  /// Secção "Objetivos" do movimento (despesas, receitas e transferências), se houver objetivos ativos.
  Widget _objetivosSecao(AppState s, Txn e) {
    final l = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    final total = _valorGuardado(s, e);
    final alocado = s.allocatedOf(e.id);
    final porAssociar = total > alocado ? total - alocado : 0;
    final associacoes = [
      for (final a in s.goalAllocations)
        if (a.txnId == e.id) a,
    ];
    final podeDividir =
        porAssociar > 0 && _objetivosDisponiveis(s, e.id).isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final a in associacoes)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                _nomeObjetivo(s, a.goalId),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(fmtMoney(a.cents)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: l.frmChangeAmount,
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () async {
                      final r = await _associar(
                        s,
                        e,
                        existente: a,
                        disponivel: porAssociar + a.cents,
                      );
                      if (r != null) s.linkMovement(e.id, r.$1, r.$2);
                    },
                  ),
                  IconButton(
                    tooltip: l.frmUnlink,
                    icon: const Icon(Icons.link_off),
                    onPressed: () => s.unlinkMovement(a.id),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              l.frmToAllocate(fmtMoney(porAssociar)),
              style: tt.bodyMedium,
            ),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.call_split),
            label: Text(l.frmSplitByGoals),
            onPressed: podeDividir
                ? () async {
                    final r = await _associar(s, e, disponivel: porAssociar);
                    if (r != null) s.linkMovement(e.id, r.$1, r.$2);
                  }
                : null,
          ),
        ],
      ),
    );
  }

  // ---------- Apresentação ----------

  /// Cor do tipo de movimento: despesa e receita usam as cores do utilizador; transferência é azul.
  Color _typeColor(AppState s, _Type t) => switch (t) {
    _Type.expense => Color(s.expenseColor),
    _Type.income => Color(s.incomeColor),
    _Type.transfer => const Color(0xFF1E88E5),
  };

  String get _sign => switch (type) {
    _Type.expense => '− ',
    _Type.income => '+ ',
    _Type.transfer => '',
  };

  /// Resultado de uma conta escrita no valor ("12,50 + 11" → "= 23,50 €"); nulo se for um número simples.
  String? _calcResult(AppLocalizations l) {
    final t = amount.text.trim();
    if (!RegExp(r'\d\s*[+\-*/×÷x]\s*[\d(]').hasMatch(t)) return null;
    final c = _centsOf(t);
    return c == null ? null : l.frm2CalcResult(fmtMoney(c));
  }

  /// Faixa no topo ao editar um movimento importado de um extrato.
  Widget? _importBanner(AppState s, AppLocalizations l) {
    final e = _orig(s);
    if (e == null || (e.source == 'manual' && e.importId == null)) return null;
    final cs = Theme.of(context).colorScheme;
    final partes = <String>[
      importFile != null
          ? l.frm2ImportedFrom(importFile!)
          : l.frm2ImportedStatement,
      if (e.description.trim().isNotEmpty)
        l.frm2OriginalDesc(e.description.trim()),
      if (e.balance != null) l.frm2BalanceAfter(fmtMoney(e.balance!)),
    ];
    return Container(
      key: const ValueKey('faixa-importado'),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.description_outlined,
            size: 20,
            color: cs.onSecondaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              partes.join(' · '),
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: cs.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }

  /// Sugestões de descrições anteriores enquanto se escreve.
  Widget _descSuggestions(AppState s, AppLocalizations l) {
    if (type == _Type.transfer || descApplied) return const SizedBox.shrink();
    final list = s.suggestDescriptions(
      desc.text,
      limit: 4,
      income: type == _Type.income,
    );
    if (list.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      key: const ValueKey('sugestoes-descricao'),
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final g in list)
            InkWell(
              onTap: () => _applySuggestion(s, g),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    CatBadge(s.cat(g.categoryId), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        [
                          g.text,
                          if (g.categoryId != null &&
                              s.cat(g.categoryId) != null)
                            ' — ${s.path(g.categoryId)}',
                          ' · ${l.frm2SuggestionTimes(g.count)}',
                        ].join(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Chips de conta: todas as contas (ou as primeiras e "+ N"); "Sem conta" se não houver contas.
  Widget _accountChips(AppState s, AppLocalizations l) {
    final accs = s.accounts;
    if (accs.isEmpty) {
      return Wrap(
        children: [
          ChoiceChip(
            label: Text(l.frm2NoAccount),
            selected: true,
            showCheckmark: false,
            onSelected: (_) {},
          ),
        ],
      );
    }
    var shown = accs;
    if (accs.length > 4) {
      shown = accs.take(3).toList();
      final sel = accs.where((a) => a.id == accountId).firstOrNull;
      if (sel != null && !shown.contains(sel)) shown.add(sel);
    }
    final more = accs.length - shown.length;
    return Wrap(
      spacing: 8,
      runSpacing: 0,
      children: [
        for (final a in shown)
          ChoiceChip(
            label: Text('${a.emoji} ${a.name}'.trim()),
            selected: a.id == accountId,
            showCheckmark: false,
            onSelected: (_) => setState(() {
              accountId = a.id == accountId ? null : a.id;
              accountManual = true;
            }),
          ),
        if (more > 0)
          ActionChip(
            label: Text('+ $more'),
            onPressed: () async {
              final id = await pickAccount(
                context,
                selected: accountId,
                title: l.frmAccount,
              );
              if (id != null) {
                setState(() {
                  accountId = id == -1 ? null : id;
                  accountManual = true;
                });
              }
            },
          ),
      ],
    );
  }

  /// "De" e "Para" lado a lado, com botão para trocar (nova transferência).
  Widget _transferAccounts(AppState s, AppLocalizations l) {
    final acc = s.account(accountId);
    final toAcc = s.account(toAccountId);
    String nome(Conta? c, String vazio) =>
        c == null ? vazio : '${c.emoji} ${c.name}'.trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: CaixaConta(
            rotulo: l.frm2FromAccount,
            texto: nome(acc, l.frmSelectAccount),
            dica: acc == null,
            onTap: () async {
              final id = await pickAccount(
                context,
                selected: accountId,
                title: l.frmFromAccount,
              );
              if (id != null) {
                setState(() {
                  accountId = id == -1 ? null : id;
                  accountManual = true;
                });
              }
            },
          ),
        ),
        if (investId == null) ...[
          IconButton(
            tooltip: l.frm2SwapAccounts,
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => setState(() {
              final t = accountId;
              accountId = toAccountId;
              toAccountId = t;
              accountManual = true;
            }),
          ),
          Expanded(
            child: CaixaConta(
              rotulo: l.frm2ToAccount,
              texto: nome(toAcc, l.frmSelectDestinationAccount),
              dica: toAcc == null,
              onTap: () async {
                final id = await pickAccount(
                  context,
                  selected: toAccountId,
                  exclude: accountId,
                  title: l.frmDestinationAccount,
                );
                if (id != null) {
                  setState(() => toAccountId = id == -1 ? null : id);
                }
              },
            ),
          ),
        ],
      ],
    );
  }

  /// Bloco único "Avançado": nota, recibo, ligação, objetivos e investimento.
  Widget _advanced(AppState s, AppLocalizations l) {
    final cs = Theme.of(context).colorScheme;
    final isTransfer = type == _Type.transfer;
    final e = _orig(s);
    final nota = noteCtrl.text.trim();
    final rows = <Widget>[];

    if (!(e == null && isTransfer)) {
      rows.add(
        LinhaAvancada(
          icon: Icons.sticky_note_2_outlined,
          title: l.frm2Note,
          subtitle: nota.isEmpty ? l.frm2NoteHint : nota.split('\n').first,
          hasValue: nota.isNotEmpty,
          trailing: noteOpen ? Icons.expand_less : Icons.expand_more,
          onTap: () => setState(() => noteOpen = !noteOpen),
          child: noteOpen
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: noteCtrl,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(hintText: l.frm2NoteHint),
                  ),
                )
              : null,
        ),
      );
    }

    rows.add(
      LinhaAvancada(
        icon: Icons.receipt_long_outlined,
        title: l.frmReceipt,
        subtitle: receipt == null
            ? l.frmTakePhotoOrChoose
            : Receipts.displayName(receipt!),
        hasValue: receipt != null,
        trailing: Icons.attach_file,
        onTap: _receiptMenu,
      ),
    );

    if (e != null && !isTransfer) {
      final others = s.linkedWith(e);
      rows.add(
        LinhaAvancada(
          icon: Icons.link,
          title: l.lnkField,
          subtitle: others.isEmpty
              ? l.lnkNone
              : others.map(s.displayName).join(', '),
          hasValue: others.isNotEmpty,
          onTap: () => _pickLink(s, e),
          child: others.isEmpty ? null : _linkDetails(s, l, e, others),
        ),
      );
    }

    if (e != null && s.goals.any((g) => !g.archived)) {
      final alocado = s.allocatedOf(e.id);
      rows.add(
        LinhaAvancada(
          icon: Icons.flag_outlined,
          title: l.goals,
          subtitle: alocado > 0
              ? l.frm2GoalsAllocated(fmtMoney(alocado))
              : l.frm2GoalsHint,
          hasValue: alocado > 0,
          trailing: goalsOpen ? Icons.expand_less : Icons.expand_more,
          onTap: () => setState(() => goalsOpen = !goalsOpen),
          child: goalsOpen ? _objetivosSecao(s, e) : null,
        ),
      );
    }

    if (isTransfer && (s.investAccounts.isNotEmpty || investId != null)) {
      final inv = s.investAccount(investId);
      rows.add(
        LinhaAvancada(
          icon: Icons.trending_up,
          title: l.frmToInvestOptional,
          subtitle: inv == null
              ? l.frmInvestPlatform
              : '${inv.emoji} ${inv.name}'.trim(),
          hasValue: inv != null,
          onTap: () => _pickInvest(s),
        ),
      );
    }

    return Container(
      key: const ValueKey('bloco-avancado'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: const Icon(Icons.tune),
            title: Text(l.frm2Advanced),
            subtitle: advOpen
                ? null
                : Text(
                    l.frm2AdvancedHint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
            trailing: Icon(advOpen ? Icons.expand_less : Icons.expand_more),
            onTap: () => setState(() => advOpen = !advOpen),
          ),
          if (advOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: rows,
              ),
            ),
        ],
      ),
    );
  }

  Widget _bottomBar(AppState s, AppLocalizations l) {
    final isEdit = widget.edit != null;
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isEdit
                      ? () => _fixAmount(s)
                      : () => _save(s, again: true),
                  child: Text(
                    isEdit ? l.edvFixAmount : l.frm2SaveAndNew,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => _save(s),
                  child: Text(l.frmSave, textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final l = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.edit != null;
    final isTransfer = type == _Type.transfer;
    final cat = s.cat(categoryId);
    final today = DateTime.now();
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final cor = _typeColor(s, type);
    final original = _orig(s)?.originalAmount;
    final banner = _importBanner(s, l);
    final mostUsed = isTransfer ? <int>[] : _mostUsed(s);
    final calc = _calcResult(l);

    Widget typeLabel(_Type t, String text) => Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: _typeColor(s, t), fontWeight: FontWeight.w700),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l.frmEditTransaction : l.frmNewTransaction),
        actions: [
          if (!isEdit)
            IconButton(
              tooltip: l.frmImportStatementTip,
              icon: const Icon(Icons.note_add_outlined),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ImportScreen()),
              ),
            ),
          if (isEdit)
            IconButton(
              tooltip: l.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                if (await confirm(context, l.frmDeleteThisTransaction)) {
                  saved = true;
                  s.deleteTxns([widget.edit!.id]);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          if (banner != null) banner,
          SegmentedButton<_Type>(
            key: const ValueKey('tipo'),
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: cor.withValues(alpha: 0.16),
              selectedForegroundColor: cor,
            ),
            segments: [
              ButtonSegment(
                value: _Type.expense,
                label: typeLabel(_Type.expense, l.frmExpense),
              ),
              ButtonSegment(
                value: _Type.income,
                label: typeLabel(_Type.income, l.frmIncome),
              ),
              ButtonSegment(
                value: _Type.transfer,
                label: typeLabel(_Type.transfer, l.frmTransfer),
              ),
            ],
            selected: {type},
            onSelectionChanged: (v) => _setType(v.first, s),
          ),
          const SizedBox(height: 20),
          // montante em destaque, com o sinal e a cor do tipo
          TextField(
            controller: amount,
            focusNode: amountFocus,
            autofocus: !isEdit,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: tt.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: cor,
            ),
            onChanged: (_) => setState(() => error = null),
            decoration: InputDecoration(
              hintText: zeroHint,
              prefixText: '$_sign$baseSym  ',
              prefixStyle: tt.headlineSmall?.copyWith(
                color: cor,
                fontWeight: FontWeight.w700,
              ),
              suffixIcon: IconButton(
                tooltip: l.frmCalculator,
                icon: const Icon(Icons.calculate_outlined),
                onPressed: _calculator,
              ),
              errorText: error,
              errorMaxLines: 4,
              helperText: calc,
              helperMaxLines: 2,
            ),
          ),
          if (original != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_note, size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      l.edvOriginalValue(fmtMoney(original)),
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          SecaoRotulo(l.frm2WhereWhat),
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
            onChanged: (v) => _onDescChanged(s),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.notes),
              hintText: l.frmDescriptionOptional,
            ),
          ),
          _descSuggestions(s, l),
          if (!isTransfer) ...[
            SecaoRotulo(l.frmCategory),
            TileField(
              icon: Icons.sell_outlined,
              text: cat == null
                  ? l.frmChooseCategory
                  : '${cat.emoji.isEmpty ? '' : '${cat.emoji} '}${s.path(cat.id)}',
              isHint: cat == null,
              onTap: () => _pickCategory(s),
            ),
            if (catSuggested && cat != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: cs.primary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        l.frm2SuggestedByName,
                        style: tt.bodySmall?.copyWith(color: cs.primary),
                      ),
                    ),
                  ],
                ),
              ),
            if (mostUsed.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  key: const ValueKey('mais-usadas'),
                  spacing: 8,
                  runSpacing: 0,
                  children: [
                    for (final id in mostUsed)
                      if (s.cat(id) != null)
                        ChoiceChip(
                          selected: id == categoryId,
                          showCheckmark: false,
                          avatar: s.cat(id)!.emoji.isEmpty
                              ? null
                              : Text(s.cat(id)!.emoji),
                          label: Text(s.cat(id)!.name),
                          onSelected: (_) => setState(() {
                            categoryId = id;
                            catManual = true;
                            catSuggested = false;
                          }),
                        ),
                  ],
                ),
              ),
            if (type == _Type.income) ...[
              const SizedBox(height: 12),
              TileField(
                icon: Icons.undo,
                title: l.frmReversesExpense,
                text: () {
                  if (reversesId == null) return l.frmNone;
                  final x = _expenseById(s, reversesId);
                  return x == null ? l.frmExpenseGone : s.displayName(x);
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
                    labelText: l.frmReversedAmount(baseSym),
                    prefixText: '$baseSym  ',
                    helperMaxLines: 3,
                    helperText: _reversalHelp(s),
                  ),
                ),
              ],
            ],
          ],
          SecaoRotulo(l.frm2When),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(l.frmToday),
                selected: _sameDay(date, today),
                showCheckmark: false,
                onSelected: (_) => setState(() => date = today),
              ),
              ChoiceChip(
                label: Text(l.frmYesterday),
                selected: _sameDay(date, yesterday),
                showCheckmark: false,
                onSelected: (_) => setState(() => date = yesterday),
              ),
              ChoiceChip(
                avatar: const Icon(Icons.event, size: 18),
                label: Text(
                  _sameDay(date, today) || _sameDay(date, yesterday)
                      ? l.frmOtherDate
                      : fmtDate(date),
                ),
                selected: !_sameDay(date, today) && !_sameDay(date, yesterday),
                showCheckmark: false,
                onSelected: (_) => _pickDate(),
              ),
            ],
          ),
          SecaoRotulo(l.frmAccount),
          if (isTransfer && !isEdit)
            _transferAccounts(s, l)
          else
            _accountChips(s, l),
          if (isTransfer && isEdit) ...[
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(l.frmOutgoing),
                  icon: const Icon(Icons.north_east),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(l.frmIncoming),
                  icon: const Icon(Icons.south_west),
                ),
              ],
              selected: {transferIn},
              onSelectionChanged: (v) => setState(() => transferIn = v.first),
            ),
          ],
          if (isTransfer)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                l.frmNotCountedNote,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 20),
          _advanced(s, l),
        ],
      ),
      bottomNavigationBar: _bottomBar(s, l),
    );
  }
}
