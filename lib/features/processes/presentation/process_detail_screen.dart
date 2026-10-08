import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/api/api_client.dart';
import '../../../core/format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/cards.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/forms.dart';
import '../../../core/widgets/layout.dart';
import '../../../core/widgets/states.dart';
import '../data/processes_repository.dart';

class ProcessDetailScreen extends StatelessWidget {
  const ProcessDetailScreen({required this.process, super.key});

  final ProcessItem process;

  Future<void> _move(
    BuildContext context,
    ProcessStage stage,
    String action,
    Future<void> Function() reload,
  ) async {
    final app = context.app;
    try {
      await app.processes.transition(app.activeFarm!.id, stage.id, action);
      app.markChanged();
      if (context.mounted) {
        showSnack(
          context,
          action == 'iniciar' ? 'Etapa iniciada.' : 'Etapa finalizada.',
        );
      }
      await reload();
    } on ApiException catch (error) {
      if (context.mounted) showSnack(context, error.message, error: true);
    } catch (_) {
      if (context.mounted) {
        showSnack(context, 'No hay conexión con el servidor.', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final farm = app.activeFarm!;
    final manage = app.access.managesInventory;
    return AsyncBody<List<ProcessStage>>(
      key: ValueKey('stages-${process.id}'),
      load: () => app.processes.stages(farm.id, process.id),
      skeleton: DetailScaffold(
        title: process.name,
        body: const AgroPage(children: [SkeletonList(rowHeight: 120)]),
      ),
      builder: (context, stages, reload) {
        final currentIndex = stages.indexWhere((s) => !s.done);
        final done = stages.where((s) => s.done).length;
        final estimated = stages.fold<double>(0, (s, e) => s + e.estimatedDays);
        return DetailScaffold(
          title: process.name,
          subtitle: process.product,
          floating: manage
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    final ok = await showAgroSheet<bool>(
                      context,
                      builder: (_) => _StageForm(app: app, process: process),
                    );
                    if (ok == true) await reload();
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Agregar etapa'),
                )
              : null,
          body: AgroPage(
            onRefresh: reload,
            children: [
              EqualGrid(
                columns: 2,
                children: [
                  KpiTile(
                    label: 'Etapas completadas',
                    value: stages.isEmpty ? '—' : '$done de ${stages.length}',
                    icon: Icons.timeline_outlined,
                    caption: process.finished
                        ? 'proceso terminado'
                        : 'en proceso',
                  ),
                  KpiTile(
                    label: 'Días estimados',
                    value: formatNumber(
                      estimated,
                      decimals: estimated % 1 == 0 ? 0 : 1,
                    ),
                    icon: Icons.schedule_outlined,
                    caption: 'sumando todas las etapas',
                    badgeBackground: AgroColors.tertiaryFixed,
                    badgeForeground: AgroColors.tertiary,
                  ),
                ],
              ),
              const Gap(16),
              AgroCard(
                child: Column(
                  children: [
                    InfoRow(label: 'Producto final', value: process.product),
                    const Divider(),
                    InfoRow(label: 'Materia prima', value: process.rawMaterial),
                    const Divider(),
                    InfoRow(
                      label: 'Origen',
                      value: process.origin == 'propia' ? 'Propia' : 'Comprada',
                    ),
                    const Divider(),
                    InfoRow(label: 'Inicio', value: formatDate(process.start)),
                  ],
                ),
              ),
              const SectionTitle('Etapas'),
              if (stages.isEmpty)
                const AgroCard(
                  child: EmptyState(
                    icon: Icons.format_list_numbered_rounded,
                    title: 'Aún no hay etapas',
                    message: 'Agregue las etapas del proceso, por ejemplo cocinar, limpiar y secar al sol.',
                  ),
                )
              else
                AgroCard(
                  child: Column(
                    children: [
                      for (var i = 0; i < stages.length; i++)
                        _StageRow(
                          stage: stages[i],
                          index: i + 1,
                          last: i == stages.length - 1,
                          current: i == currentIndex,
                          canMove: manage && !process.finished,
                          onMove: (action) =>
                              _move(context, stages[i], action, reload),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.stage,
    required this.index,
    required this.last,
    required this.current,
    required this.canMove,
    required this.onMove,
  });

  final ProcessStage stage;
  final int index;
  final bool last;
  final bool current;
  final bool canMove;
  final ValueChanged<String> onMove;

  @override
  Widget build(BuildContext context) {
    final color = stage.done
        ? AgroColors.primaryContainer
        : stage.running
        ? AgroColors.tertiary
        : AgroColors.outline;
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
                    color: stage.done || stage.running
                        ? color
                        : AgroColors.surfaceLowest,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Icon(
                    stage.done
                        ? Icons.check_rounded
                        : stage.running
                        ? Icons.play_arrow_rounded
                        : Icons.schedule_rounded,
                    size: 16,
                    color: stage.done || stage.running ? Colors.white : color,
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
                  Text('$index. ${stage.name}', style: AgroText.labelMd),
                  const SizedBox(height: 2),
                  Text(
                    'Estimado: ${formatNumber(stage.estimatedDays, decimals: stage.estimatedDays % 1 == 0 ? 0 : 1)} días',
                    style: AgroText.monoSm,
                  ),
                  if (stage.done)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: StatusPill(
                        'Finalizada el ${formatDateShort(stage.finishedAt)}',
                        tone: Tone.ok,
                      ),
                    ),
                  if (canMove && !stage.done && (stage.running || current))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              onMove(stage.running ? 'finalizar' : 'iniciar'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                          icon: Icon(
                            stage.running
                                ? Icons.check_circle_outline
                                : Icons.play_arrow_rounded,
                            size: 18,
                          ),
                          label: Text(
                            stage.running ? 'Finalizar etapa' : 'Iniciar etapa',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StageForm extends StatefulWidget {
  const _StageForm({required this.app, required this.process});

  final AppController app;
  final ProcessItem process;

  @override
  State<_StageForm> createState() => _StageFormState();
}

class _StageFormState extends State<_StageForm> {
  final _name = TextEditingController();
  final _days = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _days.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FormSheet(
    title: 'Agregar etapa',
    subtitle: widget.process.name,
    submitLabel: 'Guardar etapa',
    onSubmit: () => widget.app.processes.addStage(
      widget.app.activeFarm!.id,
      widget.process.id,
      name: _name.text.trim(),
      days: parseNumber(_days.text),
    ),
    children: [
      LabeledField(
        label: 'Nombre de la etapa',
        controller: _name,
        hint: 'Ejemplo: Secar al sol',
        maxLength: 120,
        validator: requiredText,
      ),
      LabeledField(
        label: 'Días estimados',
        controller: _days,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: positiveNumber,
      ),
    ],
  );
}
