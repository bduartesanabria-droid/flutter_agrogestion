import 'package:agrogestion/app/app_theme.dart';
import 'package:agrogestion/features/auth/data/auth_repository.dart';
import 'package:agrogestion/features/auth/domain/auth_session.dart';
import 'package:agrogestion/features/farms/data/farm_repository.dart';
import 'package:agrogestion/features/home/presentation/pages/dashboard_page.dart';
import 'package:agrogestion/features/home/presentation/pages/more_page.dart';
import 'package:agrogestion/features/money/presentation/money_page.dart';
import 'package:agrogestion/features/production/presentation/production_page.dart';
import 'package:flutter/material.dart';

class _Destino {
  const _Destino(this.nombre, this.icono);

  final String nombre;
  final IconData icono;
}

const _destinos = [
  _Destino('Inicio', Icons.grid_view_rounded),
  _Destino('Producción', Icons.eco_outlined),
  _Destino('Dinero', Icons.account_balance_wallet_outlined),
  _Destino('Más', Icons.tune_rounded),
];

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
  int _index = 0;

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    // IndexedStack conserva el estado de cada pestaña al cambiar de vista.
    final paginas = <Widget>[
      DashboardPage(
        session: widget.session,
        onOpenProduction: () => _select(1),
        onOpenMoney: () => _select(2),
      ),
      const ProductionPage(),
      const MoneyPage(),
      MorePage(
        session: widget.session,
        onSignOut: widget.onSignOut,
        onOpenProduction: () => _select(1),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final escritorio = constraints.maxWidth >= 900;
        return Scaffold(
          body: Row(
            children: [
              if (escritorio)
                _SideBar(
                  selectedIndex: _index,
                  session: widget.session,
                  onSelected: _select,
                ),
              Expanded(
                child: IndexedStack(index: _index, children: paginas),
              ),
            ],
          ),
          bottomNavigationBar: escritorio
              ? null
              : NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: _select,
                  destinations: [
                    for (final d in _destinos)
                      NavigationDestination(
                        icon: Icon(d.icono),
                        label: d.nombre,
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class _SideBar extends StatelessWidget {
  const _SideBar({
    required this.selectedIndex,
    required this.session,
    required this.onSelected,
  });

  final int selectedIndex;
  final AuthSession session;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    width: 244,
    color: const Color(0xFF123D31),
    padding: const EdgeInsets.fromLTRB(20, 28, 16, 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFDBF5D9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.spa_rounded, color: agroGreenDark),
            ),
            const SizedBox(width: 11),
            const Text(
              'AgroGestion',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 44),
        const Text(
          'GESTIÓN',
          style: TextStyle(
            color: Color(0xFF8EB8A7),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < _destinos.length; i++) ...[
          _SideItem(
            icono: _destinos[i].icono,
            etiqueta: _destinos[i].nombre,
            seleccionado: selectedIndex == i,
            onTap: () => onSelected(i),
          ),
          const SizedBox(height: 5),
        ],
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFD5F2D4),
                child: Text(
                  session.firstName[0].toUpperCase(),
                  style: const TextStyle(
                    color: agroGreenDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      session.roleLabel,
                      style: const TextStyle(
                        color: Color(0xFF9EC4B5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SideItem extends StatelessWidget {
  const _SideItem({
    required this.icono,
    required this.etiqueta,
    required this.seleccionado,
    required this.onTap,
  });

  final IconData icono;
  final String etiqueta;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: seleccionado ? const Color(0xFF2B7059) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icono,
            size: 20,
            color: seleccionado
                ? const Color(0xFFD9F4D8)
                : const Color(0xFF9EC4B5),
          ),
          const SizedBox(width: 12),
          Text(
            etiqueta,
            style: TextStyle(
              color: seleccionado ? Colors.white : const Color(0xFFB3CEC2),
              fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}
