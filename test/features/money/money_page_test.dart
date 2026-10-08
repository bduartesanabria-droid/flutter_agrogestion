import 'package:agrogestion/features/money/presentation/money_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('el título de dinero ocupa un ancho legible', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MoneyPage())),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.text('Dinero')).width, greaterThan(60));
  });

  testWidgets('Nuevo movimiento registra un gasto en la lista', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MoneyPage())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nuevo movimiento'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('movimiento_descripcion')),
      'Compra de semilla',
    );
    await tester.enterText(
      find.byKey(const Key('movimiento_categoria')),
      'Insumos',
    );
    await tester.enterText(find.byKey(const Key('movimiento_monto')), '500000');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Compra de semilla'), findsOneWidget);
  });

  testWidgets('anular exige motivo y marca el movimiento como anulado', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MoneyPage())),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Fertilizante granulado'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fertilizante granulado'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anular'));
    await tester.pumpAndSettle();
    expect(find.text('Escriba el motivo de la anulación.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('movimiento_motivo')),
      'Registro duplicado',
    );
    await tester.tap(find.text('Anular'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Anulado ·'), findsOneWidget);
  });
}
