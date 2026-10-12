import 'dart:convert';

import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:http/http.dart' as http;

import '../db/database.dart';
import 'cloud_provider.dart';

/// Login Microsoft (contas pessoais e de trabalho) com OAuth + PKCE, sem palavra-passe na app.
/// O ID da aplicação (cliente) é o que registaste no Azure; não é segredo.
class MicrosoftAuth {
  MicrosoftAuth({
    required this.db,
    required this.clientId,
    http.Client? client,
    FlutterAppAuth? appAuth,
  }) : _client = client ?? http.Client(),
       _appAuth = appAuth ?? FlutterAppAuth();

  final Db db;
  final String Function() clientId;
  final http.Client _client;
  final FlutterAppAuth _appAuth;

  /// Tem de coincidir com o URI de redirecionamento registado no Azure e com o `appAuthRedirectScheme` do Android.
  static const redirect = 'pt.financas.financas:/oauth';
  static const scopes = [
    'Files.ReadWrite.AppFolder',
    'offline_access',
    'User.Read',
  ];
  static const _config = AuthorizationServiceConfiguration(
    authorizationEndpoint:
        'https://login.microsoftonline.com/common/oauth2/v2.0/authorize',
    tokenEndpoint: 'https://login.microsoftonline.com/common/oauth2/v2.0/token',
  );

  String? _access;
  DateTime? _expiry;

  String? get account => db.setting('onedrive_account');

  Future<String> signIn() async {
    final id = clientId().trim();
    if (id.isEmpty)
      throw const CloudException(
        'Falta o ID da aplicação. Configura-o em baixo, na página do OneDrive.',
      );
    try {
      final r = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          id,
          redirect,
          serviceConfiguration: _config,
          scopes: scopes,
          promptValues: const ['select_account'],
        ),
      );
      if (r.refreshToken == null)
        throw const CloudException(
          'A Microsoft não devolveu uma sessão renovável. Tenta outra vez.',
        );
      db.putSetting('onedrive_refresh', r.refreshToken!);
      _access = r.accessToken;
      _expiry = r.accessTokenExpirationDateTime;
    } on CloudException {
      rethrow;
    } catch (e) {
      final s = '$e'.toLowerCase();
      throw CloudException(
        s.contains('cancel') ? 'Ligação cancelada.' : 'Não consegui ligar a conta Microsoft. Confirma o ID da aplicação e o URI de redirecionamento.',
      );
    }
    final name = await _accountName();
    db.putSetting('onedrive_account', name);
    return name;
  }

  Future<String> _accountName() async {
    try {
      final r = await _client.get(
        Uri.parse(
          'https://graph.microsoft.com/v1.0/me?\$select=userPrincipalName,mail',
        ),
        headers: {'Authorization': 'Bearer ${await accessToken()}'},
      );
      if (r.statusCode == 200) {
        final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map;
        return '${j['mail'] ?? j['userPrincipalName'] ?? 'Conta Microsoft'}';
      }
    } catch (_) {}
    return 'Conta Microsoft';
  }

  /// Token válido para pedidos ao Graph; renova-o com o refresh token guardado.
  Future<String> accessToken() async {
    final now = DateTime.now();
    if (_access != null &&
        _expiry != null &&
        _expiry!.isAfter(now.add(const Duration(minutes: 2))))
      return _access!;
    final refresh = db.setting('onedrive_refresh');
    final id = clientId().trim();
    if (refresh == null || id.isEmpty)
      throw const CloudException('Liga primeiro a conta Microsoft.');
    try {
      final t = await _appAuth.token(
        TokenRequest(
          id,
          redirect,
          refreshToken: refresh,
          serviceConfiguration: _config,
          scopes: scopes,
        ),
      );
      _access = t.accessToken;
      _expiry = t.accessTokenExpirationDateTime;
      if (t.refreshToken != null)
        db.putSetting('onedrive_refresh', t.refreshToken!);
      return _access!;
    } catch (_) {
      throw const CloudException(
        'A sessão da Microsoft expirou. Volta a ligar a conta.',
      );
    }
  }

  Future<void> signOut() async {
    _access = null;
    _expiry = null;
    db.deleteSetting('onedrive_refresh');
    db.deleteSetting('onedrive_account');
  }
}
