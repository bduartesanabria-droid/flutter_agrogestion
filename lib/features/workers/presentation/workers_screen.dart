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
import '../data/workers_repository.dart';
import 'worker_detail_screen.dart';

String workerTypeLabel(String type) => switch (type) {
  'jornalero' => 'Jornalero',
  'contratista' => 'Contratista',
  'fijo' => 'Fijo',
  _ => humanize(type),
};

class WorkersScreen extends StatefulWidget {
  const WorkersScreen({super.key});

  @override
  State<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends State<WorkersScreen> {
  String _query = '';
  int _filter = 0;
  static const _types = [null, 'jornalero', 'contratista', 'fijo'];

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final farm = app.activeFarm;
    return DetailScaffold(
      title: 'Trabajadores',
      subtitle: farm?.name ?? 'Sin finca activa',
      body: farm == null
          ? const AgroPage(
              children: [
                AgroCard(
                  child: EmptyState(
                    icon: Icons.groups_outlined,
                    title: 'Sin finca activa',
                    message: 'Registre una finca para llevar sus trabajadores.',
                  ),
                ),
              ],
            )
          : AsyncBody<List<Worker>>(
              key: ValueKey('workers-${farm.id}-${app.revision}'),
              load: () => app.workers.list(farm.id),
              builder: (context, all, reload) {
                final type = _types[_filter];
                final shown = all
                    .where((w) => type == null || w.type == type)
                    .where(
                      (w) =>
                          _query.isEmpty ||
                          w.name.toLowerCase().contains(_query.toLowerCase()),
                    )
                    .toList();
                int count(String? t) =>
                    all.where((w) => t == null || w.type == t).length;
                return Scaffold(
                  backgroundColor: Colors.transparent,
                  floatingActionButton: app.access.managesWorkers
                      ? FloatingActionButton.extended(
                          onPressed: () async {
                            final ok = await showAgroSheet<bool>(
                              context,
                              builder: (_) => _WorkerForm(app: app),
                            );
                            if (ok == true) await reload();
                          },
                          icon: const Icon(Icons.person_add_alt_1_outlined),
                          label: const Text('Registrar'),
                        )
                      : null,
                  body: AgroPage(
                    onRefresh: reload,
                    children: [
                      TextField(
                        onChanged: (v) => setState(() => _query = v),
                        decoration: const InputDecoration(
                          hintText: 'Buscar trabajador',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                      const Gap(12),
                      FilterBar(
                        labels: const [
                          'Todos',
                          'Jornaleros',
                          'Contratistas',
                          'Fijos',
                        ],
                        counts: [for (final t in _types) count(t)],
                        selected: _filter,
                        onSelected: (i) => setState(() => _filter = i),
                      ),
                      const Gap(16),
                      if (shown.isEmpty)
                        AgroCard(
                          child: EmptyState(
                            icon: Icons.groups_outlined,
                            title: all.isEmpty
                                ? 'Aún no hay trabajadores'
                                : 'Nadie coincide con la búsqueda',
                            message: all.isEmpty
                                ? 'Registre a quienes trabajan en la finca para llevar sus jornales.'
                                : null,
                          ),
                        )
                      else
                        for (final worker in shown)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _WorkerCard(worker: worker),
                          ),
                      const Gap(8),
                      const _PrivacyNote(),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) => AgroCard(
    color: AgroColors.surfaceLow,
    elevated: false,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.shield_outlined,
          size: 20,
          color: AgroColors.primaryContainer,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Los documentos se guardan cifrados y solo se muestran los últimos dígitos (Ley 1581 de 2012).',
            style: AgroText.bodySm.copyWith(height: 1.5),
          ),
        ),
      ],
    ),
  );
}

class _WorkerCard extends StatelessWidget {
  const _WorkerCard({required this.worker});

  final Worker worker;

  @override
  Widget build(BuildContext context) => AgroCard(
    onTap: () => pushScreen(context, WorkerDetailScreen(worker: worker)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AgroColors.secondaryContainer,
              child: Text(
                worker.initials,
                style: AgroText.labelMd.copyWith(color: AgroColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    worker.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AgroText.headlineMd.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 2),
                  Text(worker.maskedDocument, style: AgroText.monoSm),
                  const SizedBox(height: 6),
                  StatusPill(
                    workerTypeLabel(worker.type),
                    tone: worker.status == 'activo' ? Tone.ok : Tone.neutral,
                  ),
                ],
              ),
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
              Expanded(child: Text('Jornal habitual', style: AgroText.bodySm)),
              const SizedBox(width: 8),
              AmountText(formatCop(worker.dailyRate)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _WorkerForm extends StatefulWidget {
  const _WorkerForm({required this.app});

  final AppController app;

  @override
  State<_WorkerForm> createState() => _WorkerFormState();
}

class _WorkerFormState extends State<_WorkerForm> {
  final _name = TextEditingController();
  final _rate = TextEditingController();
  final _document = TextEditingController();
  final _phone = TextEditingController();
  String _type = 'jornalero';

  @override
  void dispose() {
    for (final c in [_name, _rate, _document, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FormSheet(
    title: 'Registrar trabajador',
    subtitle: widget.app.activeFarm?.name,
    submitLabel: 'Guardar trabajador',
    onSubmit: () => widget.app.workers.create(
      widget.app.activeFarm!.id,
      name: _name.text.trim(),
      type: _type,
      dailyRate: parseNumber(_rate.text),
      document: _document.text.trim().isEmpty ? null : _document.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
    ),
    children: [
      LabeledField(
        label: 'Nombre completo',
        controller: _name,
        maxLength: 150,
        textCapitalization: TextCapitalization.words,
        validator: requiredText,
      ),
      LabeledDropdown<String>(
        label: 'Tipo',
        value: _type,
        items: const {
          'jornalero': 'Jornalero',
          'contratista': 'Contratista',
          'fijo': 'Fijo',
        },
        onChanged: (v) => setState(() => _type = v ?? 'jornalero'),
      ),
      LabeledField(
        label: 'Jornal habitual',
        controller: _rate,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        prefixText: 'COP \$ ',
        inputFormatters: moneyFormatters,
        validator: positiveNumber,
      ),
      LabeledField(
        label: 'Documento de identidad (opcional)',
        controller: _document,
        keyboardType: TextInputType.number,
        maxLength: 20,
      ),
      LabeledField(
        label: 'Teléfono (opcional)',
        controller: _phone,
        keyboardType: TextInputType.phone,
        maxLength: 30,
      ),
    ],
  );
}
