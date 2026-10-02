import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../screens/transactions_screen.dart' show confirm;
import '../state/app_state.dart';
import '../util/format.dart';
import 'common.dart';

/// Cria ou edita uma categoria (e as suas subcategorias) numa única operação. Devolve o id guardado.
Future<int?> showCategoryEditor(BuildContext context, {Categoria? edit, int? parentId}) {
  return showDialog<int>(
    context: context,
    barrierDismissible: false, // não perder o que já foi escrito por um toque fora do modal
    builder: (_) => CategoryEditorDialog(edit: edit, parentId: parentId ?? edit?.parentId),
  );
}

/// Linha de subcategoria no formulário.
class _SubRow {
  final int? id; // null = nova
  final TextEditingController name;
  final FocusNode focus = FocusNode();
  String emoji;
  String? error;
  _SubRow({this.id, String name = '', this.emoji = ''}) : name = TextEditingController(text: name);

  void dispose() {
    name.dispose();
    focus.dispose();
  }
}

class CategoryEditorDialog extends StatefulWidget {
  final Categoria? edit;
  final int? parentId;
  const CategoryEditorDialog({super.key, this.edit, this.parentId});
  @override
  State<CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<CategoryEditorDialog> {
  late final name = TextEditingController(text: widget.edit?.name ?? '');
  late final desc = TextEditingController(text: widget.edit?.description ?? '');
  late int? parent = widget.parentId;
  late bool income = widget.edit?.isIncome ?? false;
  late String emoji = widget.edit?.emoji ?? '';
  late String? activeFrom = widget.edit?.activeFrom;
  late String? activeTo = widget.edit?.activeTo;
  late bool hasDates = widget.edit?.hasDates ?? false;
  final subs = <_SubRow>[];
  final removed = <int>[]; // subcategorias existentes a apagar ao guardar
  String? nameError;

  bool get isEdit => widget.edit != null;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    if (e != null && e.parentId == null) {
      // subcategorias existentes: editáveis aqui
      for (final k in context.read<AppState>().categories.where((c) => c.parentId == e.id)) {
        subs.add(_SubRow(id: k.id, name: k.name, emoji: k.emoji));
      }
    }
  }

  @override
  void dispose() {
    name.dispose();
    desc.dispose();
    for (final r in subs) {
      r.dispose();
    }
    super.dispose();
  }

  // ---------- helpers ----------
  bool get _showSubs => parent == null || !isEdit; // em edição de uma subcategoria não há subcategorias
  bool get _subsAreSiblings => parent != null; // com categoria-mãe escolhida, as extra ficam ao lado

  void _addSub() {
    final r = _SubRow();
    setState(() => subs.add(r));
    WidgetsBinding.instance.addPostFrameCallback((_) => r.focus.requestFocus());
  }

  Future<void> _removeSub(_SubRow r) async {
    final s = context.read<AppState>();
    if (r.id != null) {
      final n = s.transactions.where((t) => t.categoryId == r.id).length;
      if (n > 0 &&
          !await confirm(context, 'Remover “${r.name.text.trim()}”? Os $n movimentos ficam sem categoria (só depois de guardares).', ok: 'Remover')) {
        return;
      }
      removed.add(r.id!);
    }
    setState(() => subs.remove(r));
    r.dispose();
  }

  Future<void> _pickEmojiFor(String current, ValueChanged<String> set) async {
    final e = await pickEmoji(context, current);
    if (e != null) setState(() => set(e));
  }

  bool _validate(AppState s) {
    var ok = true;
    String key(String v) => v.trim().toLowerCase();
    final main = name.text.trim();
    final parentCat = s.cat(parent);

    nameError = null;
    if (main.isEmpty) {
      nameError = 'Indica um nome';
      ok = false;
    } else if (s.categoryNameTaken(main, parent, excludeId: widget.edit?.id)) {
      nameError = parent == null ? 'Já existe uma categoria principal com este nome' : 'Já existe esta subcategoria em ${parentCat?.name ?? 'esta categoria'}';
      ok = false;
    }

    // nomes já usados no mesmo nível das subcategorias a guardar
    final used = <String>{};
    if (_subsAreSiblings) {
      used.addAll(s.childrenOf(parent!).where((c) => c.id != widget.edit?.id).map((c) => key(c.name)));
      if (main.isNotEmpty) used.add(key(main));
    }
    for (final r in subs) {
      r.error = null;
      final n = r.name.text.trim();
      if (n.isEmpty) continue; // linhas vazias não são guardadas
      if (used.contains(key(n))) {
        r.error = 'Nome repetido';
        ok = false;
      } else {
        used.add(key(n));
      }
    }
    return ok;
  }

  void _save(AppState s) {
    setState(() {});
    if (!_validate(s)) {
      setState(() {});
      return;
    }
    final e = widget.edit;
    final parentCat = s.cat(parent);
    final main = Categoria(
      id: e?.id ?? 0,
      name: name.text.trim(),
      parentId: parent,
      isIncome: parentCat?.isIncome ?? income,
      emoji: emoji,
      description: desc.text.trim(),
      budgetType: e?.budgetType ?? ((parentCat?.isIncome ?? income) ? BudgetType.goal : BudgetType.limit),
      budgetPercent: e?.budgetPercent ?? false,
      budgetValue: e?.budgetValue ?? 0,
      hasBudget: e?.hasBudget ?? false,
      archived: e?.archived ?? false,
      activeFrom: hasDates ? activeFrom : null,
      activeTo: hasDates ? (activeTo != null && activeFrom != null && activeTo!.compareTo(activeFrom!) < 0 ? activeFrom : activeTo) : null,
    );
    final toSave = [
      if (_showSubs)
        for (final r in subs)
          if (r.name.text.trim().isNotEmpty) (id: r.id, name: r.name.text.trim(), emoji: r.emoji),
    ];
    final id = s.saveCategoryWithSubs(main, toSave, removedIds: removed, subsAreSiblings: _subsAreSiblings);
    Navigator.pop(context, id);
  }

  // ---------- UI ----------
  Widget _emojiBox(String value, VoidCallback onTap, {double size = 48, String empty = '🙂'}) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Escolher emoji',
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(border: Border.all(color: cs.outlineVariant), borderRadius: BorderRadius.circular(14)),
          child: Text(value.isEmpty ? empty : value, style: TextStyle(fontSize: size * 0.5, color: value.isEmpty ? cs.onSurfaceVariant : null)),
        ),
      ),
    );
  }

  Widget _section(String text) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 12),
        child: LayoutBuilder(
          builder: (context, c) => Row(children: [
            // o título nunca ocupa a linha toda: a divisória fica sempre com pelo menos 56 px
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: c.maxWidth - 68),
              child: Text(text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6))),
          ]),
        ),
      );

  Widget _monthTile(String label, String? month, ValueChanged<String> onPick, {VoidCallback? onClear}) {
    String txt(String? k) => k == null ? 'Escolher mês' : fmtMonth(DateTime(int.parse(k.substring(0, 4)), int.parse(k.substring(5, 7))));
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final init = month == null ? DateTime.now() : DateTime(int.parse(month.substring(0, 4)), int.parse(month.substring(5, 7)));
        final d = await showDatePicker(context: context, initialDate: init, firstDate: DateTime(2000), lastDate: DateTime(2100), helpText: 'Escolhe qualquer dia do mês');
        if (d != null) onPick(monthKey(d));
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          prefixIcon: const Icon(Icons.event, size: 20),
          suffixIcon: onClear == null ? null : IconButton(icon: const Icon(Icons.close, size: 20), tooltip: 'Remover', onPressed: onClear),
        ),
        child: Text(txt(month)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final roots = s.roots.where((r) => r.id != widget.edit?.id).toList();
    final parentCat = s.cat(parent);
    final liveSubs = subs.where((r) => r.name.text.trim().isNotEmpty || r.id != null).length;
    // uma categoria que já tem subcategorias não pode passar a ser subcategoria (só 2 níveis)
    final lockParent = isEdit && widget.edit!.parentId == null && liveSubs > 0;
    final subMode = parentCat != null;

    final title = isEdit ? (widget.edit!.parentId == null ? 'Editar categoria' : 'Editar subcategoria') : (subMode ? 'Nova subcategoria' : 'Nova categoria');
    final subtitle = isEdit
        ? (widget.edit!.parentId == null ? 'Altera os dados e as subcategorias' : 'Altera os dados desta subcategoria')
        : (subMode ? 'Cria subcategorias dentro de ${parentCat.name}' : 'Cria uma categoria e as suas subcategorias');

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // ----- cabeçalho fixo -----
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 8, 0),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: tt.titleLarge),
                  const SizedBox(height: 2),
                  Text(subtitle, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ]),
              ),
              IconButton(tooltip: 'Fechar', icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ]),
          ),
          // ----- corpo com scroll -----
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _emojiBox(emoji, () => _pickEmojiFor(emoji, (e) => emoji = e), size: 52),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: name,
                      autofocus: !isEdit,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() => nameError = null),
                      decoration: InputDecoration(
                        labelText: subMode && !isEdit ? 'Nome da subcategoria' : 'Nome',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        errorText: nameError,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  initialValue: parent,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Categoria-mãe',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    helperText: lockParent ? 'Tem subcategorias, por isso não pode ser uma subcategoria.' : null,
                    helperMaxLines: 2,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Nenhuma (categoria principal)')),
                    for (final r in roots) DropdownMenuItem(value: r.id, child: Text('${r.emoji.isEmpty ? '🏷️' : r.emoji}  ${r.name}', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: lockParent
                      ? null
                      : (v) => setState(() {
                            parent = v;
                            nameError = null;
                            final p = s.cat(v);
                            if (p != null) income = p.isIncome;
                          }),
                ),
                if (subMode) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Icon(Icons.subdirectory_arrow_right, size: 18, color: cs.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(TextSpan(style: tt.bodyMedium, children: [
                          TextSpan(text: isEdit ? 'Subcategoria de ' : 'A criar subcategoria de '),
                          TextSpan(text: '${parentCat.emoji.isEmpty ? '🏷️' : parentCat.emoji} ${parentCat.name}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        ])),
                      ),
                    ]),
                  ),
                ],
                // ----- subcategorias -----
                if (_showSubs) ...[
                  _section(subMode ? 'Mais subcategorias de ${parentCat.name}' : 'Subcategorias'),
                  for (final r in subs)
                    Padding(
                      key: ObjectKey(r),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _emojiBox(r.emoji, () => _pickEmojiFor(r.emoji, (e) => r.emoji = e), size: 48, empty: '🏷️'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: r.name,
                            focusNode: r.focus,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) => setState(() => r.error = null),
                            onSubmitted: (_) {
                              if (identical(r, subs.last) && r.name.text.trim().isNotEmpty) _addSub();
                            },
                            decoration: InputDecoration(
                              hintText: 'Nome da subcategoria',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                              errorText: r.error,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: IconButton(tooltip: 'Remover subcategoria', icon: const Icon(Icons.close), onPressed: () => _removeSub(r)),
                        ),
                      ]),
                    ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                    onPressed: _addSub,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Adicionar subcategoria'),
                  ),
                ],
                // ----- opções -----
                _section('Opções'),
                if (!subMode)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Rendimento'),
                    subtitle: const Text('Entradas de dinheiro (ex.: salário). Não conta como despesa.'),
                    value: income,
                    onChanged: (v) => setState(() => income = v),
                  ),
                if (!subMode) const SizedBox(height: 8),
                TextField(
                  controller: desc,
                  maxLines: 2,
                  minLines: 1,
                  decoration: const InputDecoration(labelText: 'Descrição (opcional)', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Só existe num período'),
                  subtitle: const Text('Ex.: “Férias 2027”. Fora do período deixa de aparecer nas escolhas.'),
                  value: hasDates,
                  onChanged: (v) => setState(() {
                    hasDates = v;
                    if (v && activeFrom == null) activeFrom = monthKey(DateTime.now());
                  }),
                ),
                if (hasDates) ...[
                  const SizedBox(height: 4),
                  _monthTile('Desde', activeFrom, (m) => setState(() => activeFrom = m)),
                  const SizedBox(height: 10),
                  if (activeTo == null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(onPressed: () => setState(() => activeTo = activeFrom ?? monthKey(DateTime.now())), icon: const Icon(Icons.event_busy, size: 20), label: const Text('Definir fim')),
                    )
                  else
                    _monthTile('Até', activeTo, (m) => setState(() => activeTo = m), onClear: () => setState(() => activeTo = null)),
                ],
                if (isEdit && !income)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.event_repeat),
                    title: const Text('Obrigatória em…'),
                    subtitle: Text(() {
                      final n = s.rangesOf(widget.edit!.id).length;
                      return n == 0 ? 'Opcional em todos os meses' : '$n período(s) definido(s)';
                    }()),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await showMandatoryDialog(context, widget.edit!);
                      if (mounted) setState(() {});
                    },
                  ),
                const SizedBox(height: 8),
              ]),
            ),
          ),
          // ----- rodapé fixo -----
          Container(
            decoration: BoxDecoration(border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)))),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(88, 46)),
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(112, 46)),
                onPressed: () => _save(s),
                child: const Text('Guardar'),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
