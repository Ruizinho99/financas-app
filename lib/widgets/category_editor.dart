import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models.dart';
import '../screens/transactions_screen.dart' show confirm;
import '../state/app_state.dart';
import '../util/format.dart';
import 'common.dart';

/// Cria ou edita uma categoria (e as suas subcategorias) numa única operação. Devolve o id guardado.
Future<int?> showCategoryEditor(
  BuildContext context, {
  Categoria? edit,
  int? parentId,
}) {
  return showDialog<int>(
    context: context,
    barrierDismissible:
        false, // não perder o que já foi escrito por um toque fora do modal
    builder: (_) =>
        CategoryEditorDialog(edit: edit, parentId: parentId ?? edit?.parentId),
  );
}

/// Linha de subcategoria no formulário.
class _SubRow {
  final int? id; // null = nova
  final TextEditingController name;
  final FocusNode focus = FocusNode();
  String emoji;
  String? error;
  _SubRow({this.id, String name = '', this.emoji = ''})
    : name = TextEditingController(text: name);

  void dispose() {
    name.dispose();
    focus.dispose();
  }
}

/// O que a categoria é: define como entra nas contas do mês.
enum _Kind { optional, mandatory, income, investment, both }

extension on _Kind {
  String labelL(AppLocalizations l) => switch (this) {
    _Kind.optional => l.frmKindOptional,
    _Kind.mandatory => l.frmKindMandatory,
    _Kind.income => l.frmKindIncome,
    _Kind.investment => l.frmKindInvestment,
    _Kind.both => l.frmKindBoth,
  };
  IconData get icon => switch (this) {
    _Kind.optional => Icons.shopping_bag_outlined,
    _Kind.mandatory => Icons.event_repeat,
    _Kind.income => Icons.south_west,
    _Kind.investment => Icons.trending_up,
    _Kind.both => Icons.swap_vert,
  };
  String helpL(AppLocalizations l) => switch (this) {
    _Kind.optional => l.frmKindOptionalHelp,
    _Kind.mandatory => l.frmKindMandatoryHelp,
    _Kind.income => l.frmKindIncomeHelp,
    _Kind.investment => l.frmKindInvestmentHelp,
    _Kind.both => l.frmKindBothHelp,
  };
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
  late _Kind kind;
  late final _Kind initialKind;
  bool get income => kind == _Kind.income;
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
    final st = context.read<AppState>();
    // receita e "despesas e receitas" deixaram de ser tipos: qualquer categoria serve para os dois
    kind = e == null
        ? _Kind.optional
        : e.isInvestment
        ? _Kind.investment
        : (st.rangesOf(e.id).isNotEmpty ? _Kind.mandatory : _Kind.optional);
    initialKind = kind;
    if (e != null) {
      // subcategorias diretas existentes (de qualquer nível): editáveis aqui
      for (final k in st.categories.where((c) => c.parentId == e.id)) {
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
  // ao criar com uma categoria-mãe escolhida, as linhas extra ficam ao lado da nova;
  // ao editar, as linhas são filhas diretas da categoria editada
  bool get _subsAreSiblings => parent != null && !isEdit;

  void _addSub() {
    final r = _SubRow();
    setState(() => subs.add(r));
    WidgetsBinding.instance.addPostFrameCallback((_) => r.focus.requestFocus());
  }

  Future<void> _removeSub(_SubRow r) async {
    final l = AppLocalizations.of(context)!;
    final s = context.read<AppState>();
    if (r.id != null) {
      // movimentos da subcategoria e de tudo o que tem dentro (também são apagados da árvore)
      final n = s.transactions
          .where((t) => s.inSubtree(t.categoryId, r.id!))
          .length;
      if (n > 0 &&
          !await confirm(
            context,
            l.frmRemoveSubQuestion(r.name.text.trim(), n),
            ok: l.frmRemove,
          )) {
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
    final l = AppLocalizations.of(context)!;
    var ok = true;
    String key(String v) => v.trim().toLowerCase();
    final main = name.text.trim();
    final parentCat = s.cat(parent);

    nameError = null;
    final e = widget.edit;
    final moveErr = (e != null && parent != e.parentId)
        ? s.canMoveCategory(e.id, parent)
        : null;
    if (moveErr == MoveError.self || moveErr == MoveError.intoDescendant) {
      nameError = moveErr == MoveError.self
          ? l.ctbMoveErrSelf
          : l.ctbMoveErrDescendant;
      ok = false;
    } else if (main.isEmpty) {
      nameError = l.frmEnterName;
      ok = false;
    } else if (s.categoryNameTaken(main, parent, excludeId: widget.edit?.id)) {
      nameError = parent == null
          ? l.frmMainCategoryExists
          : l.frmSubcategoryExists(parentCat?.name ?? l.frmThisCategory);
      ok = false;
    }

    // nomes já usados no mesmo nível das subcategorias a guardar
    final used = <String>{};
    if (_subsAreSiblings) {
      used.addAll(
        s
            .childrenOf(parent!)
            .where((c) => c.id != widget.edit?.id)
            .map((c) => key(c.name)),
      );
      if (main.isNotEmpty) used.add(key(main));
    }
    for (final r in subs) {
      r.error = null;
      final n = r.name.text.trim();
      if (n.isEmpty) continue; // linhas vazias não são guardadas
      if (used.contains(key(n))) {
        r.error = l.frmRepeatedName;
        ok = false;
      } else {
        used.add(key(n));
      }
    }
    return ok;
  }

  /// Despesa obrigatória ou opcional: cria ou apaga os períodos de obrigatoriedade quando o tipo muda.
  void _applyMandatory(AppState s, int id, Categoria? parentCat) {
    if (parentCat != null || kind == initialKind) return;
    if (kind == _Kind.mandatory) {
      if (s.rangesOf(id).isEmpty)
        s.addRange(
          id,
          hasDates && activeFrom != null ? activeFrom! : '2000-01',
          hasDates ? activeTo : null,
        );
    } else {
      for (final r in s.rangesOf(id)) {
        s.removeRange(r.id);
      }
    }
  }

  Future<void> _save(AppState s) async {
    setState(() {});
    if (!_validate(s)) {
      setState(() {});
      return;
    }
    final e = widget.edit;
    final parentCat = s.cat(parent);
    // mudar de sítio na árvore: confirma o efeito antes (a subárvore vai toda)
    final moving = e != null && parent != e.parentId;
    if (moving && !await confirmMove(context, s, e, parent)) return;
    if (!mounted) return;
    final main = Categoria(
      id: e?.id ?? 0,
      name: name.text.trim(),
      // ao editar, a mudança de mãe faz-se com moveCategory (leva a subárvore e herda o tipo)
      parentId: e == null ? parent : e.parentId,
      // as marcas antigas de receita e "despesas e receitas" guardam-se como estão (já não mudam nada)
      isIncome: e?.isIncome ?? parentCat?.isIncome ?? false,
      isInvestment: parentCat?.isInvestment ?? (kind == _Kind.investment),
      both: e?.both ?? parentCat?.both ?? false,
      emoji: emoji,
      description: desc.text.trim(),
      budgetType:
          e?.budgetType ??
          ((parentCat?.isInvestment ?? (kind == _Kind.investment))
              ? BudgetType.goal
              : BudgetType.limit),
      budgetPercent: e?.budgetPercent ?? false,
      budgetValue: e?.budgetValue ?? 0,
      hasBudget: e?.hasBudget ?? false,
      archived: e?.archived ?? false,
      activeFrom: hasDates ? activeFrom : null,
      activeTo: hasDates
          ? (activeTo != null &&
                    activeFrom != null &&
                    activeTo!.compareTo(activeFrom!) < 0
                ? activeFrom
                : activeTo)
          : null,
    );
    final toSave = [
      for (final r in subs)
        if (r.name.text.trim().isNotEmpty)
          (id: r.id, name: r.name.text.trim(), emoji: r.emoji),
    ];
    final id = s.saveCategoryWithSubs(
      main,
      toSave,
      removedIds: removed,
      subsAreSiblings: _subsAreSiblings,
    );
    if (moving) s.moveCategory(id, parent);
    _applyMandatory(s, id, parentCat);
    Navigator.pop(context, id);
  }

  // ---------- UI ----------
  Widget _emojiBox(
    String value,
    VoidCallback onTap, {
    double size = 48,
    String empty = '🙂',
  }) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: l.frmChooseEmoji,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: cs.outlineVariant),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            value.isEmpty ? empty : value,
            style: TextStyle(
              fontSize: size * 0.5,
              color: value.isEmpty ? cs.onSurfaceVariant : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String text) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 12),
    child: LayoutBuilder(
      builder: (context, c) => Row(
        children: [
          // o título nunca ocupa a linha toda: a divisória fica sempre com pelo menos 56 px
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: c.maxWidth - 68),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant
                  .withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _monthTile(
    String label,
    String? month,
    ValueChanged<String> onPick, {
    VoidCallback? onClear,
  }) {
    final l = AppLocalizations.of(context)!;
    String txt(String? k) => k == null
        ? l.frmChooseMonth
        : fmtMonth(
            DateTime(
              int.parse(k.substring(0, 4)),
              int.parse(k.substring(5, 7)),
            ),
          );
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final init = month == null
            ? DateTime.now()
            : DateTime(
                int.parse(month.substring(0, 4)),
                int.parse(month.substring(5, 7)),
              );
        final d = await showDatePicker(
          context: context,
          initialDate: init,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          helpText: l.frmPickAnyDayOfMonth,
        );
        if (d != null) onPick(monthKey(d));
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          prefixIcon: const Icon(Icons.event, size: 20),
          suffixIcon: onClear == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: l.frmRemove,
                  onPressed: onClear,
                ),
        ),
        child: Text(txt(month)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final parentCat = s.cat(parent);
    final subMode = parentCat != null;

    final title = isEdit
        ? (widget.edit!.parentId == null
              ? l.frmEditCategory
              : l.frmEditSubcategory)
        : (subMode ? l.frmNewSubcategoryTitle : l.frmNewCategoryTitle);
    final subtitle = isEdit
        ? (widget.edit!.parentId == null
              ? l.frmEditCategoryHint
              : l.frmEditSubcategoryHint)
        : (subMode
              ? l.frmCreateSubsIn(parentCat.name)
              : l.frmCreateCategoryHint);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ----- cabeçalho fixo -----
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 8, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: tt.titleLarge),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l.frmClose,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // ----- corpo com scroll -----
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _emojiBox(
                          emoji,
                          () => _pickEmojiFor(emoji, (e) => emoji = e),
                          size: 52,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: name,
                            autofocus: !isEdit,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) => setState(() => nameError = null),
                            decoration: InputDecoration(
                              labelText: subMode && !isEdit
                                  ? l.frmSubcategoryName
                                  : l.frmName,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 16,
                              ),
                              errorText: nameError,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // "Dentro de": qualquer categoria, exceto ela própria e as suas descendentes
                    InkWell(
                      key: const ValueKey('parent-field'),
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        final r = await pickCategoryInTree(
                          context,
                          selected: parent,
                          excludeSubtreeOf: widget.edit?.id,
                          title: l.ctbPickParentTitle,
                        );
                        if (r != null && mounted) {
                          setState(() {
                            parent = r.id;
                            nameError = null;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l.frmParentCategory,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          suffixIcon: const Icon(Icons.arrow_drop_down),
                        ),
                        child: Text(
                          parentCat == null
                              ? l.frmNoneMainCategory
                              : '${parentCat.emoji.isEmpty ? '🏷️' : parentCat.emoji}  ${s.path(parentCat.id)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (subMode) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.subdirectory_arrow_right,
                              size: 18,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  style: tt.bodyMedium,
                                  children: [
                                    TextSpan(
                                      text: isEdit
                                          ? l.frmSubcategoryOf
                                          : l.frmCreatingSubcategoryOf,
                                    ),
                                    TextSpan(
                                      text:
                                          '${parentCat.emoji.isEmpty ? '🏷️' : parentCat.emoji} ${s.path(parentCat.id)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // ----- subcategorias -----
                    ...[
                      _section(
                        subMode
                            ? l.frmMoreSubsOf(parentCat.name)
                            : l.frmSubcategories,
                      ),
                      for (final r in subs)
                        Padding(
                          key: ObjectKey(r),
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _emojiBox(
                                r.emoji,
                                () =>
                                    _pickEmojiFor(r.emoji, (e) => r.emoji = e),
                                size: 48,
                                empty: '🏷️',
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: r.name,
                                  focusNode: r.focus,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  textInputAction: TextInputAction.next,
                                  onChanged: (_) =>
                                      setState(() => r.error = null),
                                  onSubmitted: (_) {
                                    if (identical(r, subs.last) &&
                                        r.name.text.trim().isNotEmpty)
                                      _addSub();
                                  },
                                  decoration: InputDecoration(
                                    hintText: l.frmSubcategoryName,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 15,
                                    ),
                                    errorText: r.error,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: IconButton(
                                  tooltip: l.frmRemoveSubcategory,
                                  icon: const Icon(Icons.close),
                                  onPressed: () => _removeSub(r),
                                ),
                              ),
                            ],
                          ),
                        ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                        ),
                        onPressed: _addSub,
                        icon: const Icon(Icons.add, size: 20),
                        label: Text(l.frmAddSubcategory),
                      ),
                    ],
                    // ----- opções -----
                    _section(l.frmOptions),
                    if (!subMode)
                      DropdownButtonFormField<_Kind>(
                        key: ValueKey('kind-$kind'),
                        initialValue: kind,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: l.frmType,
                          prefixIcon: Icon(kind.icon),
                          helperText: kind.helpL(l),
                          helperMaxLines: 3,
                        ),
                        items: [
                          for (final k in const [
                            _Kind.optional,
                            _Kind.mandatory,
                            _Kind.investment,
                          ])
                            DropdownMenuItem(
                              value: k,
                              child: Text(k.labelL(l)),
                            ),
                        ],
                        onChanged: (v) => setState(() => kind = v ?? kind),
                      ),
                    if (!subMode) const SizedBox(height: 8),
                    TextField(
                      controller: desc,
                      maxLines: 2,
                      minLines: 1,
                      decoration: InputDecoration(
                        labelText: l.frmDescriptionOptional,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(l.frmOnlyInPeriod),
                      subtitle: Text(l.frmOnlyInPeriodHint),
                      value: hasDates,
                      onChanged: (v) => setState(() {
                        hasDates = v;
                        if (v && activeFrom == null)
                          activeFrom = monthKey(DateTime.now());
                      }),
                    ),
                    if (hasDates) ...[
                      const SizedBox(height: 4),
                      _monthTile(
                        l.frmSince,
                        activeFrom,
                        (m) => setState(() => activeFrom = m),
                      ),
                      const SizedBox(height: 10),
                      if (activeTo == null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => setState(
                              () => activeTo =
                                  activeFrom ?? monthKey(DateTime.now()),
                            ),
                            icon: const Icon(Icons.event_busy, size: 20),
                            label: Text(l.frmSetEnd),
                          ),
                        )
                      else
                        _monthTile(
                          l.frmUntil,
                          activeTo,
                          (m) => setState(() => activeTo = m),
                          onClear: () => setState(() => activeTo = null),
                        ),
                    ],
                    if (isEdit &&
                        (kind == _Kind.optional || kind == _Kind.mandatory))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: const Icon(Icons.event_repeat),
                        title: Text(l.frmMandatoryIn),
                        subtitle: Text(() {
                          final n = s.rangesOf(widget.edit!.id).length;
                          return n == 0
                              ? l.frmOptionalAllMonths
                              : l.frmPeriodsDefined(n);
                        }()),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await showMandatoryDialog(context, widget.edit!);
                          if (mounted) setState(() {});
                        },
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            // ----- rodapé fixo -----
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(88, 46),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(l.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(112, 46),
                    ),
                    onPressed: () => _save(s),
                    child: Text(l.frmSave),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Escolher/mover dentro da árvore ----------

/// Resultado do seletor em árvore: `id` nulo = "Nenhuma (principal)".
typedef TreePick = ({int? id});

/// Escolhe uma categoria de qualquer nível numa lista em árvore (indentada), com pesquisa.
/// [excludeSubtreeOf]: esconde essa categoria e tudo o que tem dentro (para não mover para si mesma).
/// Devolve `null` se for cancelado.
Future<TreePick?> pickCategoryInTree(
  BuildContext context, {
  int? selected,
  int? excludeSubtreeOf,
  bool allowNone = true,
  String? title,
}) {
  return showModalBottomSheet<TreePick>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _TreePickerSheet(
      selected: selected,
      excludeSubtreeOf: excludeSubtreeOf,
      allowNone: allowNone,
      title: title,
    ),
  );
}

class _TreePickerSheet extends StatefulWidget {
  final int? selected;
  final int? excludeSubtreeOf;
  final bool allowNone;
  final String? title;
  const _TreePickerSheet({
    this.selected,
    this.excludeSubtreeOf,
    this.allowNone = true,
    this.title,
  });
  @override
  State<_TreePickerSheet> createState() => _TreePickerSheetState();
}

class _TreePickerSheetState extends State<_TreePickerSheet> {
  String q = '';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final l = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final query = q.trim().toLowerCase();

    // percurso em profundidade: (categoria, nível)
    final rows = <(Categoria, int)>[];
    void walk(Categoria c, int depth) {
      if (c.id == widget.excludeSubtreeOf) return;
      rows.add((c, depth));
      for (final k in s.childrenOf(c.id)) {
        walk(k, depth + 1);
      }
    }

    for (final r in s.roots) {
      walk(r, 0);
    }
    final shown = query.isEmpty
        ? rows
        : rows.where((e) => e.$1.name.toLowerCase().contains(query)).toList();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(widget.title!, style: tt.titleMedium),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => q = v),
                decoration: InputDecoration(
                  hintText: l.ctbSearch,
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (widget.allowNone && query.isEmpty)
                    ListTile(
                      key: const ValueKey('tree-pick-none'),
                      leading: const Icon(Icons.folder_open_outlined),
                      title: Text(l.frmNoneMainCategory),
                      trailing: widget.selected == null
                          ? Icon(Icons.check, color: cs.primary)
                          : null,
                      onTap: () => Navigator.pop<TreePick>(context, (id: null)),
                    ),
                  for (final (c, depth) in shown)
                    ListTile(
                      key: ValueKey('tree-pick-${c.id}'),
                      contentPadding: EdgeInsets.only(
                        left: 16.0 + (query.isEmpty ? depth : 0) * 24,
                        right: 16,
                      ),
                      leading: CatBadge(c, size: 22),
                      title: Text(c.name),
                      // na pesquisa não há indentação: o caminho distingue nomes iguais
                      subtitle: query.isEmpty || depth == 0
                          ? null
                          : Text(s.path(c.id)),
                      trailing: widget.selected == c.id
                          ? Icon(Icons.check, color: cs.primary)
                          : null,
                      onTap: () => Navigator.pop<TreePick>(context, (id: c.id)),
                    ),
                  if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(child: Text(l.ctbNoMatches)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mensagem clara para um erro ao mover uma categoria.
String moveErrorText(
  AppLocalizations l,
  AppState s,
  Categoria c,
  int? newParentId,
  MoveError e,
) => switch (e) {
  MoveError.self => l.ctbMoveErrSelf,
  MoveError.intoDescendant => l.ctbMoveErrDescendant,
  MoveError.nameTaken => l.ctbMoveErrNameTaken(
    c.name,
    newParentId == null ? l.ctbMainLevel : '“${s.path(newParentId)}”',
  ),
};

/// Pergunta se se quer mesmo mover [c] para [newParentId], dizendo o que vai com ela.
Future<bool> confirmMove(
  BuildContext context,
  AppState s,
  Categoria c,
  int? newParentId,
) {
  final l = AppLocalizations.of(context)!;
  final n = s.descendantsOf(c.id).length;
  final text = newParentId == null
      ? l.ctbMoveConfirmTop(c.name, n)
      : l.ctbMoveConfirm(c.name, n, s.path(newParentId));
  return confirm(context, text, ok: l.ctbMoveButton);
}

/// "Mover para…": escolhe o destino, valida, confirma e move. Mostra os erros numa mensagem.
Future<void> moveCategoryFlow(
  BuildContext context,
  AppState s,
  Categoria c,
) async {
  final l = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final r = await pickCategoryInTree(
    context,
    selected: c.parentId,
    excludeSubtreeOf: c.id,
    title: l.ctbMoveTo(c.name),
  );
  if (r == null || r.id == c.parentId || !context.mounted) return;
  final err = s.canMoveCategory(c.id, r.id);
  if (err != null) {
    messenger.showSnackBar(
      SnackBar(content: Text(moveErrorText(l, s, c, r.id, err))),
    );
    return;
  }
  if (!await confirmMove(context, s, c, r.id) || !context.mounted) return;
  final e2 = s.moveCategory(c.id, r.id);
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        e2 == null ? l.ctbMoved(c.name) : moveErrorText(l, s, c, r.id, e2),
      ),
    ),
  );
}
