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
import '../domain/farm.dart';
import 'farm_detail_screen.dart';

class FarmsScreen extends StatefulWidget {
  const FarmsScreen({super.key});

  @override
  State<FarmsScreen> createState() => _FarmsScreenState();
}

class _FarmsScreenState extends State<FarmsScreen> {
  String _query = '';

  Future<void> _create() async {
    final app = context.app;
    final ok = await showAgroSheet<bool>(
      context,
      builder: (_) => _FarmForm(app: app),
    );
    if (ok == true) await app.loadFarms();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final farms = app.farms
        .where((f) => f.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    final total = app.farms.fold<double>(0, (s, f) => s + (f.areaHa ?? 0));
    return DetailScaffold(
      title: 'Mis fincas',
      subtitle: 'Fincas y lotes',
      floating: app.access.createsFarms
          ? FloatingActionButton.extended(
              onPressed: _create,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nueva finca'),
            )
          : null,
      body: AgroPage(
        onRefresh: app.loadFarms,
        children: [
          EqualGrid(
            columns: 2,
            children: [
              KpiTile(
                label: 'Área registrada',
                value: formatNumber(total, decimals: 1),
                icon: Icons.landscape_outlined,
                caption: 'hectáreas en total',
              ),
              KpiTile(
                label: 'Fincas',
                value: formatNumber(app.farms.length),
                icon: Icons.domain_outlined,
                caption: 'a su cargo',
                badgeBackground: AgroColors.surfaceHigh,
                badgeForeground: AgroColors.primaryContainer,
              ),
            ],
          ),
          const Gap(16),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Buscar finca',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const Gap(16),
          if (app.farmsLoading && app.farms.isEmpty)
            const SkeletonList()
          else if (app.farmsError != null && app.farms.isEmpty)
            ErrorState(message: app.farmsError!, onRetry: app.loadFarms)
          else if (farms.isEmpty)
            AgroCard(
              child: EmptyState(
                icon: Icons.landscape_outlined,
                title: _query.isEmpty
                    ? 'Registre su primera finca para empezar'
                    : 'No hay fincas con ese nombre',
                message: _query.isEmpty
                    ? 'Con una finca puede crear lotes, siembras y llevar sus cuentas.'
                    : null,
                actionLabel: app.access.createsFarms && _query.isEmpty
                    ? 'Nueva finca'
                    : null,
                onAction: _create,
              ),
            )
          else
            for (final farm in farms)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _FarmCard(
                  farm: farm,
                  active: farm.id == app.activeFarm?.id,
                ),
              ),
        ],
      ),
    );
  }
}

class _FarmCard extends StatelessWidget {
  const _FarmCard({required this.farm, required this.active});

  final Farm farm;
  final bool active;

  @override
  Widget build(BuildContext context) => AgroCard(
    onTap: () => pushScreen(context, FarmDetailScreen(farm: farm)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const IconBadge(icon: Icons.landscape_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    farm.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AgroText.headlineMd,
                  ),
                  Text(
                    farm.municipalityCode == null
                        ? 'Ubicación sin registrar'
                        : 'Municipio DANE ${farm.municipalityCode}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AgroText.bodySm,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AgroColors.outline),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            StatusPill(
              active ? 'Finca activa' : 'Registrada',
              tone: active ? Tone.ok : Tone.neutral,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AgroColors.surfaceLow,
            borderRadius: BorderRadius.circular(AgroRadius.md),
          ),
          child: Row(
            children: [
              Expanded(child: Text('Área total', style: AgroText.bodySm)),
              const SizedBox(width: 8),
              AmountText(
                farm.areaHa == null ? 'Sin registrar' : formatHa(farm.areaHa),
                color: AgroColors.primary,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _FarmForm extends StatefulWidget {
  const _FarmForm({required this.app});

  final AppController app;

  @override
  State<_FarmForm> createState() => _FarmFormState();
}

class _FarmFormState extends State<_FarmForm> {
  final _name = TextEditingController();
  final _area = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _area.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FormSheet(
    title: 'Nueva finca',
    submitLabel: 'Guardar finca',
    onSubmit: () => widget.app.farmsRepo.create(
      name: _name.text.trim(),
      areaHa: _area.text.trim().isEmpty ? null : parseNumber(_area.text),
    ),
    children: [
      LabeledField(
        label: 'Nombre de la finca',
        controller: _name,
        maxLength: 150,
        textCapitalization: TextCapitalization.words,
        validator: requiredText,
      ),
      LabeledField(
        label: 'Área total en hectáreas (opcional)',
        controller: _area,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    ],
  );
}
