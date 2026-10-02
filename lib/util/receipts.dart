import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Recibos anexados a movimentos: copiados para a pasta da app (ficam só no telemóvel).
class Receipts {
  static Directory? _dir;

  static Future<void> init() async {
    final base = await getApplicationDocumentsDirectory();
    _dir = Directory(p.join(base.path, 'receipts'));
    if (!_dir!.existsSync()) _dir!.createSync(recursive: true);
  }

  /// Só para testes.
  static void useDirectory(Directory d) => _dir = d;

  /// Copia [source] para a pasta de recibos e devolve o nome do ficheiro guardado.
  static Future<String> save(File source) async {
    final name = '${DateTime.now().microsecondsSinceEpoch}_${p.basename(source.path)}';
    await source.copy(p.join(_dir!.path, name));
    return name;
  }

  /// Guarda bytes (foto da câmara, ficheiro escolhido…) e devolve o nome.
  static Future<String> saveBytes(String originalName, Uint8List bytes) async {
    final name = '${DateTime.now().microsecondsSinceEpoch}_${p.basename(originalName)}';
    await File(p.join(_dir!.path, name)).writeAsBytes(bytes);
    return name;
  }

  static File? file(String? name) {
    if (name == null || _dir == null) return null;
    final f = File(p.join(_dir!.path, name));
    return f.existsSync() ? f : null;
  }

  static bool isImage(String name) {
    final e = p.extension(name).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.webp', '.heic', '.gif'].contains(e);
  }

  /// Nome apresentável (sem o prefixo numérico).
  static String displayName(String name) => name.replaceFirst(RegExp(r'^\d+_'), '');

  static void delete(String? name) {
    final f = file(name);
    try {
      f?.deleteSync();
    } catch (_) {}
  }
}
