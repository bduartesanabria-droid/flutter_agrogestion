import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';

void main() {
  for (final role in ['admin', 'agricultor']) {
    testWidgets('$role ve cuatro pestañas y el registro rápido', (
      tester,
    ) async {
      await pumpApp(tester, role: role);
      for (final tab in ['Inicio', 'Producción', 'Dinero', 'Más']) {
        expect(find.text(tab), findsWidgets, reason: tab);
      }
      expect(find.text('Registrar'), findsOneWidget);
      await tester.tap(find.text('Registrar'));
      await settle(tester);
      for (final action in [
        'Labor con jornales',
        'Gasto',
        'Ingreso',
        'Cosecha',
        'Evento adverso',
      ]) {
        expect(find.text(action), findsOneWidget, reason: action);
      }
      expectNoErrors(tester);
    });
  }

  testWidgets('el contador solo registra dinero', (tester) async {
    await pumpApp(tester, role: 'contador');
    expect(find.text('Registrar'), findsOneWidget);
    await tester.tap(find.text('Registrar'));
    await settle(tester);
    expect(find.text('Gasto'), findsOneWidget);
    expect(find.text('Ingreso'), findsOneWidget);
    expect(find.text('Labor con jornales'), findsNothing);
    expect(find.text('Cosecha'), findsNothing);
    expectNoErrors(tester);
  });

  testWidgets('el experto solo ve Inicio y Más, sin registro', (tester) async {
    await pumpApp(tester, role: 'experto');
    expect(find.text('Inicio'), findsWidgets);
    expect(find.text('Más'), findsWidgets);
    expect(find.text('Producción'), findsNothing);
    expect(find.text('Dinero'), findsNothing);
    expect(find.text('Registrar'), findsNothing);
    await tapText(tester, 'Más');
    expect(find.text('Trabajadores'), findsNothing);
    expect(find.text('Catálogo de cultivos'), findsNothing);
    expect(find.text('Glosario del campo'), findsOneWidget);
    expectNoErrors(tester);
  });

  testWidgets('el agricultor no ve la utilidad y el contador sí', (
    tester,
  ) async {
    await pumpApp(tester, role: 'agricultor');
    await tapText(tester, 'Dinero');
    expect(find.text('SALDO NETO DISPONIBLE'), findsNothing);
    expect(find.text('Ingresos del mes'), findsOneWidget);
    expectNoErrors(tester);

    await pumpApp(tester, role: 'contador');
    await tapText(tester, 'Dinero');
    expect(find.text('SALDO NETO DISPONIBLE'), findsOneWidget);
    expectNoErrors(tester);
  });

  testWidgets('anular un movimiento es del administrador y el contador', (
    tester,
  ) async {
    for (final entry in {
      'admin': true,
      'agricultor': false,
      'contador': true,
    }.entries) {
      await pumpApp(tester, role: entry.key);
      await tapText(tester, 'Dinero');
      await tapText(tester, 'Mano de obra', last: true);
      expect(
        find.text('Anular movimiento'),
        entry.value ? findsOneWidget : findsNothing,
        reason: entry.key,
      );
      expectNoErrors(tester);
    }
  });

  testWidgets('el contador no inicia ni cancela siembras', (tester) async {
    await pumpApp(tester, role: 'contador');
    await tapText(tester, 'Producción');
    await tapText(tester, 'Café');
    expect(find.text('Cancelar siembra'), findsNothing);
    expect(find.text('Registrar conteo de plantas'), findsNothing);
    expectNoErrors(tester);
  });
}
