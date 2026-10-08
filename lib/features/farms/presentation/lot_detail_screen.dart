import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/cards.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/layout.dart';
import '../../../core/widgets/states.dart';
import '../../home/presentation/work_forms.dart';
import '../../production/domain/production.dart';
import '../../production/presentation/labels.dart';
import '../../production/presentation/planting_detail_screen.dart';
import '../../production/presentation/planting_form.dart';
import '../domain/farm.dart';

class LotDetailScreen extends StatelessWidget {
  const LotDetailScreen({required this.farm, required this.lot, super.key});

  final Farm farm;
  final Lot lot;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return AsyncBody<List<Planting>>(
      key: ValueKey('lot-${lot.id}-${app.revision}'),
      load: () async {
        await app.crops();
        final all = await app.production.plantings();
        return all.items.where((p) => p.lotId == lot.id).toList();
      },
      skeleton: DetailScaffold(
        title: lot.name,
        subtitle: farm.name,
        body: const AgroPage(children: [SkeletonList(rowHeight: 120)]),
      ),
      builder: (context, plantings, reload) {
        final active = plantings
            .where((p) => p.status == 'en_curso')
            .firstOrNull;
        final past = plantings.where((p) => p.status != 'en_curso').toList();
        final planted = active?.areaHa ?? 0;
        return DetailScaffold(
          title: lot.name,
          subtitle: farm.name,
          body: AgroPage(
            onRefresh: reload,
            children: [
              EqualGrid(
                columns: 3,
                children: [
                  KpiTile(
                    label: 'Área total',
                    value: formatNumber(lot.areaHa, decimals: 1),
                    icon: Icons.straighten_rounded,
                    caption: 'hectáreas',
                  ),
                  KpiTile(
                    label: 'Sembrada',
                    value: formatNumber(planted, decimals: 1),
                    icon: Icons.eco_outlined,
                    caption: 'hectáreas',
                    badgeBackground: AgroColors.surfaceHigh,
                    badgeForeground: AgroColors.primaryContainer,
                  ),
                  KpiTile(
                    label: 'Libre',
                    value: formatNumber(
                      (lot.areaHa - planted).clamp(0, double.infinity),
                      decimals: 1,
                    ),
                    icon: Icons.crop_free_rounded,
                    caption: 'hectáreas',
                    badgeBackground: AgroColors.surfaceHighest,
                    badgeForeground: AgroColors.primaryContainer,
                  ),
                ],
              ),
              const SectionTitle('Siembra activa'),
              if (active == null)
                AgroCard(
                  child: EmptyState(
                    icon: Icons.eco_outlined,
                    title: 'Este lote no tiene siembra activa',
                    message: 'Planee una siembra para seguir sus fases, plantas y costos.',
                    actionLabel: app.access.managesProduction
                        ? 'Nueva siembra'
                        : null,
                    onAction: () async {
                      final ok = await showPlantingForm(context);
                      if (ok) {
                        app.markChanged();
                        await reload();
                      }
                    },
                  ),
                )
              else
                AgroCard(
                  onTap: () => pushScreen(
                    context,
                    PlantingDetailScreen(plantingId: active.id),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              app.cropName(active.cropId),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AgroText.headlineMd,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusPill(
                            plantingStatusLabel(active.status),
                            tone: plantingStatusTone(active.status),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${methodLabel(active.method)} · ${active.plants == null ? 'sin conteo' : '${formatNumber(active.plants)} plantas'}',
                        style: AgroText.bodySm,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Ver detalle de siembra →',
                          style: AgroText.labelMd.copyWith(
                            color: AgroColors.primaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (past.isNotEmpty) ...[
                const SectionTitle('Historial de siembras'),
                RowGroup(
                  children: [
                    for (final p in past)
                      ListRow(
                        onTap: () => pushScreen(
                          context,
                          PlantingDetailScreen(plantingId: p.id),
                        ),
                        leading: const IconBadge(
                          icon: Icons.inventory_2_outlined,
                        ),
                        title: app.cropName(p.cropId),
                        subtitle:
                            '${plantingStatusLabel(p.status)} · ${formatHa(p.areaHa)}',
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AgroColors.outline,
                        ),
                      ),
                  ],
                ),
              ],
              const Gap(24),
              if (app.access.registersFieldWork && active != null)
                OutlinedButton.icon(
                  onPressed: () => showWorkForm(context),
                  icon: const Icon(Icons.edit_calendar_outlined),
                  label: const Text('Registrar labor'),
                ),
            ],
          ),
        );
      },
    );
  }
}
