import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/cards.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/layout.dart';
import '../../../core/widgets/states.dart';
import '../data/risks_repository.dart';
import 'event_detail_screen.dart';
import 'event_form.dart';
import 'labels.dart';

class _EventsData {
  const _EventsData(this.events, this.risks);

  final List<AdverseEvent> events;
  final Map<String, RiskType> risks;
}

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  int _filter = 0;
  static const _groups = [null, 'clima', 'plaga', 'enfermedad', 'otro'];

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return AsyncBody<_EventsData>(
      key: ValueKey('events-${app.revision}'),
      load: () async {
        final events = await app.risks.events();
        final risks = await app.risks.catalog();
        return _EventsData(events, {for (final r in risks) r.id: r});
      },
      skeleton: const DetailScaffold(
        title: 'Eventos adversos',
        body: AgroPage(children: [SkeletonList(rowHeight: 140)]),
      ),
      builder: (context, data, reload) {
        final group = _groups[_filter];
        bool inGroup(AdverseEvent e) {
          if (group == null) return true;
          final type = data.risks[e.riskId]?.type ?? 'otro';
          return group == 'otro'
              ? !const ['clima', 'plaga', 'enfermedad'].contains(type)
              : type == group;
        }

        int count(String? g) => data.events.where((e) {
          if (g == null) return true;
          final type = data.risks[e.riskId]?.type ?? 'otro';
          return g == 'otro'
              ? !const ['clima', 'plaga', 'enfermedad'].contains(type)
              : type == g;
        }).length;

        final shown = data.events.where(inGroup).toList()
          ..sort((a, b) => b.start.compareTo(a.start));
        final active = data.events.where((e) => e.active).length;
        final loss = data.events.fold<double>(
          0,
          (s, e) => s + (e.estimatedLoss ?? 0),
        );
        final area = data.events.fold<double>(
          0,
          (s, e) => s + (e.affectedArea ?? 0),
        );
        return DetailScaffold(
          title: 'Eventos adversos',
          subtitle: 'Heladas, plagas, lluvias y otros riesgos',
          floating: app.access.registersFieldWork
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    final ok = await showEventForm(context);
                    if (ok) await reload();
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Registrar'),
                )
              : null,
          body: AgroPage(
            onRefresh: reload,
            children: [
              EqualGrid(
                columns: 2,
                children: [
                  KpiTile(
                    label: 'Eventos activos',
                    value: formatNumber(active),
                    icon: Icons.priority_high_rounded,
                    caption: 'en curso',
                    badgeBackground: AgroColors.tertiaryFixed,
                    badgeForeground: AgroColors.tertiary,
                  ),
                  KpiTile(
                    label: 'Eventos registrados',
                    value: formatNumber(data.events.length),
                    icon: Icons.history_rounded,
                    caption: 'en total',
                    badgeBackground: AgroColors.surfaceHigh,
                    badgeForeground: AgroColors.primaryContainer,
                  ),
                  KpiTile(
                    label: 'Pérdida estimada',
                    value: formatNumber(loss.round()),
                    prefix: '\$',
                    icon: Icons.trending_down_rounded,
                    caption: 'pesos (COP)',
                    badgeBackground: AgroColors.errorContainer,
                    badgeForeground: AgroColors.error,
                  ),
                  KpiTile(
                    label: 'Área afectada',
                    value: formatNumber(area, decimals: 1),
                    icon: Icons.crop_square_rounded,
                    caption: 'hectáreas',
                  ),
                ],
              ),
              const Gap(16),
              FilterBar(
                labels: const [
                  'Todos',
                  'Clima',
                  'Plagas',
                  'Enfermedades',
                  'Otros',
                ],
                counts: [for (final g in _groups) count(g)],
                selected: _filter,
                onSelected: (i) => setState(() => _filter = i),
              ),
              const Gap(16),
              if (shown.isEmpty)
                const AgroCard(
                  child: EmptyState(
                    icon: Icons.verified_outlined,
                    title: 'Sin eventos en esta categoría',
                    message: 'Cuando ocurra una helada, plaga o lluvia fuerte, regístrela para medir su costo.',
                  ),
                )
              else
                for (final event in shown)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _EventCard(
                      event: event,
                      risk: data.risks[event.riskId],
                      onTap: () async {
                        await pushScreen(
                          context,
                          EventDetailScreen(
                            event: event,
                            risk: data.risks[event.riskId],
                          ),
                        );
                        await reload();
                      },
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.risk,
    required this.onTap,
  });

  final AdverseEvent event;
  final RiskType? risk;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AgroCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconBadge(
              icon: riskIcon(risk?.type ?? ''),
              background: AgroColors.tertiaryFixed,
              foreground: AgroColors.tertiary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    risk?.name ?? 'Evento',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AgroText.headlineMd.copyWith(fontSize: 18),
                  ),
                  Text(
                    'Desde el ${formatDate(event.start)}',
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
              'Severidad ${event.severity}',
              tone: severityTone(event.severity),
            ),
            const SizedBox(width: 8),
            StatusPill(
              event.active ? 'En curso' : 'Terminado',
              tone: event.active ? Tone.warn : Tone.ok,
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
              Expanded(
                child: Text(
                  'Pérdida estimada',
                  style: AgroText.bodySm.copyWith(color: AgroColors.onSurface),
                ),
              ),
              const SizedBox(width: 8),
              AmountText(
                event.estimatedLoss == null
                    ? 'Sin estimar'
                    : formatCop(event.estimatedLoss),
                color: event.estimatedLoss == null
                    ? AgroColors.outline
                    : AgroColors.error,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
