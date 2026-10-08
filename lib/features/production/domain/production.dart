import '../../../core/format.dart';

class Crop {
  const Crop({
    required this.id,
    required this.name,
    required this.group,
    required this.cycleType,
    required this.countUnit,
    required this.toValidate,
  });

  final String id;
  final String name;
  final String group;
  final String cycleType;
  final String countUnit;
  final bool toValidate;

  factory Crop.fromJson(Map<String, dynamic> json) => Crop(
    id: json['id'] as String,
    name: json['nombre'] as String,
    group: json['grupo'] as String? ?? '',
    cycleType: json['tipo_ciclo'] as String? ?? '',
    countUnit: json['unidad_conteo'] as String? ?? '',
    toValidate: json['por_validar'] == true,
  );

  String get cycleLabel => humanize(cycleType);
  String get countLabel => countUnit == 'planta' ? 'Por planta' : 'Por área';
}

class CropPhase {
  const CropPhase({
    required this.phase,
    required this.order,
    required this.days,
  });

  final String phase;
  final int order;
  final int? days;

  factory CropPhase.fromJson(Map<String, dynamic> json) => CropPhase(
    phase: json['fase'] as String,
    order: (json['orden'] as num?)?.toInt() ?? 0,
    days: (json['dias_estimados'] as num?)?.toInt(),
  );
}

class CropDetail {
  const CropDetail({
    required this.crop,
    required this.scientificName,
    required this.renewalType,
    required this.harvestUnit,
    required this.phases,
    required this.source,
  });

  final Crop crop;
  final String? scientificName;
  final String? renewalType;
  final String? harvestUnit;
  final List<CropPhase> phases;
  final String? source;

  factory CropDetail.fromJson(Map<String, dynamic> json) => CropDetail(
    crop: Crop.fromJson(json),
    scientificName: json['nombre_cientifico'] as String?,
    renewalType: json['tipo_renovacion'] as String?,
    harvestUnit: json['unidad_cosecha'] as String?,
    phases:
        (json['fases'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(CropPhase.fromJson)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order)),
    source: json['fuente'] as String?,
  );
}

class PropagationMethod {
  const PropagationMethod({
    required this.method,
    this.germinationDays,
    this.nurseryDays,
  });

  final String method;
  final int? germinationDays;
  final int? nurseryDays;

  factory PropagationMethod.fromJson(Map<String, dynamic> json) =>
      PropagationMethod(
        method: json['metodo'] as String,
        germinationDays: (json['dias_germinacion'] as num?)?.toInt(),
        nurseryDays: (json['dias_vivero'] as num?)?.toInt(),
      );
}

class CropRisk {
  const CropRisk({
    required this.riskId,
    required this.phase,
    required this.susceptibility,
    this.measures,
  });

  final String riskId;
  final String phase;
  final String susceptibility;
  final String? measures;

  factory CropRisk.fromJson(Map<String, dynamic> json) => CropRisk(
    riskId: json['riesgo_id'] as String,
    phase: json['fase_critica'] as String? ?? '',
    susceptibility: json['susceptibilidad'] as String? ?? '',
    measures: json['medidas'] as String?,
  );
}

class Planting {
  const Planting({
    required this.id,
    required this.farmId,
    required this.lotId,
    required this.cropId,
    required this.method,
    required this.areaHa,
    required this.plants,
    required this.planDate,
    required this.status,
    this.budget,
    this.cycles = const [],
  });

  final String id;
  final String farmId;
  final String lotId;
  final String cropId;
  final String method;
  final double areaHa;
  final int? plants;
  final String planDate;
  final String status;
  final double? budget;
  final List<Cycle> cycles;

  factory Planting.fromJson(Map<String, dynamic> json) => Planting(
    id: json['id'] as String,
    farmId: json['finca_id'] as String,
    lotId: json['lote_id'] as String,
    cropId: json['cultivo_id'] as String,
    method: json['metodo'] as String? ?? '',
    areaHa: (json['area_ha'] as num?)?.toDouble() ?? 0,
    plants: (json['plantas_sembradas'] as num?)?.toInt(),
    planDate: json['fecha_plan'] as String? ?? '',
    status: json['estado'] as String? ?? '',
    budget: (json['presupuesto'] as num?)?.toDouble(),
    cycles: (json['ciclos'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Cycle.fromJson)
        .toList(),
  );

  Cycle? get openCycle {
    for (final cycle in cycles) {
      if (cycle.status == 'abierto') return cycle;
    }
    return null;
  }
}

class Cycle {
  const Cycle({
    required this.id,
    required this.type,
    required this.number,
    required this.status,
    this.start,
    this.end,
    this.lossReason,
  });

  final String id;
  final String type;
  final int number;
  final String status;
  final String? start;
  final String? end;
  final String? lossReason;

  factory Cycle.fromJson(Map<String, dynamic> json) => Cycle(
    id: json['id'] as String,
    type: json['tipo'] as String? ?? '',
    number: (json['numero'] as num?)?.toInt() ?? 1,
    status: json['estado'] as String? ?? '',
    start: json['fecha_inicio'] as String?,
    end: json['fecha_fin'] as String?,
    lossReason: json['motivo_perdida'] as String?,
  );
}

class ScheduledPhase {
  const ScheduledPhase({
    required this.phase,
    required this.order,
    required this.plannedDays,
    required this.planStart,
    required this.planEnd,
    this.realStart,
    this.realEnd,
    this.delayDays,
  });

  final String phase;
  final int order;
  final int? plannedDays;
  final String? planStart;
  final String? planEnd;
  final String? realStart;
  final String? realEnd;
  final int? delayDays;

  factory ScheduledPhase.fromJson(Map<String, dynamic> json) => ScheduledPhase(
    phase: json['fase'] as String,
    order: (json['orden'] as num?)?.toInt() ?? 0,
    plannedDays: (json['dias_estimados'] as num?)?.toInt(),
    planStart: json['inicio_plan'] as String?,
    planEnd: json['fin_plan'] as String?,
    realStart: json['inicio_real'] as String?,
    realEnd: json['fin_real'] as String?,
    delayDays: (json['dias_retraso'] as num?)?.toInt(),
  );

  bool get done => realEnd != null;
  bool get started => realStart != null;
}

class PlantCount {
  const PlantCount({
    required this.date,
    required this.alive,
    required this.dead,
    required this.replanted,
  });

  final String date;
  final int alive;
  final int dead;
  final int replanted;

  factory PlantCount.fromJson(Map<String, dynamic> json) => PlantCount(
    date: json['fecha'] as String? ?? '',
    alive: (json['vivas'] as num?)?.toInt() ?? 0,
    dead: (json['muertas'] as num?)?.toInt() ?? 0,
    replanted: (json['resiembras'] as num?)?.toInt() ?? 0,
  );
}

class Indicator {
  const Indicator({
    required this.title,
    required this.value,
    required this.unit,
    required this.explanation,
    required this.state,
    this.action,
    this.date,
  });

  final String title;
  final double? value;
  final String unit;
  final String explanation;
  final String state;
  final String? action;
  final String? date;

  factory Indicator.fromJson(Map<String, dynamic> json) => Indicator(
    title: json['titulo'] as String? ?? '',
    value: (json['valor'] as num?)?.toDouble(),
    unit: json['unidad'] as String? ?? '',
    explanation: json['explicacion'] as String? ?? '',
    state: json['estado'] as String? ?? 'informativo',
    action: json['que_hacer'] as String?,
    date: json['fecha_datos'] as String?,
  );
}

class RiskNotice {
  const RiskNotice({
    required this.plantingId,
    required this.crop,
    required this.phase,
    required this.risk,
    required this.susceptibility,
    required this.text,
    this.measures,
    this.toValidate = false,
  });

  final String plantingId;
  final String crop;
  final String phase;
  final String risk;
  final String susceptibility;
  final String text;
  final String? measures;
  final bool toValidate;

  factory RiskNotice.fromJson(Map<String, dynamic> json) => RiskNotice(
    plantingId: json['siembra_id'] as String? ?? '',
    crop: json['cultivo'] as String? ?? '',
    phase: json['fase'] as String? ?? '',
    risk: json['riesgo'] as String? ?? '',
    susceptibility: json['susceptibilidad'] as String? ?? '',
    text: json['texto'] as String? ?? '',
    measures: json['medidas'] as String?,
    toValidate: json['por_validar'] == true,
  );
}

class Activity {
  const Activity({
    required this.id,
    required this.cycleId,
    required this.name,
    required this.phase,
    required this.start,
    required this.areaHa,
    required this.status,
    this.end,
  });

  final String id;
  final String cycleId;
  final String name;
  final String phase;
  final String start;
  final String? end;
  final double areaHa;
  final String status;

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
    id: json['id'] as String,
    cycleId: json['ciclo_id'] as String? ?? '',
    name: json['nombre'] as String? ?? '',
    phase: json['fase'] as String? ?? '',
    start: json['fecha_inicio'] as String? ?? '',
    end: json['fecha_fin'] as String?,
    areaHa: double.tryParse('${json['area_trabajada']}') ?? 0,
    status: json['estado'] as String? ?? '',
  );
}

class SupplyNeed {
  const SupplyNeed({
    required this.type,
    required this.dose,
    required this.unit,
    required this.base,
    this.quantity,
    this.message,
  });

  final String type;
  final double dose;
  final String unit;
  final String base;
  final double? quantity;
  final String? message;

  factory SupplyNeed.fromJson(Map<String, dynamic> json) => SupplyNeed(
    type: json['insumo_tipo'] as String? ?? '',
    dose: (json['dosis'] as num?)?.toDouble() ?? 0,
    unit: json['unidad'] as String? ?? '',
    base: json['base'] as String? ?? '',
    quantity: (json['cantidad_necesaria'] as num?)?.toDouble(),
    message: json['mensaje'] as String?,
  );
}
