import 'package:agrogestion/features/production/presentation/production_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('el título de producción ocupa un ancho legible', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ProductionPage())),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.text('Producción')).width, greaterThan(100));
  });

  testWidgets('Registrar agrega un lote a la lista', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ProductionPage())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Registrar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('lote_nombre')),
      'Frijol · Lote 4',
    );
    await tester.enterText(find.byKey(const Key('lote_finca')), 'El Porvenir');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Frijol · Lote 4'), findsOneWidget);
  });
}
