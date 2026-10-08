import 'package:agrogestion/app/app_theme.dart';
import 'package:agrogestion/core/format/cop.dart';
import 'package:agrogestion/features/home/presentation/widgets/page_frame.dart';
import 'package:agrogestion/features/money/domain/movimiento.dart';
import 'package:agrogestion/features/money/presentation/movimiento_dialogs.dart';
import 'package:flutter/material.dart';

class MoneyPage extends StatefulWidget {
  const MoneyPage({super.key});

  @override
  State<MoneyPage> createState() => _MoneyPageState();
}

class _MoneyPageState extends State<MoneyPage> {
  final List<Movimiento> _movimientos = List.of(seedMovimientos);
  FiltroMovimiento _filtro = FiltroMovimiento.todos;

  List<Movimiento> get _visibles => _movimientos.where((m) {
    return switch (_filtro) {
      FiltroMovimiento.todos => true,
      FiltroMovimiento.gastos => m.tipo == TipoMovimiento.gasto,
      FiltroMovimiento.ingresos => m.tipo == TipoMovimiento.ingreso,
    };
  }).toList();

  Future<void> _nuevo() async {
    final nuevo = await showDialog<Movimiento>(
      context: context,
      builder: (_) => const NuevoMovimientoDialog(),
    );
    if (nuevo == null || !mounted) return;
    setState(() => _movimientos.insert(0, nuevo));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${nuevo.descripcion} quedó registrado.')),
    );
  }

  Future<void> _abrirDetalle(Movimiento movimiento) async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (_) => DetalleMovimientoDialog(movimiento: movimiento),
    );
    if (motivo == null || !mounted) return;
    setState(() {
      final indice = _movimientos.indexWhere((m) => m.id == movimiento.id);
      if (indice >= 0) _movimientos[indice] = movimiento.anular(motivo);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('El movimiento quedó anulado.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ingresos = totalPorTipo(_movimientos, TipoMovimiento.ingreso);
    final gastos = totalPorTipo(_movimientos, TipoMovimiento.gasto);
    final visibles = _visibles;

    return PageFrame(
      title: 'Dinero',
      subtitle: 'Ingresos, gastos y saldo. Nada se borra: se anula con motivo.',
      action: FilledButton.icon(
        onPressed: _nuevo,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Nuevo movimiento'),
      ),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 260,
              child: MetricCard(
                label: 'Saldo disponible',
                value: formatCop(ingresos - gastos),
                detail: 'Ingresos menos gastos',
                icon: Icons.account_balance_wallet_outlined,
                color: agroGreen,
              ),
            ),
            SizedBox(
              width: 260,
              child: MetricCard(
                label: 'Ingresos registrados',
                value: formatCop(ingresos),
                detail: 'Sin movimientos anulados',
                icon: Icons.trending_up_rounded,
                color: const Color(0xFF3567C8),
              ),
            ),
            SizedBox(
              width: 260,
              child: MetricCard(
                label: 'Gastos registrados',
                value: formatCop(gastos),
                detail: 'Sin movimientos anulados',
                icon: Icons.trending_down_rounded,
                color: const Color(0xFFD47B27),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        SegmentedButton<FiltroMovimiento>(
          segments: [
            for (final f in FiltroMovimiento.values)
              ButtonSegment(value: f, label: Text(f.label)),
          ],
          selected: {_filtro},
          onSelectionChanged: (s) => setState(() => _filtro = s.first),
        ),
        const SizedBox(height: 16),
        Panel(
          child: Column(
            children: [
              SectionTitle(
                title: 'Movimientos',
                actionLabel: _filtro == FiltroMovimiento.todos
                    ? null
                    : 'Ver todos',
                onAction: () =>
                    setState(() => _filtro = FiltroMovimiento.todos),
              ),
              const Divider(height: 24),
              if (visibles.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No hay movimientos en esta vista.',
                    style: TextStyle(color: agroMuted),
                  ),
                )
              else
                for (final m in visibles)
                  _MovimientoTile(movimiento: m, onTap: () => _abrirDetalle(m)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MovimientoTile extends StatelessWidget {
  const _MovimientoTile({required this.movimiento, required this.onTap});

  final Movimiento movimiento;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = movimiento;
    final esIngreso = m.tipo == TipoMovimiento.ingreso;
    final color = !m.activo
        ? agroMuted
        : esIngreso
        ? agroGreen
        : agroInk;
    final signo = esIngreso ? '+' : '-';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(
              esIngreso
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.descripcion,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: color,
                      decoration: m.activo ? null : TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    m.anulado
                        ? 'Anulado · ${m.categoria} · ${m.fecha}'
                        : '${m.categoria} · ${m.fecha}',
                    style: const TextStyle(color: agroMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '$signo${formatCop(m.monto)}',
              style: TextStyle(fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
