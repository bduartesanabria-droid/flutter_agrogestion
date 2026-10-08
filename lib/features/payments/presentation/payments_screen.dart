import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/api/api_client.dart';
import '../../../core/format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/cards.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/layout.dart';
import '../../../core/widgets/states.dart';
import '../data/payments_repository.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  int _grouping = 0;
  final Set<String> _selected = {};
  bool _paying = false;
  int _generation = 0;

  Map<String, List<Jornal>> _groups(List<Jornal> items) {
    final groups = <String, List<Jornal>>{};
    for (final j in items) {
      groups
          .putIfAbsent(_grouping == 0 ? j.payee : j.activityName, () => [])
          .add(j);
    }
    return groups;
  }

  Future<void> _pay(List<Jornal> chosen) async {
    final app = context.app;
    final farm = app.activeFarm!;
    final total = chosen.fold<double>(0, (s, j) => s + j.total);
    final yes = await confirmDialog(
      context,
      title: 'Marcar como pagado',
      message:
          '${chosen.length} jornales por ${formatCop(total)}. Se registra un gasto de mano de obra por cada pago.',
      confirmLabel: 'Marcar como pagado',
    );
    if (!yes || !mounted) return;
    setState(() => _paying = true);
    var paid = 0;
    try {
      for (final j in chosen) {
        await app.payments.pay(farm.id, j.id);
        paid++;
      }
      if (mounted) showSnack(context, '$paid jornales marcados como pagados.');
    } on ApiException catch (error) {
      if (mounted) showSnack(context, error.message, error: true);
    } catch (_) {
      if (mounted) {
        showSnack(context, 'No hay conexión con el servidor.', error: true);
      }
    } finally {
      if (mounted) {
        app.markChanged();
        setState(() {
          _paying = false;
          _selected.clear();
          _generation++;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final farm = app.activeFarm;
    if (farm == null) {
      return const DetailScaffold(
        title: 'Pagos pendientes',
        body: AgroPage(
          children: [
            AgroCard(
              child: EmptyState(
                icon: Icons.payments_outlined,
                title: 'Sin finca activa',
                message: 'Registre una finca para llevar sus pagos.',
              ),
            ),
          ],
        ),
      );
    }
    return AsyncBody<List<Jornal>>(
      key: ValueKey('pay-${farm.id}-$_generation'),
      load: () => app.payments.list(farm.id, status: 'pendiente'),
      skeleton: const DetailScaffold(
        title: 'Pagos pendientes',
        body: AgroPage(children: [SkeletonList(rowHeight: 120)]),
      ),
      builder: (context, items, reload) {
        final groups = _groups(items);
        final total = items.fold<double>(0, (s, j) => s + j.total);
        final days = items.fold<double>(0, (s, j) => s + j.workDays);
        final chosen = [
          for (final entry in groups.entries)
            if (_selected.contains(entry.key)) ...entry.value,
        ];
        final chosenTotal = chosen.fold<double>(0, (s, j) => s + j.total);
        final canPay = app.access.paysWorkers;
        return DetailScaffold(
          title: 'Pagos pendientes',
          subtitle: farm.name,
          bottom: canPay && items.isNotEmpty
              ? _PayBar(
                  count: _selected.length,
                  total: chosenTotal,
                  busy: _paying,
                  onPay: chosen.isEmpty ? null : () => _pay(chosen),
                )
              : null,
          body: AgroPage(
            onRefresh: reload,
            bottomClearance: AgroSpace.xl,
            children: [
              SegmentedTabs(
                labels: const ['Por trabajador', 'Por labor'],
                icons: const [Icons.person_outline, Icons.handyman_outlined],
                selected: _grouping,
                onSelected: (i) => setState(() {
                  _grouping = i;
                  _selected.clear();
                }),
              ),
              const Gap(12),
              AgroCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL ACUMULADO POR LIQUIDAR',
                      style: AgroText.labelSm,
                    ),
                    const SizedBox(height: 8),
                    AmountText(
                      formatCop(total),
                      style: AgroText.monoXl.copyWith(
                        fontSize: 30,
                        color: AgroColors.primary,
                      ),
                      alignment: Alignment.centerLeft,
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${formatNumber(groups.length)} ${_grouping == 0 ? 'beneficiarios' : 'labores'}',
                            style: AgroText.bodySm,
                          ),
                        ),
                        Text(
                          '${formatNumber(days, decimals: days % 1 == 0 ? 0 : 1)} jornales',
                          style: AgroText.bodySm,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SectionTitle(
                _grouping == 0
                    ? 'Partidas por trabajador'
                    : 'Partidas por labor',
                trailing: canPay && groups.isNotEmpty
                    ? TextLinkButton(
                        _selected.length == groups.length
                            ? 'Quitar selección'
                            : 'Seleccionar todos',
                        () => setState(() {
                          if (_selected.length == groups.length) {
                            _selected.clear();
                          } else {
                            _selected
                              ..clear()
                              ..addAll(groups.keys);
                          }
                        }),
                      )
                    : null,
              ),
              if (groups.isEmpty)
                const AgroCard(
                  child: EmptyState(
                    icon: Icons.task_alt_rounded,
                    title: 'No hay pagos pendientes',
                    message: 'Los jornales que registre aparecen aquí hasta que los marque como pagados.',
                  ),
                )
              else
                for (final entry in groups.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _GroupCard(
                      title: entry.key,
                      items: entry.value,
                      selectable: canPay,
                      selected: _selected.contains(entry.key),
                      onChanged: (v) => setState(() {
                        if (v) {
                          _selected.add(entry.key);
                        } else {
                          _selected.remove(entry.key);
                        }
                      }),
                    ),
                  ),
              const Gap(8),
              const AgroCard(
                color: AgroColors.surfaceLow,
                elevated: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 20,
                      color: AgroColors.primaryContainer,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Cada pago genera un solo gasto de mano de obra y queda auditado (Ley 1581 de 2012).',
                        style: AgroText.bodySm,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.title,
    required this.items,
    required this.selectable,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final List<Jornal> items;
  final bool selectable;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (s, j) => s + j.total);
    final days = items.fold<double>(0, (s, j) => s + j.workDays);
    final subtitle = items.length == 1
        ? '${items.first.activityName} · ${formatDateShort(items.first.date)}'
        : '${items.length} registros';
    return AgroCard(
      onTap: selectable ? () => onChanged(!selected) : null,
      child: Row(
        children: [
          if (selectable)
            Checkbox(
              value: selected,
              onChanged: (v) => onChanged(v ?? false),
              materialTapTargetSize: MaterialTapTargetSize.padded,
            )
          else
            const IconBadge(icon: Icons.person_outline),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AgroText.labelMd.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  '$subtitle · ${formatNumber(days, decimals: days % 1 == 0 ? 0 : 1)} jornales',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AgroText.bodySm,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AmountText(formatCop(total)),
        ],
      ),
    );
  }
}

class _PayBar extends StatelessWidget {
  const _PayBar({
    required this.count,
    required this.total,
    required this.busy,
    required this.onPay,
  });

  final int count;
  final double total;
  final bool busy;
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) => Material(
    color: AgroColors.surfaceLowest,
    child: Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AgroColors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AgroSpace.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'TOTAL A LIQUIDAR ($count seleccionados)',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AgroText.labelSm,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AmountText(formatCop(total), style: AgroText.monoXl),
                ],
              ),
              const SizedBox(height: 12),
              WideButton(
                label: 'Marcar como pagado',
                icon: Icons.check_circle_outline,
                busy: busy,
                onPressed: onPay,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
