import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ondevice/on_device_models.dart';
import 'provider/provider_kind.dart';

/// Definições do agente: as chaves ficam no armazenamento seguro do sistema
/// (Keystore/Keychain), uma por fornecedor; o fornecedor e os modelos em
/// preferências normais. Os nomes do Claude são os da versão anterior.
class AgentSettings {
  static const _kindName = 'agent_provider';
  static const _secure = FlutterSecureStorage();

  static String _keyName(AgentProviderKind k) => 'agent_${k.name}_api_key';
  static String _modelName(AgentProviderKind k) => 'agent_${k.name}_model';
  static const _baseUrlName = 'agent_local_base_url';

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

  static Future<String?> readBaseUrl() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(_baseUrlName)?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  static Future<void> saveBaseUrl(String? url) async {
    final p = await SharedPreferences.getInstance();
    final v = url?.trim() ?? '';
    if (v.isEmpty) {
      await p.remove(_baseUrlName);
    } else {
      await p.setString(_baseUrlName, v);
    }
  }

  /// O fornecedor escolhido, pronto a usar, ou nulo se faltar algo: a chave
  /// (Claude, OpenAI, Gemini) ou o endereço e o modelo (servidor local, onde a
  /// chave é opcional).
  static Future<
    ({AgentProviderKind kind, String key, String model, String? baseUrl})?
  >
  active() async {
    final kind = await readKind();
    final key = await readApiKey(kind);
    final model = await readModel(kind);
    if (kind == AgentProviderKind.onDevice) {
      final file = await OnDeviceModels.activeFile();
      if (file == null) return null;
      return (kind: kind, key: '', model: file, baseUrl: null);
    }
    if (kind.isLocal) {
      final url = normalizeBaseUrl(await readBaseUrl());
      if (url == null || model.isEmpty) return null;
      return (kind: kind, key: key ?? '', model: model, baseUrl: url);
    }
    if (key == null) return null;
    return (kind: kind, key: key, model: model, baseUrl: null);
  }
}
