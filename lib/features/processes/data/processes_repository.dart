import '../../../core/api/backend.dart';

class ProcessItem {
  const ProcessItem({
    required this.id,
    required this.name,
    required this.product,
    required this.rawMaterial,
    required this.origin,
    required this.start,
    required this.stages,
    required this.stagesDone,
    this.end,
  });

  final String id;
  final String name;
  final String product;
  final String rawMaterial;
  final String origin;
  final String start;
  final String? end;
  final int stages;
  final int stagesDone;

  bool get finished => end != null;
  double get progress => stages == 0 ? 0 : stagesDone / stages;

  factory ProcessItem.fromJson(Json json) => ProcessItem(
    id: json['id'] as String,
    name: json['nombre'] as String? ?? '',
    product: json['producto'] as String? ?? '',
    rawMaterial: json['materia_prima'] as String? ?? '',
    origin: json['origen_materia'] as String? ?? '',
    start: json['fecha_inicio'] as String? ?? '',
    end: json['fecha_fin'] as String?,
    stages: (json['etapas'] as num?)?.toInt() ?? 0,
    stagesDone: (json['etapas_finalizadas'] as num?)?.toInt() ?? 0,
  );
}

class ProcessStage {
  const ProcessStage({
    required this.id,
    required this.name,
    required this.estimatedDays,
    this.startedAt,
    this.finishedAt,
  });

  final String id;
  final String name;
  final double estimatedDays;
  final String? startedAt;
  final String? finishedAt;

  bool get done => finishedAt != null;
  bool get running => startedAt != null && finishedAt == null;

  factory ProcessStage.fromJson(Json json) => ProcessStage(
    id: json['id'] as String,
    name: json['nombre'] as String? ?? '',
    estimatedDays: double.tryParse('${json['dias_estimados']}') ?? 0,
    startedAt: json['iniciado_en'] as String?,
    finishedAt: json['finalizado_en'] as String?,
  );
}

class ProcessesRepository {
  const ProcessesRepository(this._backend);

  final Backend _backend;

  Future<List<ProcessItem>> list(String farmId) async =>
      (await _backend.getList('fincas/$farmId/procesos'))
          .map(ProcessItem.fromJson)
          .toList();

  Future<List<ProcessStage>> stages(String farmId, String processId) async =>
      (await _backend.getList('fincas/$farmId/procesos/$processId/etapas'))
          .map(ProcessStage.fromJson)
          .toList();

  Future<void> create(
    String farmId, {
    required String name,
    required String product,
    required String rawMaterial,
    required String origin,
    required String start,
  }) => _backend.post(
    'fincas/$farmId/procesos',
    body: {
      'nombre': name,
      'producto': product,
      'materia_prima': rawMaterial,
      'origen_materia': origin,
      'fecha_inicio': start,
    },
  );

  Future<void> addStage(
    String farmId,
    String processId, {
    required String name,
    required double days,
  }) => _backend.post(
    'fincas/$farmId/procesos/$processId/etapas',
    body: {'nombre': name, 'dias_estimados': days},
  );

  Future<void> transition(String farmId, String stageId, String action) =>
      _backend.post('fincas/$farmId/etapas/$stageId/$action');
}
