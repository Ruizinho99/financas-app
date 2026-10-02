import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../analysis/widgets.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import 'account_screen.dart';
import 'forms.dart';
import 'holding_screen.dart';
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
    setState(() => refreshing = true);
    final r = await s.refreshPrices(accountId: accountId);
    if (!mounted) return;
    setState(() => refreshing = false);
    final msg = StringBuffer(r.updated == 0 && r.failed.isEmpty ? 'Nenhum ativo com preço automático.' : '${r.updated} ${r.updated == 1 ? 'preço atualizado' : 'preços atualizados'}.');
    if (r.failed.isNotEmpty) msg.write(' Falhou: ${r.failed.entries.map((e) => '${e.key} (${e.value})').join('; ')}');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg.toString()), duration: const Duration(seconds: 5)));
  }

  void _addMenu(BuildContext context, AppState s) {
    final hasAcc = s.investAccounts.isNotEmpty;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (ctx) => SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.fromLTRB(24, 20, 24, 8), child: Align(alignment: Alignment.centerLeft, child: Text('Adicionar', style: Theme.of(ctx).textTheme.titleLarge))),
          _item(ctx, Icons.account_balance_outlined, 'Nova plataforma', 'XTB, Trade Republic, exchange…', () => showInvestAccountEditor(context)),
          if (hasAcc) ...[
            _item(ctx, Icons.pie_chart_outline, 'Novo ativo', 'ETF, ação, cripto, fundo…', () => showHoldingEditor(context)),
            _item(ctx, Icons.history, 'Posição que já tinha', 'Quantidade e preço médio antes de usar a app', () => showOpForm(context, type: OpType.initial)),
            _item(ctx, Icons.add_shopping_cart, 'Registar compra', 'Aloca dinheiro a um ativo', () => showOpForm(context, type: OpType.buy)),
            _item(ctx, Icons.sell_outlined, 'Registar venda', null, () => showOpForm(context, type: OpType.sell)),
            _item(ctx, Icons.payments_outlined, 'Dividendo ou juros', null, () => showOpForm(context, type: OpType.dividend)),
            _item(ctx, Icons.account_balance_wallet_outlined, 'Acertar dinheiro por alocar', 'Dinheiro que já estava na plataforma', () => showOpForm(context, type: OpType.cash)),
          ],
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _item(BuildContext ctx, IconData icon, String title, String? sub, VoidCallback onTap) => ListTile(
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
    final tt = Theme.of(context).textTheme;
    final pf = s.portfolio;
    final colors = chartColors(cs);
    final anyAuto = s.holdings.any((h) => h.needsRefresh && !h.archived);
    final times = s.holdings.where((h) => h.lastPriceAt != null && !h.archived).map((h) => h.lastPriceAt!).toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Investimentos'),
        actions: [
          if (anyAuto)
            refreshing
                ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)))
                : IconButton(tooltip: 'Atualizar preços', icon: const Icon(Icons.sync), onPressed: () => _refresh(s)),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _addMenu(context, s), icon: const Icon(Icons.add), label: const Text('Adicionar')),
      body: pf.isEmpty ? _intro(context, s) : ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 100), children: [
        // ----- resumo -----
        SectionCard(
          title: 'A minha carteira',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Valor total', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(fmtMoney(pf.total), style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800))),
            const SizedBox(height: 14),
            Wrap(spacing: 28, runSpacing: 12, children: [
              Stat('Investido', fmtMoney(pf.costBasis)),
              Stat('Valor atual', fmtMoney(pf.investedValue)),
              Stat('Ganho / perda', fmtSignedMoney(pf.pl), color: plColor(context, pf.pl), extra: pf.plPct == null ? null : Text(fmtSignedPercent(pf.plPct!), style: tt.bodySmall?.copyWith(color: plColor(context, pf.pl), fontWeight: FontWeight.w600))),
              Stat('Por alocar', fmtMoney(pf.cash), color: pf.cash < 0 ? Colors.orange.shade700 : null),
              if (pf.realized != 0) Stat('Ganho realizado', fmtSignedMoney(pf.realized), color: plColor(context, pf.realized)),
              if (pf.dividends > 0) Stat('Dividendos', fmtMoney(pf.dividends)),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: Text(
                  times.isEmpty ? (anyAuto ? 'Ainda sem preços. Carrega em atualizar.' : 'Preços definidos à mão em cada ativo.') : 'Preços atualizados ${fmtAgo(times.last)}',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
              if (anyAuto) TextButton.icon(onPressed: refreshing ? null : () => _refresh(s), icon: const Icon(Icons.sync, size: 18), label: const Text('Atualizar preços')),
            ]),
            if (pf.positions.any((p) => !p.priced))
              Padding(padding: const EdgeInsets.only(top: 4), child: Text('Ativos sem preço contam pelo custo, para não distorcer o total.', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))),
          ]),
        ),

        // ----- alocação -----
        if (pf.total > 0) _allocation(context, pf, colors, cs),

        // ----- dinheiro por alocar -----
        if (pf.accounts.any((a) => a.cashCents != 0))
          SectionCard(
            title: 'Dinheiro por alocar',
            subtitle: 'Enviado para as plataformas e ainda não investido (standby)',
            child: Column(children: [
              for (final a in pf.accounts.where((a) => a.cashCents != 0))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Text(a.account.emoji.isEmpty ? '🏦' : a.account.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a.account.name, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(fmtMoney(a.cashCents), style: tt.bodyMedium?.copyWith(color: a.cashCents < 0 ? Colors.orange.shade700 : null, fontWeight: FontWeight.w700)),
                        if (a.cashCents < 0) Text('Negativo: falta uma entrega ou um acerto de dinheiro', style: tt.bodySmall?.copyWith(color: Colors.orange.shade700)),
                      ]),
                    ),
                    if (a.cashCents > 0)
                      FilledButton.tonal(
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                        onPressed: () => showOpForm(context, type: OpType.buy, accountId: a.account.id, prefillCents: a.cashCents),
                        child: const Text('Alocar'),
                      )
                    else
                      OutlinedButton(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)), onPressed: () => showOpForm(context, type: OpType.cash, accountId: a.account.id), child: const Text('Acertar')),
                  ]),
                ),
            ]),
          ),

        // ----- plataformas -----
        Padding(padding: const EdgeInsets.fromLTRB(4, 12, 4, 0), child: Text('Plataformas', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
        for (final a in pf.accounts)
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AccountScreen(accountId: a.account.id))),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Text(a.account.emoji.isEmpty ? '🏦' : a.account.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(a.account.name, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(fmtMoney(a.total), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      if (a.costBasis > 0) PlText(a.pl, pct: a.costBasis > 0 ? a.pl / a.costBasis : null, style: tt.bodySmall),
                    ]),
                    const Icon(Icons.chevron_right),
                  ]),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 34),
                    child: Text('Por alocar ${fmtMoney(a.cashCents)} · ${a.positions.where((p) => p.open).length} ativos', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ),
                  if (a.positions.any((p) => p.open)) const Divider(height: 20),
                  for (final p in a.positions.where((p) => p.open).take(4))
                    PositionRow(p, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HoldingScreen(holdingId: p.holding.id)))),
                  if (a.positions.where((p) => p.open).length > 4)
                    Padding(padding: const EdgeInsets.only(top: 4), child: Text('+ ${a.positions.where((p) => p.open).length - 4} ativos', style: tt.bodySmall)),
                ]),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _allocation(BuildContext context, Portfolio pf, List<Color> colors, ColorScheme cs) {
    final tt = Theme.of(context).textTheme;
    final items = <({String label, int value, int? pl})>[];
    switch (view) {
      case _View.asset:
        for (final p in pf.positions) {
          items.add((label: p.holding.name, value: p.valueCents, pl: p.plCents));
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
          items.add((label: e.key.label, value: e.value, pl: null));
        }
    }
    items.sort((a, b) => b.value.compareTo(a.value));
    final cash = pf.cash > 0 ? pf.cash : 0;
    final total = items.fold(0, (a, e) => a + e.value) + cash;
    final donutItems = [for (var i = 0; i < items.length; i++) DonutItem(items[i].label, items[i].value, colors[i % colors.length]), if (cash > 0) DonutItem('Por alocar', cash, cs.outline)];
    return SectionCard(
      title: 'Onde está o dinheiro',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          height: 44,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            for (final (v, label) in [(_View.asset, 'Por ativo'), (_View.platform, 'Por plataforma'), (_View.kind, 'Por tipo')])
              Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(label), selected: view == v, onSelected: (_) => setState(() => view = v))),
          ]),
        ),
        const SizedBox(height: 8),
        Center(child: Donut(items: donutItems, centerTop: 'Total', centerBottom: fmtMoney(total, short: true))),
        const SizedBox(height: 14),
        for (var i = 0; i < items.length; i++)
          LegendRow(
            color: colors[i % colors.length],
            label: items[i].label,
            value: fmtMoney(items[i].value),
            share: total == 0 ? null : fmtPercent(items[i].value / total),
          ),
        if (cash > 0) LegendRow(color: cs.outline, label: 'Por alocar (standby)', value: fmtMoney(cash), share: total == 0 ? null : fmtPercent(cash / total)),
        if (total > 0 && items.isNotEmpty && items.first.value / total > 0.5 && view == _View.asset)
          Padding(padding: const EdgeInsets.only(top: 8), child: Text('${items.first.label} pesa ${fmtPercent(items.first.value / total)} da carteira.', style: tt.bodySmall)),
      ]),
    );
  }

  Widget _intro(BuildContext context, AppState s) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    Widget step(IconData i, String t, String d) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(radius: 18, backgroundColor: cs.primaryContainer.withValues(alpha: 0.6), child: Icon(i, size: 18, color: cs.primary)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600)), Text(d, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))])),
          ]),
        );
    return ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 100), children: [
      SectionCard(
        title: 'Acompanha o que tens investido',
        subtitle: 'Onde está o teu dinheiro, quanto vale e quanto está por alocar',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          step(Icons.account_balance_outlined, '1. Cria uma plataforma', 'XTB, Trade Republic, uma exchange de cripto…'),
          step(Icons.swap_horiz, '2. Associa as transferências do banco', 'Marcas quais foram dinheiro enviado para a plataforma. Deixam de contar como despesa.'),
          step(Icons.history, '3. Diz o que já tinhas', 'Quantidade e preço médio de compra do que investiste antes de usar a app.'),
          step(Icons.add_shopping_cart, '4. Aloca o dinheiro', 'Regista compras. O que sobra fica por alocar (standby).'),
          step(Icons.sync, '5. Atualiza os preços', 'Com APIs gratuitas (Yahoo Finance e CoinGecko), só quando tu pedires.'),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: () => showInvestAccountEditor(context), icon: const Icon(Icons.add), label: const Text('Criar a primeira plataforma')),
        ]),
      ),
    ]);
  }
}
