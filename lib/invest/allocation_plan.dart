/// Uma linha do plano de uma plataforma: um ativo e a sua parte em pontos base (10000 = 100%).
class PlanLine {
  final int holdingId;
  final int bp;
  const PlanLine(this.holdingId, this.bp);
}

/// Quanto de uma entrega vai para um ativo, em cêntimos.
class AllocationPart {
  final int holdingId;
  final int cents;
  const AllocationPart(this.holdingId, this.cents);
}

/// Divide [cents] pelas linhas do plano. Os arredondamentos vão para a maior parte, para que a soma
/// seja exata. Se o plano não chega a 100%, a parte que falta fica por distribuir (não aparece).
List<AllocationPart> splitByPlan(int cents, List<PlanLine> lines) {
  final valid = lines.where((l) => l.bp > 0).toList();
  if (cents <= 0 || valid.isEmpty) return const [];
  final sumBp = valid.fold<int>(0, (a, l) => a + l.bp);
  final total = cents * sumBp ~/ 10000;
  final parts = [
    for (final l in valid) AllocationPart(l.holdingId, cents * l.bp ~/ 10000),
  ];
  final leftover = total - parts.fold<int>(0, (a, p) => a + p.cents);
  if (leftover > 0) {
    var biggest = 0;
    for (var i = 1; i < valid.length; i++) {
      if (valid[i].bp > valid[biggest].bp) biggest = i;
    }
    parts[biggest] = AllocationPart(
      parts[biggest].holdingId,
      parts[biggest].cents + leftover,
    );
  }
  return parts;
}
