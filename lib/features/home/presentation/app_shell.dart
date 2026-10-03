import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_session.dart';
import '../../farms/data/farm_repository.dart';
import '../../farms/presentation/farms_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    required this.session,
    required this.authRepository,
    required this.farmRepository,
    required this.onSignOut,
    super.key,
  });

  final AuthSession session;
  final AuthRepository authRepository;
  final FarmRepository farmRepository;
  final Future<void> Function() onSignOut;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomePage(
        session: widget.session,
        onOpenProduction: () => setState(() => _selectedIndex = 1),
      ),
      FarmsScreen(session: widget.session, repository: widget.farmRepository),
      const _ComingSoonPage(
        title: 'Dinero',
        icon: Icons.account_balance_wallet_outlined,
        message: 'Sus gastos, ingresos y flujo de caja aparecerán aquí.',
      ),
      _MorePage(session: widget.session, onSignOut: widget.onSignOut),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.grass_outlined),
            selectedIcon: Icon(Icons.grass),
            label: 'Producción',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Dinero',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'Más',
          ),
        ],
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({required this.session, required this.onOpenProduction});

  final AuthSession session;
  final VoidCallback onOpenProduction;

  @override
  Widget build(BuildContext context) {
    final firstName = session.name.trim().split(RegExp(r'\s+')).first;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AgroGestion',
                      style: TextStyle(
                        color: agroGreen,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hola, $firstName',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: agroInk,
                          ),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 25,
                backgroundColor: agroGreen.withValues(alpha: .1),
                foregroundColor: agroGreen,
                child: Text(
                  firstName.isEmpty ? 'A' : firstName[0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [agroGreen, agroGreenDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.eco_outlined, color: Colors.white, size: 29),
                SizedBox(height: 18),
                Text(
                  'Su trabajo en el campo, organizado.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Registre sus fincas y consulte su actividad desde un solo lugar.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          Text(
            'Para empezar',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 13),
          _ActionTile(
            icon: Icons.landscape_outlined,
            title: 'Registre su primera finca',
            subtitle: 'Organice sus lotes y actividades.',
            onTap: onOpenProduction,
          ),
          const SizedBox(height: 11),
          const _ActionTile(
            icon: Icons.event_note_outlined,
            title: 'Sus labores aparecerán aquí',
            subtitle:
                'Cuando haya labores registradas, verá lo pendiente del día.',
          ),
          const SizedBox(height: 11),
          const _ActionTile(
            icon: Icons.notifications_none_rounded,
            title: 'Avisos de su región',
            subtitle:
                'Las alertas vigentes se mostrarán cuando estén disponibles.',
          ),
        ],
      ),
    );
  }
}

class _MorePage extends StatelessWidget {
  const _MorePage({required this.session, required this.onSignOut});

  final AuthSession session;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Text(
            'Más',
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE7F2EB),
                child: Icon(Icons.person_outline, color: agroGreen),
              ),
              title: Text(session.name),
              subtitle: Text('${session.email}\n${_roleLabel(session.role)}'),
              isThreeLine: true,
            ),
          ),
          const SizedBox(height: 14),
          _ActionTile(
            icon: Icons.help_outline,
            title: 'Ayuda y glosario',
            subtitle: 'Términos usados en AgroGestion.',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) => switch (role) {
    'admin' => 'Administrador',
    'agricultor' => 'Agricultor',
    'contador' => 'Contador',
    'experto' => 'Experto',
    _ => role,
  };
}

class _ComingSoonPage extends StatelessWidget {
  const _ComingSoonPage({
    required this.title,
    required this.icon,
    required this.message,
  });

  final String title;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 50, color: agroGreen),
            const SizedBox(height: 18),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: agroMuted, height: 1.4),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE7F2EB),
        child: Icon(icon, color: agroGreen),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
