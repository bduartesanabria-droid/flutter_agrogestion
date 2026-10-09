import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';

void main() {
  for (final size in allSizes) {
    testWidgets(
      'sin internet muestra lo guardado y avisa en ${size.width.toInt()} px',
      (tester) async {
        final fake = await pumpApp(tester, role: 'admin', size: size);
        await tapText(tester, 'Dinero');
        expect(find.text('DISTRIBUCIÓN DEL GASTO'), findsOneWidget);
        await tapText(tester, 'Inicio');

        fake.offline = true;
        await tapText(tester, 'Dinero');
        expect(find.text('DISTRIBUCIÓN DEL GASTO'), findsOneWidget);
        expect(find.textContaining('Sin conexión'), findsOneWidget);
        expectNoErrors(tester);
      },
    );
  }

  testWidgets('sin internet y sin nada guardado se ofrece reintentar', (
    tester,
  ) async {
    final fake = await pumpApp(tester, role: 'admin');
    fake.offline = true;
    await tapText(tester, 'Producción');
    expect(find.text('Reintentar'), findsOneWidget);
    expectNoErrors(tester);
  });
}
