import '../../../core/api/backend.dart';

enum MovementKind { expense, income }

class Movement {
  const Movement({
    required this.id,
    required this.kind,
    required this.category,
    required this.amount,
    required this.status,
  });

  final String id;
  final MovementKind kind;
  final String category;
  final double amount;
  final String status;

  bool get cancelled => status == 'anulado';
  bool get isIncome => kind == MovementKind.income;

  factory Movement.fromJson(Json json, MovementKind kind) => Movement(
    id: json['id'] as String,
    kind: kind,
    category: json['categoria'] as String? ?? '',
    amount: double.tryParse('${json['monto'] ?? json['total']}') ?? 0,
    status: json['estado'] as String? ?? 'activo',
  );
}

class CashFlow {
  const CashFlow({
    required this.income,
    required this.expenses,
    required this.balance,
  });

  final double income;
  final double expenses;
  final double balance;

  static const empty = CashFlow(income: 0, expenses: 0, balance: 0);

  factory CashFlow.fromJson(Json json) => CashFlow(
    income: double.tryParse('${json['ingresos']}') ?? 0,
    expenses: double.tryParse('${json['gastos']}') ?? 0,
    balance: double.tryParse('${json['saldo']}') ?? 0,
  );

  double? get margin => income > 0 ? balance / income * 100 : null;
}

class MoneyOverview {
  const MoneyOverview({required this.flow, required this.movements});

  final CashFlow flow;
  final List<Movement> movements;

  Map<String, double> get expensesByCategory {
    final totals = <String, double>{};
    for (final m in movements) {
      if (m.isIncome || m.cancelled) continue;
      totals.update(m.category, (v) => v + m.amount, ifAbsent: () => m.amount);
    }
    return totals;
  }
}

class MoneyRepository {
  const MoneyRepository(this._backend);

  final Backend _backend;

  Future<CashFlow> cashFlow(String farmId, {DateTime? month}) async {
    final date = month ?? DateTime.now();
    final json = await _backend.getJson(
      'fincas/$farmId/flujo-caja',
      query: {'anio': '${date.year}', 'mes': '${date.month}'},
    );
    return CashFlow.fromJson(json);
  }

  Future<List<Movement>> movements(String farmId) async {
    final expenses = await _backend.getList('fincas/$farmId/gastos');
    final incomes = await _backend.getList('fincas/$farmId/ingresos');
    return [
      ...expenses.map((j) => Movement.fromJson(j, MovementKind.expense)),
      ...incomes.map((j) => Movement.fromJson(j, MovementKind.income)),
    ];
  }

  Future<MoneyOverview> overview(String farmId) async {
    final flow = await cashFlow(farmId);
    final list = await movements(farmId);
    return MoneyOverview(flow: flow, movements: list);
  }

  Future<void> createExpense(
    String farmId, {
    required String category,
    required double amount,
    required String date,
    String? cycleId,
  }) => _backend.post(
    'fincas/$farmId/gastos',
    idempotent: true,
    queueAs: 'Gasto de $category',
    body: {
      'categoria': category,
      'monto': amount,
      'fecha': date,
      'ciclo_id': ?cycleId,
    },
  );

  Future<void> createIncome(
    String farmId, {
    required String category,
    required double quantity,
    required double unitPrice,
    required String date,
    String? buyer,
    String? cycleId,
  }) => _backend.post(
    'fincas/$farmId/ingresos',
    idempotent: true,
    queueAs: 'Ingreso de $category',
    body: {
      'categoria': category,
      'cantidad': quantity,
      'precio_unitario': unitPrice,
      'fecha': date,
      'comprador': ?buyer,
      'ciclo_id': ?cycleId,
    },
  );

  Future<void> cancel(
    String farmId,
    Movement movement, {
    required String reason,
  }) {
    final segment = movement.isIncome ? 'ingresos' : 'gastos';
    return _backend.post(
      'fincas/$farmId/$segment/${movement.id}/anular',
      body: {'motivo': reason},
    );
  }
}
