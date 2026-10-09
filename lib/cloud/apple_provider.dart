import 'dart:typed_data';

import 'cloud_provider.dart';

/// Lugar reservado para a conta Apple (iCloud).
///
/// Ainda não está ligada: o iCloud não tem uma API para Android. Quando a app existir para iPhone,
/// basta implementar aqui os mesmos métodos (iCloud Drive / CloudKit) e passar a [available] verdadeiro;
/// o ecrã "Conta e cópia na nuvem" e a lógica de cópia e restauro não mudam.
class AppleProvider implements CloudProvider {
  @override
  String get id => 'apple';
  @override
  String get label => 'iCloud (Apple)';
  @override
  String get accountHint => 'conta Apple';
  @override
  bool get available => false;
  @override
  String get unavailableReason => 'Em preparação: o iCloud só está disponível na versão para iPhone.';
  @override
  String? get account => null;

  Never _no() => throw CloudException(unavailableReason);

  @override
  Future<String> signIn() async => _no();
  @override
  Future<void> signOut() async {}
  @override
  Future<String?> restoreSession() async => null;
  @override
  Future<CloudBackupInfo> upload(Uint8List data) async => _no();
  @override
  Future<CloudBackupInfo?> latest() async => null;
  @override
  Future<Uint8List> download(CloudBackupInfo info) async => _no();
  @override
  Future<void> delete(CloudBackupInfo info) async => _no();
}
