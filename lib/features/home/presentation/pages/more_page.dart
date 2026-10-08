import 'package:agrogestion/app/app_theme.dart';
import 'package:agrogestion/features/auth/domain/auth_session.dart';
import 'package:agrogestion/features/home/presentation/widgets/page_frame.dart';
import 'package:flutter/material.dart';

class MorePage extends StatelessWidget {
  const MorePage({
    required this.session,
    required this.onSignOut,
    required this.onOpenProduction,
    super.key,
  });

  final AuthSession session;
  final Future<void> Function() onSignOut;
  final VoidCallback onOpenProduction;

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Más',
    subtitle: 'Cuenta, ayuda y herramientas de AgroGestion.',
    children: [
      Panel(
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFFDDF1E2),
              child: Text(
                session.firstName[0].toUpperCase(),
                style: const TextStyle(
                  color: agroGreenDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    session.email,
                    style: const TextStyle(color: agroMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    session.roleLabel,
                    style: const TextStyle(
                      color: agroGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _HerramientaTile(
        icono: Icons.landscape_outlined,
        titulo: 'Mis fincas',
        detalle: 'Fincas, lotes y ubicación',
        onTap: onOpenProduction,
      ),
      _HerramientaTile(
        icono: Icons.menu_book_outlined,
        titulo: 'Ayuda y glosario',
        detalle: 'Términos del agro explicados',
        onTap: () => _mostrarGlosario(context),
      ),
      _HerramientaTile(
        icono: Icons.people_outline,
        titulo: 'Trabajadores',
        detalle: 'Jornales y pagos pendientes',
        onTap: () => _mostrarTrabajadores(context),
      ),
      const SizedBox(height: 22),
      OutlinedButton.icon(
        onPressed: () => _confirmarSalida(context),
        icon: const Icon(Icons.logout),
        label: const Text('Cerrar sesión'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFB13B32),
          side: const BorderSide(color: Color(0xFFE2B5B0)),
          minimumSize: const Size.fromHeight(48),
        ),
      ),
    ],
  );

  void _mostrarGlosario(BuildContext context) {
    const terminos = {
      'Jornal': 'Un día de trabajo de una persona.',
      'Levante':
          'Etapa desde la preparación del terreno hasta la primera producción.',
      'Zoca': 'Corte de renovación de una planta productiva.',
      'Destajo': 'Pago por cantidad de trabajo realizado, no por días.',
      'Arroba': 'Unidad de peso de uso común para vender cosechas.',
      'Lote': 'Parte de la finca con un área definida para sembrar.',
    };
    showDialog<void>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Ayuda y glosario'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entrada in terminos.entries) ...[
                  Text(
                    entrada.key,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(entrada.value, style: const TextStyle(color: agroMuted)),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _mostrarTrabajadores(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Trabajadores'),
        content: const Text(
          'Lista de ejemplo. El registro de trabajadores, jornales y pagos '
          'se conectará al módulo de mano de obra de la API.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarSalida(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Desea salir de AgroGestion en este dispositivo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogo, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (confirmar == true) await onSignOut();
  }
}

class _HerramientaTile extends StatelessWidget {
  const _HerramientaTile({
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.onTap,
  });

  final IconData icono;
  final String titulo;
  final String detalle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
      leading: Icon(icono, color: agroGreen),
      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(detalle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
