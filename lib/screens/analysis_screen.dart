import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import '../widgets/common.dart';

enum _Mode { month, range, year, years }

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});
  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  _Mode mode = _Mode.month;
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime from = DateTime(DateTime.now().year, DateTime.now().month - 2);
  DateTime to = DateTime(DateTime.now().year, DateTime.now().month);
  int year = DateTime.now().year;
  int yearFrom = DateTime.now().year - 1;
  int yearTo = DateTime.now().year;

  Period get period => switch (mode) {
        _Mode.month => Period.month(month),
        _Mode.range => Period.months(from.isBefore(to) ? from : to, from.isBefore(to) ? to : from),
        _Mode.year => Period.years(year, year),
        _Mode.years => Period.years(yearFrom <= yearTo ? yearFrom : yearTo, yearFrom <= yearTo ? yearTo : yearFrom),
      };

  String get periodLabel {
    final p = period;
    return switch (mode) {
      _Mode.month => fmtMonth(month),
      _Mode.range => '${fmtMonthShort(p.start)} – ${fmtMonthShort(DateTime(p.end.year, p.end.month - 1))}',
      _Mode.year => '$year',
      _Mode.years => '${p.start.year} – ${p.end.year - 1}',
    };
  }

  Future<DateTime?> _pickMonth(DateTime initial) async {
    final d = await showDatePicker(
        context: context, initialDate: initial, firstDate: DateTime(2000), lastDate: DateTime(2100), helpText: 'Escolhe qualquer dia do mês');
    return d == null ? null : DateTime(d.year, d.month);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = period;
    final own = s.totalsByCategory(p);
    final salary = s.salaryIn(p);
    final roots = s.roots;
    final income = s.txnsIn(p).where((t) => t.amount > 0 && (s.cat(t.categoryId)?.isIncome ?? false)).fold(0, (a, t) => a + t.amount);
    final expRoots = roots.where((c) => !c.isIncome).toList();
    final mandSpent = expRoots.where((c) => c.mandatory).fold(0, (a, c) => a + s.rollup(c, own));
    final optSpent = expRoots.where((c) => !c.mandatory).fold(0, (a, c) => a + s.rollup(c, own));
    final unclassified = s.txnsIn(p).where((t) => t.categoryId == null && t.amount < 0).fold(0, (a, t) => a - t.amount);
    final totalSpent = mandSpent + optSpent + unclassified;
    final base = income > 0 ? income : salary;

    // Alertas
    final stats = <CategoryStat>[];
    for (final c in s.categories.where((c) => !c.isIncome && !c.archived)) {
      final t = c.parentId == null ? s.targetIn(c, p) : _subTarget(s, c, p);
      if (t <= 0) continue;
      final spent = c.parentId == null ? s.rollup(c, own) : (own[c.id] ?? 0);
      stats.add(CategoryStat(c, spent, t));
    }
    final over = stats.where((x) => x.category.budgetType == BudgetType.limit || !x.category.hasBudget).where((x) => x.ratio > 1).toList()..sort((a, b) => b.ratio.compareTo(a.ratio));
    final near = stats.where((x) => (x.category.budgetType == BudgetType.limit || !x.category.hasBudget) && x.ratio >= 0.85 && x.ratio <= 1).toList();
    final goalsMissed = stats.where((x) => x.category.hasBudget && x.category.budgetType == BudgetType.goal && x.ratio < 1).toList();
    final goalsHit = stats.where((x) => x.category.hasBudget && x.category.budgetType == BudgetType.goal && x.ratio >= 1).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Análise')),
      body: ListView(padding: const EdgeInsets.fromLTRB(12, 0, 12, 40), children: [
        _selector(context, s),
        const SizedBox(height: 8),
        // Resumo
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(periodLabel, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Wrap(spacing: 24, runSpacing: 8, children: [
                _kpi('Rendimentos', income > 0 ? income : salary, Colors.green),
                _kpi('Despesas', totalSpent, Colors.red),
                _kpi('Saldo', (income > 0 ? income : salary) - totalSpent, (income > 0 ? income : salary) - totalSpent >= 0 ? Colors.green : Colors.red),
              ]),
              if (income == 0 && salary > 0) const Padding(padding: EdgeInsets.only(top: 6), child: Text('Sem rendimentos categorizados: a usar o salário líquido definido.', style: TextStyle(fontSize: 12))),
              if (base > 0) ...[
                const SizedBox(height: 12),
                Text('Taxa de poupança: ${fmtPercent((base - totalSpent) / base)}'),
              ],
            ]),
          ),
        ),
        // Obrigatórias vs opcionais
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Obrigatórias vs Opcionais', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              if (totalSpent == 0)
                const Text('Sem despesas neste período.')
              else
                Row(children: [
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: PieChart(PieChartData(sectionsSpace: 2, centerSpaceRadius: 30, sections: [
                      PieChartSectionData(value: mandSpent.toDouble().clamp(0, double.infinity), color: Colors.indigo, title: '', radius: 28),
                      PieChartSectionData(value: optSpent.toDouble().clamp(0, double.infinity), color: Colors.orange, title: '', radius: 28),
                      if (unclassified > 0) PieChartSectionData(value: unclassified.toDouble(), color: Colors.grey, title: '', radius: 28),
                    ])),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _legend(Colors.indigo, 'Obrigatórias', mandSpent, totalSpent),
                      _legend(Colors.orange, 'Opcionais', optSpent, totalSpent),
                      if (unclassified > 0) _legend(Colors.grey, 'Sem categoria', unclassified, totalSpent),
                    ]),
                  ),
                ]),
              if (base > 0 && totalSpent > 0) ...[
                const SizedBox(height: 12),
                Text(_needsWants(base, mandSpent, optSpent), style: Theme.of(context).textTheme.bodyMedium),
              ],
            ]),
          ),
        ),
        // Evolução
        _trend(context, s, p),
        // Insights
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Estamos a chegar ao limite / objetivo?', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (stats.isEmpty) const Text('Define limites ou objetivos na página Orçamento para ver aqui o estado de cada categoria.'),
              for (final x in over) _insight(Icons.error, Colors.red, '${s.path(x.category.id)}: ${fmtMoney(x.spent)} de ${fmtMoney(x.target)} (${fmtPercent(x.ratio)}) – limite excedido em ${fmtMoney(x.spent - x.target)}'),
              for (final x in near) _insight(Icons.warning_amber, Colors.orange, '${s.path(x.category.id)}: ${fmtPercent(x.ratio)} do limite – restam ${fmtMoney(x.target - x.spent)}'),
              for (final x in goalsMissed) _insight(Icons.flag_outlined, Colors.amber.shade800, '${s.path(x.category.id)}: objetivo a ${fmtPercent(x.ratio)} – faltam ${fmtMoney(x.target - x.spent)}'),
              for (final x in goalsHit) _insight(Icons.check_circle, Colors.green, '${s.path(x.category.id)}: objetivo atingido (${fmtMoney(x.spent)} de ${fmtMoney(x.target)})'),
              if (stats.isNotEmpty && over.isEmpty && near.isEmpty && goalsMissed.isEmpty && goalsHit.isEmpty)
                _insight(Icons.check_circle, Colors.green, 'Tudo dentro dos limites. Bom trabalho!'),
            ]),
          ),
        ),
        // Detalhe por tipo
        _typeDetail(context, s, 'Obrigatórias', expRoots.where((c) => c.mandatory).toList(), own, p),
        _typeDetail(context, s, 'Opcionais', expRoots.where((c) => !c.mandatory).toList(), own, p),
      ]),
    );
  }

  int _subTarget(AppState s, Categoria c, Period p) {
    var t = 0;
    for (var i = 0; i < p.monthCount; i++) {
      t += c.monthlyTarget(s.salaryFor(monthKey(DateTime(p.start.year, p.start.month + i))));
    }
    return t;
  }

  String _needsWants(int base, int mand, int opt) {
    final m = mand / base, o = opt / base, sv = 1 - m - o;
    return 'Em % dos rendimentos: obrigatórias ${fmtPercent(m)}, opcionais ${fmtPercent(o)}, sobra ${fmtPercent(sv)}. '
        '${m > 0.5 ? 'As obrigatórias pesam mais de metade – vê onde poupar nos tarifários e na habitação. ' : ''}'
        '${o > 0.3 ? 'Os gastos opcionais passam os 30% – é aqui que há mais margem de manobra.' : ''}';
  }

  Widget _kpi(String l, int v, Color c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(fmtMoney(v), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c)),
      ]);

  Widget _legend(Color c, String label, int v, int total) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Container(width: 12, height: 12, color: c),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text('${fmtMoney(v)}  ${total > 0 ? fmtPercent(v / total) : ''}'),
        ]),
      );

  Widget _insight(IconData icon, Color color, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color, size: 20), const SizedBox(width: 8), Expanded(child: Text(text))]),
      );

  Widget _selector(BuildContext context, AppState s) {
    final years = {for (final t in s.transactions) t.date.year, DateTime.now().year}.toList()..sort();
    Widget chev(int dir) => IconButton(
          icon: Icon(dir < 0 ? Icons.chevron_left : Icons.chevron_right),
          onPressed: () => setState(() {
            if (mode == _Mode.month) month = DateTime(month.year, month.month + dir);
            if (mode == _Mode.year) year += dir;
          }),
        );
    return Column(children: [
      SegmentedButton<_Mode>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: _Mode.month, label: Text('Mês')),
          ButtonSegment(value: _Mode.range, label: Text('Meses')),
          ButtonSegment(value: _Mode.year, label: Text('Ano')),
          ButtonSegment(value: _Mode.years, label: Text('Anos')),
        ],
        selected: {mode},
        onSelectionChanged: (v) => setState(() => mode = v.first),
      ),
      const SizedBox(height: 4),
      if (mode == _Mode.month || mode == _Mode.year)
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [chev(-1), Text(periodLabel, style: Theme.of(context).textTheme.titleMedium), chev(1)]),
      if (mode == _Mode.range)
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          TextButton(onPressed: () async { final d = await _pickMonth(from); if (d != null) setState(() => from = d); }, child: Text('De ${fmtMonthShort(from)}')),
          TextButton(onPressed: () async { final d = await _pickMonth(to); if (d != null) setState(() => to = d); }, child: Text('a ${fmtMonthShort(to)}')),
        ]),
      if (mode == _Mode.years)
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('De '),
          DropdownButton<int>(value: yearFrom, items: [for (final y in years.toSet()..addAll([yearFrom, yearTo])) DropdownMenuItem(value: y, child: Text('$y'))], onChanged: (v) => setState(() => yearFrom = v!)),
          const Text('  a '),
          DropdownButton<int>(value: yearTo, items: [for (final y in years.toSet()..addAll([yearFrom, yearTo])) DropdownMenuItem(value: y, child: Text('$y'))], onChanged: (v) => setState(() => yearTo = v!)),
        ]),
    ]);
  }

  Widget _trend(BuildContext context, AppState s, Period p) {
    final n = p.monthCount;
    if (n < 2) return const SizedBox.shrink();
    final bucketYears = n > 24;
    final buckets = bucketYears ? (p.end.year - p.start.year) : n;
    final mand = List<double>.filled(buckets, 0), opt = List<double>.filled(buckets, 0);
    for (final t in s.txnsIn(p)) {
      final c = s.cat(t.categoryId);
      if (c == null || c.isIncome || t.amount >= 0) continue;
      final idx = bucketYears ? t.date.year - p.start.year : (t.date.year - p.start.year) * 12 + t.date.month - p.start.month;
      (c.mandatory ? mand : opt)[idx] += -t.amount / 100;
    }
    String label(int i) => bucketYears ? '${p.start.year + i}' : fmtMonthShort(DateTime(p.start.year, p.start.month + i)).split(' ').first;
    final maxY = [for (var i = 0; i < buckets; i++) mand[i] + opt[i]].fold(1.0, (a, b) => b > a ? b : a);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Evolução das despesas', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: BarChart(BarChartData(
              maxY: maxY * 1.1,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: buckets > 12 ? (buckets / 6).ceilToDouble() : 1,
                    getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 4), child: Text(label(v.toInt()), style: const TextStyle(fontSize: 10))),
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < buckets; i++)
                  BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: mand[i] + opt[i],
                      width: buckets > 12 ? 6 : 14,
                      borderRadius: BorderRadius.circular(2),
                      rodStackItems: [BarChartRodStackItem(0, mand[i], Colors.indigo), BarChartRodStackItem(mand[i], mand[i] + opt[i], Colors.orange)],
                    )
                  ]),
              ],
            )),
          ),
          const SizedBox(height: 4),
          Row(children: [Container(width: 10, height: 10, color: Colors.indigo), const Text('  Obrigatórias    '), Container(width: 10, height: 10, color: Colors.orange), const Text('  Opcionais')]),
        ]),
      ),
    );
  }

  Widget _typeDetail(BuildContext context, AppState s, String title, List<Categoria> cats, Map<int, int> own, Period p) {
    if (cats.isEmpty) return const SizedBox.shrink();
    final list = cats.map((c) => (c, s.rollup(c, own), s.targetIn(c, p))).toList()..sort((a, b) => b.$2.compareTo(a.$2));
    final total = list.fold(0, (a, e) => a + e.$2);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Text(title, style: Theme.of(context).textTheme.titleMedium), const Spacer(), Text(fmtMoney(total), style: const TextStyle(fontWeight: FontWeight.w700))]),
          const SizedBox(height: 8),
          for (final (c, spent, target) in list)
            if (spent != 0 || target > 0) _row(context, s, c, spent, target, own, p),
        ]),
      ),
    );
  }

  Widget _row(BuildContext context, AppState s, Categoria c, int spent, int target, Map<int, int> own, Period p) {
    final kids = s.childrenOf(c.id).where((k) => (own[k.id] ?? 0) != 0 || k.hasBudget).toList();
    final type = c.hasBudget ? c.budgetType : BudgetType.limit;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      shape: const Border(),
      collapsedShape: const Border(),
      title: Row(children: [Dot(c.color), const SizedBox(width: 8), Expanded(child: Text(c.name)), Text(target > 0 ? '${fmtMoney(spent)} / ${fmtMoney(target)}' : fmtMoney(spent))]),
      subtitle: target > 0 ? Padding(padding: const EdgeInsets.only(top: 4), child: BudgetBar(spent: spent < 0 ? 0 : spent, target: target, type: type, height: 8)) : null,
      children: [
        for (final k in kids)
          () {
            final ks = own[k.id] ?? 0;
            final kt = _subTarget(s, k, p);
            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 24),
              title: Text(k.name),
              subtitle: kt > 0 ? BudgetBar(spent: ks < 0 ? 0 : ks, target: kt, type: k.budgetType, height: 6) : null,
              trailing: Text(kt > 0 ? '${fmtMoney(ks)} / ${fmtMoney(kt)}' : fmtMoney(ks)),
            );
          }(),
        if ((own[c.id] ?? 0) != 0 && kids.isNotEmpty)
          ListTile(dense: true, contentPadding: const EdgeInsets.only(left: 24), title: const Text('Sem subcategoria'), trailing: Text(fmtMoney(own[c.id]!))),
      ],
    );
  }
}
