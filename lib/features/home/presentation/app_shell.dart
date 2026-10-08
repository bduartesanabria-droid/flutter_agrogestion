import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/layout.dart';
import '../../account/presentation/account_screen.dart';
import '../../content/presentation/news_screen.dart';
import '../../money/presentation/money_tab.dart';
import '../../production/presentation/production_tab.dart';
import 'farm_selector.dart';
import 'home_tab.dart';
import 'more_tab.dart';
import 'quick_register_sheet.dart';

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon, this.builder);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final WidgetBuilder builder;
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  List<_Destination> _destinations(BuildContext context) {
    final access = context.app.access;
    return [
      _Destination(
        'Inicio',
        Icons.home_outlined,
        Icons.home_rounded,
        (_) => HomeTab(onOpenTab: _openByLabel),
      ),
      if (access.seesProduction)
        _Destination(
          'Producción',
          Icons.eco_outlined,
          Icons.eco,
          (_) => const ProductionTab(),
        ),
      if (access.seesMoney)
        _Destination(
          'Dinero',
          Icons.account_balance_wallet_outlined,
          Icons.account_balance_wallet,
          (_) => const MoneyTab(),
        ),
      _Destination(
        'Más',
        Icons.menu_rounded,
        Icons.menu_rounded,
        (_) => const MoreTab(),
      ),
    ];
  }

  void _openByLabel(String label) {
    final list = _destinations(context);
    final i = list.indexWhere((d) => d.label == label);
    if (i >= 0) setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.app;
    final destinations = _destinations(context);
    final index = _index.clamp(0, destinations.length - 1);
    final current = destinations[index];
    final showFab =
        controller.access.canQuickRegister && current.label != 'Más';

    final body = KeyedSubtree(
      key: ValueKey('${current.label}-${controller.revision}'),
      child: current.builder(context),
    );

    final fab = showFab
        ? _RegisterButton(onPressed: () => showQuickRegister(context))
        : null;

    if (isWide(context)) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(
              destinations: destinations,
              index: index,
              onSelected: (i) => setState(() => _index = i),
            ),
            Expanded(
              child: Column(
                children: [
                  const _TopBar(showBrand: false),
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: fab,
      );
    }

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: _TopBar(showBrand: true),
      ),
      body: body,
      floatingActionButton: fab,
      bottomNavigationBar: _BottomBar(
        destinations: destinations,
        index: index,
        onSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _RegisterButton extends StatelessWidget {
  const _RegisterButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      minimumSize: const Size(0, 52),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      elevation: 6,
      shadowColor: AgroColors.primary.withValues(alpha: 0.35),
    ),
    icon: const Icon(Icons.add_rounded, size: 22),
    label: const Text('Registrar', maxLines: 1, softWrap: false),
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.showBrand});

  final bool showBrand;

  @override
  Widget build(BuildContext context) => Material(
    color: AgroColors.surface,
    child: Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AgroColors.outlineVariant)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AgroSpace.md),
            child: Row(
              children: [
                if (showBrand) ...[
                  const _BrandMark(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'AgroGestión',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AgroText.headlineMd.copyWith(
                        color: AgroColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ] else
                  const Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 380,
                        child: FarmSelector(compact: true),
                      ),
                    ),
                  ),
                IconButton(
                  tooltip: 'Novedades de mi región',
                  onPressed: () => pushScreen(context, const NewsScreen()),
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
                IconButton(
                  tooltip: 'Mi cuenta',
                  onPressed: () => pushScreen(context, const AccountScreen()),
                  icon: const Icon(Icons.account_circle_outlined),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: AgroColors.secondaryContainer,
      borderRadius: BorderRadius.circular(AgroRadius.md),
    ),
    child: const Icon(Icons.eco_rounded, color: AgroColors.primary, size: 22),
  );
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.destinations,
    required this.index,
    required this.onSelected,
  });

  final List<_Destination> destinations;
  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Material(
    color: AgroColors.surfaceLowest,
    child: Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AgroColors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == index,
                    label: destinations[i].label,
                    child: InkWell(
                      onTap: () => onSelected(i),
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 64,
                            minHeight: 52,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: i == index
                                ? AgroColors.secondaryContainer
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(AgroRadius.md),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                i == index
                                    ? destinations[i].selectedIcon
                                    : destinations[i].icon,
                                size: 24,
                                color: i == index
                                    ? AgroColors.primary
                                    : AgroColors.onSurfaceVariant,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                destinations[i].label,
                                maxLines: 1,
                                softWrap: false,
                                style: AgroText.labelSm.copyWith(
                                  letterSpacing: 0.1,
                                  color: i == index
                                      ? AgroColors.primary
                                      : AgroColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.destinations,
    required this.index,
    required this.onSelected,
  });

  final List<_Destination> destinations;
  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return Container(
      width: 256,
      color: const Color(0xFF104E39),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AgroSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const _BrandMark(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'AgroGestión',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AgroText.headlineMd.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AgroSpace.lg),
              for (var i = 0; i < destinations.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Semantics(
                    button: true,
                    selected: i == index,
                    label: destinations[i].label,
                    child: Material(
                      color: i == index
                          ? Colors.white.withValues(alpha: 0.14)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AgroRadius.md),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AgroRadius.md),
                        onTap: () => onSelected(i),
                        child: SizedBox(
                          height: 48,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Icon(
                                  i == index
                                      ? destinations[i].selectedIcon
                                      : destinations[i].icon,
                                  color: i == index
                                      ? Colors.white
                                      : AgroColors.onPrimaryContainer,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    destinations[i].label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AgroText.labelMd.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AgroRadius.md),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AgroColors.secondaryContainer,
                      child: Text(
                        app.session.name.isEmpty
                            ? '?'
                            : app.session.name[0].toUpperCase(),
                        style: AgroText.labelMd.copyWith(
                          color: AgroColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.session.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AgroText.labelMd.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            app.access.roleLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AgroText.bodySm.copyWith(
                              color: AgroColors.onPrimaryContainer,
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
        ),
      ),
    );
  }
}
