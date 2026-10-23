import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../analysis/widgets.dart';
import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import 'account_screen.dart';
import 'forms.dart';
import 'transfers_screen.dart';
import 'import_trades_screen.dart';
import 'holding_screen.dart';
import 'plan_widgets.dart';
import 'invest.dart';
import 'widgets.dart';

enum _View { asset, platform, kind }

/// Carteira: onde está o dinheiro investido, quanto vale e quanto está por alocar (standby).
class InvestScreen extends StatefulWidget {
  const InvestScreen({super.key});
  @override
  State<InvestScreen> createState() => _InvestScreenState();
}

class _InvestScreenState extends State<InvestScreen> {
  _View view = _View.asset;
  bool refreshing = false;

  Future<void> _refresh(AppState s, {int? accountId}) async {
    final l = AppLocalizations.of(context)!;
    setState(() => refreshing = true);
    final r = await s.refreshPrices(accountId: accountId);
    if (!mounted) return;
    setState(() => refreshing = false);
    final msg = StringBuffer(
      r.updated == 0 && r.failed.isEmpty
          ? l.invNoAutoPrices
          : l.invPricesUpdated(r.updated),
    );
    if (r.failed.isNotEmpty)
      msg.write(
        ' ${l.invPricesFailed(r.failed.entries.map((e) => '${e.key} (${e.value})').join('; '))}',
      );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg.toString()),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _addMenu(BuildContext context, AppState s) {
    final hasAcc = s.investAccounts.isNotEmpty;
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (ctx) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l.invAdd,
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
              ),
            ),
            if (hasAcc)
              _item(
                ctx,
                Icons.edit_note,
                l.invRecordOperation,
                l.invRecordOperationHint,
                () => showOpForm(context, type: OpType.buy),
              ),
            _item(
              ctx,
              Icons.upload_file,
              l.invImportFromFile,
              l.invImportFileHint,
              () => _openImport(context),
            ),
            if (hasAcc)
              _item(
                ctx,
                Icons.pie_chart_outline,
                l.invNewHolding,
                l.invNewHoldingHint,
                () => showHoldingEditor(context),
              ),
            _item(
              ctx,
              Icons.account_balance_outlined,
              l.invNewAccount,
              l.invNewAccountHint,
              () => showInvestAccountEditor(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openImport(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ImportTradesScreen()),
  );

  /// Cartão bem visível para importar um ficheiro da corretora.
  Widget _importCard(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.primaryContainer.withValues(alpha: 0.45),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.primary,
          child: Icon(Icons.upload_file, color: cs.onPrimary),
        ),
        title: Text(
          l.invImportTrades,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(l.invImportCardHint),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openImport(context),
      ),
    );
  }

  Widget _item(
    BuildContext ctx,
    IconData icon,
    String title,
    String? sub,
    VoidCallback onTap,
  ) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    subtitle: sub == null ? null : Text(sub),
    onTap: () {
      Navigator.pop(ctx);
      onTap();
    },
  );

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    final pf = s.portfolio;
    final colors = chartColors(cs);
    final anyAuto = s.holdings.any((h) => h.needsRefresh && !h.archived);
    final times =
        s.holdings
            .where((h) => h.lastPriceAt != null && !h.archived)
            .map((h) => h.lastPriceAt!)
            .toList()
          ..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.invTitle),
        actions: [
          IconButton(
            tooltip: l.invImportTrades,
            icon: const Icon(Icons.upload_file),
            onPressed: () => _openImport(context),
          ),
          if (anyAuto)
            refreshing
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                : IconButton(
                    tooltip: l.invRefreshPrices,
                    icon: const Icon(Icons.sync),
                    onPressed: () => _refresh(s),
                  ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addMenu(context, s),
        icon: const Icon(Icons.add),
        label: Text(l.invAdd),
      ),
      body: pf.isEmpty
          ? _intro(context, s)
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
              children: [
                // ----- entregas por distribuir (plano de cada plataforma) -----
                const PendingAllocationsCard(),
                // ----- resumo -----
                SectionCard(
                  title: l.invMyPortfolio,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.invTotalValue,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          fmtMoney(pf.total),
                          style: tt.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 28,
                        runSpacing: 12,
                        children: [
                          Stat(l.invInvested, fmtMoney(pf.costBasis)),
                          Stat(l.invCurrentValue, fmtMoney(pf.investedValue)),
                          Stat(
                            l.invGainLoss,
                            fmtSignedMoney(pf.pl),
                            color: plColor(context, pf.pl),
                            extra: pf.plPct == null
                                ? null
                                : Text(
                                    fmtSignedPercent(pf.plPct!),
                                    style: tt.bodySmall?.copyWith(
                                      color: plColor(context, pf.pl),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                          Stat(
                            l.invUnallocated,
                            fmtMoney(pf.cash),
                            color: pf.cash < 0 ? Colors.orange.shade700 : null,
                          ),
                          if (pf.realized != 0)
                            Stat(
                              l.invRealizedGain,
                              fmtSignedMoney(pf.realized),
                              color: plColor(context, pf.realized),
                            ),
                          if (pf.dividends > 0)
                            Stat(l.invDividends, fmtMoney(pf.dividends)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              times.isEmpty
                                  ? (anyAuto
                                        ? l.invNoPricesYet
                                        : l.invPricesManual)
                                  : l.invPricesUpdatedAgo(fmtAgo(times.last)),
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (anyAuto)
                            TextButton.icon(
                              onPressed: refreshing ? null : () => _refresh(s),
                              icon: const Icon(Icons.sync, size: 18),
                              label: Text(l.invRefreshPrices),
                            ),
                        ],
                      ),
                      if (pf.positions.any((p) => !p.priced))
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            l.invUnpricedNote,
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                _importCard(context),

                // ----- transferências do banco e o que se fez com elas -----
                const TransfersCard(),

                // ----- alocação -----
                if (pf.total > 0) _allocation(context, pf, colors, cs),

                // ----- dinheiro por alocar -----
                if (pf.accounts.any((a) => a.cashCents != 0))
                  SectionCard(
                    title: l.invCashToAllocate,
                    subtitle: l.invCashSubtitle,
                    child: Column(
                      children: [
                        for (final a in pf.accounts.where(
                          (a) => a.cashCents != 0,
                        ))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Text(
                                  a.account.emoji.isEmpty
                                      ? '🏦'
                                      : a.account.emoji,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        a.account.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        fmtMoney(a.cashCents),
                                        style: tt.bodyMedium?.copyWith(
                                          color: a.cashCents < 0
                                              ? Colors.orange.shade700
                                              : null,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (a.cashCents < 0)
                                        Text(
                                          l.invNegativeCashHint,
                                          style: tt.bodySmall?.copyWith(
                                            color: Colors.orange.shade700,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (a.cashCents > 0)
                                  FilledButton.tonal(
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size(0, 40),
                                    ),
                                    onPressed: () => showOpForm(
                                      context,
                                      type: OpType.buy,
                                      accountId: a.account.id,
                                      prefillCents: a.cashCents,
                                    ),
                                    child: Text(l.invAllocate),
                                  )
                                else
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(0, 40),
                                    ),
                                    onPressed: () => showOpForm(
                                      context,
                                      type: OpType.cash,
                                      accountId: a.account.id,
                                    ),
                                    child: Text(l.invAdjust),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                // ----- plataformas -----
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
                  child: Text(
                    l.invPlatforms,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                for (final a in pf.accounts)
                  Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AccountScreen(accountId: a.account.id),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Text(
                                  a.account.emoji.isEmpty
                                      ? '🏦'
                                      : a.account.emoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    a.account.name,
                                    style: tt.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      fmtMoney(a.total),
                                      style: tt.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (a.costBasis > 0)
                                      PlText(
                                        a.pl,
                                        pct: a.costBasis > 0
                                            ? a.pl / a.costBasis
                                            : null,
                                        style: tt.bodySmall,
                                      ),
                                  ],
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 34),
                              child: Text(
                                l.invAccountLine(
                                  fmtMoney(a.cashCents),
                                  a.positions.where((p) => p.open).length,
                                ),
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                            if (a.positions.any((p) => p.open))
                              const Divider(height: 20),
                            for (final p
                                in a.positions.where((p) => p.open).take(4))
                              PositionRow(
                                p,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        HoldingScreen(holdingId: p.holding.id),
                                  ),
                                ),
                              ),
                            if (a.positions.where((p) => p.open).length > 4)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '+ ${l.invAssetsCount(a.positions.where((p) => p.open).length - 4)}',
                                  style: tt.bodySmall,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _allocation(
    BuildContext context,
    Portfolio pf,
    List<Color> colors,
    ColorScheme cs,
  ) {
    final l = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    final items = <({String label, int value, int? pl})>[];
    switch (view) {
      case _View.asset:
        for (final p in pf.positions) {
          items.add((
            label: p.holding.name,
            value: p.valueCents,
            pl: p.plCents,
          ));
        }
      case _View.platform:
        for (final a in pf.accounts) {
          items.add((label: a.account.name, value: a.investedValue, pl: a.pl));
        }
      case _View.kind:
        final m = <HoldingKind, int>{};
        for (final p in pf.positions) {
          m[p.holding.kind] = (m[p.holding.kind] ?? 0) + p.valueCents;
        }
        for (final e in m.entries) {
          items.add((label: e.key.labelL(l), value: e.value, pl: null));
        }
    }
    items.sort((a, b) => b.value.compareTo(a.value));
    final cash = pf.cash > 0 ? pf.cash : 0;
    final total = items.fold(0, (a, e) => a + e.value) + cash;
    final donutItems = [
      for (var i = 0; i < items.length; i++)
        DonutItem(items[i].label, items[i].value, colors[i % colors.length]),
      if (cash > 0) DonutItem(l.invUnallocated, cash, cs.outline),
    ];
    return SectionCard(
      title: 'Onde está o dinheiro',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final (v, label) in [
                  (_View.asset, l.invByAsset),
                  (_View.platform, l.invByPlatform),
                  (_View.kind, l.invByType),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: view == v,
                      onSelected: (_) => setState(() => view = v),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Donut(
              items: donutItems,
              centerTop: l.invTotal,
              centerBottom: fmtMoney(total, short: true),
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < items.length; i++)
            LegendRow(
              color: colors[i % colors.length],
              label: items[i].label,
              value: fmtMoney(items[i].value),
              share: total == 0 ? null : fmtPercent(items[i].value / total),
            ),
          if (cash > 0)
            LegendRow(
              color: cs.outline,
              label: l.invUnallocatedStandby,
              value: fmtMoney(cash),
              share: total == 0 ? null : fmtPercent(cash / total),
            ),
          if (total > 0 &&
              items.isNotEmpty &&
              items.first.value / total > 0.5 &&
              view == _View.asset)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l.invTopAssetWeight(
                  items.first.label,
                  fmtPercent(items.first.value / total),
                ),
                style: tt.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  Widget _intro(BuildContext context, AppState s) {
    final l = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    Widget step(IconData i, String t, String d) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: cs.primaryContainer.withValues(alpha: 0.6),
            child: Icon(i, size: 18, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t,
                  style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  d,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        SectionCard(
          title: l.invIntroTitle,
          subtitle: l.invIntroSubtitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              step(
                Icons.account_balance_outlined,
                l.invStep1Title,
                l.invStep1Desc,
              ),
              step(Icons.swap_horiz, l.invStep2Title, l.invStep2Desc),
              step(Icons.history, l.invStep3Title, l.invStep3Desc),
              step(Icons.add_shopping_cart, l.invStep4Title, l.invStep4Desc),
              step(Icons.sync, l.invStep5Title, l.invStep5Desc),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => showInvestAccountEditor(context),
                icon: const Icon(Icons.add),
                label: Text(l.invCreateFirstPlatform),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _openImport(context),
                icon: const Icon(Icons.upload_file),
                label: Text(l.invImportFromFileButton),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
