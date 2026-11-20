import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'provider/provider_kind.dart';

/// Definições do agente: as chaves ficam no armazenamento seguro do sistema
/// (Keystore/Keychain), uma por fornecedor; o fornecedor e os modelos em
/// preferências normais. Os nomes do Claude são os da versão anterior.
class AgentSettings {
  static const _kindName = 'agent_provider';
  static const _secure = FlutterSecureStorage();

  static String _keyName(AgentProviderKind k) => 'agent_${k.name}_api_key';
  static String _modelName(AgentProviderKind k) => 'agent_${k.name}_model';

  static Future<AgentProviderKind> readKind() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(_kindName);
    return AgentProviderKind.values.firstWhere(
      (k) => k.name == v,
      orElse: () => AgentProviderKind.claude,
    );
  }

  static Future<void> saveKind(AgentProviderKind k) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kindName, k.name);
  }

  static Future<String?> readApiKey(AgentProviderKind k) async {
    try {
      final v = await _secure.read(key: _keyName(k));
      return (v == null || v.isEmpty) ? null : v;
    } on Object {
      return null;
    }
  }

  static Future<void> saveApiKey(AgentProviderKind k, String? key) async {
    final v = key?.trim() ?? '';
    if (v.isEmpty) {
      await _secure.delete(key: _keyName(k));
    } else {
      await _secure.write(key: _keyName(k), value: v);
    }
  }

  static Future<String> readModel(AgentProviderKind k) async {
    final p = await SharedPreferences.getInstance();
    final m = p.getString(_modelName(k))?.trim();
    return (m == null || m.isEmpty) ? k.defaultModel : m;
  }

  static Future<void> saveModel(AgentProviderKind k, String model) async {
    final p = await SharedPreferences.getInstance();
    final m = model.trim();
    if (m.isEmpty) {
      await p.remove(_modelName(k));
    } else {
      await p.setString(_modelName(k), m);
    }
  }

  /// O fornecedor escolhido com a sua chave e modelo, ou nulo se faltar a chave.
  static Future<({AgentProviderKind kind, String key, String model})?>
  active() async {
    final kind = await readKind();
    final key = await readApiKey(kind);
    if (key == null) return null;
    return (kind: kind, key: key, model: await readModel(kind));
  }
}
