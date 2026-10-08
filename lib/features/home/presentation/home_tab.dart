import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/cards.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/layout.dart';
import '../../../core/widgets/states.dart';
import '../../money/data/money_repository.dart';
import '../../production/data/production_repository.dart';
import '../../production/domain/production.dart';
import '../../production/presentation/planting_detail_screen.dart';
import '../../risks/presentation/events_screen.dart';
import '../../risks/presentation/labels.dart';
import '../data/home_repository.dart';
import 'farm_selector.dart';

class _HomeData {
  const _HomeData({required this.overview, this.flow, this.plantings});

  final HomeOverview overview;
  final CashFlow? flow;
  final PlantingList? plantings;
}

class HomeTab extends StatelessWidget {
  const HomeTab({required this.onOpenTab, super.key});

  final ValueChanged<String> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return AsyncBody<_HomeData>(
      key: ValueKey('home-${app.activeFarm?.id}'),
      load: () async {
        final overview = await app.home.overview();
        CashFlow? flow;
        PlantingList? plantings;
        final farm = app.activeFarm;
        if (farm != null && app.access.seesMoney) {
          try {
            flow = await app.money.cashFlow(farm.id);
          } catch (_) {}
        }
        if (app.access.seesProduction) {
          try {
            plantings = await app.production.plantings();
            await app.crops();
          } catch (_) {}
        }
        return _HomeData(overview: overview, flow: flow, plantings: plantings);
      },
      skeleton: const AgroPage(
        children: [FarmSelector(inPage: true), Gap(16), SkeletonList()],
      ),
      builder: (context, data, reload) =>
          _HomeBody(data: data, reload: reload, onOpenTab: onOpenTab),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.data,
    required this.reload,
    required this.onOpenTab,
  });

  final _HomeData data;
  final Future<void> Function() reload;
  final ValueChanged<String> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final access = app.access;
    final overview = data.overview;
    final flow = data.flow;
    final farm = app.activeFarm;
    final notice = overview.notices.isEmpty ? null : overview.notices.first;

    final tiles = <Widget>[
      KpiTile(
        label: 'Fincas activas',
        value: formatNumber(overview.farms),
        icon: Icons.landscape_outlined,
        caption: overview.farms == 1 ? 'a su cargo' : 'a su cargo',
      ),
      KpiTile(
        label: 'Siembras en curso',
        value: formatNumber(overview.activePlantings),
        icon: Icons.eco_outlined,
        caption: '${formatNumber(overview.plannedPlantings)} planeadas',
        badgeBackground: AgroColors.surfaceHigh,
        badgeForeground: AgroColors.primaryContainer,
      ),
      if (flow != null)
        KpiTile(
          label: access.seesProfit ? 'Saldo del mes' : 'Gastos del mes',
          value: formatNumber(
            (access.seesProfit ? flow.balance : flow.expenses).round(),
          ),
          prefix: '\$',
          icon: Icons.payments_outlined,
          caption: 'pesos colombianos (COP)',
          badgeBackground: AgroColors.tertiaryFixed,
          badgeForeground: AgroColors.tertiary,
        )
      else
        KpiTile(
          label: 'Eventos recientes',
          value: formatNumber(overview.recentEvents.length),
          icon: Icons.warning_amber_rounded,
          caption: 'en sus siembras',
          badgeBackground: AgroColors.tertiaryFixed,
          badgeForeground: AgroColors.tertiary,
        ),
      KpiTile(
        label: 'Avisos de riesgo',
        value: formatNumber(overview.notices.length),
        icon: Icons.shield_outlined,
        caption: overview.notices.isEmpty ? 'sin avisos hoy' : 'según la fase',
        badgeBackground: AgroColors.surfaceHighest,
        badgeForeground: AgroColors.primaryContainer,
      ),
    ];

    return AgroPage(
      onRefresh: reload,
      children: [
        const FarmSelector(inPage: true),
        const Gap(16),
        _Greeting(),
        if (overview.firstSteps.isNotEmpty) ...[
          const Gap(16),
          _FirstSteps(steps: overview.firstSteps),
        ],
        if (notice != null) ...[
          const Gap(16),
          _NoticeCard(
            notice: notice,
            onTap: notice.plantingId.isEmpty
                ? null
                : () => pushScreen(
                    context,
                    PlantingDetailScreen(plantingId: notice.plantingId),
                  ),
          ),
        ],
        const SectionTitle('Resumen de hoy'),
        EqualGrid(children: tiles),
        if (farm != null && data.plantings != null) ...[
          const Gap(16),
          _AreaCard(
            farmName: farm.name,
            farmArea: farm.areaHa,
            plantings: data.plantings!.items
                .where((p) => p.farmId == farm.id && p.status == 'en_curso')
                .toList(),
          ),
        ],
        SectionTitle(
          'Eventos recientes',
          trailing: access.seesRisks
              ? TextLinkButton(
                  'Ver eventos',
                  () => pushScreen(context, const EventsScreen()),
                )
              : null,
        ),
        if (overview.recentEvents.isEmpty)
          const AgroCard(
            child: EmptyState(
              icon: Icons.verified_outlined,
              title: 'Sin eventos recientes',
              message: 'Cuando registre una helada, plaga o lluvia fuerte, aparecerá aquí.',
            ),
          )
        else
          RowGroup(
            children: [
              for (final event in overview.recentEvents.take(4))
                ListRow(
                  leading: const IconBadge(
                    icon: Icons.warning_amber_rounded,
                    background: AgroColors.tertiaryFixed,
                    foreground: AgroColors.tertiary,
                  ),
                  title: event.risk,
                  subtitle: 'Desde el ${formatDate(event.start)}',
                  trailing: StatusPill(
                    humanize(event.severity),
                    tone: severityTone(event.severity),
                  ),
                ),
            ],
          ),
        if (access.seesProduction && overview.activePlantings > 0) ...[
          const Gap(16),
          Align(
            alignment: Alignment.centerLeft,
            child: TextLinkButton(
              'Ir a producción',
              () => onOpenTab('Producción'),
              icon: Icons.arrow_forward_rounded,
            ),
          ),
        ],
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${greeting()}, ${firstName(app.session.name)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AgroText.headlineMd.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(app.access.roleLabel, style: AgroText.bodySm),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(formatDate(DateTime.now()), style: AgroText.monoSm),
      ],
    );
  }
}

class _FirstSteps extends StatelessWidget {
  const _FirstSteps({required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) => AgroCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Primeros pasos', style: AgroText.labelMd),
        const SizedBox(height: 8),
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AgroColors.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: AgroText.monoSm.copyWith(color: AgroColors.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(steps[i], style: AgroText.bodyMd)),
              ],
            ),
          ),
      ],
    ),
  );
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice, this.onTap});

  final RiskNotice notice;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AgroCard(
    accent: AgroColors.tertiary,
    padding: const EdgeInsets.fromLTRB(21, 16, 16, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: StatusPill(
            'Atención · ${notice.susceptibility}',
            tone: Tone.warn,
            icon: Icons.warning_amber_rounded,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${notice.risk} en ${notice.crop}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AgroText.labelMd.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 6),
        Text(
          'Fase de ${humanize(notice.phase).toLowerCase()}',
          style: AgroText.monoSm.copyWith(color: AgroColors.tertiary),
        ),
        const SizedBox(height: 6),
        Text(notice.text, style: AgroText.bodySm.copyWith(height: 1.5)),
        if (notice.measures != null) ...[
          const SizedBox(height: 6),
          Text(
            notice.measures!,
            style: AgroText.bodySm.copyWith(
              color: AgroColors.onSurface,
              height: 1.5,
            ),
          ),
        ],
        if (notice.toValidate) ...[
          const SizedBox(height: 8),
          Text(
            'Dato por validar con asistencia técnica.',
            style: AgroText.bodySm.copyWith(color: AgroColors.outline),
          ),
        ],
        if (onTap != null) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              iconAlignment: IconAlignment.end,
              label: const Text('Ver siembra'),
            ),
          ),
        ],
      ],
    ),
  );
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({
    required this.farmName,
    required this.farmArea,
    required this.plantings,
  });

  final String farmName;
  final double? farmArea;
  final List<Planting> plantings;

  @override
  Widget build(BuildContext context) {
    final planted = plantings.fold<double>(0, (sum, p) => sum + p.areaHa);
    final total = farmArea ?? planted;
    final free = (total - planted).clamp(0, double.infinity);
    final ratio = total <= 0 ? 0.0 : (planted / total).clamp(0, 1).toDouble();
    return AgroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estado de área física', style: AgroText.labelMd),
                    Text(
                      farmName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AgroText.bodySm,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formatHa(total),
                style: AgroText.monoMd.copyWith(color: AgroColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Semantics(
            label: 'Área sembrada ${(ratio * 100).round()} por ciento',
            child: ProgressLine(value: ratio, height: 12),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              _Legend('Total', formatHa(total), AgroColors.onSurface),
              _Legend(
                'Sembrada',
                formatHa(planted),
                AgroColors.primaryContainer,
                dot: AgroColors.primaryContainer,
              ),
              _Legend(
                'Libre',
                formatHa(free),
                AgroColors.onSurfaceVariant,
                dot: AgroColors.surfaceHigh,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.label, this.value, this.color, {this.dot});

  final String label;
  final String value;
  final Color color;
  final Color? dot;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (dot != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AgroText.bodySm.copyWith(fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        AmountText(
          value,
          style: AgroText.monoSm.copyWith(fontWeight: FontWeight.w700),
          color: color,
          alignment: Alignment.centerLeft,
        ),
      ],
    ),
  );
}
