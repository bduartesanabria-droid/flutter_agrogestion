import '../../../core/api/backend.dart';

class Supply {
  const Supply({
    required this.id,
    required this.name,
    required this.unit,
    required this.stock,
    required this.value,
    this.averageCost,
    this.lastMovement,
  });

  final String id;
  final String name;
  final String unit;
  final double stock;
  final double value;
  final double? averageCost;
  final String? lastMovement;

  factory Supply.fromJson(Json json) => Supply(
    id: json['id'] as String,
    name: json['nombre'] as String? ?? '',
    unit: json['unidad'] as String? ?? '',
    stock: double.tryParse('${json['existencia']}') ?? 0,
    value: double.tryParse('${json['valor']}') ?? 0,
    averageCost: double.tryParse('${json['costo_promedio']}'),
    lastMovement: json['ultimo_movimiento'] as String?,
  );
}

class SupplyMovement {
  const SupplyMovement({
    required this.id,
    required this.supplyId,
    required this.type,
    required this.quantity,
    required this.cost,
    required this.date,
  });

  final String id;
  final String supplyId;
  final String type;
  final double quantity;
  final double cost;
  final String date;

  bool get isEntry => type == 'entrada';

  factory SupplyMovement.fromJson(Json json) => SupplyMovement(
    id: json['id'] as String,
    supplyId: json['insumo_id'] as String,
    type: json['tipo'] as String? ?? '',
    quantity: double.tryParse('${json['cantidad']}') ?? 0,
    cost: double.tryParse('${json['costo']}') ?? 0,
    date: json['fecha'] as String? ?? '',
  );
}

class InventoryRepository {
  const InventoryRepository(this._backend);

  final Backend _backend;

  Future<List<Supply>> list(String farmId) async =>
      (await _backend.getList('fincas/$farmId/insumos'))
          .map(Supply.fromJson)
          .toList();

  Future<List<SupplyMovement>> movements(
    String farmId,
    String supplyId,
  ) async =>
      (await _backend.getList('fincas/$farmId/movimientos-insumo'))
          .map(SupplyMovement.fromJson)
          .where((m) => m.supplyId == supplyId)
          .toList();

  Future<void> create(
    String farmId, {
    required String name,
    required String unit,
  }) => _backend.post(
    'fincas/$farmId/insumos',
    body: {'nombre': name, 'unidad': unit},
  );

  Future<void> entry(
    String farmId, {
    required String supplyId,
    required double quantity,
    required double cost,
    required String date,
  }) => _backend.post(
    'fincas/$farmId/insumos/entrada',
    idempotent: true,
    body: {
      'insumo_id': supplyId,
      'cantidad': quantity,
      'costo': cost,
      'fecha': date,
    },
  );

  Future<void> consumption(
    String farmId, {
    required String supplyId,
    required double quantity,
    required String activityId,
    required String date,
  }) => _backend.post(
    'fincas/$farmId/insumos/consumo',
    idempotent: true,
    body: {
      'insumo_id': supplyId,
      'cantidad': quantity,
      'actividad_id': activityId,
      'fecha': date,
    },
  );
}
