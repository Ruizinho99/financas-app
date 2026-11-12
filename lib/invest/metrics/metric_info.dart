/// Explicação de uma métrica, para mostrar escondida atrás de um ícone "i" (ou toque longo) em todo o lado
/// onde a métrica aparece. REGRA: toda a métrica que uma fórmula devolve (`Metric.key`) tem de ter uma entrada
/// aqui, incluindo as que ficam "não disponíveis" (a explicação diz porquê). Um teste verifica a cobertura.
library;

/// Se a métrica se consegue calcular com dados gratuitos.
enum MetricAvailability {
  /// Calcula-se sempre que os dados existem.
  available,

  /// Calcula-se com uma aproximação ou só para certos tipos de empresa (a explicação diz qual).
  partial,

  /// Não se calcula com dados gratuitos (a explicação diz porquê). A interface mostra "não disponível".
  unavailable,
}

class MetricInfo {
  /// Mesma chave de `Metric.key` (snake_case em inglês).
  final String key;
  final String namePt, nameEn;

  /// Fórmula curta, igual nas duas línguas (ex.: `(Receita − Custo das vendas) / Receita`).
  /// Nas métricas sem fórmula (ex.: não disponível) pode ficar vazia.
  final String formula;

  /// O que a métrica mede, numa ou duas frases.
  final String meaningPt, meaningEn;

  /// Como a ler: o que é "bom" ou "mau", com a ressalva de que depende do setor e de comparar com pares.
  final String readPt, readEn;

  /// Armadilhas e limitações (opcional).
  final String? cautionPt, cautionEn;
  final MetricAvailability availability;

  const MetricInfo({
    required this.key,
    required this.namePt,
    required this.nameEn,
    this.formula = '',
    required this.meaningPt,
    required this.meaningEn,
    required this.readPt,
    required this.readEn,
    this.cautionPt,
    this.cautionEn,
    this.availability = MetricAvailability.available,
  });

  String name(String lang) => lang == 'en' ? nameEn : namePt;
  String meaning(String lang) => lang == 'en' ? meaningEn : meaningPt;
  String howToRead(String lang) => lang == 'en' ? readEn : readPt;
  String? caution(String lang) => lang == 'en' ? cautionEn : cautionPt;
}
