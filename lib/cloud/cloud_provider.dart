import 'dart:typed_data';

/// Uma cópia guardada na nuvem.
class CloudBackupInfo {
  final String id;
  final String name;
  final DateTime modified;
  final int size;
  const CloudBackupInfo({required this.id, required this.name, required this.modified, required this.size});
}

class CloudException implements Exception {
  final String message;
  const CloudException(this.message);
  @override
  String toString() => message;
}

/// Uma conta na nuvem onde se guardam cópias dos dados (Google Drive, iCloud…).
/// Cada serviço implementa isto; o resto da app não sabe qual é.
abstract class CloudProvider {
  String get id; // 'google', 'apple'…
  String get label; // "Google Drive"
  String get accountHint; // ex.: "conta Google"

  /// Falso quando o serviço ainda não está disponível neste telemóvel.
  bool get available;
  String get unavailableReason => '';

  /// Conta ligada (email), se houver.
  String? get account;

  /// Liga a conta (abre o ecrã de escolha da conta). Devolve o email.
  Future<String> signIn();
  Future<void> signOut();

  /// Tenta repor a sessão anterior sem perguntar nada. Devolve o email, se conseguir.
  Future<String?> restoreSession();

  /// Guarda uma cópia (substitui a anterior).
  Future<CloudBackupInfo> upload(Uint8List data);

  /// A cópia mais recente, se existir.
  Future<CloudBackupInfo?> latest();

  Future<Uint8List> download(CloudBackupInfo info);

  /// Apaga a cópia da nuvem.
  Future<void> delete(CloudBackupInfo info);
}
