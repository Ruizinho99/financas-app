import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_litertlm/flutter_edge_ai_litertlm.dart';

/// Um modelo que se pode descarregar e correr no telemóvel.
class OnDeviceModelOption {
  /// Nome do ficheiro instalado (identifica o modelo no motor).
  final String file;
  final String name;
  final int sizeBytes;

  /// O mais pequeno da família que o motor recomenda para conversar e usar ferramentas.
  final bool recommended;
  final InferenceVariant variant;
  const OnDeviceModelOption({
    required this.file,
    required this.name,
    required this.sizeBytes,
    required this.recommended,
    required this.variant,
  });
}

/// Ponte entre a app e o motor de modelos no telemóvel (LiteRT-LM).
/// Arranca só quando se usa: a app normal não paga nada por ele.
class OnDeviceModels {
  static Future<void>? _init;

  static Future<void> ensureInitialized() {
    return _init ??=
        FlutterEdgeAi.initialize(inferenceEngines: const [LiteRtLmEngine()])
            .catchError((Object e) {
              _init = null; // deixa tentar de novo
              throw e;
            });
  }

  /// Modelos que correm neste telemóvel e sabem chamar ferramentas, do mais
  /// pequeno para o maior. Vazio se o aparelho não for suportado.
  static Future<List<OnDeviceModelOption>> options() async {
    await ensureInitialized();
    final out = <OnDeviceModelOption>[];
    for (final m in FlutterEdgeAi.catalog.models) {
      if (m is! LiteRtLmModel) continue;
      final v = m.variantFor();
      if (v is! LiteRtLmVariant) continue;
      final f = v.file;
      if (v.isWebBundle || !v.supportsFunctionCalls) continue;
      // o FunctionGemma só emite a chamada e não conversa: o agente precisa de responder
      if (v.modelType == ModelType.functionGemma) continue;
      out.add(
        OnDeviceModelOption(
          file: f.installFilename,
          name: m.displayName,
          sizeBytes: f.sizeBytes,
          recommended: false,
          variant: v,
        ),
      );
    }
    out.sort((a, b) => a.sizeBytes.compareTo(b.sizeBytes));
    // recomendado: o mais pequeno com tamanho útil (acima de 1 GB costuma conversar bem)
    final rec = out.indexWhere((o) => o.sizeBytes >= 1000 * 1000 * 1000);
    return [
      for (var i = 0; i < out.length; i++)
        OnDeviceModelOption(
          file: out[i].file,
          name: out[i].name,
          sizeBytes: out[i].sizeBytes,
          recommended: i == rec,
          variant: out[i].variant,
        ),
    ];
  }

  static Future<Set<String>> installedFiles() async {
    await ensureInitialized();
    return (await FlutterEdgeAi.listInstalledModels()).toSet();
  }

  /// Nome do ficheiro do modelo em uso, se houver.
  static Future<String?> activeFile() async {
    await ensureInitialized();
    return FlutterEdgeAi.hasActiveModel()
        ? FlutterEdgeAi.activeModelSpec?.name
        : null;
  }

  /// Descarrega (se ainda não estiver) e passa a usar [o]. [onProgress] recebe 0 a 100.
  static Future<void> install(
    OnDeviceModelOption o, {
    void Function(int percent)? onProgress,
  }) async {
    await ensureInitialized();
    var b = FlutterEdgeAi.installModelFromCatalog(o.variant);
    if (onProgress != null) b = b.withProgress(onProgress);
    await b.install();
  }

  static Future<void> uninstall(OnDeviceModelOption o) async {
    await ensureInitialized();
    await FlutterEdgeAi.uninstallModel(o.file);
  }

  /// Abre uma conversa no modelo em uso. Quem chama fecha-a.
  static Future<InferenceChat> openChat({
    required String system,
    required List<Tool> tools,
  }) async {
    await ensureInitialized();
    if (!FlutterEdgeAi.hasActiveModel()) {
      throw StateError('no active model');
    }
    final model = await FlutterEdgeAi.getActiveModel(maxTokens: 4096);
    return model.openChat(
      tools: tools,
      supportsFunctionCalls: true,
      systemInstruction: system,
      temperature: 0.2,
      maxOutputTokens: 1024,
    );
  }
}
