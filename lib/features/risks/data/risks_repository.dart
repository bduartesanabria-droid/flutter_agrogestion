import '../../../core/api/backend.dart';

class RiskType {
  const RiskType({required this.id, required this.name, required this.type});

  final String id;
  final String name;
  final String type;

  factory RiskType.fromJson(Json json) => RiskType(
    id: json['id'] as String,
    name: json['nombre'] as String? ?? '',
    type: json['tipo'] as String? ?? '',
  );
}

class AdverseEvent {
  const AdverseEvent({
    required this.id,
    required this.riskId,
    required this.start,
    required this.severity,
    this.plantingId,
    this.end,
    this.affectedArea,
    this.lossPercent,
    this.estimatedLoss,
    this.notes,
  });

  final String id;
  final String riskId;
  final String? plantingId;
  final String start;
  final String? end;
  final String severity;
  final double? affectedArea;
  final double? lossPercent;
  final double? estimatedLoss;
  final String? notes;

  bool get active => end == null;

  factory AdverseEvent.fromJson(Json json) => AdverseEvent(
    id: json['id'] as String,
    riskId: json['riesgo_id'] as String,
    plantingId: json['siembra_id'] as String?,
    start: json['inicio'] as String? ?? '',
    end: json['fin'] as String?,
    severity: json['severidad'] as String? ?? '',
    affectedArea: (json['area_afectada'] as num?)?.toDouble(),
    lossPercent: (json['perdida_pct'] as num?)?.toDouble(),
    estimatedLoss: (json['perdida_estimada'] as num?)?.toDouble(),
    notes: json['notas'] as String?,
  );
}

class RisksRepository {
  const RisksRepository(this._backend);

  final Backend _backend;

  Future<List<RiskType>> catalog() async =>
      (await _backend.getList('riesgos')).map(RiskType.fromJson).toList();

  Future<List<AdverseEvent>> events() async {
    final page = await _backend.getPage(
      'eventos-adversos',
      query: {'limit': '50'},
    );
    return page.items.map(AdverseEvent.fromJson).toList();
  }

  Future<AdverseEvent> event(String id) async =>
      AdverseEvent.fromJson(await _backend.getJson('eventos-adversos/$id'));

  Future<void> create({
    required String farmId,
    required String riskId,
    required String start,
    required String severity,
    String? plantingId,
    double? affectedArea,
    double? estimatedLoss,
    String? notes,
  }) => _backend.post(
    'eventos-adversos',
    body: {
      'finca_id': farmId,
      'riesgo_id': riskId,
      'inicio': start,
      'severidad': severity,
      'siembra_id': ?plantingId,
      'area_afectada': ?affectedArea,
      'perdida_estimada': ?estimatedLoss,
      'notas': ?notes,
    },
  );

  Future<void> close(String id, String end) =>
      _backend.patch('eventos-adversos/$id', body: {'fin': end});
}
