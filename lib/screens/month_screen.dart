import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../analysis/analytics.dart';
import '../analysis/widgets.dart';
import '../goals/goals.dart';
import '../invest/plan_widgets.dart';
import '../planning/planning.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import '../widgets/common.dart' show showTxnEditor;
import 'analysis_screen.dart';
import 'budget_screen.dart';
import 'classify_screen.dart';
import 'goals_screen.dart';
import 'import_screen.dart';
import 'planning_screen.dart';

/// Ecrã principal: o mês em foco — quanto gastaste, quanto entrou, quanto sobrou e onde foi o dinheiro.
class MonthScreen extends StatefulWidget {
  const MonthScreen({super.key});
  @override
  State<MonthScreen> createState() => _MonthScreenState();
}

class _MonthScreenState extends State<MonthScreen> {
  late DateTime month = DateTime(DateTime.now().year, DateTime.now().month);

  void _shift(int d) =>
      setState(() => month = DateTime(month.year, month.month + d));

  bool get _isCurrent {
    final n = DateTime.now();
    return month.year == n.year && month.month == n.month;
  }

  void _open(Widget w) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => w));

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final p = Period.month(month);
    final an = Analytics(
      s,
      p,
      const AnalysisFilter(),
      previous: previousPeriod(p),
    );
    final pending = s.transactions
        .where((t) => t.categoryId == null && !t.isTransfer)
        .length;
    final hasData = s.transactions.isNotEmpty;
    final ceiling = an.income;
    final over = ceiling > 0 && an.spent > ceiling;
    final top = (an.byCategory()..sort((a, b) => b.amount.compareTo(a.amount)))
        .where((e) => e.amount > 0)
        .take(5)
        .toList();
    final maxTop = top.isEmpty ? 1 : top.first.amount;
    final expenseColor = Color(s.expenseColor),
        incomeColor = Color(s.incomeColor);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Mês anterior',
          icon: const Icon(Icons.chevron_left),
          onPressed: () => _shift(-1),
        ),
        title: GestureDetector(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: month,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              helpText: 'Escolhe um dia do mês',
            );
            if (d != null) setState(() => month = DateTime(d.year, d.month));
          },
          child: Text(fmtMonth(month), style: tt.titleLarge),
        ),
        actions: [
          IconButton(
            tooltip: 'Mês seguinte',
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _shift(1),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTxnEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Movimento'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
        children: [
          if (!hasData)
            SectionCard(
              title: 'Começa por aqui',
              subtitle: 'O mês aparece assim que tiveres movimentos',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: () => _open(const ImportScreen()),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Importar um extrato'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => showTxnEditor(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar um movimento'),
                  ),
                ],
              ),
            )
          else ...[
            // ----- anel -----
            Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: _RingPainter(
                    value: ceiling > 0 ? an.spent / ceiling : 0,
                    color: over ? expenseColor : cs.primary,
                    track: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Gasto',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Text(
                              fmtMoney(an.spent),
                              style: tt.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          ceiling > 0
                              ? 'de ${fmtMoney(ceiling, short: true)}'
                              : 'sem rendimento definido',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                ceiling <= 0
                    ? 'Define o salário no Orçamento para ver quanto ainda podes gastar.'
                    : (over
                          ? 'Passaste ${fmtMoney(an.spent - ceiling)} do previsto'
                          : 'Ainda podes gastar ${fmtMoney(ceiling - an.spent)}'),
                style: tt.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: over ? expenseColor : null,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (an.ongoing)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Center(
                  child: Text(
                    'Média de ${fmtMoney(an.dailyAvg)} por dia',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            // ----- números -----
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label:
                        an.incomeFromSalary || (an.ongoing && s.salaryIn(p) > 0)
                        ? 'Receitas (previstas)'
                        : 'Receitas',
                    value: fmtMoney(an.income),
                    color: incomeColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Stat(
                    label: 'Poupado',
                    value:
                        '${an.balance >= 0 ? '+' : '−'}${fmtMoney(an.balance.abs())}',
                    color: an.balance >= 0 ? incomeColor : expenseColor,
                    note: an.savingsRate == null
                        ? null
                        : '${(an.savingsRate! * 100).round()}% do rendimento',
                  ),
                ),
              ],
            ),
            if (an.invested != 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _Stat(
                  label: 'Enviado para investir',
                  value: fmtMoney(an.invested),
                  color: cs.onSurface,
                  wide: true,
                ),
              ),
            const SizedBox(height: 6),
            // ----- onde gastas mais -----
            if (top.isNotEmpty)
              SectionCard(
                title: 'Onde gastas mais',
                trailing: TextButton(
                  onPressed: () => _open(AnalysisScreen(initialMonth: month)),
                  child: const Text('Ver análise'),
                ),
                child: Column(
                  children: [
                    for (final e in top)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 26,
                                  child: Text(
                                    e.emoji.isEmpty ? '•' : e.emoji,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    e.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: tt.bodyLarge,
                                  ),
                                ),
                                Text(
                                  fmtMoney(e.amount),
                                  style: tt.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: math.min(1, e.amount / maxTop),
                                minHeight: 5,
                                backgroundColor: cs.outlineVariant.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
          // ----- por tratar -----
          if (pending > 0)
            Card(
              color: cs.primaryContainer.withValues(alpha: 0.45),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: cs.primary,
                  child: Icon(Icons.style, color: cs.onPrimary, size: 20),
                ),
                title: Text(
                  '$pending por classificar',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Um cartão por nome; memoriza para as próximas vezes',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(const ClassifyScreen()),
              ),
            ),
          if (hasData)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _open(const BudgetScreen()),
                      icon: const Icon(Icons.savings_outlined, size: 18),
                      label: const Text('Orçamento'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _open(AnalysisScreen(initialMonth: month)),
                      icon: const Icon(Icons.insights_outlined, size: 18),
                      label: const Text('Análise'),
                    ),
                  ),
                ],
              ),
            ),
          _CartoesMes(month: month, spent: an.spent),
          if (hasData && !_isCurrent)
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () => setState(
                  () => month = DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                  ),
                ),
                child: const Text('Voltar a este mês'),
              ),
            ),
        ],
      ),
    );
  }
}

/// Cartões compactos do mês: objetivos, planeamento do mês mostrado e entregas por distribuir.
/// Cada um só aparece se tiver dados.
class _CartoesMes extends StatelessWidget {
  final DateTime month;
  final int spent; // gasto real do mês mostrado
  const _CartoesMes({required this.month, required this.spent});

  void _abrir(BuildContext context, Widget w) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => w));

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final key = monthKey(month);

    // objetivos ativos, o de prazo mais próximo primeiro (sem prazo, no fim)
    final far = DateTime(9999);
    final objetivos = s.goals.where((g) => !g.archived).toList()
      ..sort((a, b) => (a.endDate ?? far).compareTo(b.endDate ?? far));
    final planeadas = s.planFor(key);
    final entregas = s.pendingAllocations;
    final entregasTotal = entregas.fold<int>(0, (a, p) => a - p.txn.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (objetivos.isNotEmpty)
          SectionCard(
            title: 'Objetivos',
            trailing: TextButton(
              onPressed: () => _abrir(context, const GoalsScreen()),
              child: const Text('Ver todos'),
            ),
            child: Column(
              children: [
                for (final g in objetivos.take(3))
                  _LinhaObjetivo(
                    nome: g.name,
                    progresso: s.goalProgressOf(g),
                    prazo: g.endDate,
                    onTap: () =>
                        _abrir(context, GoalDetailScreen(goalId: g.id)),
                  ),
              ],
            ),
          ),
        if (planeadas.isNotEmpty) _cartaoPlaneamento(context, s, key),
        if (entregas.isNotEmpty)
          SectionCard(
            title: 'Entregas para distribuir',
            subtitle:
                '${entregas.length} ${entregas.length == 1 ? 'entrega' : 'entregas'} · ${fmtMoney(entregasTotal)}',
            trailing: TextButton(
              onPressed: () => _abrir(context, const _EntregasScreen()),
              child: const Text('Distribuir'),
            ),
            child: Text(
              'Entregas do banco que ainda não repartiste pelos ativos.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
      ],
    );
  }

  Widget _cartaoPlaneamento(BuildContext context, AppState s, String key) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final t = planTotals(s.salaryFor(key), s.planFor(key));
    final excede = spent > t.planned;
    final ratio = t.planned <= 0
        ? 0.0
        : (spent / t.planned).clamp(0.0, 1.0).toDouble();
    final sobra = t.left;
    return SectionCard(
      title: 'Planeamento',
      trailing: TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlanningScreen(initialMonth: month),
          ),
        ),
        child: const Text('Ver plano'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Planeado',
                  value: fmtMoney(t.planned),
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Stat(
                  label: 'Gasto real',
                  value: fmtMoney(spent),
                  color: excede ? Color(s.expenseColor) : cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              color: excede ? Color(s.expenseColor) : null,
              backgroundColor: cs.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.salary <= 0
                ? 'Define o salário no Orçamento para ver o que sobra.'
                : (sobra < 0
                      ? 'O plano excede o salário em ${fmtMoney(-sobra)}'
                      : 'Sobra do salário, depois do plano: ${fmtMoney(sobra)}'),
            style: tt.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: sobra < 0 ? Color(s.expenseColor) : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Uma linha de objetivo: nome, barra de progresso e quanto falta.
class _LinhaObjetivo extends StatelessWidget {
  final String nome;
  final GoalProgress progresso;
  final DateTime? prazo;
  final VoidCallback onTap;
  const _LinhaObjetivo({
    required this.nome,
    required this.progresso,
    required this.prazo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final s = context.read<AppState>();
    final p = progresso;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '🎯 $nome',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  p.done ? 'Atingido' : 'Faltam ${fmtMoney(p.remaining)}',
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: p.done ? Color(s.incomeColor) : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: p.fraction,
                minHeight: 6,
                backgroundColor: cs.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${fmtMoney(p.saved)} de ${fmtMoney(p.target)}'
              '${prazo == null ? '' : ' · até ${fmtDate(prazo!)}'}',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Entregas para distribuir, num ecrã próprio a partir do cartão do mês.
class _EntregasScreen extends StatelessWidget {
  const _EntregasScreen();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Entregas para distribuir')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: const [PendingAllocationsCard()],
    ),
  );
}

class _Stat extends StatelessWidget {
  final String label, value;
  final String? note;
  final Color color;
  final bool wide;
  const _Stat({
    required this.label,
    required this.value,
    required this.color,
    this.note,
    this.wide = false,
  });
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: tt.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          if (note != null)
            Text(
              note!,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value; // 0..1+ (acima de 1 fica cheio)
  final Color color, track;
  _RingPainter({required this.value, required this.color, required this.track});
  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final r = (math.min(size.width, size.height) - stroke) / 2;
    final c = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: c, radius: r);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawCircle(c, r, base);
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    if (v > 0) {
      final arc = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color;
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * v, false, arc);
    }
  }

  @override
  bool shouldRepaint(_RingPainter o) =>
      o.value != value || o.color != color || o.track != track;
}
