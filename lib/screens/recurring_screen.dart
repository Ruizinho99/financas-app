import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../recurring/recurring.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import '../widgets/category_picker.dart';
import '../widgets/form_kit.dart';
import 'accounts_screen.dart';
import 'transactions_screen.dart' show confirm;

/// Nome do dia da semana (1 = segunda … 7 = domingo).
String _weekdayName(AppLocalizations l, int weekday) => switch (weekday) {
  1 => l.bpMonday,
  2 => l.bpTuesday,
  3 => l.bpWednesday,
  4 => l.bpThursday,
  5 => l.bpFriday,
  6 => l.bpSaturday,
  _ => l.bpSunday,
};

/// Nome do mês (1 = janeiro … 12 = dezembro).
String _monthName(AppLocalizations l, int month) => switch (month) {
  1 => l.bpJanuary,
  2 => l.bpFebruary,
  3 => l.bpMarch,
  4 => l.bpApril,
  5 => l.bpMay,
  6 => l.bpJune,
  7 => l.bpJuly,
  8 => l.bpAugust,
  9 => l.bpSeptember,
  10 => l.bpOctober,
  11 => l.bpNovember,
  _ => l.bpDecember,
};

String _freqNome(AppLocalizations l, RecurrenceFreq f) => switch (f) {
  RecurrenceFreq.monthly => l.bpFreqMonthly,
  RecurrenceFreq.weekly => l.bpFreqWeekly,
  RecurrenceFreq.yearly => l.bpFreqYearly,
};

/// "dia 5", "quarta-feira" ou "15 de março", conforme a frequência.
String _quando(AppLocalizations l, RecurringRule r) => switch (r.freq) {
  RecurrenceFreq.monthly => l.bpWhenMonthly(r.day),
  RecurrenceFreq.weekly => _weekdayName(l, r.day),
  RecurrenceFreq.yearly => l.bpWhenYearly(r.day, _monthName(l, r.start.month)),
};

/// Dia que acompanha a data de início (dia do mês, ou dia da semana no semanal).
int _diaPorDefeito(RecurrenceFreq f, DateTime inicio) =>
    f == RecurrenceFreq.weekly ? inicio.weekday : inicio.day;

/// Lista dos movimentos recorrentes, com a próxima data de cada um.
class RecurringScreen extends StatelessWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final rules = s.recurringRules;
    final hoje = DateTime.now();
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.bpRecurringTitle)),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(l.bpNew),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RecurringFormScreen()),
        ),
      ),
      body: rules.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l.bpNoRecurringHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                for (final r in rules) _RecurringTile(rule: r, hoje: hoje),
              ],
            ),
    );
  }
}

class _RecurringTile extends StatelessWidget {
  final RecurringRule rule;
  final DateTime hoje;
  const _RecurringTile({required this.rule, required this.hoje});

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final r = rule;
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final entrada = r.amount > 0;
    final cor = Color(entrada ? s.incomeColor : s.expenseColor);
    final String estado;
    if (!r.active) {
      estado = l.bpPaused;
    } else {
      final prox = nextOccurrence(r, hoje);
      estado = prox == null ? l.bpEnded : l.bpNextDate(fmtDate(prox));
    }
    final conta = s.account(r.accountId);
    return Card(
      child: ListTile(
        leading: Icon(
          entrada ? Icons.south_west : Icons.north_east,
          color: cor,
        ),
        title: Text(r.description),
        subtitle: Text(
          [
            '${_freqNome(l, r.freq)} · ${_quando(l, r)}',
            if (conta != null) conta.name,
            estado,
          ].join(' · '),
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        trailing: Text(
          fmtMoney(r.amount),
          style: TextStyle(color: cor, fontWeight: FontWeight.w700),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RecurringFormScreen(edit: r)),
        ),
      ),
    );
  }
}

/// Criar ou editar um movimento recorrente.
class RecurringFormScreen extends StatefulWidget {
  final RecurringRule? edit;
  const RecurringFormScreen({super.key, this.edit});

  @override
  State<RecurringFormScreen> createState() => _RecurringFormScreenState();
}

class _RecurringFormScreenState extends State<RecurringFormScreen> {
  late final TextEditingController desc;
  late final TextEditingController amount;
  late bool income;
  int? categoryId;
  int? accountId;
  late RecurrenceFreq freq;
  late int day;
  late DateTime start;
  DateTime? end;
  late bool active;
  String? error;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    desc = TextEditingController(text: e?.description ?? '');
    amount = TextEditingController(
      text: e == null
          ? ''
          : (e.amount.abs() / 100).toStringAsFixed(2).replaceAll('.', ','),
    );
    income = e != null && e.amount > 0;
    categoryId = e?.categoryId;
    accountId = e?.accountId;
    freq = e?.freq ?? RecurrenceFreq.monthly;
    start = e?.start ?? dateOnly(DateTime.now());
    day = e?.day ?? _diaPorDefeito(freq, start);
    end = e?.end;
    active = e?.active ?? true;
  }

  @override
  void dispose() {
    desc.dispose();
    amount.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final d = await showDatePicker(
      context: context,
      initialDate: start,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    setState(() {
      start = dateOnly(d);
      day = _diaPorDefeito(freq, start);
    });
  }

  Future<void> _pickEnd() async {
    final d = await showDatePicker(
      context: context,
      initialDate: end ?? start,
      firstDate: start,
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => end = dateOnly(d));
  }

  void _setFreq(RecurrenceFreq f) => setState(() {
    freq = f;
    day = _diaPorDefeito(f, start);
  });

  void _save() {
    final s = context.read<AppState>();
    final l = AppLocalizations.of(context)!;
    final name = desc.text.trim();
    final cents = parseCents(amount.text)?.abs();
    String? err;
    if (name.isEmpty) {
      err = l.bpEnterDescription;
    } else if (cents == null || cents == 0) {
      err = l.bpEnterAmount;
    } else if (end != null && end!.isBefore(start)) {
      err = l.bpEndBeforeStart;
    }
    if (err != null) {
      setState(() => error = err);
      return;
    }
    s.saveRecurring(
      RecurringRule(
        id: widget.edit?.id,
        description: name,
        amount: income ? cents! : -cents!,
        categoryId: categoryId,
        accountId: accountId,
        freq: freq,
        day: day,
        start: start,
        end: end,
        active: active,
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final e = widget.edit!;
    final l = AppLocalizations.of(context)!;
    final ok = await confirm(
      context,
      l.bpDeleteRecurringQuestion(e.description),
    );
    if (!ok || !mounted) return;
    context.read<AppState>().deleteRecurring(e.id!);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final cat = s.cat(categoryId);
    final acc = s.account(accountId);
    final isEdit = widget.edit != null;
    final l = AppLocalizations.of(context)!;

    final dias = freq == RecurrenceFreq.weekly
        ? [
            for (var i = 1; i <= 7; i++)
              DropdownMenuItem(value: i, child: Text(_weekdayName(l, i))),
          ]
        : [
            for (var i = 1; i <= 31; i++)
              DropdownMenuItem(value: i, child: Text(l.dayOfMonthItem(i))),
          ];

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l.bpEditRecurring : l.bpNewRecurring),
        actions: [
          if (isEdit)
            IconButton(
              tooltip: l.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: false, label: Text(l.bpExpenseType)),
              ButtonSegment(value: true, label: Text(l.bpIncomeType)),
            ],
            selected: {income},
            onSelectionChanged: (v) => setState(() {
              income = v.first;
              categoryId = null;
            }),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: amount,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: tt.displaySmall?.copyWith(fontWeight: FontWeight.w800),
            onChanged: (_) => setState(() => error = null),
            decoration: InputDecoration(
              hintText: '0,00',
              prefixText: '$baseSym  ',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: desc,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() => error = null),
            decoration: InputDecoration(
              labelText: l.bpDescription,
              hintText: l.bpDescriptionHint,
            ),
          ),
          const SizedBox(height: 12),
          TileField(
            icon: Icons.sell_outlined,
            title: l.bpCategory,
            text: cat == null
                ? l.noCategory
                : '${cat.emoji} ${cat.name}'.trim(),
            isHint: cat == null,
            onTap: () async {
              final id = await chooseCategory(
                context,
                selected: categoryId,
                income: income,
              );
              if (id == null) return;
              setState(() => categoryId = id == -1 ? null : id);
            },
          ),
          const SizedBox(height: 12),
          TileField(
            icon: Icons.account_balance_wallet_outlined,
            title: l.bpAccount,
            text: acc == null
                ? l.bpNoAccount
                : '${acc.emoji} ${acc.name}'.trim(),
            isHint: acc == null,
            onTap: () async {
              final id = await pickAccount(context, selected: accountId);
              if (id == null) return;
              setState(() => accountId = id == -1 ? null : id);
            },
          ),
          const SizedBox(height: 20),
          Text(l.bpFrequency, style: tt.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<RecurrenceFreq>(
            showSelectedIcon: false,
            segments: [
              for (final f in RecurrenceFreq.values)
                ButtonSegment(value: f, label: Text(_freqNome(l, f))),
            ],
            selected: {freq},
            onSelectionChanged: (v) => _setFreq(v.first),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            key: ValueKey(freq),
            initialValue: day,
            decoration: InputDecoration(
              labelText: freq == RecurrenceFreq.weekly
                  ? l.bpDayOfWeek
                  : l.bpDayOfMonth,
            ),
            items: dias,
            onChanged: (v) => setState(() => day = v ?? day),
          ),
          if (freq == RecurrenceFreq.monthly || freq == RecurrenceFreq.yearly)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                l.bpShortMonthHint,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 12),
          TileField(
            icon: Icons.event_outlined,
            title: l.bpStart,
            text: fmtDate(start),
            trailing: Icons.edit_calendar_outlined,
            onTap: _pickStart,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              l.bpPastStartHint,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 12),
          TileField(
            icon: Icons.event_busy_outlined,
            title: l.bpEndOptional,
            text: end == null ? l.bpNoEndDate : fmtDate(end!),
            isHint: end == null,
            trailing: Icons.edit_calendar_outlined,
            onTap: _pickEnd,
          ),
          if (end != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => end = null),
                child: Text(l.bpRemoveEndDate),
              ),
            ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.bpActive),
            subtitle: Text(l.bpActiveHint),
            value: active,
            onChanged: (v) => setState(() => active = v),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(error!, style: TextStyle(color: cs.error)),
            ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: Text(l.bpSave)),
        ],
      ),
    );
  }
}
