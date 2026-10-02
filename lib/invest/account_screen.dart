import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../analysis/widgets.dart';
import '../screens/transactions_screen.dart' show confirm;
import '../state/app_state.dart';
import '../util/format.dart';
import '../widgets/common.dart';
import 'forms.dart';
import 'holding_screen.dart';
import 'invest.dart';
import 'widgets.dart';

/// Uma plataforma: dinheiro por alocar, transferências do banco, ativos e histórico.
class AccountScreen extends StatefulWidget {
  final int accountId;
  const AccountScreen({super.key, required this.accountId});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool refreshing = false;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final acc = s.investAccount(widget.accountId);
    if (acc == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Plataforma apagada.')));
    final pf = s.portfolio;
    final sums = pf.accounts.where((a) => a.account.id == acc.id);
    final sum = sums.isEmpty ? AccountSummary(acc, const [], 0, 0) : sums.first;
    final ops = s.investOps.where((o) => o.accountId == acc.id).toList()..sort((a, b) => b.date.compareTo(a.date));
    int by(OpType t) => ops.where((o) => o.type == t).fold(0, (a, o) => a + o.amount);
    final linked = s.transactions.where((t) => t.investAccountId == acc.id).toList();
    final name = acc.name.toLowerCase();
    final suggestions = s.transactions.where((t) => t.investAccountId == null && '${t.description} ${t.merchantKey}'.toLowerCase().contains(name)).length;
    final patterns = s.investPatterns.where((p) => p.accountId == acc.id).toList();
    final holdings = s.holdings.where((h) => h.accountId == acc.id && !h.archived).toList();
    final positions = {for (final p in sum.positions) p.holding.id: p};

    return Scaffold(
      appBar: AppBar(
        title: Text('${acc.emoji} ${acc.name}'.trim()),
        actions: [
          if (holdings.any((h) => h.canAutoPrice))
            refreshing
                ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)))
                : IconButton(
                    tooltip: 'Atualizar preços',
                    icon: const Icon(Icons.sync),
                    onPressed: () async {
                      setState(() => refreshing = true);
                      final r = await s.refreshPrices(accountId: acc.id);
                      if (!mounted) return;
                      setState(() => refreshing = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${r.updated} preços atualizados.${r.failed.isEmpty ? '' : ' Falhou: ${r.failed.keys.join(', ')}'}')));
                    },
                  ),
          IconButton(tooltip: 'Editar', icon: const Icon(Icons.edit_outlined), onPressed: () => showInvestAccountEditor(context, edit: acc)),
          IconButton(
            tooltip: 'Apagar',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              if (await confirm(context, 'Apagar a plataforma “${acc.name}” com os seus ativos e operações? Os movimentos do banco ficam (deixam de estar associados).')) {
                s.deleteInvestAccount(acc.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          useSafeArea: true,
          builder: (ctx) => SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(padding: const EdgeInsets.fromLTRB(24, 20, 24, 8), child: Align(alignment: Alignment.centerLeft, child: Text('Adicionar a ${acc.name}', style: Theme.of(ctx).textTheme.titleLarge))),
              for (final (icon, t, sub, fn) in <(IconData, String, String?, VoidCallback)>[
                (Icons.pie_chart_outline, 'Novo ativo', 'ETF, ação, cripto, fundo…', () => showHoldingEditor(context, accountId: acc.id)),
                (Icons.history, 'Posição que já tinha', 'Quantidade e preço médio antes de usar a app', () => showOpForm(context, type: OpType.initial, accountId: acc.id)),
                (Icons.add_shopping_cart, 'Registar compra', null, () => showOpForm(context, type: OpType.buy, accountId: acc.id)),
                (Icons.sell_outlined, 'Registar venda', null, () => showOpForm(context, type: OpType.sell, accountId: acc.id)),
                (Icons.payments_outlined, 'Dividendo ou juros', null, () => showOpForm(context, type: OpType.dividend, accountId: acc.id)),
                (Icons.account_balance_wallet_outlined, 'Acertar dinheiro por alocar', 'Dinheiro que já estava aqui antes de usar a app', () => showOpForm(context, type: OpType.cash, accountId: acc.id)),
              ])
                ListTile(
                  leading: Icon(icon),
                  title: Text(t),
                  subtitle: sub == null ? null : Text(sub),
                  onTap: () {
                    Navigator.pop(ctx);
                    fn();
                  },
                ),
              const SizedBox(height: 8),
            ]),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 100), children: [
        SectionCard(
          title: 'Resumo',
          child: Wrap(spacing: 28, runSpacing: 12, children: [
            Stat('Valor total', fmtMoney(sum.total)),
            Stat('Investido', fmtMoney(sum.costBasis)),
            Stat('Valor atual', fmtMoney(sum.investedValue)),
            Stat('Ganho / perda', fmtSignedMoney(sum.pl), color: plColor(context, sum.pl), extra: sum.costBasis > 0 ? Text(fmtSignedPercent(sum.pl / sum.costBasis), style: tt.bodySmall?.copyWith(color: plColor(context, sum.pl), fontWeight: FontWeight.w600)) : null),
          ]),
        ),

        // ----- dinheiro por alocar -----
        SectionCard(
          title: 'Dinheiro por alocar',
          subtitle: 'O que está na plataforma e ainda não foi investido',
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(fmtMoney(sum.cashCents), style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: sum.cashCents < 0 ? Colors.orange.shade700 : null)),
            const SizedBox(height: 10),
            _line('Entregas do banco (líquidas)', sum.depositedCents),
            if (by(OpType.cash) != 0) _line('Acertos de dinheiro', by(OpType.cash)),
            if (by(OpType.sell) != 0) _line('Vendas', by(OpType.sell)),
            if (by(OpType.dividend) != 0) _line('Dividendos', by(OpType.dividend)),
            if (by(OpType.buy) != 0) _line('Compras', -by(OpType.buy)),
            if (sum.cashCents < 0)
              Padding(padding: const EdgeInsets.only(top: 8), child: Text('O valor está negativo: gastaste mais do que o dinheiro registado. Associa a transferência do banco ou acerta o dinheiro que já lá estava.', style: tt.bodySmall?.copyWith(color: Colors.orange.shade700))),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (sum.cashCents > 0) FilledButton.icon(style: FilledButton.styleFrom(minimumSize: const Size(0, 44)), onPressed: () => showOpForm(context, type: OpType.buy, accountId: acc.id, prefillCents: sum.cashCents), icon: const Icon(Icons.add_shopping_cart, size: 18), label: const Text('Alocar dinheiro')),
              OutlinedButton.icon(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)), onPressed: () => showOpForm(context, type: OpType.cash, accountId: acc.id), icon: const Icon(Icons.tune, size: 18), label: const Text('Acertar')),
            ]),
          ]),
        ),

        // ----- transferências do banco -----
        SectionCard(
          title: 'Transferências do banco',
          subtitle: linked.isEmpty ? 'Marca quais foram dinheiro enviado para ${acc.name}' : '${linked.length} associadas · não contam como despesa',
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (suggestions > 0)
              Callout(
                icon: Icons.lightbulb_outline,
                color: cs.primary,
                title: '$suggestions ${suggestions == 1 ? 'movimento parece' : 'movimentos parecem'} ser desta plataforma',
                body: 'Têm “${acc.name}” no nome. Toca para rever e associar.',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LinkTransfersScreen(accountId: acc.id))),
              ),
            for (final t in linked.take(8))
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(s.displayName(t), maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${fmtDate(t.date)} · ${t.amount < 0 ? 'entrega' : 'levantamento'}'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  MoneyText(t.amount, colored: false),
                  IconButton(tooltip: 'Desassociar', icon: const Icon(Icons.link_off, size: 20), onPressed: () => s.unlinkTransfers([t.id])),
                ]),
              ),
            if (linked.length > 8) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('… e mais ${linked.length - 8}', style: tt.bodySmall)),
            if (patterns.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Títulos lembrados para as próximas importações', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 4, children: [for (final p in patterns) InputChip(label: Text(p.pattern), onDeleted: () => s.deleteInvestPattern(p.id))]),
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LinkTransfersScreen(accountId: acc.id))),
              icon: const Icon(Icons.add_link, size: 20),
              label: const Text('Associar transferências do banco'),
            ),
          ]),
        ),

        // ----- ativos -----
        SectionCard(
          title: 'Ativos',
          trailing: TextButton.icon(onPressed: () => showHoldingEditor(context, accountId: acc.id), icon: const Icon(Icons.add, size: 18), label: const Text('Novo')),
          child: holdings.isEmpty
              ? const Text('Ainda sem ativos. Cria um (ex.: o ETF ou a ação que compraste) e regista a posição que já tinhas ou uma compra.')
              : Column(children: [
                  for (final h in holdings)
                    PositionRow(
                      positions[h.id] ?? Position(h, 0, 0, 0, 0),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HoldingScreen(holdingId: h.id))),
                    ),
                ]),
        ),

        // ----- histórico -----
        if (ops.isNotEmpty)
          SectionCard(
            title: 'Histórico',
            subtitle: 'Toca para editar',
            child: Column(children: [
              for (final o in ops.take(30)) OpTile(o, holdingName: s.holding(o.holdingId)?.name, currencyCode: s.holding(o.holdingId)?.currency, onTap: () => showOpForm(context, type: o.type, edit: o)),
              if (ops.length > 30) Padding(padding: const EdgeInsets.all(8), child: Text('… e mais ${ops.length - 30}', style: tt.bodySmall)),
            ]),
          ),
      ]),
    );
  }

  Widget _line(String label, int cents) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Expanded(child: Text(label)),
          Text(fmtSignedMoney(cents), style: TextStyle(fontWeight: FontWeight.w600, color: plColor(context, cents))),
        ]),
      );
}
