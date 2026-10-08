import 'package:agrogestion/app/app_theme.dart';
import 'package:agrogestion/core/format/cop.dart';
import 'package:agrogestion/features/auth/domain/auth_session.dart';
import 'package:agrogestion/features/home/presentation/widgets/page_frame.dart';
import 'package:agrogestion/features/money/domain/movimiento.dart';
import 'package:agrogestion/features/production/domain/lote_produccion.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.session,
    required this.onOpenProduction,
    required this.onOpenMoney,
    super.key,
  });

  final AuthSession session;
  final VoidCallback onOpenProduction;
  final VoidCallback onOpenMoney;

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final columnas = ancho >= 720 ? 4 : 2;
    final escritorio = ancho >= 900;
    final cultivos = seedProduccion
        .where((l) => l.categoria == CategoriaProduccion.cultivos)
        .length;
    final gastos = totalPorTipo(seedMovimientos, TipoMovimiento.gasto);

    final actividad = Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Actividad reciente'),
          const SizedBox(height: 8),
          const _ActividadItem(
            icono: Icons.water_drop_outlined,
            titulo: 'Riego por goteo',
            detalle: 'Lote 2 · El Porvenir',
            hora: 'Hoy, 08:40',
            color: Color(0xFF3F86C8),
          ),
          const _ActividadItem(
            icono: Icons.people_outline,
            titulo: 'Jornales registrados',
            detalle: 'Mantenimiento · Siembra A',
            hora: 'Ayer, 16:20',
            color: agroGreen,
          ),
          const _ActividadItem(
            icono: Icons.inventory_2_outlined,
            titulo: 'Entrada de insumos',
            detalle: 'Fertilizante granulado · 12 bultos',
            hora: '28 sep, 11:05',
            color: Color(0xFFD47B27),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onOpenProduction,
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Ir a producción'),
            ),
          ),
        ],
      ),
    );

    final fincas = Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SectionTitle(title: 'Estado de sus fincas'),
          SizedBox(height: 18),
          _ProgresoFinca(
            nombre: 'El Porvenir',
            area: '12,5 ha',
            avance: .72,
            color: agroGreen,
          ),
          SizedBox(height: 18),
          _ProgresoFinca(
            nombre: 'La Esperanza',
            area: '7 ha',
            avance: .48,
            color: Color(0xFF4E83CC),
          ),
          SizedBox(height: 18),
          _ProgresoFinca(
            nombre: 'Los Naranjos',
            area: '5 ha',
            avance: .31,
            color: Color(0xFFD48432),
          ),
        ],
      ),
    );

    return PageFrame(
      title: 'Buenos días, ${session.firstName}',
      subtitle: 'Aquí tiene el resumen de su operación agrícola.',
      action: const _FechaChip(texto: '30 sep 2026'),
      children: [
        _AlertaBanner(onTap: () => _mostrarAlerta(context)),
        const SizedBox(height: 22),
        SectionTitle(
          title: 'Resumen',
          actionLabel: 'Ver dinero',
          onAction: onOpenMoney,
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: columnas,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: columnas == 4 ? 1.6 : 1.3,
          children: [
            const MetricCard(
              label: 'Fincas activas',
              value: '3',
              detail: 'Con lotes registrados',
              icon: Icons.landscape_outlined,
              color: agroGreen,
            ),
            MetricCard(
              label: 'Cultivos en curso',
              value: '$cultivos',
              detail: 'Según producción',
              icon: Icons.eco_outlined,
              color: const Color(0xFF3567C8),
            ),
            MetricCard(
              label: 'Gastos registrados',
              value: formatCop(gastos),
              detail: 'Sin movimientos anulados',
              icon: Icons.trending_down_rounded,
              color: const Color(0xFFD47B27),
            ),
            const MetricCard(
              label: 'Área cultivada',
              value: '24,5 ha',
              detail: 'de 38 ha disponibles',
              icon: Icons.square_foot_outlined,
              color: Color(0xFF7652AA),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (escritorio)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: actividad),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: fincas),
            ],
          )
        else ...[
          actividad,
          const SizedBox(height: 16),
          fincas,
        ],
      ],
    );
  }

  void _mostrarAlerta(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Labores atrasadas'),
        content: const Text(
          'Hay 2 labores atrasadas en la finca El Porvenir: el mantenimiento '
          'de la Siembra A y la fertilización del Lote 1. Revise el cronograma '
          'en Producción.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo),
            child: const Text('Cerrar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogo);
              onOpenProduction();
            },
            child: const Text('Ir a producción'),
          ),
        ],
      ),
    );
  }
}

class _AlertaBanner extends StatelessWidget {
  const _AlertaBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF6D88F)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFF8A5A00)),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Atención en su operación',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6D4700),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Hay 2 labores atrasadas en El Porvenir. Toque para ver el detalle.',
                  style: TextStyle(color: Color(0xFF805C1A)),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Color(0xFF8A5A00)),
        ],
      ),
    ),
  );
}

class _FechaChip extends StatelessWidget {
  const _FechaChip({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE1E8E2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.calendar_today_outlined, size: 16, color: agroMuted),
        const SizedBox(width: 8),
        Text(texto, style: const TextStyle(color: agroInk)),
      ],
    ),
  );
}

class _ActividadItem extends StatelessWidget {
  const _ActividadItem({
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.hora,
    required this.color,
  });

  final IconData icono;
  final String titulo;
  final String detalle;
  final String hora;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icono, color: color, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(
                detalle,
                style: const TextStyle(color: agroMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        Text(hora, style: const TextStyle(color: agroMuted, fontSize: 11)),
      ],
    ),
  );
}

class _ProgresoFinca extends StatelessWidget {
  const _ProgresoFinca({
    required this.nombre,
    required this.area,
    required this.avance,
    required this.color,
  });

  final String nombre;
  final String area;
  final double avance;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              nombre,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(area, style: const TextStyle(color: agroMuted, fontSize: 12)),
        ],
      ),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: LinearProgressIndicator(
          value: avance,
          minHeight: 8,
          color: color,
          backgroundColor: const Color(0xFFE7ECE8),
        ),
      ),
    ],
  );
}
