import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Uma versão publicada no GitHub.
class ReleaseInfo {
  final String tag; // v1.9.0
  final String name;
  final String notes;
  final String pageUrl;
  final String? apkName;
  final String? apkUrl;
  final int apkSize;
  const ReleaseInfo({
    required this.tag,
    required this.name,
    required this.notes,
    required this.pageUrl,
    this.apkName,
    this.apkUrl,
    this.apkSize = 0,
  });

  String get version => tag.startsWith('v') ? tag.substring(1) : tag;
}

class UpdateException implements Exception {
  final String message;
  const UpdateException(this.message);
  @override
  String toString() => message;
}

/// Procura novas versões no GitHub e descarrega o APK. Só usa a internet quando o utilizador pede.
class UpdateService {
  UpdateService({
    http.Client? client,
    this.owner = 'Ruizinho99',
    this.repo = 'financas-app',
    this.tempDir,
  }) : _client = client ?? http.Client();
  final http.Client _client;
  final String owner, repo;
  final Directory? tempDir; // para testes

  /// Compara versões "1.9.0" > "1.8.0" (ignora o sufixo +build e partes não numéricas).
  static bool isNewer(String candidate, String current) {
    List<int> parts(String v) => [
      for (final p
          in v.replaceFirst(RegExp(r'^v'), '').split('+').first.split('.'))
        int.tryParse(RegExp(r'\d+').firstMatch(p)?[0] ?? '') ?? 0,
    ];
    final a = parts(candidate), b = parts(current);
    for (var i = 0; i < 4; i++) {
      final x = i < a.length ? a[i] : 0, y = i < b.length ? b[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }

  /// Tag da última release, lida do redirecionamento de github.com (não usa a API, por isso não tem o limite de 60 pedidos/hora).
  Future<String> latestTag() async {
    final req =
        http.Request(
            'GET',
            Uri.parse('https://github.com/$owner/$repo/releases/latest'),
          )
          ..followRedirects = false
          ..headers['User-Agent'] = 'FinancasApp';
    final http.StreamedResponse res;
    try {
      res = await _client.send(req).timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const UpdateException('O GitHub demorou demasiado a responder.');
    } catch (_) {
      throw const UpdateException('Sem ligação à internet.');
    }
    await res.stream.drain<void>();
    final m = RegExp(r'/releases/tag/([^/?#]+)')
        .firstMatch(res.headers['location'] ?? '');
    if (m == null) {
      if (res.statusCode == 404)
        throw const UpdateException('Ainda não há nenhuma versão publicada.');
      throw UpdateException(
        'Resposta inesperada do GitHub (${res.statusCode}).',
      );
    }
    return Uri.decodeComponent(m[1]!);
  }

  Future<ReleaseInfo> latest() async {
    final http.Response r;
    try {
      r = await _client
          .get(
            Uri.https('api.github.com', '/repos/$owner/$repo/releases/latest'),
            headers: {
              'Accept': 'application/vnd.github+json',
              'User-Agent': 'FinancasApp',
            },
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const UpdateException('O GitHub demorou demasiado a responder.');
    } catch (_) {
      throw const UpdateException('Sem ligação à internet.');
    }
    if (r.statusCode == 404)
      throw const UpdateException('Ainda não há nenhuma versão publicada.');
    if (r.statusCode == 403 || r.statusCode == 429)
      throw const UpdateException(
        'Limite do GitHub atingido. Tenta daqui a pouco.',
      );
    if (r.statusCode != 200)
      throw UpdateException('Erro do GitHub (${r.statusCode}).');
    final Map<String, dynamic> j;
    try {
      j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw const UpdateException('Resposta inesperada do GitHub.');
    }
    final assets = (j['assets'] as List?)?.whereType<Map>().toList() ?? [];
    Map? apk;
    for (final a in assets) {
      final n = '${a['name']}'.toLowerCase();
      if (n.endsWith('.apk') && n.contains('release')) apk = a;
    }
    apk ??= assets
        .where((a) => '${a['name']}'.toLowerCase().endsWith('.apk'))
        .firstOrNull;
    return ReleaseInfo(
      tag: '${j['tag_name'] ?? ''}',
      name: '${j['name'] ?? j['tag_name'] ?? ''}',
      notes: '${j['body'] ?? ''}',
      pageUrl: '${j['html_url'] ?? 'https://github.com/$owner/$repo/releases'}',
      apkName: apk == null ? null : '${apk['name']}',
      apkUrl: apk == null ? null : '${apk['browser_download_url']}',
      apkSize: apk == null ? 0 : (apk['size'] as num?)?.toInt() ?? 0,
    );
  }

  /// Descarrega o APK para a pasta temporária e devolve o ficheiro.
  Future<File> download(
    ReleaseInfo r, {
    void Function(double)? onProgress,
  }) async {
    if (r.apkUrl == null)
      throw const UpdateException('Esta versão não tem APK para descarregar.');
    final dir = tempDir ?? await getTemporaryDirectory();
    final file = File('${dir.path}/${r.apkName ?? 'financas.apk'}');
    try {
      final res = await _client
          .send(
            http.Request('GET', Uri.parse(r.apkUrl!))
              ..headers['User-Agent'] = 'FinancasApp',
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode != 200)
        throw UpdateException('Erro ao descarregar (${res.statusCode}).');
      final total = res.contentLength ?? r.apkSize;
      final sink = file.openWrite();
      var got = 0;
      try {
        await for (final chunk in res.stream) {
          sink.add(chunk);
          got += chunk.length;
          if (total > 0) onProgress?.call(got / total);
        }
      } finally {
        await sink.close();
      }
      if (total > 0 && got < total * 0.99)
        throw const UpdateException(
          'A transferência ficou incompleta. Tenta outra vez.',
        );
    } on UpdateException {
      rethrow;
    } on TimeoutException {
      throw const UpdateException('A transferência demorou demasiado.');
    } catch (_) {
      throw const UpdateException(
        'Não consegui descarregar. Verifica a ligação.',
      );
    }
    return file;
  }
}
