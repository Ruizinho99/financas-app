/// Lógica pura da distribuição de um valor pelas subcategorias.

/// Divide [total] por [n] partes; o resto (cêntimos) vai uma unidade a cada uma das primeiras,
/// de modo a que a soma seja exatamente [total].
List<int> splitEqually(int total, int n) {
  if (n <= 0) return const [];
  final t = total < 0 ? 0 : total;
  final base = t ~/ n, rest = t % n;
  return [for (var i = 0; i < n; i++) base + (i < rest ? 1 : 0)];
}

/// Uma subcategoria na distribuição: [percent] = orçamento em % do salário (só leitura).
class DistKid {
  final int id;
  final bool percent;
  const DistKid(this.id, {this.percent = false});
}

/// Valores a gravar (id -> cêntimos) ao distribuir: só as filhas cujo campo foi editado e tem
/// valor válido; as de orçamento em % e as não editadas ficam intactas.
/// [edited] tem o valor lido do campo (nulo = campo vazio/ilegível).
Map<int, int> distributionWrites(
  Iterable<DistKid> kids,
  Map<int, int?> edited,
) {
  final out = <int, int>{};
  for (final k in kids) {
    if (k.percent) continue;
    final v = edited[k.id];
    if (v == null) continue;
    out[k.id] = v.abs();
  }
  return out;
}
