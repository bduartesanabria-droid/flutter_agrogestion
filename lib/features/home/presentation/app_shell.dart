import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_session.dart';
import '../../farms/data/farm_repository.dart';

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

  static const _labels = ['Inicio', 'Producción', 'Dinero', 'Más'];
  static const _icons = [
    Icons.grid_view_rounded,
    Icons.eco_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.tune_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DashboardPage(session: widget.session, onProduction: () => _select(1)),
      const _ProductionPage(),
      const _MoneyPage(),
      _MorePage(session: widget.session, onSignOut: widget.onSignOut),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        return Scaffold(
          body: Row(
            children: [
              if (desktop)
                _SideBar(
                  selectedIndex: _selectedIndex,
                  labels: _labels,
                  icons: _icons,
                  onSelected: _select,
                  session: widget.session,
                ),
              Expanded(
                child: IndexedStack(index: _selectedIndex, children: pages),
              ),
            ],
          ),
          bottomNavigationBar: desktop
              ? null
              : NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _select,
                  destinations: List.generate(
                    _labels.length,
                    (index) => NavigationDestination(
                      icon: Icon(_icons[index]),
                      selectedIcon: Icon(_icons[index]),
                      label: _labels[index],
                    ),
                  ),
                ),
        );
      },
    );
  }

  void _select(int index) => setState(() => _selectedIndex = index);
}

class _SideBar extends StatelessWidget {
  const _SideBar({
    required this.selectedIndex,
    required this.labels,
    required this.icons,
    required this.onSelected,
    required this.session,
  });

  final int selectedIndex;
  final List<String> labels;
  final List<IconData> icons;
  final ValueChanged<int> onSelected;
  final AuthSession session;

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
        for (var i = 0; i < labels.length; i++) ...[
          _SideItem(
            icon: icons[i],
            label: labels[i],
            selected: selectedIndex == i,
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
                  session.name.isEmpty ? 'A' : session.name[0],
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
                      session.name.isEmpty ? 'Usuario' : session.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _roleLabel(session.role),
                      style: const TextStyle(
                        color: Color(0xFF9EC4B5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_horiz, color: Color(0xFF9EC4B5)),
            ],
          ),
        ),
      ],
    ),
  );

  static String _roleLabel(String role) => switch (role) {
    'admin' => 'Administrador',
    'contador' => 'Contador',
    'experto' => 'Experto',
    _ => 'Agricultor',
  };
}

class _SideItem extends StatelessWidget {
  const _SideItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF2B7059) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: selected ? const Color(0xFFD9F4D8) : const Color(0xFF9EC4B5),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFFB3CEC2),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage({required this.session, required this.onProduction});
  final AuthSession session;
  final VoidCallback onProduction;

  @override
  Widget build(BuildContext context) {
    final firstName = session.name.trim().split(RegExp(r'\s+')).first;
    return _PageFrame(
      title: 'Buenos días, $firstName',
      subtitle: 'Aquí tienes el resumen de tu operación agrícola.',
      action: _OutlineAction(
        icon: Icons.calendar_today_outlined,
        label: '30 sep 2026',
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 720;
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              _AlertBanner(
                onTap: () => _showInfo(
                  context,
                  'Revisa las labores de mantenimiento en la Siembra A.',
                ),
              ),
              const SizedBox(height: 22),
              _SectionTitle(
                title: 'Resumen de hoy',
                action: 'Ver reportes',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: wide ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: wide ? 1.5 : 1.35,
                children: const [
                  _MetricCard(
                    label: 'Fincas activas',
                    value: '03',
                    detail: '+1 este mes',
                    icon: Icons.landscape_outlined,
                    tone: _MetricTone.green,
                  ),
                  _MetricCard(
                    label: 'Siembras en curso',
                    value: '08',
                    detail: '2 requieren atención',
                    icon: Icons.eco_outlined,
                    tone: _MetricTone.blue,
                  ),
                  _MetricCard(
                    label: 'Gastos del mes',
                    value: '\$2,4 M',
                    detail: 'Corte al 30 sep',
                    icon: Icons.trending_down_rounded,
                    tone: _MetricTone.orange,
                  ),
                  _MetricCard(
                    label: 'Área cultivada',
                    value: '24,5 ha',
                    detail: 'de 38 ha disponibles',
                    icon: Icons.square_foot_outlined,
                    tone: _MetricTone.purple,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _TodayCard(onProduction: onProduction),
                    ),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: const _FarmHealthCard()),
                  ],
                )
              else ...[
                _TodayCard(onProduction: onProduction),
                const SizedBox(height: 16),
                const _FarmHealthCard(),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PageFrame extends StatelessWidget {
  const _PageFrame({
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
  });
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: agroInk,
                              ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          style: const TextStyle(color: agroMuted),
                        ),
                      ],
                    ),
                  ),
                  ?action,
                ],
              ),
              const SizedBox(height: 28),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    ),
  );
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.onTap});
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
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD77B),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFF8A5A00),
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Atención en tu operación',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6D4700),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Hay 2 labores atrasadas en la finca El Porvenir. Revisa el cronograma.',
                  style: TextStyle(color: Color(0xFF805C1A)),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF8A5A00)),
        ],
      ),
    ),
  );
}

enum _MetricTone { green, blue, orange, purple }

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.tone,
  });
  final String label, value, detail;
  final IconData icon;
  final _MetricTone tone;
  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      _MetricTone.green => agroGreen,
      _MetricTone.blue => const Color(0xFF3567C8),
      _MetricTone.orange => const Color(0xFFD47B27),
      _MetricTone.purple => const Color(0xFF7652AA),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: agroMuted, fontSize: 12),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: agroInk,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              detail,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.onProduction});
  final VoidCallback onProduction;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Actividad reciente'),
          const SizedBox(height: 8),
          const _ActivityRow(
            icon: Icons.water_drop_outlined,
            title: 'Riego por goteo',
            subtitle: 'Lote 2 · El Porvenir',
            time: 'Hoy, 08:40',
            color: Color(0xFF3F86C8),
          ),
          const _ActivityRow(
            icon: Icons.people_outline,
            title: 'Jornales registrados',
            subtitle: 'Mantenimiento · Siembra A',
            time: 'Ayer, 16:20',
            color: agroGreen,
          ),
          const _ActivityRow(
            icon: Icons.inventory_2_outlined,
            title: 'Entrada de insumos',
            subtitle: 'Fertilizante granulado · 12 bultos',
            time: '28 sep, 11:05',
            color: Color(0xFFD47B27),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onProduction,
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Ir a producción'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _FarmHealthCard extends StatelessWidget {
  const _FarmHealthCard();
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Estado de tus fincas'),
          const SizedBox(height: 18),
          const _ProgressRow(
            label: 'El Porvenir',
            value: '12,5 ha',
            progress: .72,
            color: agroGreen,
          ),
          const SizedBox(height: 18),
          const _ProgressRow(
            label: 'La Esperanza',
            value: '7 ha',
            progress: .48,
            color: Color(0xFF4E83CC),
          ),
          const SizedBox(height: 18),
          const _ProgressRow(
            label: 'Los Naranjos',
            value: '5 ha',
            progress: .31,
            color: Color(0xFFD48432),
          ),
        ],
      ),
    ),
  );
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });
  final IconData icon;
  final String title, subtitle, time;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 11),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: color, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: agroMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        Text(time, style: const TextStyle(color: agroMuted, fontSize: 11)),
      ],
    ),
  );
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });
  final String label, value;
  final double progress;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(value, style: const TextStyle(color: agroMuted, fontSize: 12)),
        ],
      ),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          color: color,
          backgroundColor: const Color(0xFFE7ECE8),
        ),
      ),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action, this.onTap});
  final String title;
  final String? action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: agroInk,
        ),
      ),
      if (action != null) TextButton(onPressed: onTap, child: Text(action!)),
    ],
  );
}

class _OutlineAction extends StatelessWidget {
  const _OutlineAction({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: () {},
    icon: Icon(icon, size: 16),
    label: Text(label),
  );
}

class _ProductionPage extends StatelessWidget {
  const _ProductionPage();

  @override
  Widget build(BuildContext context) => _PageFrame(
    title: 'Producción',
    subtitle: 'Controla tus cultivos, procesos y actividades.',
    action: FilledButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Registrar'),
    ),
    child: ListView(
      children: [
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Pill(label: 'Cultivos', selected: true),
            _Pill(label: 'Procesos'),
            _Pill(label: 'Animales'),
          ],
        ),
        const SizedBox(height: 22),
        const _SectionTitle(title: 'Siembras en curso', action: 'Ver todas'),
        const SizedBox(height: 12),
        const _PlantingCard(
          name: 'Café · Lote 2',
          farm: 'El Porvenir',
          phase: 'Mantenimiento',
          progress: .68,
          status: 'Al día',
          color: agroGreen,
        ),
        const SizedBox(height: 12),
        const _PlantingCard(
          name: 'Plátano · Lote 1',
          farm: 'La Esperanza',
          phase: 'Producción 2',
          progress: .42,
          status: 'Atrasada',
          color: Color(0xFFD47B27),
        ),
        const SizedBox(height: 12),
        const _PlantingCard(
          name: 'Maíz · Lote 3',
          farm: 'Los Naranjos',
          phase: 'Cosecha',
          progress: .86,
          status: 'Al día',
          color: Color(0xFF4E83CC),
        ),
      ],
    ),
  );
}

class _MoneyPage extends StatelessWidget {
  const _MoneyPage();

  @override
  Widget build(BuildContext context) => _PageFrame(
    title: 'Dinero',
    subtitle: 'Una vista clara de ingresos, gastos y saldo.',
    action: FilledButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Nuevo movimiento'),
    ),
    child: ListView(
      children: [
        const Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MoneyMetric(
              label: 'Saldo disponible',
              value: '\$1.850.000',
              color: agroGreen,
            ),
            _MoneyMetric(
              label: 'Ingresos del mes',
              value: '\$4.250.000',
              color: Color(0xFF4E83CC),
            ),
            _MoneyMetric(
              label: 'Gastos del mes',
              value: '\$2.400.000',
              color: Color(0xFFD47B27),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _SectionTitle(
                  title: 'Movimientos recientes',
                  action: 'Ver todos',
                ),
                SizedBox(height: 8),
                _MoneyRow(
                  title: 'Jornales de socola',
                  category: 'Mano de obra · 28 sep',
                  amount: '-\$2.160.000',
                ),
                _MoneyRow(
                  title: 'Venta de cosecha',
                  category: 'Ingreso · 26 sep',
                  amount: '+\$3.450.000',
                ),
                _MoneyRow(
                  title: 'Fertilizante granulado',
                  category: 'Insumos · 25 sep',
                  amount: '-\$240.000',
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.selected = false});
  final String label;
  final bool selected;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: selected ? agroGreen : Colors.white,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: selected ? agroGreen : const Color(0xFFE1E8E2)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: selected ? Colors.white : agroMuted,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    ),
  );
}

class _PlantingCard extends StatelessWidget {
  const _PlantingCard({
    required this.name,
    required this.farm,
    required this.phase,
    required this.progress,
    required this.status,
    required this.color,
  });
  final String name, farm, phase, status;
  final double progress;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.eco_outlined, color: color),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$farm · $phase',
                      style: const TextStyle(color: agroMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: status == 'Al día'
                      ? const Color(0xFFE1F5E8)
                      : const Color(0xFFFFF0D1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: status == 'Al día'
                        ? agroGreen
                        : const Color(0xFF9A6814),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    color: color,
                    backgroundColor: const Color(0xFFE7ECE8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _MoneyMetric extends StatelessWidget {
  const _MoneyMetric({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 215,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: agroMuted, fontSize: 12)),
            const SizedBox(height: 13),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.title,
    required this.category,
    required this.amount,
  });
  final String title, category, amount;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        const Icon(Icons.receipt_long_outlined, color: agroMuted, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(
                category,
                style: const TextStyle(color: agroMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: amount.startsWith('+') ? agroGreen : agroInk,
          ),
        ),
      ],
    ),
  );
}

class _MorePage extends StatelessWidget {
  const _MorePage({required this.session, required this.onSignOut});
  final AuthSession session;
  final Future<void> Function() onSignOut;
  @override
  Widget build(BuildContext context) => _PageFrame(
    title: 'Más',
    subtitle: 'Configuración y herramientas de AgroGestion.',
    child: ListView(
      children: [
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(18),
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFFDDF1E2),
              child: Text(
                session.name.isEmpty ? 'A' : session.name[0],
                style: const TextStyle(
                  color: agroGreenDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            title: Text(
              session.name,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              '${session.email}\n${_SideBar._roleLabel(session.role)}',
            ),
            isThreeLine: true,
          ),
        ),
        const SizedBox(height: 16),
        const _ToolTile(
          icon: Icons.landscape_outlined,
          title: 'Mis fincas',
          detail: 'Fincas, lotes y ubicación',
        ),
        const _ToolTile(
          icon: Icons.menu_book_outlined,
          title: 'Ayuda y glosario',
          detail: 'Términos del agro explicados',
        ),
        const _ToolTile(
          icon: Icons.people_outline,
          title: 'Trabajadores',
          detail: 'Jornales y pagos pendientes',
        ),
        const SizedBox(height: 22),
        OutlinedButton.icon(
          onPressed: onSignOut,
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFB13B32),
            side: const BorderSide(color: Color(0xFFE2B5B0)),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    ),
  );
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final String title, detail;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
      leading: Icon(icon, color: agroGreen),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(detail),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}

void _showInfo(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
