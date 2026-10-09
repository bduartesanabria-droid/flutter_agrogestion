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
import '../data/processes_repository.dart';
import 'process_detail_screen.dart';

class ProcessesScreen extends StatefulWidget {
  const ProcessesScreen({super.key});

  @override
  State<ProcessesScreen> createState() => _ProcessesScreenState();
}

class _ProcessesScreenState extends State<ProcessesScreen> {
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final farm = app.activeFarm;
    return DetailScaffold(
      title: 'Procesos de transformación',
      subtitle: farm?.name ?? 'Sin finca activa',
      floating: app.access.managesInventory && farm != null
          ? FloatingActionButton.extended(
              onPressed: () async {
                final ok = await showAgroSheet<bool>(
                  context,
                  builder: (_) => _ProcessForm(app: app),
                );
                if (ok == true) app.markChanged();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nuevo proceso'),
            )
          : null,
      body: farm == null
          ? const AgroPage(
              children: [
                AgroCard(
                  child: EmptyState(
                    icon: Icons.precision_manufacturing_outlined,
                    title: 'Sin finca activa',
                    message: 'Registre una finca para llevar sus procesos.',
                  ),
                ),
              ],
            )
          : AsyncBody<List<ProcessItem>>(
              key: ValueKey('proc-${farm.id}-${app.revision}'),
              load: () => app.processes.list(farm.id),
              builder: (context, all, reload) {
                final active = all.where((p) => !p.finished).toList();
                final done = all.where((p) => p.finished).toList();
                final shown = _filter == 0 ? active : done;
                return AgroPage(
                  onRefresh: reload,
                  children: [
                    FilterBar(
                      labels: const ['En proceso', 'Terminados'],
                      counts: [active.length, done.length],
                      selected: _filter,
                      onSelected: (i) => setState(() => _filter = i),
                    ),
                    const Gap(16),
                    if (shown.isEmpty)
                      AgroCard(
                        child: EmptyState(
                          icon: Icons.precision_manufacturing_outlined,
                          title: _filter == 0
                              ? 'No hay procesos en curso'
                              : 'Aún no hay procesos terminados',
                          message: 'Un proceso transforma la cosecha, por ejemplo el secado del bijao por etapas.',
                        ),
                      )
                    else
                      for (final process in shown)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ProcessCard(process: process),
                        ),
                  ],
                );
              },
            ),
    );
  }
}

class _ProcessCard extends StatelessWidget {
  const _ProcessCard({required this.process});

  final ProcessItem process;

  @override
  Widget build(BuildContext context) => AgroCard(
    onTap: () => pushScreen(context, ProcessDetailScreen(process: process)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                process.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AgroText.headlineMd.copyWith(fontSize: 18),
              ),
            ),
            const SizedBox(width: 8),
            StatusPill(
              process.finished ? 'Terminado' : 'En proceso',
              tone: process.finished ? Tone.neutral : Tone.ok,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${process.product} · materia prima ${process.origin == 'propia' ? 'propia' : 'comprada'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AgroText.bodySm,
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      process.stages == 0
                          ? 'Sin etapas definidas'
                          : '${process.stagesDone} de ${process.stages} etapas',
                      style: AgroText.bodySm.copyWith(
                        color: AgroColors.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    '${(process.progress * 100).round()}%',
                    style: AgroText.monoSm.copyWith(
                      color: AgroColors.primaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ProgressLine(value: process.progress),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text('Desde el ${formatDate(process.start)}', style: AgroText.monoSm),
      ],
    ),
  );
}

class _ProcessForm extends StatefulWidget {
  const _ProcessForm({required this.app});

  final AppController app;

  @override
  State<_ProcessForm> createState() => _ProcessFormState();
}

class _ProcessFormState extends State<_ProcessForm> {
  final _name = TextEditingController();
  final _product = TextEditingController();
  final _raw = TextEditingController();
  String _origin = 'propia';
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    for (final c in [_name, _product, _raw]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FormSheet(
    title: 'Nuevo proceso',
    subtitle: widget.app.activeFarm?.name,
    submitLabel: 'Guardar proceso',
    onSubmit: () => widget.app.processes.create(
      widget.app.activeFarm!.id,
      name: _name.text.trim(),
      product: _product.text.trim(),
      rawMaterial: _raw.text.trim(),
      origin: _origin,
      start: isoDate(_date),
    ),
    children: [
      LabeledField(
        label: 'Nombre del proceso',
        controller: _name,
        hint: 'Ejemplo: Secado lote 1',
        maxLength: 150,
        validator: requiredText,
      ),
      LabeledField(
        label: 'Producto final',
        controller: _product,
        maxLength: 150,
        validator: requiredText,
      ),
      LabeledField(
        label: 'Materia prima',
        controller: _raw,
        maxLength: 150,
        validator: requiredText,
      ),
      LabeledDropdown<String>(
        label: 'Origen de la materia prima',
        value: _origin,
        items: const {'propia': 'Propia', 'comprada': 'Comprada'},
        onChanged: (v) => setState(() => _origin = v ?? 'propia'),
      ),
      DateField(
        label: 'Fecha de inicio',
        value: _date,
        onChanged: (d) => setState(() => _date = d),
      ),
    ],
  );
}
