import 'dart:typed_data';

import 'package:google_sign_in/google_sign_in.dart';

import 'cloud_provider.dart';
import 'drive_appdata.dart';

/// Cópias na conta Google (Google Drive, pasta privada da app).
///
/// Precisa de um projeto na Google Cloud com a API do Drive ligada e um cliente OAuth
/// (ver o ecrã "Conta e cópia na nuvem"). O ID de cliente Web é guardado na app, não no código.
class GoogleProvider implements CloudProvider {
  GoogleProvider({required this.serverClientId});

  /// ID de cliente OAuth do tipo "Web" do projeto Google Cloud do utilizador.
  final String Function() serverClientId;

  GoogleSignInAccount? _user;
  bool _inited = false;
  String? _initedWith;

  @override
  String get id => 'google';
  @override
  String get label => 'Google Drive';
  @override
  String get accountHint => 'conta Google';
  @override
  bool get available => true;
  @override
  String get unavailableReason => '';
  @override
  String? get account => _user?.email;

  Future<void> _init() async {
    final cid = serverClientId().trim();
    if (cid.isEmpty) throw const CloudException('Falta o ID de cliente da Google. Indica-o na configuração (passos abaixo).');
    if (_inited && _initedWith == cid) return;
    try {
      await GoogleSignIn.instance.initialize(serverClientId: cid);
    } catch (_) {
      // já inicializado nesta sessão
    }
    _inited = true;
    _initedWith = cid;
  }

  @override
  Future<String> signIn() async {
    await _init();
    try {
      final u = await GoogleSignIn.instance.authenticate(scopeHint: const [DriveAppData.scope]);
      _user = u;
      await _token(); // pede já a permissão de guardar dados da app
      return u.email;
    } on GoogleSignInException catch (e) {
      throw CloudException(_msg(e));
    }
  }

  @override
  Future<String?> restoreSession() async {
    try {
      await _init();
      final f = GoogleSignIn.instance.attemptLightweightAuthentication();
      final u = f == null ? null : await f;
      _user = u;
      return u?.email;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    _user = null;
  }

  String _msg(GoogleSignInException e) => switch (e.code) {
        GoogleSignInExceptionCode.canceled => 'Ligação cancelada.',
        GoogleSignInExceptionCode.interrupted => 'Ligação interrompida. Tenta outra vez.',
        GoogleSignInExceptionCode.uiUnavailable => 'Não foi possível abrir o ecrã da Google.',
        _ => 'A Google recusou a ligação (${e.code.name}). Confirma a configuração do projeto: nome do pacote, SHA-1 e ID de cliente Web.',
      };

  Future<String> _token() async {
    final u = _user;
    if (u == null) throw const CloudException('Liga primeiro a conta Google.');
    try {
      final c = u.authorizationClient;
      final a = await c.authorizationForScopes(const [DriveAppData.scope]) ?? await c.authorizeScopes(const [DriveAppData.scope]);
      return a.accessToken;
    } on GoogleSignInException catch (e) {
      throw CloudException(_msg(e));
    }
  }

  late final DriveAppData _drive = DriveAppData(token: _token);

  @override
  Future<CloudBackupInfo> upload(Uint8List data) => _drive.upload(data);
  @override
  Future<CloudBackupInfo?> latest() => _drive.latest();
  @override
  Future<Uint8List> download(CloudBackupInfo info) => _drive.download(info);
  @override
  Future<void> delete(CloudBackupInfo info) => _drive.delete(info);
}
