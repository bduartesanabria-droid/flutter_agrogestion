/// Cuerpo de `POST /proyecciones/agricola`.
class ProyeccionRequest {
  const ProyeccionRequest({required this.cultivoId, required this.areaM2});

  final String cultivoId;
  final double areaM2;

  Map<String, dynamic> toJson() => {'cultivo_id': cultivoId, 'area_m2': areaM2};
}

/// Respuesta de `POST /proyecciones/agricola`. Todos los montos están en pesos.
class ProyeccionResponse {
  const ProyeccionResponse({
    required this.areaM2,
    required this.cultivoNombre,
    required this.plantasEstimadas,
    required this.mesesPrimeraCosecha,
    required this.cosechasPorAnio,
    required this.costoSemillaEstimado,
    required this.costoAbonoEstimado,
    required this.ingresoEstimadoAnual,
    required this.utilidadEstimadaAnual,
  });

  final double areaM2;
  final String cultivoNombre;
  final int plantasEstimadas;
  final int mesesPrimeraCosecha;
  final double cosechasPorAnio;
  final double costoSemillaEstimado;
  final double costoAbonoEstimado;
  final double ingresoEstimadoAnual;
  final double utilidadEstimadaAnual;

  /// Costo de establecimiento: semilla más abono.
  double get costoTotal => costoSemillaEstimado + costoAbonoEstimado;

  factory ProyeccionResponse.fromJson(Map<String, dynamic> json) {
    return ProyeccionResponse(
      areaM2: _leerDecimal(json, 'area_m2'),
      cultivoNombre: json['cultivo_nombre'] as String,
      plantasEstimadas: _leerEntero(json, 'plantas_estimadas'),
      mesesPrimeraCosecha: _leerEntero(json, 'meses_primera_cosecha'),
      cosechasPorAnio: _leerDecimal(json, 'cosechas_por_anio'),
      costoSemillaEstimado: _leerDecimal(json, 'costo_semilla_estimado'),
      costoAbonoEstimado: _leerDecimal(json, 'costo_abono_estimado'),
      ingresoEstimadoAnual: _leerDecimal(json, 'ingreso_estimado_anual'),
      utilidadEstimadaAnual: _leerDecimal(json, 'utilidad_estimada_anual'),
    );
  }

  Map<String, dynamic> toJson() => {
    'area_m2': areaM2,
    'cultivo_nombre': cultivoNombre,
    'plantas_estimadas': plantasEstimadas,
    'meses_primera_cosecha': mesesPrimeraCosecha,
    'cosechas_por_anio': cosechasPorAnio,
    'costo_semilla_estimado': costoSemillaEstimado,
    'costo_abono_estimado': costoAbonoEstimado,
    'ingreso_estimado_anual': ingresoEstimadoAnual,
    'utilidad_estimada_anual': utilidadEstimadaAnual,
  };
}

/// La API acepta enteros o decimales; aquí se normalizan a double.
double _leerDecimal(Map<String, dynamic> json, String clave) =>
    (json[clave] as num).toDouble();

int _leerEntero(Map<String, dynamic> json, String clave) =>
    (json[clave] as num).toInt();

class CultivoOpcion {
  const CultivoOpcion({required this.id, required this.nombre});

  final String id;
  final String nombre;
}

/// Catálogo provisional para la pantalla. El backend exige un UUID existente en
/// la tabla de cultivos: reemplace estos IDs por los de `GET /cultivos`.
const cultivosDemo = <CultivoOpcion>[
  CultivoOpcion(id: '00000000-0000-0000-0000-000000000001', nombre: 'Café'),
  CultivoOpcion(id: '00000000-0000-0000-0000-000000000002', nombre: 'Plátano'),
  CultivoOpcion(id: '00000000-0000-0000-0000-000000000003', nombre: 'Maíz'),
];
