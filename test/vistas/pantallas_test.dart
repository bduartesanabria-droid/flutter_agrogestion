import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_api.dart';
import '../support/harness.dart';
import '../support/recorridos.dart';

void main() {
  for (final size in allSizes) {
    for (final entry in recorridos.entries) {
      testWidgets(
        '${entry.key} se dibuja sin desbordes en ${size.width.toInt()} px',
        (tester) async {
          await pumpApp(tester, role: 'admin', size: size);
          await entry.value(tester);
          expectNoErrors(tester);
        },
      );
    }
  }

  testWidgets('el inicio de sesión se dibuja en todos los anchos', (
    tester,
  ) async {
    for (final size in allSizes) {
      await pumpLogin(tester, size);
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expectNoErrors(tester);
    }
  });

  testWidgets('sin consentimiento se pide la autorización de datos', (
    tester,
  ) async {
    final fake = FakeBackend(consentAccepted: false);
    await pumpApp(tester, role: 'agricultor', backend: fake);
    expect(find.text('Aceptar y continuar'), findsOneWidget);
    expectNoErrors(tester);
    await tester.tap(find.byType(Checkbox).first);
    await settle(tester);
    await tester.tap(find.text('Aceptar y continuar'));
    await settle(tester);
    expect(find.text('RESUMEN DE HOY'), findsOneWidget);
    expect(fake.consentAccepted, isTrue);
  });

  testWidgets('si el servidor falla se muestra un error con reintento', (
    tester,
  ) async {
    final fake = FakeBackend(failPaths: {'inicio'});
    await pumpApp(tester, role: 'agricultor', backend: fake);
    expect(find.text('No pudimos cargar esto'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expectNoErrors(tester);
  });

  testWidgets('sin fincas se invita a registrar la primera', (tester) async {
    final fake = FakeBackend(farms: []);
    await pumpApp(tester, role: 'agricultor', backend: fake);
    await tapText(tester, 'Dinero');
    expect(find.text('Registre una finca para ver su dinero'), findsOneWidget);
    expectNoErrors(tester);
  });
}
