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
import '../data/production_repository.dart';
import '../domain/production.dart';
import 'cycle_screen.dart';
import 'labels.dart';
import 'plant_count_sheet.dart';

class PlantingDetailScreen extends StatefulWidget {
  const PlantingDetailScreen({required this.plantingId, super.key});

  final String plantingId;

  @override
  State<PlantingDetailScreen> createState() => _PlantingDetailScreenState();
}

class _PlantingDetailScreenState extends State<PlantingDetailScreen> {
  int _tab = 0;
  final _bodyKey = GlobalKey<AsyncBodyState<PlantingOverview>>();

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return AsyncBody<PlantingOverview>(
      key: _bodyKey,
      load: () => app.production.overview(widget.plantingId),
      skeleton: const DetailScaffold(
        title: 'Siembra',
        body: AgroPage(children: [SkeletonList(rowHeight: 120)]),
      ),
      builder: (context, data, reload) {
        final planting = data.planting;
        final cropName = app.cropName(planting.cropId);
        return DetailScaffold(
          title: cropName,
          subtitle:
              'Siembra ${plantingStatusLabel(planting.status).toLowerCase()}',
          body: AgroPage(
            onRefresh: reload,
            bottomClearance: AgroSpace.xl,
            children: [
              SegmentedTabs(
                labels: const ['Resumen', 'Ciclos', 'Plantas', 'Tiempos'],
                selected: _tab,
                onSelected: (i) => setState(() => _tab = i),
              ),
              const Gap(16),
              switch (_tab) {
                0 => _Summary(data: data, reload: reload),
                1 => _Cycles(data: data, reload: reload),
                2 => _Plants(data: data, reload: reload),
                _ => _Timeline(data: data),
              },
            ],
          ),
        );
      },
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.data, required this.reload});

  final PlantingOverview data;
  final Future<void> Function() reload;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final planting = data.planting;
    final access = app.access;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EqualGrid(
          children: [
            KpiTile(
              label: 'Área sembrada',
              value: formatNumber(planting.areaHa, decimals: 1),
              icon: Icons.crop_square_rounded,
              caption: 'hectáreas',
            ),
            KpiTile(
              label: 'Plantas sembradas',
              value: planting.plants == null
                  ? '—'
                  : formatNumber(planting.plants),
              icon: Icons.park_outlined,
              caption: methodLabel(planting.method),
              badgeBackground: AgroColors.surfaceHigh,
              badgeForeground: AgroColors.primaryContainer,
            ),
            KpiTile(
              label: 'Presupuesto',
              value: planting.budget == null
                  ? '—'
                  : formatNumber(planting.budget!.round()),
              prefix: planting.budget == null ? null : '\$',
              icon: Icons.savings_outlined,
              caption: planting.budget == null ? 'sin definir' : 'pesos (COP)',
              badgeBackground: AgroColors.tertiaryFixed,
              badgeForeground: AgroColors.tertiary,
            ),
            KpiTile(
              label: 'Fecha planeada',
              value: formatDateShort(planting.planDate),
              icon: Icons.event_outlined,
              caption: formatDate(planting.planDate),
              badgeBackground: AgroColors.surfaceHighest,
              badgeForeground: AgroColors.primaryContainer,
            ),
          ],
        ),
        const SectionTitle('Índices por planta'),
        if (data.indicators.isEmpty)
          const AgroCard(
            child: EmptyState(
              icon: Icons.query_stats_outlined,
              title: 'Aún no hay conteos',
              message: 'Registre un conteo de plantas para calcular densidad y pérdidas.',
            ),
          )
        else
          for (final indicator in data.indicators)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _IndicatorCard(indicator),
            ),
        if (access.managesProduction) ...[
          const SectionTitle('Acciones'),
          if (planting.status == 'planeada')
            WideButton(
              label: 'Iniciar siembra',
              icon: Icons.play_arrow_rounded,
              onPressed: () => _run(
                context,
                () => app.production.startPlanting(planting.id),
                'Siembra iniciada.',
                reload,
              ),
            ),
          if (planting.status == 'en_curso') ...[
            WideButton(
              label: 'Registrar conteo de plantas',
              icon: Icons.numbers_rounded,
              onPressed: () async {
                final ok = await showPlantCountSheet(context, planting.id);
                if (ok) await reload();
              },
            ),
          ],
          if (planting.status == 'planeada' ||
              planting.status == 'en_curso') ...[
            const Gap(12),
            WideButton(
              label: 'Cancelar siembra',
              icon: Icons.block_rounded,
              outlined: true,
              destructive: true,
              onPressed: () async {
                final yes = await confirmDialog(
                  context,
                  title: 'Cancelar siembra',
                  message: 'La siembra deja de contar como activa. Esta acción no se puede deshacer.',
                  confirmLabel: 'Cancelar siembra',
                  destructive: true,
                );
                if (!yes || !context.mounted) return;
                await _run(
                  context,
                  () => app.production.cancelPlanting(planting.id),
                  'Siembra cancelada.',
                  reload,
                );
              },
            ),
          ],
        ],
      ],
    );
  }
}

Future<void> _run(
  BuildContext context,
  Future<void> Function() action,
  String success,
  Future<void> Function() reload,
) async {
  final app = context.app;
  try {
    await action();
    if (!context.mounted) return;
    showSnack(context, success);
    app.markChanged();
    await reload();
  } on ApiException catch (error) {
    if (context.mounted) showSnack(context, error.message, error: true);
  } catch (_) {
    if (context.mounted) {
      showSnack(context, 'No hay conexión con el servidor.', error: true);
    }
  }
}

class _IndicatorCard extends StatelessWidget {
  const _IndicatorCard(this.indicator);

  final Indicator indicator;

  @override
  Widget build(BuildContext context) => AgroCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                indicator.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AgroText.labelMd,
              ),
            ),
            const SizedBox(width: 8),
            StatusPill(
              humanize(indicator.state),
              tone: indicator.state == 'alerta' ? Tone.danger : Tone.neutral,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              indicator.value == null
                  ? '—'
                  : formatNumber(
                      indicator.value,
                      decimals: indicator.value! % 1 == 0 ? 0 : 1,
                    ),
              style: AgroText.monoXl,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                indicator.unit,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AgroText.bodySm,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          indicator.explanation,
          style: AgroText.bodySm.copyWith(height: 1.5),
        ),
        if (indicator.action != null) ...[
          const SizedBox(height: 8),
          Text(
            indicator.action!,
            style: AgroText.bodySm.copyWith(
              color: AgroColors.onSurface,
              height: 1.5,
            ),
          ),
        ],
        if (indicator.date != null) ...[
          const SizedBox(height: 8),
          Text(
            'Datos del ${formatDate(indicator.date)}',
            style: AgroText.monoSm,
          ),
        ],
      ],
    ),
  );
}

class _Cycles extends StatelessWidget {
  const _Cycles({required this.data, required this.reload});

  final PlantingOverview data;
  final Future<void> Function() reload;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final cycles = data.planting.cycles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (cycles.isEmpty)
          const AgroCard(
            child: EmptyState(
              icon: Icons.autorenew_rounded,
              title: 'Todavía no hay ciclos',
              message: 'El primer ciclo se abre al iniciar la siembra.',
            ),
          )
        else
          RowGroup(
            children: [
              for (final cycle in cycles)
                ListRow(
                  onTap: () => pushScreen(
                    context,
                    CycleScreen(
                      plantingId: data.planting.id,
                      cycleId: cycle.id,
                    ),
                  ),
                  leading: const IconBadge(icon: Icons.autorenew_rounded),
                  title:
                      'Ciclo ${cycle.number} · ${cycleTypeLabel(cycle.type)}',
                  subtitle: cycle.start == null
                      ? 'Sin fecha de inicio'
                      : 'Desde el ${formatDate(cycle.start)}'
                            '${cycle.end == null ? '' : ' hasta el ${formatDate(cycle.end)}'}',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusPill(
                        humanize(cycle.status),
                        tone: cycle.status == 'abierto'
                            ? Tone.ok
                            : Tone.neutral,
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AgroColors.outline,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        if (app.access.managesProduction &&
            data.planting.status == 'en_curso' &&
            data.planting.openCycle == null) ...[
          const Gap(16),
          WideButton(
            label: 'Abrir siguiente ciclo',
            icon: Icons.add_rounded,
            onPressed: () async {
              final type = await showAgroSheet<String>(
                context,
                builder: (context) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Tipo de ciclo', style: AgroText.headlineMd),
                    const SizedBox(height: 8),
                    for (final type in const [
                      'levante',
                      'produccion',
                      'renovacion',
                    ])
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        minVerticalPadding: 12,
                        title: Text(
                          cycleTypeLabel(type),
                          style: AgroText.labelMd,
                        ),
                        onTap: () => Navigator.pop(context, type),
                      ),
                  ],
                ),
              );
              if (type == null || !context.mounted) return;
              await _run(
                context,
                () => app.production.openNextCycle(data.planting.id, type),
                'Ciclo abierto.',
                reload,
              );
            },
          ),
        ],
      ],
    );
  }
}

class _Plants extends StatelessWidget {
  const _Plants({required this.data, required this.reload});

  final PlantingOverview data;
  final Future<void> Function() reload;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final counts = [...data.counts]..sort((a, b) => b.date.compareTo(a.date));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (counts.isEmpty)
          const AgroCard(
            child: EmptyState(
              icon: Icons.numbers_rounded,
              title: 'Sin conteos de plantas',
              message: 'El conteo permite saber cuántas plantas siguen vivas.',
            ),
          )
        else
          RowGroup(
            children: [
              for (final count in counts)
                ListRow(
                  leading: const IconBadge(icon: Icons.park_outlined),
                  title: formatDate(count.date),
                  subtitle:
                      '${formatNumber(count.dead)} muertas · ${formatNumber(count.replanted)} resiembras',
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatNumber(count.alive), style: AgroText.monoMd),
                      Text(
                        'vivas',
                        style: AgroText.bodySm.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        if (app.access.managesProduction &&
            data.planting.status == 'en_curso') ...[
          const Gap(16),
          WideButton(
            label: 'Registrar conteo',
            icon: Icons.add_rounded,
            onPressed: () async {
              final ok = await showPlantCountSheet(context, data.planting.id);
              if (ok) await reload();
            },
          ),
        ],
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.data});

  final PlantingOverview data;

  @override
  Widget build(BuildContext context) {
    final phases = data.schedule;
    if (phases.isEmpty) {
      return const AgroCard(
        child: EmptyState(
          icon: Icons.timeline_outlined,
          title: 'Sin cronograma',
          message: 'El calendario aparece cuando la siembra tiene un ciclo abierto y fases cargadas.',
        ),
      );
    }
    final currentIndex = phases.indexWhere((p) => !p.done);
    return AgroCard(
      child: Column(
        children: [
          for (var i = 0; i < phases.length; i++)
            _TimelineRow(
              phase: phases[i],
              state: phases[i].done
                  ? _PhaseState.done
                  : i == currentIndex
                  ? _PhaseState.current
                  : _PhaseState.planned,
              last: i == phases.length - 1,
            ),
        ],
      ),
    );
  }
}

enum _PhaseState { done, current, planned }

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.phase,
    required this.state,
    required this.last,
  });

  final ScheduledPhase phase;
  final _PhaseState state;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _PhaseState.done => AgroColors.primaryContainer,
      _PhaseState.current => AgroColors.tertiary,
      _PhaseState.planned => AgroColors.outline,
    };
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: state == _PhaseState.planned
                        ? AgroColors.surfaceLowest
                        : color,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Icon(
                    state == _PhaseState.done
                        ? Icons.check_rounded
                        : state == _PhaseState.current
                        ? Icons.play_arrow_rounded
                        : Icons.schedule_rounded,
                    size: 16,
                    color: state == _PhaseState.planned ? color : Colors.white,
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AgroColors.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${phase.order}. ${phaseLabel(phase.phase)}',
                    style: AgroText.labelMd,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatDateShort(phase.planStart)} → ${formatDateShort(phase.planEnd)}'
                    '${phase.plannedDays == null ? '' : ' · ${phase.plannedDays} días'}',
                    style: AgroText.monoSm,
                  ),
                  if (phase.delayDays != null && phase.delayDays! > 0) ...[
                    const SizedBox(height: 6),
                    StatusPill(
                      '${phase.delayDays} días de retraso',
                      tone: Tone.warn,
                      icon: Icons.warning_amber_rounded,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
