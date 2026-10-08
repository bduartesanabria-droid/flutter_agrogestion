import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/cards.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/forms.dart';
import '../../../core/widgets/layout.dart';
import '../../../core/widgets/states.dart';
import '../../production/domain/production.dart';
import '../data/inventory_repository.dart';

class SupplyDetailScreen extends StatelessWidget {
  const SupplyDetailScreen({required this.supply, super.key});

  final Supply supply;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final farm = app.activeFarm!;
    return AsyncBody<List<SupplyMovement>>(
      key: ValueKey('supply-${supply.id}-${app.revision}'),
      load: () => app.inventory.movements(farm.id, supply.id),
      skeleton: DetailScaffold(
        title: supply.name,
        body: const AgroPage(children: [SkeletonList(rowHeight: 120)]),
      ),
      builder: (context, movements, reload) {
        final current = supply;
        return DetailScaffold(
          title: current.name,
          subtitle: 'Bodega · ${farm.name}',
          body: AgroPage(
            onRefresh: reload,
            bottomClearance: AgroSpace.xl,
            children: [
              EqualGrid(
                columns: 3,
                children: [
                  KpiTile(
                    label: 'Existencia',
                    value: formatNumber(
                      current.stock,
                      decimals: current.stock % 1 == 0 ? 0 : 1,
                    ),
                    icon: Icons.inventory_2_outlined,
                    caption: current.unit,
                  ),
                  KpiTile(
                    label: 'Costo promedio',
                    value: current.averageCost == null
                        ? '—'
                        : formatNumber(current.averageCost!.round()),
                    prefix: current.averageCost == null ? null : '\$',
                    icon: Icons.price_change_outlined,
                    caption: 'por ${current.unit}',
                    badgeBackground: AgroColors.tertiaryFixed,
                    badgeForeground: AgroColors.tertiary,
                  ),
                  KpiTile(
                    label: 'Valor en bodega',
                    value: formatNumber(current.value.round()),
                    prefix: '\$',
                    icon: Icons.account_balance_wallet_outlined,
                    caption: 'pesos (COP)',
                    badgeBackground: AgroColors.surfaceHigh,
                    badgeForeground: AgroColors.primaryContainer,
                  ),
                ],
              ),
              if (app.access.managesInventory) ...[
                const Gap(16),
                WideButton(
                  label: 'Registrar entrada',
                  icon: Icons.add_shopping_cart_outlined,
                  onPressed: () async {
                    final ok = await showAgroSheet<bool>(
                      context,
                      builder: (_) => _EntryForm(app: app, supply: current),
                    );
                    if (ok == true) {
                      app.markChanged();
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                ),
                const Gap(12),
                WideButton(
                  label: 'Registrar consumo',
                  icon: Icons.output_rounded,
                  outlined: true,
                  onPressed: () async {
                    final ok = await showAgroSheet<bool>(
                      context,
                      builder: (_) =>
                          _ConsumptionForm(app: app, supply: current),
                    );
                    if (ok == true) {
                      app.markChanged();
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                ),
              ],
              const SectionTitle('Movimientos de kardex'),
              if (movements.isEmpty)
                const AgroCard(
                  child: EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Sin movimientos',
                    message:
                        'Las entradas y los consumos quedan aquí con su fecha.',
                  ),
                )
              else
                RowGroup(
                  children: [
                    for (final m in movements)
                      ListRow(
                        leading: IconBadge(
                          icon: m.isEntry
                              ? Icons.south_west_rounded
                              : Icons.north_east_rounded,
                          background: m.isEntry
                              ? AgroColors.secondaryContainer
                              : AgroColors.tertiaryFixed,
                          foreground: m.isEntry
                              ? AgroColors.primary
                              : AgroColors.tertiary,
                        ),
                        title: m.isEntry
                            ? 'Entrada de compra'
                            : 'Consumo en campo',
                        subtitle: m.isEntry && m.cost > 0
                            ? '${formatDate(m.date)} · inversión ${formatCop(m.cost)}'
                            : formatDate(m.date),
                        trailing: Text(
                          '${m.isEntry ? '+' : '-'}${formatNumber(m.quantity, decimals: m.quantity % 1 == 0 ? 0 : 1)} ${current.unit}',
                          style: AgroText.monoMd.copyWith(
                            color: m.isEntry
                                ? AgroColors.success
                                : AgroColors.error,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _EntryForm extends StatefulWidget {
  const _EntryForm({required this.app, required this.supply});

  final AppController app;
  final Supply supply;

  @override
  State<_EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<_EntryForm> {
  final _quantity = TextEditingController();
  final _cost = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _quantity.dispose();
    _cost.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FormSheet(
    title: 'Registrar entrada',
    subtitle: '${widget.supply.name} · ${widget.supply.unit}',
    submitLabel: 'Guardar entrada',
    onSubmit: () => widget.app.inventory.entry(
      widget.app.activeFarm!.id,
      supplyId: widget.supply.id,
      quantity: parseNumber(_quantity.text),
      cost: _cost.text.trim().isEmpty ? 0 : parseNumber(_cost.text),
      date: isoDate(_date),
    ),
    children: [
      LabeledField(
        label: 'Cantidad comprada',
        controller: _quantity,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: positiveNumber,
      ),
      LabeledField(
        label: 'Valor total de la compra (opcional)',
        controller: _cost,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        prefixText: 'COP \$ ',
        inputFormatters: moneyFormatters,
      ),
      DateField(
        label: 'Fecha',
        value: _date,
        lastDate: DateTime.now(),
        onChanged: (d) => setState(() => _date = d),
      ),
    ],
  );
}

class _ConsumptionForm extends StatefulWidget {
  const _ConsumptionForm({required this.app, required this.supply});

  final AppController app;
  final Supply supply;

  @override
  State<_ConsumptionForm> createState() => _ConsumptionFormState();
}

class _ConsumptionFormState extends State<_ConsumptionForm> {
  late final Future<List<Activity>> _activities = widget.app.production
      .activities(widget.app.activeFarm!.id);
  final _quantity = TextEditingController();
  String? _activityId;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Activity>>(
    future: _activities,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (snapshot.hasError) {
        return ErrorState(message: errorMessage(snapshot.error!));
      }
      final activities = snapshot.requireData;
      if (activities.isEmpty) {
        return const EmptyState(
          icon: Icons.handyman_outlined,
          title: 'Aún no hay labores',
          message: 'El consumo de un insumo se registra contra una labor. Registre primero la labor.',
        );
      }
      return FormSheet(
        title: 'Registrar consumo',
        subtitle:
            '${widget.supply.name} · existencia ${formatNumber(widget.supply.stock)} ${widget.supply.unit}',
        submitLabel: 'Guardar consumo',
        onSubmit: () => widget.app.inventory.consumption(
          widget.app.activeFarm!.id,
          supplyId: widget.supply.id,
          quantity: parseNumber(_quantity.text),
          activityId: _activityId!,
          date: isoDate(_date),
        ),
        children: [
          LabeledDropdown<String>(
            label: 'Labor donde se usó',
            value: _activityId,
            items: {for (final a in activities) a.id: a.name},
            validator: (v) => v == null ? 'Elija una labor.' : null,
            onChanged: (v) => setState(() => _activityId = v),
          ),
          LabeledField(
            label: 'Cantidad consumida',
            controller: _quantity,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: positiveNumber,
          ),
          DateField(
            label: 'Fecha',
            value: _date,
            lastDate: DateTime.now(),
            onChanged: (d) => setState(() => _date = d),
          ),
        ],
      );
    },
  );
}
