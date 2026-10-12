import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'cloud_provider.dart';
import 'microsoft_auth.dart';

/// Cópias no OneDrive, na pasta privada da app (approot): só esta app as vê.
/// Ficheiros pequenos vão de uma vez; os grandes por sessão de carregamento em partes.
class OneDriveProvider implements CloudProvider {
  OneDriveProvider({
    required this.auth,
    http.Client? client,
    this.simpleLimit = 4 * 1024 * 1024,
    this.chunkSize = 3276800,
  }) : _client = client ?? http.Client();

  final MicrosoftAuth auth;
  final http.Client _client;
  final int simpleLimit; // até aqui, upload de uma vez
  final int chunkSize; // múltiplo de 320 KiB, exigido pelo Graph

  static const fileName = 'financas-backup.db';
  static const _item =
      'https://graph.microsoft.com/v1.0/me/drive/special/approot:/$fileName';

  @override
  String get label => 'OneDrive';
  @override
  String? get account => auth.account;
  @override
  Future<String> signIn() => auth.signIn();
  @override
  Future<void> signOut() => auth.signOut();

  Future<Map<String, String>> _headers([
    Map<String, String> extra = const {},
  ]) async => {'Authorization': 'Bearer ${await auth.accessToken()}', ...extra};

  Never _fail(http.Response r) {
    if (r.statusCode == 401 || r.statusCode == 403)
      throw const CloudException(
        'O OneDrive recusou o acesso. Volta a ligar a conta Microsoft.',
      );
    if (r.statusCode == 404)
      throw const CloudException('Cópia não encontrada no OneDrive.');
    if (r.statusCode == 429 || r.statusCode == 503)
      throw const CloudException(
        'O OneDrive está ocupado. Tenta daqui a pouco.',
      );
    throw CloudException('Erro do OneDrive (${r.statusCode}).');
  }

  void _ok(http.Response r) {
    if (r.statusCode < 200 || r.statusCode > 299) _fail(r);
  }

  Future<http.Response> _send(Future<http.Response> Function() f) async {
    try {
      return await f().timeout(const Duration(seconds: 60));
    } on TimeoutException {
      throw const CloudException('O OneDrive demorou demasiado a responder.');
    } on CloudException {
      rethrow;
    } catch (_) {
      throw const CloudException('Sem ligação à internet.');
    }
  }

  CloudBackupInfo _info(Object? json) {
    final j = json as Map;
    return CloudBackupInfo(
      id: '${j['id']}',
      name: '${j['name'] ?? fileName}',
      modified:
          DateTime.tryParse('${j['lastModifiedDateTime'] ?? ''}')?.toLocal() ??
          DateTime.now(),
      size: (j['size'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<CloudBackupInfo?> latest() async {
    final r = await _send(
      () async => _client.get(Uri.parse(_item), headers: await _headers()),
    );
    if (r.statusCode == 404) return null;
    _ok(r);
    return _info(jsonDecode(utf8.decode(r.bodyBytes)));
  }

  @override
  Future<CloudBackupInfo> upload(Uint8List data) async {
    if (data.length <= simpleLimit) {
      final r = await _send(
        () async => _client.put(
          Uri.parse('$_item:/content'),
          headers: await _headers({'Content-Type': 'application/octet-stream'}),
          body: data,
        ),
      );
      _ok(r);
      return _info(jsonDecode(utf8.decode(r.bodyBytes)));
    }
    // ficheiro grande: sessão de carregamento e partes com Content-Range
    final s = await _send(
      () async => _client.post(
        Uri.parse('$_item:/createUploadSession'),
        headers: await _headers({'Content-Type': 'application/json'}),
        body: jsonEncode({
          'item': {'@microsoft.graph.conflictBehavior': 'replace'},
        }),
      ),
    );
    _ok(s);
    final url =
        (jsonDecode(utf8.decode(s.bodyBytes)) as Map)['uploadUrl'] as String;
    http.Response? last;
    for (var start = 0; start < data.length; start += chunkSize) {
      final end = math.min(start + chunkSize, data.length) - 1;
      final part = Uint8List.sublistView(data, start, end + 1);
      last = await _send(
        () async => _client.put(
          Uri.parse(url),
          headers: {'Content-Range': 'bytes $start-$end/${data.length}'},
          body: part,
        ),
      );
      if (last.statusCode != 200 &&
          last.statusCode != 201 &&
          last.statusCode != 202)
        _fail(last);
    }
    return _info(jsonDecode(utf8.decode(last!.bodyBytes)));
  }

  @override
  Future<Uint8List> download(CloudBackupInfo info) async {
    final r = await _send(
      () async =>
          _client.get(Uri.parse('$_item:/content'), headers: await _headers()),
    );
    _ok(r);
    return r.bodyBytes;
  }

  @override
  Future<void> delete(CloudBackupInfo info) async {
    final r = await _send(
      () async => _client.delete(Uri.parse(_item), headers: await _headers()),
    );
    if (r.statusCode != 204) _ok(r);
  }
}
