import '../../../core/api/backend.dart';

class Worker {
  const Worker({
    required this.id,
    required this.name,
    required this.type,
    required this.dailyRate,
    required this.status,
    this.documentLast4,
    this.phone,
  });

  final String id;
  final String name;
  final String type;
  final double dailyRate;
  final String status;
  final String? documentLast4;
  final String? phone;

  factory Worker.fromJson(Json json) => Worker(
    id: json['id'] as String,
    name: json['nombre'] as String? ?? '',
    type: json['tipo'] as String? ?? '',
    dailyRate: double.tryParse('${json['jornal_habitual']}') ?? 0,
    status: json['estado'] as String? ?? 'activo',
    documentLast4: json['documento_ultimos4'] as String?,
    phone: json['telefono'] as String?,
  );

  String get maskedDocument =>
      documentLast4 == null ? 'Sin documento' : 'CC ****$documentLast4';

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }
}

class WorkersRepository {
  const WorkersRepository(this._backend);

  final Backend _backend;

  Future<List<Worker>> list(String farmId) async =>
      (await _backend.getList('fincas/$farmId/trabajadores'))
          .map(Worker.fromJson)
          .toList();

  Future<Worker> create(
    String farmId, {
    required String name,
    required String type,
    required double dailyRate,
    String? document,
    String? phone,
  }) async => Worker.fromJson(
    await _backend.post(
      'fincas/$farmId/trabajadores',
      body: {
        'nombre': name,
        'tipo': type,
        'jornal_habitual': dailyRate,
        'documento': ?document,
        'telefono': ?phone,
      },
    ),
  );

  Future<String> registerWork(
    String farmId, {
    required String cycleId,
    required String name,
    required String phase,
    required String date,
    required double workedArea,
    required double workers,
    required double days,
    required double dailyValue,
    String? workerId,
  }) async {
    final activity = await _backend.post(
      'fincas/$farmId/actividades',
      body: {
        'ciclo_id': cycleId,
        'nombre': name,
        'fase': phase,
        'fecha_inicio': date,
        'area_trabajada': workedArea,
      },
    );
    final activityId = activity['id'] as String;
    await _backend.post(
      'fincas/$farmId/jornales',
      idempotent: true,
      body: {
        'trabajador_id': ?workerId,
        'actividad_id': activityId,
        'ciclo_id': cycleId,
        'fecha': date,
        'obreros': workers,
        'dias': days,
        'valor_jornal': dailyValue,
      },
    );
    return activityId;
  }
}
