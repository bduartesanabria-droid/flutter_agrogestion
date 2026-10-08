import '../../../core/api/backend.dart';
import '../../production/domain/production.dart';

class RecentEvent {
  const RecentEvent({
    required this.id,
    required this.risk,
    required this.severity,
    required this.start,
  });

  final String id;
  final String risk;
  final String severity;
  final String start;

  factory RecentEvent.fromJson(Json json) => RecentEvent(
    id: json['id'] as String,
    risk: json['riesgo'] as String? ?? '',
    severity: json['severidad'] as String? ?? '',
    start: json['inicio'] as String? ?? '',
  );
}

class HomeOverview {
  const HomeOverview({
    required this.farms,
    required this.activePlantings,
    required this.plannedPlantings,
    required this.notices,
    required this.recentEvents,
    required this.firstSteps,
  });

  final int farms;
  final int activePlantings;
  final int plannedPlantings;
  final List<RiskNotice> notices;
  final List<RecentEvent> recentEvents;
  final List<String> firstSteps;

  factory HomeOverview.fromJson(Json json) => HomeOverview(
    farms: (json['fincas'] as num?)?.toInt() ?? 0,
    activePlantings: (json['siembras_en_curso'] as num?)?.toInt() ?? 0,
    plannedPlantings: (json['siembras_planeadas'] as num?)?.toInt() ?? 0,
    notices: (json['avisos'] as List? ?? const [])
        .whereType<Json>()
        .map(RiskNotice.fromJson)
        .toList(),
    recentEvents: (json['eventos_recientes'] as List? ?? const [])
        .whereType<Json>()
        .map(RecentEvent.fromJson)
        .toList(),
    firstSteps: (json['primeros_pasos'] as List? ?? const [])
        .whereType<String>()
        .toList(),
  );
}

class HomeRepository {
  const HomeRepository(this._backend);

  final Backend _backend;

  Future<HomeOverview> overview() async =>
      HomeOverview.fromJson(await _backend.getJson('inicio'));
}
