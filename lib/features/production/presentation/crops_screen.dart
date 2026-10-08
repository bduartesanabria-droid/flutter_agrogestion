import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/cards.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/layout.dart';
import '../../../core/widgets/states.dart';
import '../domain/production.dart';
import 'labels.dart';

IconData _cropIcon(Crop crop) => switch (crop.cycleType) {
  'transitorio' => Icons.grass_rounded,
  'forestal' => Icons.forest_outlined,
  'permanente' => Icons.park_outlined,
  _ => Icons.eco_outlined,
};

class CropsScreen extends StatefulWidget {
  const CropsScreen({super.key});

  @override
  State<CropsScreen> createState() => _CropsScreenState();
}

class _CropsScreenState extends State<CropsScreen> {
  static const _types = [
    null,
    'permanente',
    'transitorio',
    'semipermanente',
    'forestal',
  ];
  int _filter = 0;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return DetailScaffold(
      title: 'Catálogo de cultivos',
      subtitle: 'El perfil define fases, conteo y alertas',
      body: AsyncBody<List<Crop>>(
        load: app.production.crops,
        builder: (context, crops, reload) {
          final type = _types[_filter];
          final shown = crops
              .where((c) => type == null || c.cycleType == type)
              .where(
                (c) =>
                    _query.isEmpty ||
                    c.name.toLowerCase().contains(_query.toLowerCase()),
              )
              .toList();
          int count(String? t) =>
              crops.where((c) => t == null || c.cycleType == t).length;
          return AgroPage(
            onRefresh: reload,
            bottomClearance: AgroSpace.xl,
            children: [
              TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Buscar cultivo',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const Gap(12),
              FilterBar(
                labels: const [
                  'Todos',
                  'Permanentes',
                  'Transitorios',
                  'Semipermanentes',
                  'Forestales',
                ],
                counts: [for (final t in _types) count(t)],
                selected: _filter,
                onSelected: (i) => setState(() => _filter = i),
              ),
              const Gap(16),
              if (shown.isEmpty)
                const AgroCard(
                  child: EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No hay cultivos con ese filtro',
                    message: 'Pruebe con otro nombre o quite el filtro.',
                  ),
                )
              else
                for (final crop in shown)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AgroCard(
                      onTap: () => pushScreen(
                        context,
                        CropDetailScreen(cropId: crop.id),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconBadge(icon: _cropIcon(crop)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      crop.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AgroText.headlineMd,
                                    ),
                                    Text(
                                      '${capitalize(crop.group)} · conteo ${crop.countLabel.toLowerCase()}',
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
                              StatusPill(crop.cycleLabel, tone: Tone.ok),
                              if (crop.toValidate) ...[
                                const SizedBox(width: 8),
                                const StatusPill(
                                  'Por validar',
                                  tone: Tone.warn,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _CropFull {
  const _CropFull({
    required this.detail,
    required this.methods,
    required this.risks,
    required this.doses,
    required this.riskNames,
  });

  final CropDetail detail;
  final List<PropagationMethod> methods;
  final List<CropRisk> risks;
  final List<Map<String, dynamic>> doses;
  final Map<String, String> riskNames;
}

class CropDetailScreen extends StatefulWidget {
  const CropDetailScreen({required this.cropId, super.key});

  final String cropId;

  @override
  State<CropDetailScreen> createState() => _CropDetailScreenState();
}

class _CropDetailScreenState extends State<CropDetailScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return AsyncBody<_CropFull>(
      load: () async {
        final detail = await app.production.cropDetail(widget.cropId);
        return _CropFull(
          detail: detail,
          methods: await app.production.cropMethods(widget.cropId),
          risks: await app.production.cropRisks(widget.cropId),
          doses: await app.production.cropDoses(widget.cropId),
          riskNames: await app.production.riskNames(),
        );
      },
      skeleton: const DetailScaffold(
        title: 'Ficha del cultivo',
        body: AgroPage(children: [SkeletonList(rowHeight: 120)]),
      ),
      builder: (context, data, reload) {
        final crop = data.detail.crop;
        return DetailScaffold(
          title: crop.name,
          subtitle: data.detail.scientificName ?? 'Perfil agronómico',
          body: AgroPage(
            onRefresh: reload,
            bottomClearance: AgroSpace.xl,
            children: [
              AgroCard(
                child: Column(
                  children: [
                    InfoRow(label: 'Tipo de ciclo', value: crop.cycleLabel),
                    const Divider(),
                    InfoRow(label: 'Unidad de conteo', value: crop.countLabel),
                    const Divider(),
                    InfoRow(
                      label: 'Unidad de cosecha',
                      value: humanize(data.detail.harvestUnit ?? '—'),
                    ),
                    if (data.detail.renewalType != null) ...[
                      const Divider(),
                      InfoRow(
                        label: 'Renovación',
                        value: humanize(data.detail.renewalType!),
                      ),
                    ],
                  ],
                ),
              ),
              if (crop.toValidate) ...[
                const Gap(12),
                AgroCard(
                  color: AgroColors.tertiaryFixed.withValues(alpha: 0.4),
                  elevated: false,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AgroColors.tertiary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Estos valores están por validar con asistencia técnica. ${data.detail.source ?? ''}',
                          style: AgroText.bodySm.copyWith(
                            color: AgroColors.onSurface,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Gap(16),
              SegmentedTabs(
                labels: const ['Fases', 'Propag.', 'Dosis', 'Riesgos'],
                selected: _tab,
                onSelected: (i) => setState(() => _tab = i),
              ),
              const Gap(16),
              switch (_tab) {
                0 => _list(
                  empty: 'Sin fases cargadas',
                  children: [
                    for (final p in data.detail.phases)
                      ListRow(
                        leading: _Number(p.order),
                        title: phaseLabel(p.phase),
                        subtitle: p.days == null
                            ? 'Duración sin definir'
                            : 'Duración estimada: ${p.days} días',
                      ),
                  ],
                ),
                1 => _list(
                  empty: 'Sin métodos de propagación',
                  children: [
                    for (final m in data.methods)
                      ListRow(
                        leading: const IconBadge(icon: Icons.spa_outlined),
                        title: methodLabel(m.method),
                        subtitle: [
                          if (m.germinationDays != null)
                            'Germinación: ${m.germinationDays} días',
                          if (m.nurseryDays != null)
                            'Vivero: ${m.nurseryDays} días',
                        ].join(' · ').ifEmpty('Tiempos sin definir'),
                      ),
                  ],
                ),
                2 => _list(
                  empty: 'Sin dosis de referencia',
                  message: 'Falta cargar las dosis de este cultivo desde una fuente técnica.',
                  children: [
                    for (final d in data.doses)
                      ListRow(
                        leading: const IconBadge(icon: Icons.science_outlined),
                        title: humanize('${d['insumo_tipo'] ?? 'Insumo'}'),
                        subtitle: '${d['dosis'] ?? '—'} ${d['unidad'] ?? ''}',
                      ),
                  ],
                ),
                _ => _list(
                  empty: 'Sin riesgos asociados',
                  children: [
                    for (final r in data.risks)
                      ListRow(
                        leading: const IconBadge(
                          icon: Icons.shield_outlined,
                          background: AgroColors.tertiaryFixed,
                          foreground: AgroColors.tertiary,
                        ),
                        title: data.riskNames[r.riskId] ?? 'Riesgo',
                        subtitle: [
                          'Fase crítica: ${phaseLabel(r.phase)}',
                          if (r.measures != null) r.measures!,
                        ].join('\n'),
                        trailing: StatusPill(
                          r.susceptibility,
                          tone: susceptibilityTone(r.susceptibility),
                        ),
                      ),
                  ],
                ),
              },
            ],
          ),
        );
      },
    );
  }

  Widget _list({
    required String empty,
    String? message,
    required List<Widget> children,
  }) => children.isEmpty
      ? AgroCard(
          child: EmptyState(
            icon: Icons.inbox_outlined,
            title: empty,
            message: message,
          ),
        )
      : RowGroup(children: children);
}

class _Number extends StatelessWidget {
  const _Number(this.value);

  final int value;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AgroColors.secondaryContainer,
      borderRadius: BorderRadius.circular(AgroRadius.md),
    ),
    child: Text(
      '$value',
      style: AgroText.monoMd.copyWith(color: AgroColors.primary),
    ),
  );
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
