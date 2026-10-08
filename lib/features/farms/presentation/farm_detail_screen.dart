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
import '../../production/domain/production.dart';
import '../domain/farm.dart';
import 'lot_detail_screen.dart';

class _FarmData {
  const _FarmData(this.lots, this.plantings);

  final List<Lot> lots;
  final List<Planting> plantings;
}

class FarmDetailScreen extends StatelessWidget {
  const FarmDetailScreen({required this.farm, super.key});

  final Farm farm;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return AsyncBody<_FarmData>(
      key: ValueKey('farm-${farm.id}-${app.revision}'),
      load: () async {
        final lots = await app.farmsRepo.lots(farm.id);
        var plantings = <Planting>[];
        if (app.access.seesProduction) {
          try {
            await app.crops();
            plantings = (await app.production.plantings()).items
                .where((p) => p.farmId == farm.id)
                .toList();
          } catch (_) {}
        }
        return _FarmData(lots, plantings);
      },
      skeleton: DetailScaffold(
        title: farm.name,
        body: const AgroPage(children: [SkeletonList(rowHeight: 120)]),
      ),
      builder: (context, data, reload) {
        final active = data.plantings.where((p) => p.status == 'en_curso');
        final planted = active.fold<double>(0, (s, p) => s + p.areaHa);
        final total =
            farm.areaHa ?? data.lots.fold<double>(0, (s, l) => s + l.areaHa);
        final free = (total - planted).clamp(0, double.infinity).toDouble();
        final ratio = total <= 0
            ? 0.0
            : (planted / total).clamp(0, 1).toDouble();
        return DetailScaffold(
          title: farm.name,
          subtitle: farm.municipalityCode == null
              ? 'Ubicación sin registrar'
              : 'Municipio DANE ${farm.municipalityCode}',
          floating: app.access.createsFarms
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    final ok = await showAgroSheet<bool>(
                      context,
                      builder: (_) => _LotForm(app: app, farm: farm),
                    );
                    if (ok == true) await reload();
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Agregar lote'),
                )
              : null,
          body: AgroPage(
            onRefresh: reload,
            children: [
              AgroCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const IconBadge(
                          icon: Icons.straighten_rounded,
                          size: 32,
                          circle: true,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'DISTRIBUCIÓN TERRITORIAL',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AgroText.labelSm,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _Metric(
                          'Área total',
                          formatHa(total),
                          AgroColors.onSurface,
                        ),
                        _Metric(
                          'Sembrada',
                          formatHa(planted),
                          AgroColors.primaryContainer,
                        ),
                        _Metric(
                          'Libre',
                          formatHa(free),
                          AgroColors.onSurfaceVariant,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ProgressLine(value: ratio, height: 12),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${formatNumber(ratio * 100, decimals: 0)}% sembrada',
                            style: AgroText.bodySm,
                          ),
                        ),
                        Text(
                          '${formatNumber((1 - ratio) * 100, decimals: 0)}% disponible',
                          style: AgroText.bodySm,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SectionTitle(
                'Lotes registrados',
                caption: 'Gestión individual por cuartel',
                trailing: StatusPill('${data.lots.length}', tone: Tone.neutral),
              ),
              if (data.lots.isEmpty)
                const AgroCard(
                  child: EmptyState(
                    icon: Icons.grid_view_rounded,
                    title: 'Esta finca aún no tiene lotes',
                    message: 'Los lotes dividen la finca para sembrar y llevar costos por cuartel.',
                  ),
                )
              else
                for (final lot in data.lots)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _LotCard(
                      lot: lot,
                      farmArea: total,
                      planting: data.plantings
                          .where(
                            (p) => p.lotId == lot.id && p.status == 'en_curso',
                          )
                          .firstOrNull,
                      onTap: () => pushScreen(
                        context,
                        LotDetailScreen(farm: farm, lot: lot),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AgroText.bodySm,
        ),
        const SizedBox(height: 2),
        AmountText(
          value,
          style: AgroText.monoMd,
          color: color,
          alignment: Alignment.centerLeft,
        ),
      ],
    ),
  );
}

class _LotCard extends StatelessWidget {
  const _LotCard({
    required this.lot,
    required this.farmArea,
    required this.planting,
    required this.onTap,
  });

  final Lot lot;
  final double farmArea;
  final Planting? planting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final share = farmArea <= 0 ? 0 : lot.areaHa / farmArea * 100;
    return AgroCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                icon: planting == null
                    ? Icons.crop_free_rounded
                    : Icons.eco_outlined,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lot.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AgroText.headlineMd.copyWith(fontSize: 18),
                    ),
                    Text(
                      planting == null
                          ? 'Sin siembra activa'
                          : app.cropName(planting!.cropId),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AgroText.bodySm,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AgroColors.outline,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${formatHa(lot.areaHa)} · ${formatNumber(share, decimals: 0)}% del predio',
                  style: AgroText.monoSm,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(
                planting == null ? 'Libre' : 'En producción',
                tone: planting == null ? Tone.neutral : Tone.ok,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LotForm extends StatefulWidget {
  const _LotForm({required this.app, required this.farm});

  final AppController app;
  final Farm farm;

  @override
  State<_LotForm> createState() => _LotFormState();
}

class _LotFormState extends State<_LotForm> {
  final _name = TextEditingController();
  final _area = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _area.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FormSheet(
    title: 'Agregar lote',
    subtitle: widget.farm.name,
    submitLabel: 'Guardar lote',
    onSubmit: () => widget.app.farmsRepo.createLot(
      widget.farm.id,
      name: _name.text.trim(),
      areaHa: parseNumber(_area.text),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    ),
    children: [
      LabeledField(
        label: 'Nombre del lote',
        controller: _name,
        maxLength: 150,
        textCapitalization: TextCapitalization.words,
        validator: requiredText,
      ),
      LabeledField(
        label: 'Área en hectáreas',
        controller: _area,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: positiveNumber,
      ),
      LabeledField(
        label: 'Notas (opcional)',
        controller: _notes,
        maxLines: 2,
        maxLength: 500,
      ),
    ],
  );
}
