import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:financas/invest/analysis/metric_sheet.dart';

void main() {
  testWidgets('a ficha de explicação abre para qualquer métrica', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) => TextButton(
            onPressed: () => showMetricInfo(c, 'roic'),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await t.tap(find.text('abrir'));
    await t.pumpAndSettle();
    expect(find.text('How to read it'), findsOneWidget);
    expect(find.textContaining('ROIC'), findsWidgets);
  });
}
