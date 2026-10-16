import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../recurring/recurring.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import '../widgets/category_picker.dart';
import '../widgets/form_kit.dart';
import 'accounts_screen.dart';
import 'transactions_screen.dart' show confirm;

const _diasSemana = [
  'segunda-feira',
  'terça-feira',
  'quarta-feira',
  'quinta-feira',
  'sexta-feira',
  'sábado',
  'domingo',
];

const _meses = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

String _freqNome(RecurrenceFreq f) => switch (f) {
  RecurrenceFreq.monthly => 'Mensal',
  RecurrenceFreq.weekly => 'Semanal',
  RecurrenceFreq.yearly => 'Anual',
};

/// "dia 5", "quarta-feira" ou "15 de março", conforme a frequência.
String _quando(RecurringRule r) => switch (r.freq) {
  RecurrenceFreq.monthly => 'dia ${r.day}',
  RecurrenceFreq.weekly => _diasSemana[r.day - 1],
  RecurrenceFreq.yearly => '${r.day} de ${_meses[r.start.month - 1]}',
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
    return Scaffold(
      appBar: AppBar(title: const Text('Movimentos recorrentes')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Novo'),
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
                  'Ainda não há movimentos recorrentes.\n\nRegista aqui o salário, a renda ou uma subscrição: o movimento é criado sozinho na data certa.',
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
    final entrada = r.amount > 0;
    final cor = Color(entrada ? s.incomeColor : s.expenseColor);
    final String estado;
    if (!r.active) {
      estado = 'em pausa';
    } else {
      final prox = nextOccurrence(r, hoje);
      estado = prox == null ? 'terminada' : 'próxima ${fmtDate(prox)}';
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
            '${_freqNome(r.freq)} · ${_quando(r)}',
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
    final name = desc.text.trim();
    final cents = parseCents(amount.text)?.abs();
    String? err;
    if (name.isEmpty) {
      err = 'Escreve uma descrição.';
    } else if (cents == null || cents == 0) {
      err = 'Indica um valor.';
    } else if (end != null && end!.isBefore(start)) {
      err = 'A data de fim é anterior à de início.';
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
    final ok = await confirm(
      context,
      'Apagar "${e.description}"? Os movimentos já registados ficam.',
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

    final dias = freq == RecurrenceFreq.weekly
        ? [
            for (var i = 1; i <= 7; i++)
              DropdownMenuItem(value: i, child: Text(_diasSemana[i - 1])),
          ]
        : [
            for (var i = 1; i <= 31; i++)
              DropdownMenuItem(value: i, child: Text('Dia $i')),
          ];

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar recorrente' : 'Novo recorrente'),
        actions: [
          if (isEdit)
            IconButton(
              tooltip: 'Apagar',
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
            segments: const [
              ButtonSegment(value: false, label: Text('Despesa')),
              ButtonSegment(value: true, label: Text('Receita')),
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
            decoration: const InputDecoration(
              labelText: 'Descrição',
              hintText: 'Ex.: Salário, Renda, Netflix',
            ),
          ),
          const SizedBox(height: 12),
          TileField(
            icon: Icons.sell_outlined,
            title: 'Categoria',
            text: cat == null
                ? 'Sem categoria'
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
            title: 'Conta',
            text: acc == null ? 'Sem conta' : '${acc.emoji} ${acc.name}'.trim(),
            isHint: acc == null,
            onTap: () async {
              final id = await pickAccount(context, selected: accountId);
              if (id == null) return;
              setState(() => accountId = id == -1 ? null : id);
            },
          ),
          const SizedBox(height: 20),
          Text('Frequência', style: tt.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<RecurrenceFreq>(
            showSelectedIcon: false,
            segments: [
              for (final f in RecurrenceFreq.values)
                ButtonSegment(value: f, label: Text(_freqNome(f))),
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
                  ? 'Dia da semana'
                  : 'Dia do mês',
            ),
            items: dias,
            onChanged: (v) => setState(() => day = v ?? day),
          ),
          if (freq == RecurrenceFreq.monthly || freq == RecurrenceFreq.yearly)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                'Em meses mais curtos, passa para o último dia do mês.',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 12),
          TileField(
            icon: Icons.event_outlined,
            title: 'Início',
            text: fmtDate(start),
            trailing: Icons.edit_calendar_outlined,
            onTap: _pickStart,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'Se a data de início já passou, os movimentos desde então são criados ao abrir a app.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 12),
          TileField(
            icon: Icons.event_busy_outlined,
            title: 'Fim (opcional)',
            text: end == null ? 'Sem data de fim' : fmtDate(end!),
            isHint: end == null,
            trailing: Icons.edit_calendar_outlined,
            onTap: _pickEnd,
          ),
          if (end != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => end = null),
                child: const Text('Remover data de fim'),
              ),
            ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ativa'),
            subtitle: const Text('Desativa para pausar, sem apagar'),
            value: active,
            onChanged: (v) => setState(() => active = v),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(error!, style: TextStyle(color: cs.error)),
            ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: const Text('Guardar')),
        ],
      ),
    );
  }
}
