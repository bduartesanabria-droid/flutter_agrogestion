// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';
import 'dart:ui' as ui;

import 'package:agrogestion/app/agrogestion_app.dart';
import 'package:agrogestion/features/auth/data/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/support/fake_api.dart';
import '../test/support/harness.dart' show goBack, settle, tapText;

const _out = String.fromEnvironment('CAPTURAS', defaultValue: 'build/capturas');
const _sizes = {
  'movil': Size(390, 1500),
  'chico': Size(320, 1500),
  'escritorio': Size(1280, 1000),
};

final _boundary = GlobalKey();
final _problems = <String>[];

Future<void> _shot(WidgetTester tester, String name) async {
  await settle(tester);
  final problem = tester.takeException();
  if (problem != null) _problems.add('$name: $problem');
  await tester.runAsync(() async {
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$_out/$name.png')..createSync(recursive: true);
    file.writeAsBytesSync(data!.buffer.asUint8List());
  });
}

Future<void> _open(WidgetTester tester, String role, Size size) async {
  FlutterSecureStorage.setMockInitialValues({
    'agrogestion_access_token': 'token-$role',
  });
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final api = FakeBackend().client();
  final auth = AuthRepository(api: api, storage: const FlutterSecureStorage());
  await tester.pumpWidget(
    RepaintBoundary(
      key: _boundary,
      child: AgroGestionApp(api: api, authRepository: auth),
    ),
  );
  await settle(tester);
}

void main() {
  for (final entry in _sizes.entries) {
    testWidgets('capturas ${entry.key}', (tester) async {
      final tag = entry.key;
      await _open(tester, 'admin', entry.value);
      await _shot(tester, '$tag-01-inicio');
      await tapText(tester, 'Producción');
      await _shot(tester, '$tag-02-produccion');
      await tapText(tester, 'Café');
      await _shot(tester, '$tag-03-siembra-resumen');
      await tapText(tester, 'Ciclos');
      await _shot(tester, '$tag-04-siembra-ciclos');
      await tapText(tester, 'Plantas');
      await _shot(tester, '$tag-05-siembra-plantas');
      await tapText(tester, 'Tiempos');
      await _shot(tester, '$tag-06-siembra-tiempos');
      await goBack(tester);
      await tapText(tester, 'Dinero');
      await _shot(tester, '$tag-07-dinero');
      await tapText(tester, 'Ver todos');
      await _shot(tester, '$tag-08-movimientos');
      await goBack(tester);
      await tapText(tester, 'Más');
      await _shot(tester, '$tag-09-mas');
      await tapText(tester, 'Mis fincas y lotes');
      await _shot(tester, '$tag-10-fincas');
      await tapText(tester, 'Finca La Esperanza');
      await _shot(tester, '$tag-11-finca-detalle');
      await goBack(tester);
      await goBack(tester);
      await tapText(tester, 'Trabajadores');
      await _shot(tester, '$tag-12-trabajadores');
      await goBack(tester);
      await tapText(tester, 'Eventos adversos');
      await _shot(tester, '$tag-13-eventos');
      await goBack(tester);
      await tapText(tester, 'Catálogo de cultivos');
      await _shot(tester, '$tag-14-cultivos');
      expect(_problems, isEmpty);
    });
  }

  testWidgets('capturas formularios', (tester) async {
    await _open(tester, 'admin', const Size(390, 1500));
    await tapText(tester, 'Registrar');
    await _shot(tester, 'extra-01-registro-rapido');
    await tapText(tester, 'Gasto');
    await _shot(tester, 'extra-02-form-gasto');
    await tester.tapAt(const Offset(5, 5));
    await settle(tester);
    await tapText(tester, 'Registrar');
    await tapText(tester, 'Labor con jornales');
    await _shot(tester, 'extra-03-form-labor');
    await tester.tapAt(const Offset(5, 5));
    await settle(tester);
    await tapText(tester, 'Producción');
    await tapText(tester, 'Café');
    await tapText(tester, 'Ciclos');
    await tapText(tester, 'Ciclo 1 · Levante');
    await _shot(tester, 'extra-04-ciclo');
    await goBack(tester);
    await goBack(tester);
    await tapText(tester, 'Más');
    await tapText(tester, 'Catálogo de cultivos');
    await tapText(tester, 'Café');
    await _shot(tester, 'extra-05-cultivo');
    await tapText(tester, 'Riesgos');
    await _shot(tester, 'extra-06-cultivo-riesgos');
    await goBack(tester);
    await goBack(tester);
    await tapText(tester, 'Eventos adversos');
    await tapText(tester, 'Helada');
    await _shot(tester, 'extra-07-evento');
    await goBack(tester);
    await goBack(tester);
    await tapText(tester, 'Mi cuenta');
    await _shot(tester, 'extra-08-cuenta');
    expect(_problems, isEmpty);
  });

  testWidgets('capturas pagos, inventario y procesos', (tester) async {
    await _open(tester, 'admin', const Size(390, 1500));
    await tapText(tester, 'Más');
    await tapText(tester, 'Pagos pendientes');
    await _shot(tester, 'nuevo-01-pagos');
    await tapText(tester, 'Por labor');
    await _shot(tester, 'nuevo-02-pagos-labor');
    await goBack(tester);
    await tapText(tester, 'Insumos e inventario');
    await _shot(tester, 'nuevo-03-inventario');
    await tapText(tester, 'Urea granulada 46%');
    await _shot(tester, 'nuevo-04-insumo');
    await goBack(tester);
    await goBack(tester);
    await tapText(tester, 'Procesos de transformación');
    await _shot(tester, 'nuevo-05-procesos');
    await tapText(tester, 'Secado de bijao lote 1');
    await _shot(tester, 'nuevo-06-proceso');
    expect(_problems, isEmpty);
  });
}
