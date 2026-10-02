import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../analysis/analytics.dart';
import '../analysis/filter_sheet.dart';
import '../analysis/overview_tab.dart';
import '../analysis/save_tab.dart';
import '../analysis/spend_tab.dart';
import '../analysis/trend_tab.dart';
import '../state/app_state.dart';
import '../util/format.dart';

enum _Mode { month, year, ytd, custom }

/// Análise: ferramenta para perceber onde se gasta, o que mudou e onde se pode poupar.
class AnalysisScreen extends StatefulWidget {
  /// Mês inicial (por omissão, o mês atual).
  final DateTime? initialMonth;
  const AnalysisScreen({super.key, this.initialMonth});
  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> with SingleTickerProviderStateMixin {
  late final TabController tabs = TabController(length: 4, vsync: this);
  _Mode mode = _Mode.month;
  late DateTime month = DateTime((widget.initialMonth ?? DateTime.now()).year, (widget.initialMonth ?? DateTime.now()).month);
  late int year = month.year;
  late DateTime customFrom = month;
  late DateTime customTo = DateTime(month.year, month.month + 1, 0);
  AnalysisFilter filter = const AnalysisFilter();
  bool compare = true;

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  Period get period => switch (mode) {
        _Mode.month => Period.month(month),
        _Mode.year => Period.year(year),
        _Mode.ytd => Period.ytd(),
        _Mode.custom => Period.custom(customFrom, customTo),
      };

  String get periodLabel => switch (mode) {
        _Mode.month => fmtMonth(month),
        _Mode.year => '$year',
        _Mode.ytd => 'YTD ${DateTime.now().year} · 1 jan – hoje',
        _Mode.custom => customFrom.isAfter(customTo) ? '${fmtDate(customTo)} – ${fmtDate(customFrom)}' : '${fmtDate(customFrom)} – ${fmtDate(customTo)}',
      };

  void _viewCategory(int id) {
    setState(() => filter = filter.copyWith(categoryIds: {id}));
    tabs.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = period;
    final a = Analytics(s, p, filter, previous: compare ? previousPeriod(p, today: DateTime.now()) : null);
    final cs = Theme.of(context).colorScheme;

    Widget chev(int dir) => IconButton(
          icon: Icon(dir < 0 ? Icons.chevron_left : Icons.chevron_right),
          onPressed: () => setState(() {
            if (mode == _Mode.month) month = DateTime(month.year, month.month + dir);
            if (mode == _Mode.year) year += dir;
          }),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Análise'),
        actions: [
          IconButton(
            tooltip: compare ? 'A comparar com o período anterior' : 'Comparar com o período anterior',
            isSelected: compare,
            icon: const Icon(Icons.compare_arrows),
            selectedIcon: Icon(Icons.compare_arrows, color: cs.primary),
            onPressed: () => setState(() => compare = !compare),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, inner) => [
          SliverToBoxAdapter(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<_Mode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: _Mode.month, label: Text('Mês')),
                      ButtonSegment(value: _Mode.year, label: Text('Ano')),
                      ButtonSegment(value: _Mode.ytd, label: Text('YTD')),
                      ButtonSegment(value: _Mode.custom, label: Text('Custom')),
                    ],
                    selected: {mode},
                    onSelectionChanged: (v) => setState(() => mode = v.first),
                  ),
                ),
              ),
              if (mode == _Mode.month || mode == _Mode.year)
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [chev(-1), Text(periodLabel, style: Theme.of(context).textTheme.titleMedium), chev(1)])
              else if (mode == _Mode.ytd)
                Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Text(periodLabel, style: Theme.of(context).textTheme.titleMedium))
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(periodLabel),
                    onPressed: () async {
                      final r = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        initialDateRange: DateTimeRange(start: customFrom.isAfter(customTo) ? customTo : customFrom, end: customFrom.isAfter(customTo) ? customFrom : customTo),
                        helpText: 'Escolhe o intervalo',
                        saveText: 'Aplicar',
                      );
                      if (r != null) setState(() {
                        customFrom = r.start;
                        customTo = r.end;
                      });
                    },
                  ),
                ),
              FilterBar(filter: filter, onChanged: (f) => setState(() => filter = f)),
            ]),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabsDelegate(
              Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: TabBar(
                  controller: tabs,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: const [Tab(text: 'Visão geral'), Tab(text: 'Gastos'), Tab(text: 'Poupar'), Tab(text: 'Evolução')],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: tabs,
          children: [
            OverviewTab(a: a, periodLabel: periodLabel, compare: compare, onSavings: () => tabs.animateTo(2)),
            SpendTab(a: a, compare: compare, onFilterCategory: _viewCategory),
            SaveTab(a: a, onViewCategory: _viewCategory),
            TrendTab(a: a),
          ],
        ),
      ),
    );
  }
}

class _TabsDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _TabsDelegate(this.child);
  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;
  @override
  bool shouldRebuild(covariant _TabsDelegate old) => true;
}
