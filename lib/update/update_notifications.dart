import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notificação do sistema quando há uma versão nova no GitHub.
class UpdateNotifications {
  UpdateNotifications._();
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static const _channel = 'updates';
  static const _id = 7;

  static Future<void> init() async {
    if (_ready) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _ready = true;
  }

  /// Pede a permissão de notificações (Android 13+). Se for recusada, a app continua a funcionar sem avisos.
  static Future<void> show(String tag) async {
    await init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    await _plugin.show(
      id: _id,
      title: 'Atualização disponível',
      body:
          'Finanças ${tag.replaceFirst('v', '')} já está disponível. Abre Mais › Atualizações para instalar.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channel,
          'Atualizações',
          channelDescription: 'Aviso quando sai uma versão nova',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
    );
  }
}
