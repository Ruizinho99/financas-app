import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../l10n/app_localizations.dart';

/// Traduções para as notificações (sem BuildContext). [appLanguage] é 'pt', 'en' ou 'system'
/// (o idioma do telemóvel; se não for inglês, usa português).
Future<AppLocalizations> notificationL10n(String appLanguage) {
  final code = appLanguage == 'system'
      ? PlatformDispatcher.instance.locale.languageCode
      : appLanguage;
  return AppLocalizations.delegate.load(Locale(code == 'en' ? 'en' : 'pt'));
}

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
  static Future<void> show(String tag, {String appLanguage = 'system'}) async {
    await init();
    final l = await notificationL10n(appLanguage);
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    await _plugin.show(
      id: _id,
      title: l.morUpdateAvailableTitle,
      body: l.morUpdateAvailableBody(tag.replaceFirst('v', '')),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel,
          l.morUpdateChannelName,
          channelDescription: l.morUpdateChannelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
    );
  }
}
