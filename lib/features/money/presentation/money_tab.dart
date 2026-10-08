import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/cards.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/layout.dart';
import '../../../core/widgets/states.dart';
import '../../home/presentation/farm_selector.dart';
import '../data/money_repository.dart';
import 'movement_detail_screen.dart';
import 'movements_screen.dart';

const _categoryColors = [
  AgroColors.primary,
  AgroColors.secondary,
  AgroColors.tertiaryContainer,
  AgroColors.outline,
  AgroColors.info,
  AgroColors.error,
];

class _MoneyData {
  const _MoneyData({required this.flow, required this.movements});

  final CashFlow flow;
  final List<Movement> movements;

  Map<String, double> get byCategory {
    final totals = <String, double>{};
    for (final m in movements) {
      if (m.isIncome || m.cancelled) continue;
      totals.update(m.category, (v) => v + m.amount, ifAbsent: () => m.amount);
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in entries) e.key: e.value};
  }
}

class MoneyTab extends StatefulWidget {
  const MoneyTab({super.key});

  @override
  State<MoneyTab> createState() => _MoneyTabState();
}

class _MoneyTabState extends State<MoneyTab> {
  int _period = 0;

  DateTime get _month {
    final now = DateTime.now();
    return _period == 0
        ? DateTime(now.year, now.month)
        : DateTime(now.year, now.month - 1);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final farm = app.activeFarm;
    if (farm == null) {
      return const AgroPage(
        children: [
          FarmSelector(inPage: true),
          Gap(16),
          AgroCard(
            child: EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Registre una finca para ver su dinero',
              message: 'Los gastos e ingresos se llevan por finca.',
            ),
          ),
        ],
      );
    }
    return AsyncBody<_MoneyData>(
      key: ValueKey('money-${farm.id}-$_period'),
      load: () async => _MoneyData(
        flow: await app.money.cashFlow(farm.id, month: _month),
        movements: await app.money.movements(farm.id),
      ),
      skeleton: const AgroPage(
        children: [
          FarmSelector(inPage: true),
          Gap(16),
          SkeletonList(rowHeight: 160),
        ],
      ),
      builder: (context, data, reload) {
        final access = app.access;
        final flow = data.flow;
        final positive = flow.balance >= 0;
        final categories = data.byCategory;
        final totalExpenses = categories.values.fold<double>(
          0,
          (a, b) => a + b,
        );
        final recent = data.movements.reversed.take(5).toList();
        return AgroPage(
          onRefresh: reload,
          children: [
            const FarmSelector(inPage: true),
            const Gap(12),
            Text('Dinero y finanzas', style: AgroText.headlineMd),
            const Gap(8),
            FilterBar(
              labels: const ['Este mes', 'Mes pasado'],
              selected: _period,
              onSelected: (i) => setState(() => _period = i),
            ),
            const Gap(12),
            AgroCard(
              elevated: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (access.seesProfit) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'SALDO NETO DISPONIBLE',
                            maxLines: 2,
                            style: AgroText.labelMd.copyWith(
                              color: AgroColors.onSurfaceVariant,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusPill(
                          positive ? 'Flujo positivo' : 'Flujo negativo',
                          tone: positive ? Tone.ok : Tone.danger,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AmountText(
                          formatCop(flow.balance),
                          style: AgroText.monoXl.copyWith(fontSize: 30),
                          alignment: Alignment.centerLeft,
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('COP', style: AgroText.monoSm),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                  ],
                  _FlowRow(
                    label: 'Ingresos del mes',
                    amount: flow.income,
                    income: true,
                  ),
                  const SizedBox(height: 8),
                  _FlowRow(
                    label: 'Gastos del mes',
                    amount: flow.expenses,
                    income: false,
                  ),
                  if (access.seesProfit && flow.margin != null) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.bar_chart_rounded,
                          size: 20,
                          color: AgroColors.primaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Margen operativo estimado',
                            style: AgroText.bodySm.copyWith(
                              color: AgroColors.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          '${formatNumber(flow.margin, decimals: 1)}%',
                          style: AgroText.monoMd.copyWith(
                            color: AgroColors.primaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SectionTitle('Distribución del gasto'),
            AgroCard(
              child: categories.isEmpty
                  ? const EmptyState(
                      icon: Icons.pie_chart_outline_rounded,
                      title: 'Aún no hay gastos',
                      message: 'Cuando registre gastos verá aquí en qué se va el dinero.',
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total registrado: ${formatCop(totalExpenses)}',
                          style: AgroText.bodySm,
                        ),
                        const SizedBox(height: 12),
                        _StackedBar(
                          values: categories.values.toList(),
                          total: totalExpenses,
                        ),
                        const SizedBox(height: 12),
                        for (var i = 0; i < categories.length; i++)
                          _CategoryRow(
                            color: _categoryColors[i % _categoryColors.length],
                            name: categories.keys.elementAt(i),
                            amount: categories.values.elementAt(i),
                            share:
                                categories.values.elementAt(i) / totalExpenses,
                          ),
                      ],
                    ),
            ),
            SectionTitle(
              'Últimos movimientos',
              trailing: TextLinkButton(
                'Ver todos',
                () => pushScreen(context, const MovementsScreen()),
                icon: Icons.arrow_forward_rounded,
              ),
            ),
            if (recent.isEmpty)
              const AgroCard(
                child: EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Sin movimientos',
                  message:
                      'Registre un gasto o un ingreso con el botón Registrar.',
                ),
              )
            else
              RowGroup(
                children: [
                  for (final m in recent)
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
    );
  }
}

class _FlowRow extends StatelessWidget {
  const _FlowRow({
    required this.label,
    required this.amount,
    required this.income,
  });

  final String label;
  final double amount;
  final bool income;

  @override
  Widget build(BuildContext context) {
    final color = income ? AgroColors.success : AgroColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AgroColors.surfaceLow,
        borderRadius: BorderRadius.circular(AgroRadius.md),
        border: Border.all(color: AgroColors.outlineVariant),
      ),
      child: Row(
        children: [
          IconBadge(
            icon: income
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 36,
            circle: true,
            background: income
                ? AgroColors.secondaryContainer
                : AgroColors.errorContainer,
            foreground: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AgroText.labelMd,
            ),
          ),
          const SizedBox(width: 8),
          AmountText(formatCop(amount), color: color),
        ],
      ),
    );
  }
}

class _StackedBar extends StatelessWidget {
  const _StackedBar({required this.values, required this.total});

  final List<double> values;
  final double total;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AgroRadius.pill),
    child: SizedBox(
      height: 12,
      child: Row(
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              flex: ((values[i] / total) * 1000).round().clamp(1, 1000),
              child: Container(
                color: _categoryColors[i % _categoryColors.length],
              ),
            ),
        ],
      ),
    ),
  );
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.color,
    required this.name,
    required this.amount,
    required this.share,
  });

  final Color color;
  final String name;
  final double amount;
  final double share;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AgroColors.surfaceLow,
        borderRadius: BorderRadius.circular(AgroRadius.md),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AgroText.labelMd,
                ),
                Text(
                  '${formatNumber(share * 100, decimals: 0)}% del gasto',
                  style: AgroText.bodySm,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AmountText(formatCop(amount), style: AgroText.monoSm),
        ],
      ),
    ),
  );
}

class MovementRow extends StatelessWidget {
  const MovementRow({required this.movement, this.onTap, super.key});

  final Movement movement;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final m = movement;
    final color = m.cancelled
        ? AgroColors.outline
        : m.isIncome
        ? AgroColors.success
        : AgroColors.error;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              IconBadge(
                icon: m.cancelled
                    ? Icons.block_rounded
                    : m.isIncome
                    ? Icons.local_shipping_outlined
                    : Icons.groups_outlined,
                background: m.cancelled
                    ? AgroColors.surfaceHigh
                    : m.isIncome
                    ? AgroColors.secondaryContainer
                    : AgroColors.errorContainer,
                foreground: color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.category,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AgroText.labelMd.copyWith(
                        decoration: m.cancelled
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (m.cancelled)
                      const StatusPill('Anulado', tone: Tone.neutral)
                    else
                      Text(
                        m.isIncome ? 'Ingreso' : 'Gasto',
                        style: AgroText.bodySm,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AmountText(
                '${m.isIncome ? '+' : '-'} ${formatCop(m.amount)}',
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
