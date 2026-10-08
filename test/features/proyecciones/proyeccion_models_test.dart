import 'package:agrogestion/features/proyecciones/domain/proyeccion_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ProyeccionRequest serializa cultivo_id y area_m2', () {
    const request = ProyeccionRequest(cultivoId: 'abc-123', areaM2: 10000);
    expect(request.toJson(), {'cultivo_id': 'abc-123', 'area_m2': 10000.0});
  });

  test(
    'ProyeccionResponse lee la respuesta de la API y calcula el costo total',
    () {
      final respuesta = ProyeccionResponse.fromJson({
        'area_m2': 10000.0,
        'cultivo_nombre': 'Café',
        'plantas_estimadas': 5000,
        'meses_primera_cosecha': 18,
        'cosechas_por_anio': 1.0,
        'costo_semilla_estimado': 7500000.0,
        'costo_abono_estimado': 10000000.0,
        'ingreso_estimado_anual': 150000000.0,
        'utilidad_estimada_anual': 132500000.0,
      });

      expect(respuesta.cultivoNombre, 'Café');
      expect(respuesta.plantasEstimadas, 5000);
      expect(respuesta.mesesPrimeraCosecha, 18);
      expect(respuesta.costoTotal, 17500000.0);
      expect(respuesta.utilidadEstimadaAnual, 132500000.0);
      expect(respuesta.toJson()['plantas_estimadas'], 5000);
    },
  );
}
