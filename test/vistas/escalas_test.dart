import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';
import '../support/recorridos.dart';

void main() {
  for (final scale in [1.3, 1.6, 2.0]) {
    for (final entry in recorridos.entries) {
      testWidgets('${entry.key} con letra al ${(scale * 100).toInt()}%', (
        tester,
      ) async {
        await pumpApp(
          tester,
          role: 'admin',
          size: const Size(360, 800),
          textScale: scale,
        );
        await entry.value(tester);
        expectNoErrors(tester);
        expect(verticalTexts(), isEmpty);
      });
    }
  }
}
