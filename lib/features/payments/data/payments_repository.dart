import '../../../core/api/backend.dart';

class Jornal {
  const Jornal({
    required this.id,
    required this.activityName,
    required this.date,
    required this.workers,
    required this.days,
    required this.dailyValue,
    required this.total,
    required this.status,
    this.workerName,
    this.paidAt,
  });

  final String id;
  final String? workerName;
  final String activityName;
  final String date;
  final double workers;
  final double days;
  final double dailyValue;
  final double total;
  final String status;
  final String? paidAt;

  bool get paid => status == 'pagado';
  double get workDays => workers * days;
  String get payee => workerName ?? 'Cuadrilla sin nombre';

  factory Jornal.fromJson(Json json) => Jornal(
    id: json['id'] as String,
    workerName: json['trabajador_nombre'] as String?,
    activityName: json['actividad_nombre'] as String? ?? '',
    date: json['fecha'] as String? ?? '',
    workers: double.tryParse('${json['obreros']}') ?? 0,
    days: double.tryParse('${json['dias']}') ?? 0,
    dailyValue: double.tryParse('${json['valor_jornal']}') ?? 0,
    total: double.tryParse('${json['total']}') ?? 0,
    status: json['estado'] as String? ?? 'pendiente',
    paidAt: json['pagado_en'] as String?,
  );
}

class PaymentsRepository {
  const PaymentsRepository(this._backend);

  final Backend _backend;

  Future<List<Jornal>> list(String farmId, {String? status}) async =>
      (await _backend.getList(
        'fincas/$farmId/jornales',
        query: {'estado': ?status},
      )).map(Jornal.fromJson).toList();

  Future<void> pay(String farmId, String jornalId) => _backend.post(
    'fincas/$farmId/jornales/$jornalId/pagar',
    idempotent: true,
  );
}
