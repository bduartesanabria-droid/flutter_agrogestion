import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_api.dart';
import '../support/harness.dart';

typedef Recorrido = Future<void> Function(WidgetTester tester);

final _recorridos = <String, Recorrido>{
  'inicio': (t) async {
    expect(find.text('RESUMEN DE HOY'), findsOneWidget);
    expect(find.text('Helada en Café'), findsOneWidget);
  },
  'producción': (t) async {
    await tapText(t, 'Producción');
    expect(find.text('BALANCE OPERATIVO ACTUAL'), findsOneWidget);
  },
  'detalle de siembra': (t) async {
    await tapText(t, 'Producción');
    await tapText(t, 'Café');
    expect(find.text('ÍNDICES POR PLANTA'), findsOneWidget);
    await tapText(t, 'Ciclos');
    await tapText(t, 'Plantas');
    await tapText(t, 'Tiempos');
    expect(find.text('4 DÍAS DE RETRASO'), findsOneWidget);
  },
  'detalle de ciclo': (t) async {
    await tapText(t, 'Producción');
    await tapText(t, 'Café');
    await tapText(t, 'Ciclos');
    await tapText(t, 'Ciclo 1 · Levante');
    expect(find.text('LABORES DEL CICLO'), findsOneWidget);
  },
  'dinero': (t) async {
    await tapText(t, 'Dinero');
    expect(find.text('DISTRIBUCIÓN DEL GASTO'), findsOneWidget);
    await tapText(t, 'Ver todos');
    await tapText(t, 'Ingresos (1)');
  },
  'detalle de movimiento': (t) async {
    await tapText(t, 'Dinero');
    await tapText(t, 'Mano de obra', last: true);
    expect(find.text('TRAZABILIDAD'), findsOneWidget);
  },
  'más': (t) async {
    await tapText(t, 'Más');
    expect(find.text('OPERACIÓN DE CAMPO'), findsOneWidget);
  },
  'fincas, finca y lote': (t) async {
    await tapText(t, 'Más');
    await tapText(t, 'Mis fincas y lotes');
    await tapText(t, 'Finca La Esperanza');
    expect(find.text('LOTES REGISTRADOS'), findsOneWidget);
    await tapText(t, 'Lote 4B La Ceiba');
    expect(find.text('SIEMBRA ACTIVA'), findsOneWidget);
  },
  'trabajadores': (t) async {
    await tapText(t, 'Más');
    await tapText(t, 'Trabajadores');
    await tapText(t, 'Pedro Nel Builes');
    expect(find.text('CC ****5831'), findsWidgets);
  },
  'eventos adversos': (t) async {
    await tapText(t, 'Más');
    await tapText(t, 'Eventos adversos');
    await tapText(t, 'Helada');
    expect(find.text('DETALLE'), findsOneWidget);
  },
  'catálogo y ficha de cultivo': (t) async {
    await tapText(t, 'Más');
    await tapText(t, 'Catálogo de cultivos');
    await tapText(t, 'Café');
    for (final tab in ['Propag.', 'Dosis', 'Riesgos', 'Fases']) {
      await tapText(t, tab);
    }
  },
  'conocimiento, glosario y novedades': (t) async {
    await tapText(t, 'Más');
    await tapText(t, 'Glosario del campo');
    expect(find.text('Jornal'), findsOneWidget);
    await goBack(t);
    await tapText(t, 'Novedades de mi región');
    expect(find.text('Alerta de lluvias en su región'), findsOneWidget);
    await goBack(t);
    await tapText(t, 'Biblioteca de conocimiento');
    await tapText(t, 'Manchas amarillas en la hoja');
    expect(find.text('Hongo favorecido por la humedad.'), findsOneWidget);
  },
  'cuenta': (t) async {
    await tapText(t, 'Más');
    await tapText(t, 'Mi cuenta');
    expect(find.text('PRIVACIDAD Y HABEAS DATA'), findsOneWidget);
    await tapText(t, 'Ver política completa');
    expect(find.text('Política de datos'), findsOneWidget);
  },
  'pagos pendientes': (t) async {
    await tapText(t, 'Más');
    await tapText(t, 'Pagos pendientes');
    expect(find.text('TOTAL ACUMULADO POR LIQUIDAR'), findsOneWidget);
    await tapText(t, 'Por labor');
    expect(find.text('PARTIDAS POR LABOR'), findsOneWidget);
  },
  'inventario y detalle de insumo': (t) async {
    await tapText(t, 'Más');
    await tapText(t, 'Insumos e inventario');
    expect(find.text('Urea granulada 46%'), findsOneWidget);
    await tapText(t, 'Urea granulada 46%');
    expect(find.text('MOVIMIENTOS DE KARDEX'), findsOneWidget);
  },
  'formularios de inventario': (t) async {
    await tapText(t, 'Más');
    await tapText(t, 'Insumos e inventario');
    await tapText(t, 'Nuevo insumo');
    expect(find.text('Guardar insumo'), findsOneWidget);
    await t.tapAt(const Offset(5, 5));
    await settle(t);
    await tapText(t, 'Urea granulada 46%');
    await tapText(t, 'Registrar entrada');
    expect(find.text('Guardar entrada'), findsOneWidget);
    await t.tapAt(const Offset(5, 5));
    await settle(t);
    await tapText(t, 'Registrar consumo');
    expect(find.text('Guardar consumo'), findsOneWidget);
  },
  'procesos y detalle': (t) async {
    await tapText(t, 'Más');
    await tapText(t, 'Procesos de transformación');
    expect(find.text('Secado de bijao lote 1'), findsOneWidget);
    await tapText(t, 'Secado de bijao lote 1');
    expect(find.text('ETAPAS'), findsOneWidget);
    expect(find.text('Finalizar etapa'), findsOneWidget);
  },
  'formulario de proceso': (t) async {
    await tapText(t, 'Más');
    await tapText(t, 'Procesos de transformación');
    await tapText(t, 'Nuevo proceso');
    expect(find.text('Guardar proceso'), findsOneWidget);
  },
  'registro rápido': (t) async {
    await tapText(t, 'Registrar');
    expect(find.text('Registro rápido'), findsOneWidget);
  },
  'formulario de gasto': (t) async {
    await tapText(t, 'Registrar');
    await tapText(t, 'Gasto');
    expect(find.text('Guardar gasto'), findsOneWidget);
  },
  'formulario de ingreso': (t) async {
    await tapText(t, 'Registrar');
    await tapText(t, 'Ingreso');
    expect(find.text('Guardar ingreso'), findsOneWidget);
  },
  'formulario de labor': (t) async {
    await tapText(t, 'Registrar');
    await tapText(t, 'Labor con jornales');
    expect(find.text('Guardar labor'), findsOneWidget);
  },
  'formulario de cosecha': (t) async {
    await tapText(t, 'Registrar');
    await tapText(t, 'Cosecha');
    expect(find.text('Guardar cosecha'), findsOneWidget);
  },
  'formulario de evento': (t) async {
    await tapText(t, 'Registrar');
    await tapText(t, 'Evento adverso');
    expect(find.text('Guardar evento'), findsOneWidget);
  },
};

void main() {
  for (final size in allSizes) {
    for (final entry in _recorridos.entries) {
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
