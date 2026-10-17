import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../state/app_state.dart';
import '../update/update_notifications.dart';
import '../util/format.dart';

/// Envia uma notificação do sistema. Nos testes substitui-se pela versão que não chama a plataforma.
typedef ShowNotification = Future<void> Function(
  int id,
  String title,
  String body,
);

/// Definição com os ids das entregas já notificadas (separados por vírgulas).
const investAlertsNotifiedKey = 'invest_alerts_notified';

const _recurringId = 301;
const _allocationBaseId = 400; // um id por plataforma: 400 + id da conta
const _channelId = 'alerts';
const _channelName = 'Alertas';

// ---------- Textos (funções puras) ----------

const recurringTitle = 'Movimentos recorrentes';

String recurringBody(int n) => n == 1
    ? '1 movimento recorrente registado'
    : '$n movimentos recorrentes registados';

/// Entregas novas de uma plataforma, somadas por ativo.
class AllocationAlert {
  final int accountId;
  final String accountName;
  final List<int> txnIds; // movimentos cobertos por este aviso
  final List<({String name, int cents})>
  parts; // soma por ativo, pela ordem do plano
  final int undistributed; // cêntimos que o plano não cobre

  const AllocationAlert({
    required this.accountId,
    required this.accountName,
    required this.txnIds,
    required this.parts,
    required this.undistributed,
  });

  int get count => txnIds.length;
}

/// Agrupa as entregas ainda não notificadas por plataforma. [nameOf] dá o nome de cada ativo.
List<AllocationAlert> allocationAlerts(
  List<PendingAllocation> pending,
  Set<int> notified, {
  required String Function(int holdingId) nameOf,
}) {
  final porConta = <int, List<PendingAllocation>>{};
  for (final p in pending) {
    if (notified.contains(p.txn.id)) continue;
    porConta.putIfAbsent(p.account.id, () => []).add(p);
  }
  final out = <AllocationAlert>[];
  for (final e in porConta.entries) {
    final porAtivo = <int, int>{}; // mantém a ordem de inserção
    var naoDistribuido = 0;
    for (final p in e.value) {
      for (final part in p.parts) {
        porAtivo[part.holdingId] = (porAtivo[part.holdingId] ?? 0) + part.cents;
      }
      naoDistribuido += p.undistributed;
    }
    out.add(
      AllocationAlert(
        accountId: e.key,
        accountName: e.value.first.account.name,
        txnIds: [for (final p in e.value) p.txn.id],
        parts: [
          for (final en in porAtivo.entries)
            if (en.value > 0) (name: nameOf(en.key), cents: en.value),
        ],
        undistributed: naoDistribuido,
      ),
    );
  }
  return out;
}

const allocationTitle = 'Entrega de investimento';

/// Ex.: "XTB: VWCE 700,00 €, Apple 300,00 €". Com várias entregas indica quantas.
String allocationBody(AllocationAlert a) {
  final quantas = a.count > 1 ? ' (${a.count} entregas)' : '';
  final detalhe = [
    for (final p in a.parts) '${p.name} ${fmtMoney(p.cents)}',
    if (a.undistributed > 0) '${fmtMoney(a.undistributed)} por distribuir',
  ].join(', ');
  return '${a.accountName}$quantas: $detalhe';
}

// ---------- Ids notificados ----------

Set<int> parseNotifiedIds(String? raw) {
  final out = <int>{};
  for (final s in (raw ?? '').split(',')) {
    final v = int.tryParse(s.trim());
    if (v != null) out.add(v);
  }
  return out;
}

String encodeNotifiedIds(Set<int> ids) => (ids.toList()..sort()).join(',');

// ---------- Envio ----------

/// Notificação real, pelo mesmo plugin (e a mesma inicialização) das atualizações.
Future<void> _sendSystem(int id, String title, String body) async {
  await UpdateNotifications.init();
  final plugin = FlutterLocalNotificationsPlugin();
  final android = plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  await android?.requestNotificationsPermission();
  await plugin.show(
    id: id,
    title: title,
    body: body,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Movimentos recorrentes e entregas de investimento',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    ),
  );
}

/// Avisos do arranque: movimentos recorrentes criados e entregas de investimento novas.
/// Cada aviso é independente: uma falha não impede os outros nem o arranque.
Future<void> notifyStartup(
  AppState s, {
  required int recurringCreated,
  ShowNotification? show,
}) async {
  final send = show ?? _sendSystem;
  if (recurringCreated > 0) {
    try {
      await send(_recurringId, recurringTitle, recurringBody(recurringCreated));
    } catch (_) {}
  }

  final raw = s.db.setting(investAlertsNotifiedKey);
  final notified = parseNotifiedIds(raw);
  if (raw == null) {
    // primeira execução (depois da atualização): as entregas que já existem ficam como vistas,
    // sem aviso. Só as entregas novas a partir daqui geram notificação.
    notified.addAll(s.pendingAllocations.map((p) => p.txn.id));
    s.db.putSetting(investAlertsNotifiedKey, encodeNotifiedIds(notified));
    return;
  }
  final alerts = allocationAlerts(
    s.pendingAllocations,
    notified,
    nameOf: (id) => s.holding(id)?.name ?? 'Ativo',
  );
  for (final a in alerts) {
    try {
      await send(
        _allocationBaseId + a.accountId,
        allocationTitle,
        allocationBody(a),
      );
      // só fica marcada como notificada depois de o aviso sair
      notified.addAll(a.txnIds);
      s.db.putSetting(investAlertsNotifiedKey, encodeNotifiedIds(notified));
    } catch (_) {}
  }
}
