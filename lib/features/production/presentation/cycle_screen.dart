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
import '../../home/presentation/work_forms.dart';
import '../domain/production.dart';
import 'labels.dart';

class _CycleData {
  const _CycleData({
    required this.cycle,
    required this.activities,
    required this.schedule,
    required this.needs,
  });

  final Cycle cycle;
  final List<Activity> activities;
  final List<ScheduledPhase> schedule;
  final List<SupplyNeed> needs;
}

class CycleScreen extends StatelessWidget {
  const CycleScreen({
    required this.plantingId,
    required this.cycleId,
    super.key,
  });

  final String plantingId;
  final String cycleId;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return AsyncBody<_CycleData>(
      key: ValueKey('cycle-$cycleId-${app.revision}'),
      load: () async {
        final cycle = await app.production.cycle(cycleId);
        final planting = await app.production.overview(plantingId);
        final all = await app.production.activities(planting.planting.farmId);
        List<ScheduledPhase> schedule = const [];
        List<SupplyNeed> needs = const [];
        try {
          schedule = await app.production.cycleSchedule(cycleId);
        } catch (_) {}
        try {
          needs = await app.production.supplyNeeds(cycleId);
        } catch (_) {}
        return _CycleData(
          cycle: cycle,
          activities: all.where((a) => a.cycleId == cycleId).toList(),
          schedule: schedule,
          needs: needs,
        );
      },
      skeleton: const DetailScaffold(
        title: 'Ciclo',
        body: AgroPage(children: [SkeletonList(rowHeight: 120)]),
      ),
      builder: (context, data, reload) {
        final cycle = data.cycle;
        final open = cycle.status == 'abierto';
        final days = cycle.start == null
            ? null
            : DateTime.now().difference(DateTime.parse(cycle.start!)).inDays;
        final done = data.schedule.where((p) => p.done).length;
        return DetailScaffold(
          title: 'Ciclo ${cycle.number} · ${cycleTypeLabel(cycle.type)}',
          subtitle: open ? 'En curso' : 'Cerrado',
          body: AgroPage(
            onRefresh: reload,
            children: [
              EqualGrid(
                children: [
                  KpiTile(
                    label: 'Días transcurridos',
                    value: days == null ? '—' : formatNumber(days),
                    icon: Icons.calendar_today_outlined,
                    caption: cycle.start == null
                        ? 'sin fecha de inicio'
                        : 'desde ${formatDate(cycle.start)}',
                  ),
                  KpiTile(
                    label: 'Fases completadas',
                    value: data.schedule.isEmpty
                        ? '—'
                        : '$done de ${data.schedule.length}',
                    icon: Icons.timeline_outlined,
                    caption: 'según el cronograma',
                    badgeBackground: AgroColors.surfaceHigh,
                    badgeForeground: AgroColors.primaryContainer,
                  ),
                  KpiTile(
                    label: 'Labores registradas',
                    value: formatNumber(data.activities.length),
                    icon: Icons.handyman_outlined,
                    caption: 'en este ciclo',
                    badgeBackground: AgroColors.tertiaryFixed,
                    badgeForeground: AgroColors.tertiary,
                  ),
                  KpiTile(
                    label: 'Estado',
                    value: open ? 'Abierto' : 'Cerrado',
                    icon: open ? Icons.lock_open_rounded : Icons.lock_outline,
                    caption: cycle.end == null
                        ? 'sin cierre'
                        : formatDate(cycle.end),
                    badgeBackground: AgroColors.surfaceHighest,
                    badgeForeground: AgroColors.primaryContainer,
                  ),
                ],
              ),
              SectionTitle(
                'Labores del ciclo',
                caption: '${data.activities.length} registradas',
              ),
              if (data.activities.isEmpty)
                AgroCard(
                  child: EmptyState(
                    icon: Icons.handyman_outlined,
                    title: 'Aún no hay labores',
                    message: 'Registre la primera labor con sus jornales para ver costos y avance.',
                    actionLabel: open && app.access.registersFieldWork
                        ? 'Agregar labor'
                        : null,
                    onAction: () async {
                      final ok = await showWorkForm(context, cycleId: cycleId);
                      if (ok) await reload();
                    },
                  ),
                )
              else
                RowGroup(
                  children: [
                    for (final activity in data.activities)
                      ListRow(
                        leading: const IconBadge(icon: Icons.handyman_outlined),
                        title: activity.name,
                        subtitle:
                            '${phaseLabel(activity.phase)} · ${formatHa(activity.areaHa)}',
                        trailing: StatusPill(
                          humanize(activity.status),
                          tone: activity.status == 'finalizada'
                              ? Tone.ok
                              : Tone.info,
                        ),
                      ),
                  ],
                ),
              const SectionTitle('Insumos que necesita'),
              if (data.needs.isEmpty)
                const AgroCard(
                  child: EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Sin dosis cargadas',
                    message: 'Falta cargar las dosis de este cultivo desde una fuente técnica.',
                  ),
                )
              else
                RowGroup(
                  children: [
                    for (final need in data.needs)
                      ListRow(
                        leading: const IconBadge(icon: Icons.science_outlined),
                        title: humanize(need.type),
                        subtitle:
                            '${formatNumber(need.dose, decimals: 1)} ${need.unit} por ${need.base}',
                        trailing: Text(
                          need.quantity == null
                              ? '—'
                              : formatNumber(need.quantity, decimals: 1),
                          style: AgroText.monoMd,
                        ),
                      ),
                  ],
                ),
              if (open && app.access.registersFieldWork) ...[
                const SectionTitle('Acciones'),
                WideButton(
                  label: 'Agregar labor',
                  icon: Icons.add_rounded,
                  onPressed: () async {
                    final ok = await showWorkForm(context, cycleId: cycleId);
                    if (ok) await reload();
                  },
                ),
                if (app.access.managesProduction) ...[
                  const Gap(12),
                  WideButton(
                    label: 'Cerrar ciclo',
                    icon: Icons.lock_clock_outlined,
                    outlined: true,
                    onPressed: () => _close(context, reload),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _close(
    BuildContext context,
    Future<void> Function() reload,
  ) async {
    final app = context.app;
    final yes = await confirmDialog(
      context,
      title: 'Cerrar ciclo',
      message: 'Antes de cerrar, registre la cosecha final o el motivo de la pérdida si hubo un siniestro. El cierre no se puede deshacer.',
      confirmLabel: 'Cerrar ciclo',
    );
    if (!yes || !context.mounted) return;
    try {
      await app.production.closeCycle(cycleId);
      if (!context.mounted) return;
      showSnack(context, 'Ciclo cerrado.');
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
}
