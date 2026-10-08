import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/cards.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/forms.dart';
import '../../../core/widgets/layout.dart';
import '../../../core/widgets/states.dart';
import '../data/inventory_repository.dart';
import 'supply_detail_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final farm = app.activeFarm;
    return DetailScaffold(
      title: 'Insumos e inventario',
      subtitle: farm?.name ?? 'Sin finca activa',
      floating: app.access.managesInventory && farm != null
          ? FloatingActionButton.extended(
              onPressed: () async {
                final ok = await showAgroSheet<bool>(
                  context,
                  builder: (_) => _SupplyForm(app: app),
                );
                if (ok == true) app.markChanged();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nuevo insumo'),
            )
          : null,
      body: farm == null
          ? const AgroPage(
              children: [
                AgroCard(
                  child: EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Sin finca activa',
                    message: 'Registre una finca para llevar su inventario.',
                  ),
                ),
              ],
            )
          : AsyncBody<List<Supply>>(
              key: ValueKey('inv-${farm.id}-${app.revision}'),
              load: () => app.inventory.list(farm.id),
              builder: (context, all, reload) {
                final shown = all
                    .where(
                      (s) =>
                          s.name.toLowerCase().contains(_query.toLowerCase()),
                    )
                    .toList();
                final value = all.fold<double>(0, (s, i) => s + i.value);
                final empty = all.where((s) => s.stock <= 0).length;
                return AgroPage(
                  onRefresh: reload,
                  children: [
                    EqualGrid(
                      columns: 2,
                      children: [
                        KpiTile(
                          label: 'Valor estimado de la bodega',
                          value: formatNumber(value.round()),
                          prefix: '\$',
                          icon: Icons.warehouse_outlined,
                          caption: 'pesos (COP)',
                          badgeBackground: AgroColors.tertiaryFixed,
                          badgeForeground: AgroColors.tertiary,
                        ),
                        KpiTile(
                          label: 'Insumos sin existencias',
                          value: formatNumber(empty),
                          icon: Icons.warning_amber_rounded,
                          caption: 'de ${formatNumber(all.length)} registrados',
                          badgeBackground: empty > 0
                              ? AgroColors.errorContainer
                              : AgroColors.secondaryContainer,
                          badgeForeground: empty > 0
                              ? AgroColors.error
                              : AgroColors.primary,
                        ),
                      ],
                    ),
                    const Gap(16),
                    TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: const InputDecoration(
                        hintText: 'Buscar insumo',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                    const Gap(16),
                    if (shown.isEmpty)
                      AgroCard(
                        child: EmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: all.isEmpty
                              ? 'Aún no hay insumos'
                              : 'No hay insumos con ese nombre',
                          message: all.isEmpty
                              ? 'Registre fertilizantes, semillas o herramientas para llevar sus existencias.'
                              : null,
                        ),
                      )
                    else
                      for (final supply in shown)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _SupplyCard(supply: supply),
                        ),
                  ],
                );
              },
            ),
    );
  }
}

class _SupplyCard extends StatelessWidget {
  const _SupplyCard({required this.supply});

  final Supply supply;

  @override
  Widget build(BuildContext context) {
    final empty = supply.stock <= 0;
    return AgroCard(
      onTap: () => pushScreen(context, SupplyDetailScreen(supply: supply)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                icon: Icons.inventory_2_outlined,
                background: empty
                    ? AgroColors.errorContainer
                    : AgroColors.surfaceMid,
                foreground: empty
                    ? AgroColors.error
                    : AgroColors.primaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  supply.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AgroText.headlineMd.copyWith(fontSize: 18),
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(
                empty ? 'Sin existencias' : 'Disponible',
                tone: empty ? Tone.danger : Tone.ok,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AgroColors.surfaceLow,
              borderRadius: BorderRadius.circular(AgroRadius.md),
              border: Border.all(color: AgroColors.outlineVariant),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _Stat(
                    '${formatNumber(supply.stock, decimals: supply.stock % 1 == 0 ? 0 : 1)} ${supply.unit}',
                    'existencia',
                  ),
                  const VerticalDivider(width: 12),
                  _Stat(
                    supply.averageCost == null
                        ? '—'
                        : formatCop(supply.averageCost),
                    'costo promedio',
                  ),
                  const VerticalDivider(width: 12),
                  _Stat(formatCop(supply.value), 'valor'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AmountText(
          value,
          style: AgroText.monoSm.copyWith(
            color: AgroColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
          alignment: Alignment.centerLeft,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AgroText.bodySm.copyWith(fontSize: 11),
        ),
      ],
    ),
  );
}

class _SupplyForm extends StatefulWidget {
  const _SupplyForm({required this.app});

  final AppController app;

  @override
  State<_SupplyForm> createState() => _SupplyFormState();
}

class _SupplyFormState extends State<_SupplyForm> {
  final _name = TextEditingController();
  String _unit = 'bulto';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FormSheet(
    title: 'Nuevo insumo',
    subtitle: widget.app.activeFarm?.name,
    submitLabel: 'Guardar insumo',
    onSubmit: () => widget.app.inventory.create(
      widget.app.activeFarm!.id,
      name: _name.text.trim(),
      unit: _unit,
    ),
    children: [
      LabeledField(
        label: 'Nombre del insumo',
        controller: _name,
        maxLength: 150,
        textCapitalization: TextCapitalization.words,
        validator: requiredText,
      ),
      LabeledDropdown<String>(
        label: 'Unidad',
        value: _unit,
        items: const {
          'bulto': 'Bulto',
          'kilo': 'Kilo',
          'litro': 'Litro',
          'unidad': 'Unidad',
          'galón': 'Galón',
        },
        onChanged: (v) => setState(() => _unit = v ?? 'bulto'),
      ),
    ],
  );
}
