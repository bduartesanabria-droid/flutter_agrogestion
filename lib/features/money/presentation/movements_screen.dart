import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/cards.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/layout.dart';
import '../../../core/widgets/states.dart';
import '../data/money_repository.dart';
import 'money_tab.dart';
import 'movement_detail_screen.dart';

class MovementsScreen extends StatefulWidget {
  const MovementsScreen({super.key});

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> {
  int _kind = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final farm = app.activeFarm;
    return DetailScaffold(
      title: 'Movimientos',
      subtitle: farm?.name,
      body: farm == null
          ? const AgroPage(
              children: [
                AgroCard(
                  child: EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Sin finca activa',
                    message: 'Registre una finca para llevar sus movimientos.',
                  ),
                ),
              ],
            )
          : AsyncBody<List<Movement>>(
              key: ValueKey('movs-${app.revision}'),
              load: () => app.money.movements(farm.id),
              builder: (context, all, reload) {
                final expenses = all.where((m) => !m.isIncome).toList();
                final incomes = all.where((m) => m.isIncome).toList();
                final shown = _kind == 0 ? expenses : incomes;
                final active = shown.where((m) => !m.cancelled);
                final total = active.fold<double>(0, (s, m) => s + m.amount);
                return AgroPage(
                  onRefresh: reload,
                  bottomClearance: AgroSpace.xl,
                  children: [
                    SegmentedTabs(
                      labels: [
                        'Gastos (${expenses.length})',
                        'Ingresos (${incomes.length})',
                      ],
                      icons: const [
                        Icons.north_east_rounded,
                        Icons.south_west_rounded,
                      ],
                      selected: _kind,
                      onSelected: (i) => setState(() => _kind = i),
                    ),
                    const Gap(12),
                    AgroCard(
                      color: AgroColors.surfaceLow,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _kind == 0
                                  ? 'Total de gastos'
                                  : 'Total de ingresos',
                              style: AgroText.labelMd,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AmountText(
                            formatCop(total),
                            color: _kind == 0
                                ? AgroColors.error
                                : AgroColors.success,
                            style: AgroText.monoXl,
                          ),
                        ],
                      ),
                    ),
                    const Gap(16),
                    if (shown.isEmpty)
                      AgroCard(
                        child: EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: _kind == 0
                              ? 'Aún no hay gastos'
                              : 'Aún no hay ingresos',
                          message: 'Use el botón Registrar de la pantalla principal.',
                        ),
                      )
                    else
                      RowGroup(
                        children: [
                          for (final m in shown)
                            MovementRow(
                              movement: m,
                              onTap: () => pushScreen(
                                context,
                                MovementDetailScreen(movement: m),
                              ),
                            ),
                        ],
                      ),
                  ],
                );
              },
            ),
    );
  }
}
