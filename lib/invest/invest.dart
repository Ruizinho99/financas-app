import '../models.dart';
import '../util/format.dart' show baseCcy;

/// Plataforma / corretora onde tens dinheiro investido (XTB, Trade Republic, uma exchange…).
class InvestAccount {
  final int id;
  final String name;
  final String emoji;
  final String note;
  final bool archived;
  const InvestAccount({required this.id, required this.name, this.emoji = '', this.note = '', this.archived = false});

  InvestAccount copyWith({String? name, String? emoji, String? note, bool? archived}) =>
      InvestAccount(id: id, name: name ?? this.name, emoji: emoji ?? this.emoji, note: note ?? this.note, archived: archived ?? this.archived);
}

/// Moedas disponíveis (para o ativo e para a moeda de base da app).
const kCurrencies = ['EUR', 'USD', 'GBP', 'CHF', 'CAD', 'AUD', 'JPY', 'SEK', 'NOK', 'DKK', 'PLN', 'BRL'];

enum HoldingKind { etf, stock, crypto, fund, bond, other }

extension HoldingKindX on HoldingKind {
  String get label => switch (this) {
        HoldingKind.etf => 'ETF',
        HoldingKind.stock => 'Ação',
        HoldingKind.crypto => 'Cripto',
        HoldingKind.fund => 'Fundo',
        HoldingKind.bond => 'Obrigação',
        HoldingKind.other => 'Outro',
      };
  String get emoji => switch (this) {
        HoldingKind.etf => '📊',
        HoldingKind.stock => '🏢',
        HoldingKind.crypto => '🪙',
        HoldingKind.fund => '🗂️',
        HoldingKind.bond => '📜',
        HoldingKind.other => '💼',
      };
}

/// Fonte do preço: Yahoo Finance e CoinGecko (gratuitas, sem chave) ou manual.
enum PriceProvider { manual, yahoo, coingecko }

extension PriceProviderX on PriceProvider {
  String get label => switch (this) {
        PriceProvider.manual => 'Manual',
        PriceProvider.yahoo => 'Yahoo Finance',
        PriceProvider.coingecko => 'CoinGecko',
      };
}

/// Um ativo (ETF, ação, cripto…) numa plataforma. Os valores da carteira são convertidos para a moeda de base.
class Holding {
  final int id;
  final int accountId;
  final String name;
  final String symbol; // ex.: VWCE.DE (Yahoo) ou bitcoin (CoinGecko)
  final PriceProvider provider;
  final HoldingKind kind;
  final double? lastPrice; // na moeda de base (já convertido)
  final DateTime? lastPriceAt;
  final bool archived;
  final String currency; // moeda em que o ativo cota: EUR, USD, GBP…
  final bool currencyManual; // true: escolhida pelo utilizador; false: detetada pelo preço
  final double? lastPriceOrig; // último preço na moeda do ativo
  final double? lastFx; // moeda de base por 1 unidade da moeda do ativo, no momento do último preço
  Holding({
    required this.id,
    required this.accountId,
    required this.name,
    this.symbol = '',
    this.provider = PriceProvider.manual,
    this.kind = HoldingKind.etf,
    this.lastPrice,
    this.lastPriceAt,
    this.archived = false,
    String? currency,
    this.currencyManual = false,
    this.lastPriceOrig,
    this.lastFx,
  }) : currency = currency ?? baseCcy;

  bool get foreign => currency != baseCcy;

  /// Último preço na moeda do ativo (em euros, se o ativo for em euros).
  double? get priceOrig => foreign ? lastPriceOrig : lastPrice;

  bool get canAutoPrice => provider != PriceProvider.manual && symbol.trim().isNotEmpty;

  /// Tem algo a atualizar pela internet: o preço, ou só o câmbio (ativo com preço manual noutra moeda).
  bool get needsRefresh => canAutoPrice || (foreign && lastPriceOrig != null);

  Holding copyWith({String? name, String? symbol, PriceProvider? provider, HoldingKind? kind, int? accountId, Object? lastPrice = _k, Object? lastPriceAt = _k, bool? archived, String? currency, bool? currencyManual, Object? lastPriceOrig = _k, Object? lastFx = _k}) => Holding(
        id: id,
        accountId: accountId ?? this.accountId,
        name: name ?? this.name,
        symbol: symbol ?? this.symbol,
        provider: provider ?? this.provider,
        kind: kind ?? this.kind,
        lastPrice: identical(lastPrice, _k) ? this.lastPrice : lastPrice as double?,
        lastPriceAt: identical(lastPriceAt, _k) ? this.lastPriceAt : lastPriceAt as DateTime?,
        archived: archived ?? this.archived,
        currency: currency ?? this.currency,
        currencyManual: currencyManual ?? this.currencyManual,
        lastPriceOrig: identical(lastPriceOrig, _k) ? this.lastPriceOrig : lastPriceOrig as double?,
        lastFx: identical(lastFx, _k) ? this.lastFx : lastFx as double?,
      );
}

const Object _k = Object();

/// Tipos de operação:
///  - initial: posição que já tinhas antes de usar a app (quantidade e preço médio); não mexe no dinheiro;
///  - buy / sell: compra e venda (o dinheiro por alocar desce/sobe);
///  - dividend: dividendo ou juros recebidos;
///  - cash: acerto manual do dinheiro por alocar (positivo = entrada, negativo = saída).
enum OpType { initial, buy, sell, dividend, cash }

extension OpTypeX on OpType {
  String get label => switch (this) {
        OpType.initial => 'Posição inicial',
        OpType.buy => 'Compra',
        OpType.sell => 'Venda',
        OpType.dividend => 'Dividendo',
        OpType.cash => 'Acerto de dinheiro',
      };
}

class InvestOp {
  final int id;
  final int accountId;
  final int? holdingId;
  final DateTime date;
  final OpType type;
  final double quantity;
  final double price; // por unidade, na moeda do ativo (se [fx] for nulo, em euros)
  final double? fx; // moeda de base por 1 unidade da moeda do ativo, no dia da operação (nulo = preço na moeda de base)
  final int amount; // cêntimos: pago (compra, com comissão), recebido (venda/dividendo), custo da posição (initial) ou ± (cash)
  final int fee; // cêntimos (já incluída em amount nas compras)
  final String note;
  const InvestOp({
    required this.id,
    required this.accountId,
    this.holdingId,
    required this.date,
    required this.type,
    this.quantity = 0,
    this.price = 0,
    this.fx,
    this.amount = 0,
    this.fee = 0,
    this.note = '',
  });
}

/// Posição aberta num ativo, pelo método do preço médio ponderado.
class Position {
  final Holding holding;
  final double qty;
  final int costCents; // custo (EUR) da quantidade que ainda tens
  final int realizedCents; // ganho/perda já realizado nas vendas
  final int dividendsCents;
  final double costOrig; // custo na moeda do ativo (igual a costCents/100 nos ativos em euros)
  const Position(this.holding, this.qty, this.costCents, this.realizedCents, this.dividendsCents, [double? costOrig]) : costOrig = costOrig ?? costCents / 100;

  bool get open => qty > 1e-9;
  double get avgCost => open ? costCents / 100 / qty : 0; // EUR
  double get avgCostOrig => open ? costOrig / qty : 0; // moeda do ativo
  double? get price => holding.lastPrice; // EUR
  double? get priceOrig => holding.priceOrig; // moeda do ativo

  /// Ganho/perda só no preço, na moeda do ativo (sem o efeito do câmbio).
  double? get plOrig => open && holding.foreign && priceOrig != null ? qty * priceOrig! - costOrig : null;
  double? get plOrigPct => plOrig != null && costOrig > 0 ? plOrig! / costOrig : null;
  bool get priced => price != null;

  /// Valor atual; sem preço, usa o custo (para não distorcer o total).
  int get valueCents => !open ? 0 : (price == null ? costCents : (qty * price! * 100).round());
  int get plCents => valueCents - costCents;
  double? get plPct => costCents > 0 && priced ? plCents / costCents : null;
}

/// Resumo de uma plataforma.
class AccountSummary {
  final InvestAccount account;
  final List<Position> positions;
  final int cashCents; // dinheiro por alocar (standby)
  final int depositedCents; // entregas líquidas vindas do banco (transferências associadas)
  const AccountSummary(this.account, this.positions, this.cashCents, this.depositedCents);

  int get investedValue => positions.fold(0, (a, p) => a + p.valueCents);
  int get costBasis => positions.fold(0, (a, p) => a + p.costCents);
  int get total => investedValue + cashCents;
  int get pl => investedValue - costBasis;
  int get realized => positions.fold(0, (a, p) => a + p.realizedCents);
  int get dividends => positions.fold(0, (a, p) => a + p.dividendsCents);
}

class Portfolio {
  final List<AccountSummary> accounts;
  const Portfolio(this.accounts);

  int get investedValue => accounts.fold(0, (a, e) => a + e.investedValue);
  int get costBasis => accounts.fold(0, (a, e) => a + e.costBasis);
  int get cash => accounts.fold(0, (a, e) => a + e.cashCents);
  int get total => investedValue + cash;
  int get pl => investedValue - costBasis;
  double? get plPct => costBasis > 0 ? pl / costBasis : null;
  int get realized => accounts.fold(0, (a, e) => a + e.realized);
  int get dividends => accounts.fold(0, (a, e) => a + e.dividends);
  int get deposited => accounts.fold(0, (a, e) => a + e.depositedCents);
  List<Position> get positions => [for (final a in accounts) ...a.positions.where((p) => p.open)];
  bool get isEmpty => accounts.isEmpty;

  /// Calcula tudo a partir dos dados guardados.
  /// [txns]: só os movimentos do banco associados a plataformas (entregas e levantamentos).
  static Portfolio compute({
    required List<InvestAccount> accounts,
    required List<Holding> holdings,
    required List<InvestOp> ops,
    required List<Txn> txns,
  }) {
    final out = <AccountSummary>[];
    for (final acc in accounts) {
      final hs = holdings.where((h) => h.accountId == acc.id).toList();
      final aops = ops.where((o) => o.accountId == acc.id).toList()
        ..sort((a, b) {
          final c = a.date.compareTo(b.date);
          return c != 0 ? c : a.id.compareTo(b.id);
        });
      // dinheiro que entrou/saiu da plataforma pelo banco (saída do banco = entrada na plataforma)
      final deposited = txns.where((t) => t.investAccountId == acc.id).fold(0, (a, t) => a - t.amount);
      var cash = deposited;
      final positions = <Position>[];
      for (final h in hs) {
        var qty = 0.0, cost = 0, realized = 0, divs = 0;
        var costOrig = 0.0;
        // custo de uma compra na moeda do ativo (operações antigas, sem câmbio, usam o câmbio atual)
        double origOf(InvestOp o) {
          if (!h.foreign) return o.amount / 100;
          if (o.fx != null && o.fx! > 0) return o.quantity * o.price + o.fee / 100 / o.fx!;
          return o.amount / 100 / ((h.lastFx ?? 0) > 0 ? h.lastFx! : 1);
        }

        for (final o in aops.where((o) => o.holdingId == h.id)) {
          switch (o.type) {
            case OpType.initial:
            case OpType.buy:
              qty += o.quantity;
              cost += o.amount;
              costOrig += origOf(o);
            case OpType.sell:
              final sold = o.quantity > qty ? qty : o.quantity;
              final avg = qty > 1e-9 ? cost / qty : 0.0;
              final removed = (avg * sold).round();
              realized += o.amount - removed;
              costOrig -= qty > 1e-9 ? costOrig * sold / qty : 0;
              cost -= removed;
              qty -= sold;
              if (qty < 1e-9) {
                qty = 0;
                cost = 0;
                costOrig = 0;
              }
            case OpType.dividend:
              divs += o.amount;
            case OpType.cash:
              break;
          }
        }
        positions.add(Position(h, qty, cost, realized, divs, costOrig));
      }
      for (final o in aops) {
        switch (o.type) {
          case OpType.buy:
            cash -= o.amount;
          case OpType.sell:
          case OpType.dividend:
          case OpType.cash:
            cash += o.amount;
          case OpType.initial:
            break;
        }
      }
      positions.sort((a, b) => b.valueCents.compareTo(a.valueCents));
      out.add(AccountSummary(acc, positions, cash, deposited));
    }
    out.sort((a, b) => b.total.compareTo(a.total));
    return Portfolio(out);
  }
}
