import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/cards.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/layout.dart';
import '../../../core/widgets/states.dart';
import '../../farms/domain/farm.dart';
import '../../home/presentation/farm_selector.dart';
import '../data/production_repository.dart';
import '../domain/production.dart';
import 'crops_screen.dart';
import 'labels.dart';
import 'planting_detail_screen.dart';
import 'planting_form.dart';

class _TabData {
  const _TabData({required this.plantings, required this.lots});

  final PlantingList plantings;
  final Map<String, Lot> lots;
}

class ProductionTab extends StatefulWidget {
  const ProductionTab({super.key});

  @override
  State<ProductionTab> createState() => _ProductionTabState();
}

class _ProductionTabState extends State<ProductionTab> {
  int _filter = 0;
  static const _statuses = ['en_curso', 'planeada', 'cerrada'];

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final farm = app.activeFarm;
    return AsyncBody<_TabData>(
      key: ValueKey('prod-${farm?.id}'),
      load: () async {
        final plantings = await app.production.plantings();
        await app.crops();
        final lots = <String, Lot>{};
        if (farm != null) {
          for (final lot in await app.farmsRepo.lots(farm.id)) {
            lots[lot.id] = lot;
          }
        }
        return _TabData(plantings: plantings, lots: lots);
      },
      skeleton: const AgroPage(
        children: [
          FarmSelector(inPage: true),
          Gap(16),
          SkeletonList(rowHeight: 168),
        ],
      ),
      builder: (context, data, reload) {
        final all = data.plantings.items
            .where((p) => farm == null || p.farmId == farm.id)
            .toList();
        List<Planting> byStatus(String status) => all
            .where(
              (p) => status == 'cerrada'
                  ? p.status == 'cerrada' || p.status == 'cancelada'
                  : p.status == status,
            )
            .toList();
        final shown = byStatus(_statuses[_filter]);
        final active = byStatus('en_curso');
        final planted = active.fold<double>(0, (s, p) => s + p.areaHa);
        final plants = active.fold<int>(0, (s, p) => s + (p.plants ?? 0));
        final access = app.access;

        return AgroPage(
          onRefresh: reload,
          children: [
            const FarmSelector(inPage: true),
            const Gap(12),
            Row(
              children: [
                Expanded(child: Text('Producción', style: AgroText.headlineMd)),
                if (access.managesCatalog)
                  TextLinkButton(
                    'Catálogo',
                    () => pushScreen(context, const CropsScreen()),
                    icon: Icons.menu_book_outlined,
                  ),
              ],
            ),
            const Gap(8),
            FilterBar(
              labels: const ['En curso', 'Planeadas', 'Cerradas'],
              counts: [
                active.length,
                byStatus('planeada').length,
                byStatus('cerrada').length,
              ],
              selected: _filter,
              onSelected: (i) => setState(() => _filter = i),
            ),
            const Gap(12),
            AgroCard(
              color: AgroColors.surfaceLow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const IconBadge(
                        icon: Icons.insights_outlined,
                        size: 32,
                        circle: true,
                        background: AgroColors.secondaryContainer,
                        foreground: AgroColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'BALANCE OPERATIVO ACTUAL',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AgroText.labelSm,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Stat(formatHa(planted), 'sembradas'),
                        const VerticalDivider(width: 16),
                        _Stat(formatNumber(active.length), 'siembras activas'),
                        const VerticalDivider(width: 16),
                        _Stat(formatNumber(plants), 'plantas'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(16),
            if (shown.isEmpty)
              AgroCard(
                child: EmptyState(
                  icon: Icons.eco_outlined,
                  title: _filter == 0
                      ? 'Aún no tiene siembras en curso'
                      : _filter == 1
                      ? 'No hay siembras planeadas'
                      : 'No hay siembras cerradas',
                  message: farm == null ? 'Registre una finca para empezar.' : 'Planee una siembra para seguir sus fases, plantas y tiempos.',
                  actionLabel:
                      access.managesProduction && farm != null && _filter != 2
                      ? 'Planear siembra'
                      : null,
                  onAction: () async {
                    final created = await showPlantingForm(context);
                    if (created) app.markChanged();
                  },
                ),
              )
            else
              for (final planting in shown)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PlantingCard(
                    key: ValueKey(planting.id),
                    planting: planting,
                    lotName: data.lots[planting.lotId]?.name ?? 'Lote',
                  ),
                ),
          ],
        );
      },
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
          style: AgroText.monoMd.copyWith(color: AgroColors.primaryContainer),
          alignment: Alignment.centerLeft,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AgroText.bodySm,
        ),
      ],
    ),
  );
}

class PlantingCard extends StatefulWidget {
  const PlantingCard({
    required this.planting,
    required this.lotName,
    super.key,
  });

  final Planting planting;
  final String lotName;

  @override
  State<PlantingCard> createState() => _PlantingCardState();
}

class _PlantingCardState extends State<PlantingCard> {
  Future<List<ScheduledPhase>>? _schedule;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedule ??= _load();
  }

  Future<List<ScheduledPhase>> _load() async {
    final app = context.app;
    try {
      final detail = await app.backend.getJson(
        'siembras/${widget.planting.id}',
      );
      final planting = Planting.fromJson(detail);
      final open = planting.openCycle;
      if (open == null) return const [];
      return await app.production.cycleSchedule(open.id);
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final planting = widget.planting;
    final cropName = app.cropName(planting.cropId);
    return AgroCard(
      onTap: () =>
          pushScreen(context, PlantingDetailScreen(plantingId: planting.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.lotName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AgroText.labelSm,
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(
                plantingStatusLabel(planting.status),
                tone: plantingStatusTone(planting.status),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            cropName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AgroText.headlineMd.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<ScheduledPhase>>(
            future: _schedule,
            builder: (context, snapshot) {
              final phases = snapshot.data ?? const <ScheduledPhase>[];
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 44,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Skeleton(height: 12, width: 180),
                  ),
                );
              }
              if (phases.isEmpty) {
                return SizedBox(
                  height: 44,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      planting.status == 'planeada'
                          ? 'Aún no inicia: sin calendario de fases.'
                          : 'Sin calendario de fases.',
                      style: AgroText.bodySm,
                    ),
                  ),
                );
              }
              final done = phases.where((p) => p.done).length;
              final current = phases.firstWhere(
                (p) => !p.done,
                orElse: () => phases.last,
              );
              final ratio = done / phases.length;
              return SizedBox(
                height: 44,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${phaseLabel(current.phase)} (fase ${current.order} de ${phases.length})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AgroText.bodySm.copyWith(
                              color: AgroColors.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(ratio * 100).round()}%',
                          style: AgroText.monoSm.copyWith(
                            color: AgroColors.primaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ProgressLine(value: ratio),
                  ],
                ),
              );
            },
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
                  _Fact(formatHa(planting.areaHa), 'área'),
                  const VerticalDivider(width: 12),
                  _Fact(
                    planting.plants == null
                        ? '—'
                        : formatNumber(planting.plants),
                    'plantas',
                  ),
                  const VerticalDivider(width: 12),
                  _Fact(methodLabel(planting.method), 'propagación'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.value, this.label);

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
