import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'provider/claude_provider.dart';

/// Definições do agente: a chave fica no armazenamento seguro do sistema
/// (Keystore/Keychain), o modelo em preferências normais.
class AgentSettings {
  static const _keyName = 'agent_claude_api_key';
  static const _modelName = 'agent_claude_model';
  static const _secure = FlutterSecureStorage();

  static Future<String?> readApiKey() async {
    try {
      final v = await _secure.read(key: _keyName);
      return (v == null || v.isEmpty) ? null : v;
    } on Object {
      return null;
    }
  }

  static Future<void> saveApiKey(String? key) async {
    final k = key?.trim() ?? '';
    if (k.isEmpty) {
      await _secure.delete(key: _keyName);
    } else {
      await _secure.write(key: _keyName, value: k);
    }
  }

  static Future<String> readModel() async {
    final p = await SharedPreferences.getInstance();
    final m = p.getString(_modelName)?.trim();
    return (m == null || m.isEmpty) ? ClaudeProvider.defaultModel : m;
  }

  static Future<void> saveModel(String model) async {
    final p = await SharedPreferences.getInstance();
    final m = model.trim();
    if (m.isEmpty) {
      await p.remove(_modelName);
    } else {
      await p.setString(_modelName, m);
    }
  }
}
