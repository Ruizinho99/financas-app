import 'dart:io';

import 'package:flutter/services.dart';

/// Carrega o Roboto do SDK do Flutter para os testes de interface terem medidas de texto realistas
/// (a fonte de teste por omissão tem letras quadradas muito largas e dá falsos transbordos).
Future<void> loadRoboto() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return;
  final dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) return;
  Future<ByteData> bytes(String name) async => ByteData.sublistView(await File('${dir.path}/$name').readAsBytes());
  final roboto = FontLoader('Roboto')
    ..addFont(bytes('Roboto-Regular.ttf'))
    ..addFont(bytes('Roboto-Medium.ttf'))
    ..addFont(bytes('Roboto-Bold.ttf'));
  await roboto.load();
  final icons = FontLoader('MaterialIcons')..addFont(bytes('MaterialIcons-Regular.otf'));
  await icons.load();
}
