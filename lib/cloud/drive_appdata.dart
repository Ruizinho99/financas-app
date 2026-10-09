import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'cloud_provider.dart';

/// Ficheiros na pasta privada da app no Google Drive ("appDataFolder"): só esta app os vê,
/// não aparecem no Drive do utilizador. API REST simples, sem bibliotecas extra.
class DriveAppData {
  DriveAppData({required this.token, http.Client? client}) : _client = client ?? http.Client();

  /// Devolve um token de acesso válido (pede a autorização se for preciso).
  final Future<String> Function() token;
  final http.Client _client;

  static const scope = 'https://www.googleapis.com/auth/drive.appdata';
  static const fileName = 'financas-backup.db';

  Future<Map<String, String>> _headers() async => {'Authorization': 'Bearer ${await token()}'};

  Never _fail(http.Response r) {
    if (r.statusCode == 401 || r.statusCode == 403) {
      throw const CloudException('A Google recusou o acesso. Volta a ligar a conta e aceita a permissão de guardar dados da app.');
    }
    if (r.statusCode == 404) throw const CloudException('Cópia não encontrada na nuvem.');
    if (r.statusCode == 429) throw const CloudException('Limite do serviço atingido. Tenta daqui a pouco.');
    throw CloudException('Erro do Google Drive (${r.statusCode}).');
  }

  Future<http.Response> _send(Future<http.Response> Function() f) async {
    try {
      return await f().timeout(const Duration(seconds: 60));
    } on TimeoutException {
      throw const CloudException('O Google Drive demorou demasiado a responder.');
    } on CloudException {
      rethrow;
    } catch (_) {
      throw const CloudException('Sem ligação à internet.');
    }
  }

  CloudBackupInfo _info(Map<String, dynamic> j) => CloudBackupInfo(
        id: j['id'] as String,
        name: j['name'] as String,
        modified: DateTime.tryParse((j['modifiedTime'] as String?) ?? '')?.toLocal() ?? DateTime.now(),
        size: int.tryParse('${j['size'] ?? 0}') ?? 0,
      );

  Future<CloudBackupInfo?> latest() async {
    final h = await _headers();
    final r = await _send(() => _client.get(
          Uri.https('www.googleapis.com', '/drive/v3/files', {
            'spaces': 'appDataFolder',
            'q': "name = '$fileName' and trashed = false",
            'orderBy': 'modifiedTime desc',
            'pageSize': '1',
            'fields': 'files(id,name,modifiedTime,size)',
          }),
          headers: h,
        ));
    if (r.statusCode != 200) _fail(r);
    final files = (jsonDecode(utf8.decode(r.bodyBytes))['files'] as List?) ?? [];
    return files.isEmpty ? null : _info(files.first as Map<String, dynamic>);
  }

  Future<CloudBackupInfo> upload(Uint8List data) async {
    final h = await _headers();
    final existing = await latest();
    final fields = 'id,name,modifiedTime,size';
    final http.Response r;
    if (existing != null) {
      r = await _send(() => _client.patch(
            Uri.https('www.googleapis.com', '/upload/drive/v3/files/${existing.id}', {'uploadType': 'media', 'fields': fields}),
            headers: {...h, 'Content-Type': 'application/octet-stream'},
            body: data,
          ));
    } else {
      // criação com metadados + conteúdo (multipart/related)
      const boundary = 'financas_boundary_8f3a';
      final meta = jsonEncode({'name': fileName, 'parents': ['appDataFolder']});
      final body = BytesBuilder()
        ..add(utf8.encode('--$boundary\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n$meta\r\n--$boundary\r\nContent-Type: application/octet-stream\r\n\r\n'))
        ..add(data)
        ..add(utf8.encode('\r\n--$boundary--'));
      r = await _send(() => _client.post(
            Uri.https('www.googleapis.com', '/upload/drive/v3/files', {'uploadType': 'multipart', 'fields': fields}),
            headers: {...h, 'Content-Type': 'multipart/related; boundary=$boundary'},
            body: body.toBytes(),
          ));
    }
    if (r.statusCode != 200) _fail(r);
    return _info(jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>);
  }

  Future<Uint8List> download(CloudBackupInfo info) async {
    final h = await _headers();
    final r = await _send(() => _client.get(Uri.https('www.googleapis.com', '/drive/v3/files/${info.id}', {'alt': 'media'}), headers: h));
    if (r.statusCode != 200) _fail(r);
    return r.bodyBytes;
  }

  Future<void> delete(CloudBackupInfo info) async {
    final h = await _headers();
    final r = await _send(() => _client.delete(Uri.https('www.googleapis.com', '/drive/v3/files/${info.id}'), headers: h));
    if (r.statusCode != 204 && r.statusCode != 200) _fail(r);
  }
}
