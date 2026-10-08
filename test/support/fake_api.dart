import 'dart:convert';

import 'package:agrogestion/core/api/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const farmId = 'f0000000-0000-4000-8000-000000000001';
const lotId = 'l0000000-0000-4000-8000-000000000001';
const lotId2 = 'l0000000-0000-4000-8000-000000000002';
const cropId = 'c0000000-0000-4000-8000-000000000001';
const cropId2 = 'c0000000-0000-4000-8000-000000000002';
const plantingId = 's0000000-0000-4000-8000-000000000001';
const cycleId = 'y0000000-0000-4000-8000-000000000001';
const riskId = 'r0000000-0000-4000-8000-000000000001';
const eventId = 'e0000000-0000-4000-8000-000000000001';

const roles = ['admin', 'agricultor', 'contador', 'experto'];

List<Map<String, String>> _permissions(String role) {
  Map<String, String> p(String method, String route) => {
    'grupo': 'x',
    'metodo': method,
    'ruta': route,
    'resumen': 'x',
  };
  final base = [p('GET', '/auth/me'), p('GET', '/glosario')];
  final lists = [
    p('GET', '/fincas/{finca_id}/jornales'),
    p('GET', '/fincas/{finca_id}/insumos'),
    p('GET', '/fincas/{finca_id}/procesos'),
  ];
  return switch (role) {
    'admin' => [
      ...base,
      p('GET', '/siembras'),
      p('POST', '/siembras'),
      p('GET', '/cultivos'),
      p('GET', '/eventos-adversos'),
      p('GET', '/consultas'),
      p('POST', '/usuarios'),
      ...lists,
    ],
    'agricultor' => [
      ...base,
      p('GET', '/siembras'),
      p('POST', '/siembras'),
      p('GET', '/cultivos'),
      p('GET', '/eventos-adversos'),
      p('GET', '/consultas'),
      ...lists,
    ],
    'contador' => [...base, p('GET', '/siembras'), ...lists],
    _ => base,
  };
}

Map<String, dynamic> farm({String name = 'Finca La Esperanza'}) => {
  'id': farmId,
  'nombre': name,
  'departamento_dane': '05',
  'municipio_dane': '05001',
  'area_ha': '18.5000',
};

Map<String, dynamic> planting({String status = 'en_curso'}) => {
  'id': plantingId,
  'finca_id': farmId,
  'lote_id': lotId,
  'cultivo_id': cropId,
  'metodo': 'semilla',
  'area_ha': 4.5,
  'plantas_sembradas': 18000,
  'fecha_plan': '2026-08-01',
  'estado': status,
};

Map<String, dynamic> plantingDetail() => {
  ...planting(),
  'presupuesto': 15000000.0,
  'ciclos': [
    {
      'id': cycleId,
      'tipo': 'levante',
      'numero': 1,
      'estado': 'abierto',
      'fecha_inicio': '2026-08-01',
      'fecha_fin': null,
      'motivo_perdida': null,
    },
  ],
};

Map<String, dynamic> _jornal(
  String id,
  String? worker,
  String activity,
  num workers,
  num days,
  num value, {
  bool paid = false,
}) => {
  'id': id,
  'trabajador_id': worker == null ? null : 'w-$id',
  'trabajador_nombre': worker,
  'actividad_id': 'act-1',
  'actividad_nombre': activity,
  'ciclo_id': cycleId,
  'fecha': '2026-10-05T08:00:00',
  'obreros': '$workers',
  'dias': '$days',
  'valor_jornal': '$value',
  'modalidad': 'jornal',
  'total': '${workers * days * value}',
  'estado': paid ? 'pagado' : 'pendiente',
  'pagado_en': paid ? '2026-10-06T08:00:00' : null,
};

Map<String, dynamic> _proceso(
  String id,
  String name,
  int stages,
  int done,
  String? end,
) => {
  'id': id,
  'nombre': name,
  'producto': 'Producto seco',
  'materia_prima': 'Hoja de bijao',
  'origen_materia': 'propia',
  'fecha_inicio': '2026-09-28T08:00:00',
  'fecha_fin': end,
  'etapas': stages,
  'etapas_finalizadas': done,
  'estado': end == null ? 'en_proceso' : 'terminado',
};

Map<String, dynamic> _etapa(
  String id,
  String name,
  num days,
  String? start,
  String? end,
) => {
  'id': id,
  'proceso_id': 'p1',
  'finca_id': farmId,
  'nombre': name,
  'dias_estimados': '$days',
  'iniciado_en': start,
  'finalizado_en': end,
};

List<Map<String, dynamic>> _phases() => [
  {
    'fase': 'preparacion',
    'orden': 1,
    'dias_estimados': 30,
    'por_validar': true,
  },
  {'fase': 'siembra', 'orden': 2, 'dias_estimados': 15, 'por_validar': true},
  {
    'fase': 'mantenimiento',
    'orden': 3,
    'dias_estimados': 120,
    'por_validar': true,
  },
  {'fase': 'cosecha', 'orden': 4, 'dias_estimados': 60, 'por_validar': true},
];

Map<String, dynamic> _page(List<Map<String, dynamic>> items) => {
  'items': items,
  'total': items.length,
  'page': 1,
  'size': 50,
  'has_more': false,
};

class FakeBackend {
  FakeBackend({
    this.consentAccepted = true,
    this.farms,
    this.failPaths = const {},
  });

  bool consentAccepted;
  List<Map<String, dynamic>>? farms;
  final Set<String> failPaths;
  final List<String> calls = [];

  String? _role(http.Request request) {
    final header = request.headers['authorization'] ?? '';
    if (!header.startsWith('Bearer token-')) return null;
    return header.substring('Bearer token-'.length);
  }

  http.Response _json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  Future<http.Response> handle(http.Request request) async {
    final path = request.url.path.replaceFirst(RegExp(r'^/'), '');
    final method = request.method;
    calls.add('$method $path');
    if (failPaths.contains(path)) {
      return _json({
        'error': {'code': 'ERROR', 'message': 'Fallo de prueba.'},
      }, 500);
    }
    if (path == 'auth/login' && method == 'POST') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final email = '${body['email']}';
      final role = email.split('@').first;
      if (!roles.contains(role) || body['password'] != '1234') {
        return _json({
          'error': {
            'code': 'CREDENCIALES_INVALIDAS',
            'message': 'El correo o la contraseña no son válidos.',
          },
        }, 401);
      }
      return _json({'access_token': 'token-$role', 'rol': role});
    }
    if (path == 'politica') {
      return _json({
        'version': '2026-09',
        'estado': 'vigente',
        'datos_que_usamos': ['Su nombre y correo, para identificarlo.'],
        'para_que': ['Para operar la aplicación.'],
        'sus_derechos': ['Conocer, actualizar y rectificar sus datos.'],
      });
    }
    final role = _role(request);
    if (role == null) {
      return _json({
        'error': {'code': 'NO_AUTENTICADO', 'message': 'Debe autenticarse.'},
      }, 401);
    }
    if (method == 'POST' &&
        path.startsWith('fincas/$farmId/jornales/') &&
        path.endsWith('/pagar')) {
      return _json({});
    }
    switch (path) {
      case 'auth/me':
        return _json({
          'id': 'u-$role',
          'email': '$role@demo.com',
          'nombre': switch (role) {
            'admin' => 'Administrador local',
            'agricultor' => 'Hernando Gómez Restrepo',
            'contador' => 'Contadora de prueba',
            _ => 'Experto de prueba',
          },
          'rol': role,
          'activo': true,
          'fincas': role == 'experto' ? <String>[] : [farmId],
          'permisos': _permissions(role),
        });
      case 'cuenta/consentimiento':
        if (method == 'POST') {
          consentAccepted = true;
          return _json({'version_politica': '2026-09'});
        }
        return consentAccepted
            ? _json({
                'version_politica': '2026-09',
                'aceptado_en': '2026-10-01T10:00:00',
                'acepta_transferencia_ia': false,
              })
            : _json({
                'error': {
                  'code': 'CONSENTIMIENTO_PENDIENTE',
                  'message': 'Aún no ha aceptado.',
                },
              }, 404);
      case 'fincas':
        if (method == 'POST') return _json(farm(), 201);
        return _json(farms ?? [farm()]);
      case 'fincas/$farmId/lotes':
        if (method == 'POST') return _json({}, 201);
        return _json([
          {
            'id': lotId,
            'finca_id': farmId,
            'nombre': 'Lote 4B La Ceiba',
            'area': '4.5000',
            'notas': null,
          },
          {
            'id': lotId2,
            'finca_id': farmId,
            'nombre': 'Lote 2 El Mirador',
            'area': '3.2000',
            'notas': null,
          },
        ]);
      case 'inicio':
        return _json({
          'fincas': 1,
          'siembras_en_curso': 1,
          'siembras_planeadas': 0,
          'avisos': [
            {
              'siembra_id': plantingId,
              'ciclo_id': cycleId,
              'cultivo': 'Café',
              'fase': 'siembra',
              'riesgo': 'Helada',
              'susceptibilidad': 'alta',
              'medidas': 'Proteja las plantas jóvenes de la helada.',
              'por_validar': true,
              'texto': 'Su Café está en la fase de siembra. El riesgo de helada es alta en esta fase.',
            },
          ],
          'eventos_recientes': [
            {
              'id': eventId,
              'riesgo': 'Helada',
              'severidad': 'moderada',
              'inicio': '2026-09-27',
            },
          ],
          'primeros_pasos': <String>[],
        });
      case 'siembras':
        return _json(_page([planting()]));
      case 'siembras/$plantingId':
        return _json(plantingDetail());
      case 'siembras/$plantingId/conteos':
        if (method == 'POST') return _json({}, 201);
        return _json([
          {
            'id': 'k1',
            'fecha': '2026-10-02',
            'vivas': 17100,
            'muertas': 900,
            'resiembras': 0,
          },
        ]);
      case 'siembras/$plantingId/indices':
        return _json({
          'siembra_id': plantingId,
          'fecha_conteo': '2026-10-02',
          'indicadores': [
            {
              'titulo': 'Plantas por hectárea',
              'valor': 3800.0,
              'unidad': 'plantas por hectárea',
              'explicacion': 'Son las plantas vivas del último conteo divididas entre el área sembrada.',
              'estado': 'informativo',
              'que_hacer': null,
              'fecha_datos': '2026-10-02',
            },
            {
              'titulo': 'Plantas perdidas',
              'valor': 5.0,
              'unidad': 'por ciento',
              'explicacion': 'De 18000 plantas sembradas hoy hay 17100 vivas.',
              'estado': 'informativo',
              'que_hacer':
                  'Si el número sube, revise la causa y considere resembrar.',
              'fecha_datos': '2026-10-02',
            },
          ],
          'aviso': null,
        });
      case 'ciclos/$cycleId':
        return _json(plantingDetail()['ciclos'][0] as Map<String, dynamic>);
      case 'ciclos/$cycleId/cronograma':
        return _json({
          'ciclo_id': cycleId,
          'tipo': 'levante',
          'fecha_inicio': '2026-08-01',
          'fases': [
            {
              'fase': 'preparacion',
              'orden': 1,
              'dias_estimados': 30,
              'por_validar': true,
              'inicio_plan': '2026-08-01',
              'fin_plan': '2026-08-31',
              'inicio_real': '2026-08-01',
              'fin_real': '2026-08-30',
              'dias_retraso': 0,
            },
            {
              'fase': 'siembra',
              'orden': 2,
              'dias_estimados': 15,
              'por_validar': true,
              'inicio_plan': '2026-08-31',
              'fin_plan': '2026-09-15',
              'inicio_real': '2026-08-31',
              'fin_real': null,
              'dias_retraso': 4,
            },
            {
              'fase': 'mantenimiento',
              'orden': 3,
              'dias_estimados': 120,
              'por_validar': true,
              'inicio_plan': '2026-09-15',
              'fin_plan': '2027-01-13',
              'inicio_real': null,
              'fin_real': null,
              'dias_retraso': null,
            },
          ],
          'aviso': null,
        });
      case 'ciclos/$cycleId/necesidad-insumos':
        return _json({
          'ciclo_id': cycleId,
          'items': [],
          'aviso': 'Falta cargar las dosis.',
        });
      case 'fincas/$farmId/actividades':
        if (method == 'POST') return _json({'id': 'act-1'}, 201);
        return _json([
          {
            'id': 'act-1',
            'finca_id': farmId,
            'ciclo_id': cycleId,
            'nombre': 'Socola y limpieza selectiva del lote',
            'fase': 'preparacion',
            'fecha_inicio': '2026-08-05',
            'fecha_fin': null,
            'area_trabajada': '4.5000',
            'estado': 'en_curso',
          },
        ]);
      case 'fincas/$farmId/cosechas':
        return _json({}, 201);
      case 'cultivos':
        return _json(
          _page([
            {
              'id': cropId,
              'nombre': 'Café',
              'grupo': 'plantación',
              'tipo_ciclo': 'permanente',
              'unidad_conteo': 'planta',
              'por_validar': true,
            },
            {
              'id': cropId2,
              'nombre': 'Plátano Dominico Hartón de la región',
              'grupo': 'fruta',
              'tipo_ciclo': 'semipermanente',
              'unidad_conteo': 'planta',
              'por_validar': false,
            },
          ]),
        );
      case 'cultivos/$cropId':
        return _json({
          'id': cropId,
          'nombre': 'Café',
          'grupo': 'plantación',
          'tipo_ciclo': 'permanente',
          'unidad_conteo': 'planta',
          'por_validar': true,
          'nombre_cientifico': 'Coffea arabica',
          'tipo_renovacion': 'zoca',
          'unidad_cosecha': 'kilo',
          'fuente': 'Estructura inicial del equipo.',
          'fases': _phases(),
        });
      case 'cultivos/$cropId/metodos':
        return _json([
          {
            'metodo': 'semilla',
            'dias_germinacion': 30,
            'dias_vivero': 180,
            'por_validar': true,
          },
        ]);
      case 'cultivos/$cropId/dosis':
        return _json(<Object>[]);
      case 'cultivos/$cropId/riesgos':
        return _json([
          {
            'riesgo_id': riskId,
            'fase_critica': 'siembra',
            'susceptibilidad': 'alta',
            'medidas': 'Proteja las plantas jóvenes de la helada.',
            'por_validar': true,
          },
        ]);
      case 'riesgos':
        return _json([
          {
            'id': riskId,
            'nombre': 'Helada',
            'tipo': 'clima',
            'aplica_a': 'ambos',
          },
          {
            'id': 'r2',
            'nombre': 'Broca del café',
            'tipo': 'plaga',
            'aplica_a': 'cultivo',
          },
        ]);
      case 'eventos-adversos':
        if (method == 'POST') return _json({}, 201);
        return _json(
          _page([
            {
              'id': eventId,
              'finca_id': farmId,
              'riesgo_id': riskId,
              'siembra_id': plantingId,
              'ciclo_id': null,
              'inicio': '2026-09-27',
              'fin': null,
              'severidad': 'moderada',
              'area_afectada': 1.2,
              'perdida_pct': 12.0,
              'perdida_estimada': 1850000.0,
              'notas': 'Defoliación del dosel por granizada.',
            },
          ]),
        );
      case 'fincas/$farmId/flujo-caja':
        return _json({
          'finca_id': farmId,
          'ciclo_id': null,
          'anio': 2026,
          'mes': 10,
          'ingresos': '14850000.00',
          'gastos': '6450000.00',
          'saldo': '8400000.00',
        });
      case 'fincas/$farmId/gastos':
        if (method == 'POST') return _json({}, 201);
        return _json([
          {
            'id': 'g1000000-0000-4000-8000-000000000001',
            'finca_id': farmId,
            'categoria': 'Mano de obra',
            'monto': '3741000.00',
            'total': null,
            'estado': 'activo',
          },
          {
            'id': 'g1000000-0000-4000-8000-000000000002',
            'finca_id': farmId,
            'categoria': 'Insumos y fertilizantes',
            'monto': '1548000.00',
            'total': null,
            'estado': 'activo',
          },
          {
            'id': 'g1000000-0000-4000-8000-000000000003',
            'finca_id': farmId,
            'categoria': 'Compra de urea equivocada',
            'monto': '215000.00',
            'total': null,
            'estado': 'anulado',
          },
        ]);
      case 'fincas/$farmId/ingresos':
        if (method == 'POST') return _json({}, 201);
        return _json([
          {
            'id': 'i1000000-0000-4000-8000-000000000001',
            'finca_id': farmId,
            'categoria': 'Venta de cosecha',
            'monto': null,
            'total': '14850000.00',
            'estado': 'activo',
          },
        ]);
      case 'fincas/$farmId/trabajadores':
        if (method == 'POST') return _json({}, 201);
        return _json([
          {
            'id': 'w1',
            'finca_id': farmId,
            'nombre': 'Pedro Nel Builes',
            'tipo': 'jornalero',
            'jornal_habitual': '90000.00',
            'documento_ultimos4': '5831',
            'telefono': '3125550450',
            'estado': 'activo',
          },
          {
            'id': 'w2',
            'finca_id': farmId,
            'nombre': 'Juan Camilo Henao Zuluaga de los Ríos',
            'tipo': 'contratista',
            'jornal_habitual': '1250000.00',
            'documento_ultimos4': null,
            'telefono': null,
            'estado': 'activo',
          },
        ]);
      case 'fincas/$farmId/jornales':
        if (method == 'POST') return _json({}, 201);
        final status = request.url.queryParameters['estado'];
        final all = [
          _jornal(
            'j1',
            'Pedro Nel Builes',
            'Socola y limpia Lote 2',
            2,
            3,
            90000,
          ),
          _jornal('j2', null, 'Ahoyado y siembra', 4, 2, 60000),
          _jornal(
            'j3',
            'Juan Camilo Henao Zuluaga de los Ríos',
            'Plateo y abono del Lote 4B',
            1,
            6,
            90000,
          ),
          _jornal(
            'j4',
            'Rosa Helena Gómez',
            'Desyerbe',
            1,
            4,
            80000,
            paid: true,
          ),
        ];
        return _json(
          status == null
              ? all
              : all.where((j) => j['estado'] == status).toList(),
        );
      case 'fincas/$farmId/insumos':
        if (method == 'POST') return _json({}, 201);
        return _json([
          {
            'id': 'in1',
            'nombre': 'Urea granulada 46%',
            'unidad': 'bulto',
            'existencia': '12.00',
            'costo_promedio': '185000.00',
            'valor': '2220000.00',
            'ultimo_movimiento': '2026-10-08T10:00:00',
            'estado': 'activo',
          },
          {
            'id': 'in2',
            'nombre': 'Machete Collins 22 pulgadas para desmonte manual',
            'unidad': 'unidad',
            'existencia': '0.00',
            'costo_promedio': null,
            'valor': '0.00',
            'ultimo_movimiento': null,
            'estado': 'activo',
          },
        ]);
      case 'fincas/$farmId/insumos/entrada':
      case 'fincas/$farmId/insumos/consumo':
        return _json({}, 200);
      case 'fincas/$farmId/movimientos-insumo':
        return _json([
          {
            'id': 'm1',
            'finca_id': farmId,
            'insumo_id': 'in1',
            'actividad_id': null,
            'tipo': 'entrada',
            'cantidad': '14.00',
            'costo': '2590000.00',
            'fecha': '2026-10-01T10:00:00',
            'creado_por': 'u',
          },
          {
            'id': 'm2',
            'finca_id': farmId,
            'insumo_id': 'in1',
            'actividad_id': 'act-1',
            'tipo': 'consumo',
            'cantidad': '2.00',
            'costo': '0.00',
            'fecha': '2026-10-05T10:00:00',
            'creado_por': 'u',
          },
        ]);
      case 'fincas/$farmId/procesos':
        if (method == 'POST') return _json({}, 201);
        return _json([
          _proceso('p1', 'Secado de bijao lote 1', 3, 1, null),
          _proceso(
            'p2',
            'Beneficio de café pergamino',
            2,
            2,
            '2026-09-20T10:00:00',
          ),
        ]);
      case 'fincas/$farmId/procesos/p1/etapas':
        if (method == 'POST') return _json({}, 201);
        return _json([
          _etapa(
            'e1',
            'Cocinar',
            1,
            '2026-10-01T08:00:00',
            '2026-10-01T18:00:00',
          ),
          _etapa('e2', 'Secar al sol', 5, '2026-10-02T08:00:00', null),
          _etapa('e3', 'Recoger y empacar', 1, null, null),
        ]);
      case 'fincas/$farmId/etapas/e2/finalizar':
      case 'fincas/$farmId/etapas/e3/iniciar':
        return _json({});
      case 'glosario':
        return _json([
          {
            'id': 'gl1',
            'termino': 'Jornal',
            'explicacion': 'Día de trabajo de una persona en el campo.',
            'categoria': 'mano_de_obra',
          },
          {
            'id': 'gl2',
            'termino': 'Soqueo',
            'explicacion':
                'Corte del cultivo para que rebrote y se renueve la planta.',
            'categoria': 'renovación',
          },
        ]);
      case 'noticias':
        return _json(
          _page([
            {
              'id': 'n1',
              'titulo': 'Alerta de lluvias en su región',
              'resumen':
                  'Se esperan lluvias fuertes esta semana en el suroeste.',
              'enlace': 'https://ejemplo.test/noticia',
              'fuente': 'Fuente de ejemplo',
              'region_dane': '05',
              'cultivo_id': null,
              'publicada': '2026-10-07T10:00:00',
              'vigente_hasta': DateTime.now()
                  .add(const Duration(days: 6, hours: 12))
                  .toIso8601String(),
            },
          ]),
        );
      case 'conocimiento':
        return _json(
          _page([
            {
              'id': 'p1',
              'nombre': 'Manchas amarillas en la hoja',
              'tipo': 'enfermedad',
              'cultivo_id': cropId,
              'estado': 'validado',
            },
          ]),
        );
      case 'conocimiento/p1':
        return _json({
          'id': 'p1',
          'nombre': 'Manchas amarillas en la hoja',
          'tipo': 'enfermedad',
          'cultivo_id': cropId,
          'estado': 'validado',
          'causa': 'Hongo favorecido por la humedad.',
          'sintomas': [
            {
              'descripcion': 'Manchas amarillas en el envés.',
              'parte': 'hoja',
              'fase_o_edad': 'adulta',
            },
          ],
          'manejos': [
            {
              'tipo': 'cultural',
              'descripcion': 'Mejore la aireación.',
              'producto_ica': null,
              'fuente': null,
            },
          ],
          'aviso': 'Consulte con asistencia técnica.',
          'validaciones': <Object>[],
        });
    }
    return _json({
      'error': {'code': 'NO_ENCONTRADO', 'message': 'No existe: $path'},
    }, 404);
  }

  ApiClient client() =>
      ApiClient(baseUrl: 'http://api.test', client: MockClient(handle));
}
