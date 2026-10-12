import 'dart:typed_data';

/// Uma cópia guardada na nuvem.
class CloudBackupInfo {
  final String id;
  final String name;
  final DateTime modified;
  final int size;
  const CloudBackupInfo({
    required this.id,
    required this.name,
    required this.modified,
    required this.size,
  });
}

class CloudException implements Exception {
  final String message;
  const CloudException(this.message);
  @override
  String toString() => message;
}

/// Onde se guardam cópias dos dados (hoje, o OneDrive).
abstract class CloudProvider {
  String get label; // "OneDrive"

  /// Conta ligada (email ou nome), se houver.
  String? get account;

  /// Liga a conta. Devolve o nome da conta.
  Future<String> signIn();
  Future<void> signOut();

  /// Guarda uma cópia (substitui a anterior).
  Future<CloudBackupInfo> upload(Uint8List data);

  /// A cópia mais recente, se existir.
  Future<CloudBackupInfo?> latest();

  Future<Uint8List> download(CloudBackupInfo info);

  Future<void> delete(CloudBackupInfo info);
}
