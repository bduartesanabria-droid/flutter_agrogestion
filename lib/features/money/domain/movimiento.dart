enum TipoMovimiento {
  gasto('Gasto'),
  ingreso('Ingreso');

  const TipoMovimiento(this.label);
  final String label;
}

enum FiltroMovimiento {
  todos('Todos'),
  gastos('Gastos'),
  ingresos('Ingresos');

  const FiltroMovimiento(this.label);
  final String label;
}

/// Un gasto o ingreso. Nunca se borra: se anula con motivo.
class Movimiento {
  const Movimiento({
    required this.id,
    required this.descripcion,
    required this.categoria,
    required this.fecha,
    required this.monto,
    required this.tipo,
    this.anulado = false,
    this.motivoAnulacion,
  });

  final String id;
  final String descripcion;
  final String categoria;
  final String fecha;

  /// Monto en pesos, siempre positivo. El tipo indica si suma o resta.
  final int monto;
  final TipoMovimiento tipo;
  final bool anulado;
  final String? motivoAnulacion;

  bool get activo => !anulado;

  Movimiento anular(String motivo) => Movimiento(
    id: id,
    descripcion: descripcion,
    categoria: categoria,
    fecha: fecha,
    monto: monto,
    tipo: tipo,
    anulado: true,
    motivoAnulacion: motivo,
  );
}

const _meses = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

String fechaHoy() {
  final hoy = DateTime.now();
  return '${hoy.day} ${_meses[hoy.month - 1]} ${hoy.year}';
}

/// Suma solo los movimientos activos (los anulados no cuentan).
int totalPorTipo(Iterable<Movimiento> movimientos, TipoMovimiento tipo) =>
    movimientos
        .where((m) => m.activo && m.tipo == tipo)
        .fold(0, (suma, m) => suma + m.monto);

/// Datos de ejemplo mientras el módulo de dinero se conecta a la API.
const seedMovimientos = <Movimiento>[
  Movimiento(
    id: '1',
    descripcion: 'Jornales de socola',
    categoria: 'Mano de obra',
    fecha: '28 sep 2026',
    monto: 2160000,
    tipo: TipoMovimiento.gasto,
  ),
  Movimiento(
    id: '2',
    descripcion: 'Venta de cosecha',
    categoria: 'Ingreso por venta',
    fecha: '26 sep 2026',
    monto: 3450000,
    tipo: TipoMovimiento.ingreso,
  ),
  Movimiento(
    id: '3',
    descripcion: 'Fertilizante granulado',
    categoria: 'Insumos',
    fecha: '25 sep 2026',
    monto: 240000,
    tipo: TipoMovimiento.gasto,
  ),
  Movimiento(
    id: '4',
    descripcion: 'Transporte de insumos',
    categoria: 'Transporte',
    fecha: '20 sep 2026',
    monto: 120000,
    tipo: TipoMovimiento.gasto,
  ),
];
