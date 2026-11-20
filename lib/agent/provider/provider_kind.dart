import 'package:http/http.dart' as http;

import 'claude_provider.dart';
import 'gemini_provider.dart';
import 'llm_provider.dart';
import 'openai_provider.dart';

/// Fornecedores de modelos que o utilizador pode escolher.
enum AgentProviderKind {
  claude('Claude (Anthropic)', ClaudeProvider.defaultModel),
  openai('OpenAI', OpenAiProvider.defaultModel),
  gemini('Gemini (Google)', GeminiProvider.defaultModel);

  final String label;
  final String defaultModel;
  const AgentProviderKind(this.label, this.defaultModel);

  LlmProvider build({
    required String apiKey,
    String? model,
    http.Client? client,
  }) {
    final m = (model == null || model.trim().isEmpty) ? defaultModel : model;
    return switch (this) {
      claude => ClaudeProvider(apiKey: apiKey, model: m, client: client),
      openai => OpenAiProvider(apiKey: apiKey, model: m, client: client),
      gemini => GeminiProvider(apiKey: apiKey, model: m, client: client),
    };
  }
}
