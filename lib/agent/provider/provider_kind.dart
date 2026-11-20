import 'package:http/http.dart' as http;

import 'claude_provider.dart';
import 'gemini_provider.dart';
import 'llm_provider.dart';
import 'openai_provider.dart';

/// Fornecedores de modelos que o utilizador pode escolher.
enum AgentProviderKind {
  claude('Claude (Anthropic)', ClaudeProvider.defaultModel),
  openai('OpenAI', OpenAiProvider.defaultModel),
  gemini('Gemini (Google)', GeminiProvider.defaultModel),

  /// Servidor compatível com a API da OpenAI (Ollama, LM Studio, llama.cpp…),
  /// no PC ou na rede de casa. O modelo tem de ser indicado.
  local('Servidor local', '');

  final String label;
  final String defaultModel;
  const AgentProviderKind(this.label, this.defaultModel);

  bool get isLocal => this == local;

  /// Cria o fornecedor. O servidor local precisa de [baseUrl] válido (ver
  /// [normalizeBaseUrl]) e de [model]; a chave é opcional.
  LlmProvider build({
    required String apiKey,
    String? model,
    String? baseUrl,
    http.Client? client,
  }) {
    final m = (model == null || model.trim().isEmpty) ? defaultModel : model;
    return switch (this) {
      claude => ClaudeProvider(apiKey: apiKey, model: m, client: client),
      openai => OpenAiProvider(apiKey: apiKey, model: m, client: client),
      gemini => GeminiProvider(apiKey: apiKey, model: m, client: client),
      local => OpenAiProvider(
        apiKey: apiKey,
        model: m,
        baseUrl:
            normalizeBaseUrl(baseUrl) ??
            (throw ArgumentError('endereço inválido')),
        // modelos a correr em casa respondem mais devagar
        timeout: const Duration(minutes: 5),
        client: client,
      ),
    };
  }
}

/// Endereço de um servidor local: http(s) com anfitrião, sem barras no fim.
/// Devolve nulo se não for válido.
String? normalizeBaseUrl(String? raw) {
  final v = raw?.trim() ?? '';
  final u = Uri.tryParse(v);
  if (u == null ||
      !(u.scheme == 'http' || u.scheme == 'https') ||
      u.host.isEmpty) {
    return null;
  }
  if (u.hasQuery || u.hasFragment) return null;
  return v.replaceFirst(RegExp(r'/+$'), '');
}
