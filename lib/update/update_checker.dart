import 'package:package_info_plus/package_info_plus.dart';

import '../db/database.dart';
import 'update_service.dart';

/// Verifica, ao abrir a app, se há uma release nova. Só volta a perguntar ao GitHub
/// uma vez por dia (e não avisa duas vezes pela mesma versão).
class UpdateChecker {
  UpdateChecker({
    required this.db,
    required this.service,
    required this.currentVersion,
    required this.notify,
    this.interval = const Duration(hours: 24),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Db db;
  final UpdateService service;
  final String currentVersion;
  final Future<void> Function(String tag) notify; // recebe a tag, ex.: v1.9.1
  final Duration interval;
  final DateTime Function() _now;

  static const _checkedKey = 'update_checked_at';
  static const _notifiedKey = 'update_notified_tag';

  /// Devolve a tag da versão nova se houver (e se a notificação foi pedida), ou nulo.
  /// Erros de rede são ignorados: tenta de novo na próxima abertura.
  Future<String?> check({bool force = false}) async {
    final last = DateTime.tryParse(db.setting(_checkedKey) ?? '');
    if (!force && last != null && _now().difference(last) < interval)
      return null;
    final String tag;
    try {
      tag = await service.latestTag();
    } on UpdateException {
      return null;
    }
    db.putSetting(_checkedKey, _now().toIso8601String());
    if (!UpdateService.isNewer(tag, currentVersion)) return null;
    if (db.setting(_notifiedKey) == tag) return null; // já avisado desta versão
    db.putSetting(_notifiedKey, tag);
    await notify(tag);
    return tag;
  }

  /// Versão instalada (do pubspec, via o sistema).
  static Future<String> installedVersion() async =>
      (await PackageInfo.fromPlatform()).version;
}
