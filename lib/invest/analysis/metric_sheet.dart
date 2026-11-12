import 'package:flutter/material.dart';

import '../metrics/metric_catalog.dart';
import '../metrics/metric_info.dart';

/// Mostra a explicação escondida de uma métrica: nome, o que mede, fórmula, como ler, cuidados e disponibilidade.
Future<void> showMetricInfo(BuildContext context, String key) {
  final lang = Localizations.localeOf(context).languageCode;
  final info = metricInfoFor(key);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      final tt = Theme.of(ctx).textTheme;
      final cs = Theme.of(ctx).colorScheme;
      String t(String pt, String en) => lang == 'en' ? en : pt;
      if (info == null) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Text(key, style: tt.titleMedium),
        );
      }
      Widget block(String title, String body) => Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: tt.labelLarge?.copyWith(color: cs.primary),
            ),
            const SizedBox(height: 4),
            Text(body, style: tt.bodyMedium),
          ],
        ),
      );
      final caution = info.caution(lang);
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          children: [
            Text(info.name(lang), style: tt.titleLarge),
            if (info.availability != MetricAvailability.available)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Chip(
                  avatar: const Icon(Icons.info_outline, size: 18),
                  label: Text(
                    info.availability == MetricAvailability.unavailable
                        ? t(
                            'Não disponível com dados gratuitos',
                            'Not available with free data',
                          )
                        : t(
                            'Aproximação ou só para certos setores',
                            'Approximation or only for some sectors',
                          ),
                  ),
                ),
              ),
            block(t('O que mede', 'What it measures'), info.meaning(lang)),
            if (info.formula.isNotEmpty)
              block(t('Fórmula', 'Formula'), info.formula),
            block(t('Como ler', 'How to read it'), info.howToRead(lang)),
            if (caution != null && caution.isNotEmpty)
              block(t('Cuidado', 'Caution'), caution),
          ],
        ),
      );
    },
  );
}
