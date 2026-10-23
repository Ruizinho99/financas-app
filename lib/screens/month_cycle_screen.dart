import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import '../util/month_cycle.dart';
import '../widgets/category_picker.dart';

/// Escolhe quando começa o mês: calendário, um dia fixo (ex.: 25) ou o dia em que se recebe o salário.
class MonthCycleScreen extends StatelessWidget {
  const MonthCycleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = context.watch<AppState>();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final key = s.currentMonthKey;
    final p = s.periodOfMonth(key);
    final range =
        '${fmtDayMonth(p.start)} – ${fmtDayMonth(p.end.subtract(const Duration(days: 1)))}';
    final salaryCat = s.cat(s.salaryCategoryId);
    final dates = s.salaryDates;

    return Scaffold(
      appBar: AppBar(title: Text(l.monthStartTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          SegmentedButton<CycleMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: CycleMode.calendar,
                label: Text(l.monthModeCalendar),
              ),
              ButtonSegment(
                value: CycleMode.fixedDay,
                label: Text(l.monthModeFixed),
              ),
              ButtonSegment(
                value: CycleMode.salary,
                label: Text(l.monthModeSalary),
              ),
            ],
            selected: {s.monthMode},
            onSelectionChanged: (v) => s.setMonthCycle(
              mode: v.first,
              day: v.first == CycleMode.fixedDay && s.monthStartDay <= 1
                  ? 25
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          if (s.monthMode == CycleMode.calendar)
            Text(l.monthCalendarHint, style: tt.bodyMedium),
          if (s.monthMode == CycleMode.fixedDay) ...[
            DropdownButtonFormField<int>(
              initialValue: s.monthStartDay,
              decoration: InputDecoration(labelText: l.monthStartDayLabel),
              items: [
                for (var d = 1; d <= 31; d++)
                  DropdownMenuItem(value: d, child: Text(l.dayOfMonthItem(d))),
              ],
              onChanged: (d) {
                if (d != null)
                  s.setMonthCycle(mode: CycleMode.fixedDay, day: d);
              },
            ),
            const SizedBox(height: 8),
            Text(l.monthNamedByEnd, style: tt.bodySmall),
          ],
          if (s.monthMode == CycleMode.salary) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.sell_outlined),
              title: Text(l.salaryCategoryLabel),
              subtitle: Text(
                salaryCat == null
                    ? l.salaryCategoryChoose
                    : '${salaryCat.emoji.isEmpty ? '' : '${salaryCat.emoji} '}${s.path(salaryCat.id)}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final id = await chooseCategory(
                  context,
                  selected: s.salaryCategoryId,
                  income: true,
                );
                if (id != null && id != -1) {
                  s.setMonthCycle(mode: CycleMode.salary, salaryCategory: id);
                }
              },
            ),
            Text(l.salaryCategoryHint, style: tt.bodySmall),
            const SizedBox(height: 8),
            Text(
              dates.isEmpty && salaryCat != null
                  ? l.salaryNoneFound
                  : l.salaryDatesFound(dates.length),
              style: tt.bodySmall,
            ),
            Text(l.monthNamedByEnd, style: tt.bodySmall),
          ],
          const SizedBox(height: 20),
          Card(
            color: cs.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l.thisMonthIs(
                  '${fmtMonth(DateTime(int.parse(key.substring(0, 4)), int.parse(key.substring(5, 7))))} · $range',
                ),
                style: tt.titleSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
