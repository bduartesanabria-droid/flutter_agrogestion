import '../../../core/api/backend.dart';
import '../domain/production.dart';

class PlantingList {
  const PlantingList(this.items, this.total);

  final List<Planting> items;
  final int total;
}

class PlantingOverview {
  const PlantingOverview({
    required this.planting,
    required this.counts,
    required this.indicators,
    required this.schedule,
  });

  final Planting planting;
  final List<PlantCount> counts;
  final List<Indicator> indicators;
  final List<ScheduledPhase> schedule;
}

class OpenCycleOption {
  const OpenCycleOption(this.planting, this.cycle);

  final Planting planting;
  final Cycle cycle;
}

class ProductionRepository {
  const ProductionRepository(this._backend);

  final Backend _backend;

  Future<List<Crop>> crops({String? search}) async {
    final page = await _backend.getPage(
      'cultivos',
      query: {
        'limit': '50',
        if (search != null && search.isNotEmpty) 'q': search,
      },
    );
    return page.items.map(Crop.fromJson).toList();
  }

  Future<CropDetail> cropDetail(String id) async =>
      CropDetail.fromJson(await _backend.getJson('cultivos/$id'));

  Future<List<PropagationMethod>> cropMethods(String id) async =>
      (await _backend.getList('cultivos/$id/metodos'))
          .map(PropagationMethod.fromJson)
          .toList();

  Future<List<CropRisk>> cropRisks(String id) async =>
      (await _backend.getList('cultivos/$id/riesgos'))
          .map(CropRisk.fromJson)
          .toList();

  Future<List<Json>> cropDoses(String id) =>
      _backend.getList('cultivos/$id/dosis');

  Future<Map<String, String>> riskNames() async {
    final list = await _backend.getList('riesgos');
    return {for (final r in list) r['id'] as String: r['nombre'] as String};
  }

  Future<PlantingList> plantings() async {
    final page = await _backend.getPage('siembras', query: {'limit': '50'});
    return PlantingList(page.items.map(Planting.fromJson).toList(), page.total);
  }

  Future<PlantingOverview> overview(String plantingId) async {
    final planting = Planting.fromJson(
      await _backend.getJson('siembras/$plantingId'),
    );
    final counts = await _optionalList('siembras/$plantingId/conteos');
    final indices = await _optionalJson('siembras/$plantingId/indices');
    final open = planting.openCycle;
    final schedule = open == null
        ? null
        : await _optionalJson('ciclos/${open.id}/cronograma');
    return PlantingOverview(
      planting: planting,
      counts: counts.map(PlantCount.fromJson).toList(),
      indicators: ((indices?['indicadores'] as List?) ?? const [])
          .whereType<Json>()
          .map(Indicator.fromJson)
          .toList(),
      schedule:
          ((schedule?['fases'] as List?) ?? const [])
              .whereType<Json>()
              .map(ScheduledPhase.fromJson)
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order)),
    );
  }

  Future<Planting> createPlanting({
    required String farmId,
    required String lotId,
    required String cropId,
    required String method,
    required double areaHa,
    required String planDate,
    int? plants,
    double? budget,
  }) async {
    final response = await _backend.post(
      'siembras',
      body: {
        'finca_id': farmId,
        'lote_id': lotId,
        'cultivo_id': cropId,
        'metodo': method,
        'area_ha': areaHa,
        'fecha_plan': planDate,
        'plantas_sembradas': ?plants,
        'presupuesto': ?budget,
      },
    );
    return Planting.fromJson(response);
  }

  Future<void> startPlanting(String id) =>
      _backend.post('siembras/$id/iniciar');

  Future<void> cancelPlanting(String id) =>
      _backend.post('siembras/$id/cancelar');

  Future<void> addCount(
    String plantingId, {
    required String date,
    required int alive,
    required int dead,
    int replanted = 0,
  }) => _backend.post(
    'siembras/$plantingId/conteos',
    body: {
      'fecha': date,
      'vivas': alive,
      'muertas': dead,
      'resiembras': replanted,
    },
  );

  Future<void> closeCycle(String cycleId, {String? lossReason}) =>
      _backend.post(
        'ciclos/$cycleId/cerrar',
        body: lossReason == null ? null : {'motivo_perdida': lossReason},
      );

  Future<List<Activity>> activities(String farmId) async =>
      (await _backend.getList('fincas/$farmId/actividades'))
          .map(Activity.fromJson)
          .toList();

  Future<Cycle> cycle(String cycleId) async =>
      Cycle.fromJson(await _backend.getJson('ciclos/$cycleId'));

  Future<List<ScheduledPhase>> cycleSchedule(String cycleId) async {
    final data = await _backend.getJson('ciclos/$cycleId/cronograma');
    return ((data['fases'] as List?) ?? const [])
        .whereType<Json>()
        .map(ScheduledPhase.fromJson)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  Future<List<SupplyNeed>> supplyNeeds(String cycleId) async {
    final data = await _backend.getJson('ciclos/$cycleId/necesidad-insumos');
    return ((data['items'] as List?) ?? const [])
        .whereType<Json>()
        .map(SupplyNeed.fromJson)
        .toList();
  }

  Future<void> openNextCycle(String plantingId, String type) =>
      _backend.post('siembras/$plantingId/ciclos', body: {'tipo': type});

  Future<void> createHarvest(
    String farmId, {
    required String cycleId,
    required double quantity,
    required String unit,
    required String date,
    String? quality,
  }) => _backend.post(
    'fincas/$farmId/cosechas',
    queueAs: 'Cosecha',
    body: {
      'ciclo_id': cycleId,
      'cantidad': quantity,
      'unidad': unit,
      'fecha': date,
      'calidad': ?quality,
    },
  );

  Future<List<OpenCycleOption>> openCycles(String farmId) async {
    final list = await plantings();
    final options = <OpenCycleOption>[];
    for (final planting in list.items) {
      if (planting.farmId != farmId || planting.status != 'en_curso') continue;
      final detail = Planting.fromJson(
        await _backend.getJson('siembras/${planting.id}'),
      );
      final open = detail.openCycle;
      if (open != null) options.add(OpenCycleOption(detail, open));
    }
    return options;
  }

  Future<List<RiskNotice>> notices() async {
    final data = await _backend.getJson('avisos');
    return ((data['avisos'] as List?) ?? const [])
        .whereType<Json>()
        .map(RiskNotice.fromJson)
        .toList();
  }

  Future<List<Json>> _optionalList(String path) async {
    try {
      return await _backend.getList(path);
    } catch (_) {
      return const [];
    }
  }

  Future<Json?> _optionalJson(String path) async {
    try {
      return await _backend.getJson(path);
    } catch (_) {
      return null;
    }
  }
}
