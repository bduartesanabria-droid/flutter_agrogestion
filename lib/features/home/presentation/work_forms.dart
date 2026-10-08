import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/forms.dart';
import '../../../core/widgets/states.dart';
import '../../production/data/production_repository.dart';
import '../../production/presentation/labels.dart';
import '../../workers/data/workers_repository.dart';

Future<bool> showWorkForm(BuildContext context, {String? cycleId}) =>
    _show(context, (app) => _WorkForm(app: app, cycleId: cycleId));

Future<bool> showHarvestForm(BuildContext context) =>
    _show(context, (app) => _HarvestForm(app: app));

Future<bool> _show(
  BuildContext context,
  Widget Function(AppController app) builder,
) async {
  final app = context.app;
  if (app.activeFarm == null) {
    showSnack(context, 'Primero registre una finca.', error: true);
    return false;
  }
  final result = await showAgroSheet<bool>(
    context,
    builder: (_) => builder(app),
  );
  if (result == true) app.markChanged();
  return result == true;
}

class _CycleData {
  const _CycleData(this.options, this.workers);

  final List<OpenCycleOption> options;
  final List<Worker> workers;
}

Widget _noCycles() => const EmptyState(
  icon: Icons.eco_outlined,
  title: 'No hay siembras en curso',
  message:
      'Inicie una siembra para poder registrar labores y cosechas en su ciclo.',
);

String _optionLabel(AppController app, OpenCycleOption o) =>
    '${app.cropName(o.planting.cropId)} · ${cycleTypeLabel(o.cycle.type)} ${o.cycle.number}';

class _WorkForm extends StatefulWidget {
  const _WorkForm({required this.app, this.cycleId});

  final AppController app;
  final String? cycleId;

  @override
  State<_WorkForm> createState() => _WorkFormState();
}

class _WorkFormState extends State<_WorkForm> {
  late final Future<_CycleData> _data = _load();
  final _name = TextEditingController();
  final _area = TextEditingController();
  final _workers = TextEditingController(text: '1');
  final _days = TextEditingController(text: '1');
  final _value = TextEditingController();
  String? _cycleId;
  String _phase = 'mantenimiento';
  String? _workerId;
  DateTime _date = DateTime.now();

  Future<_CycleData> _load() async {
    final app = widget.app;
    await app.crops();
    final options = await app.production.openCycles(app.activeFarm!.id);
    var workers = <Worker>[];
    try {
      workers = await app.workers.list(app.activeFarm!.id);
    } catch (_) {}
    _cycleId =
        widget.cycleId ?? (options.length == 1 ? options.first.cycle.id : null);
    return _CycleData(options, workers);
  }

  @override
  void dispose() {
    for (final c in [_name, _area, _workers, _days, _value]) {
      c.dispose();
    }
    super.dispose();
  }

  double get _total {
    double n(TextEditingController c) =>
        double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;
    return n(_workers) * n(_days) * n(_value);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_CycleData>(
    future: _data,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (snapshot.hasError) {
        return ErrorState(message: errorMessage(snapshot.error!));
      }
      final data = snapshot.requireData;
      if (data.options.isEmpty) return _noCycles();
      final app = widget.app;
      return FormSheet(
        title: 'Registrar labor con jornales',
        subtitle: app.activeFarm!.name,
        submitLabel: 'Guardar labor',
        onSubmit: () => app.workers.registerWork(
          app.activeFarm!.id,
          cycleId: _cycleId!,
          name: _name.text.trim(),
          phase: _phase,
          date: isoDate(_date),
          workedArea: parseNumber(_area.text),
          workers: parseNumber(_workers.text),
          days: parseNumber(_days.text),
          dailyValue: parseNumber(_value.text),
          workerId: _workerId,
        ),
        children: [
          LabeledDropdown<String>(
            label: 'Siembra y ciclo',
            value: _cycleId,
            items: {
              for (final o in data.options) o.cycle.id: _optionLabel(app, o),
            },
            validator: (v) => v == null ? 'Elija una siembra.' : null,
            onChanged: (v) => setState(() => _cycleId = v),
          ),
          LabeledField(
            label: 'Nombre de la labor',
            controller: _name,
            hint: 'Ejemplo: Socola y limpia',
            maxLength: 150,
            validator: requiredText,
          ),
          LabeledDropdown<String>(
            label: 'Fase',
            value: _phase,
            items: {
              for (final p in const [
                'preparacion',
                'siembra',
                'mantenimiento',
                'cosecha',
                'poscosecha',
                'renovacion',
              ])
                p: phaseLabel(p),
            },
            onChanged: (v) => setState(() => _phase = v ?? 'mantenimiento'),
          ),
          DateField(
            label: 'Fecha',
            value: _date,
            lastDate: DateTime.now(),
            onChanged: (d) => setState(() => _date = d),
          ),
          LabeledField(
            label: 'Área trabajada (hectáreas)',
            controller: _area,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: positiveNumber,
          ),
          if (data.workers.isNotEmpty)
            LabeledDropdown<String?>(
              label: 'Trabajador (opcional)',
              value: _workerId,
              items: {
                null: 'Cuadrilla sin nombre',
                for (final w in data.workers) w.id: w.name,
              },
              onChanged: (v) => setState(() => _workerId = v),
            ),
          LabeledField(
            label: 'Obreros',
            controller: _workers,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: positiveNumber,
            onChanged: (_) => setState(() {}),
          ),
          LabeledField(
            label: 'Días trabajados',
            controller: _days,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: positiveNumber,
            onChanged: (_) => setState(() {}),
          ),
          LabeledField(
            label: 'Valor del jornal',
            controller: _value,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixText: 'COP \$ ',
            inputFormatters: moneyFormatters,
            validator: positiveNumber,
            onChanged: (_) => setState(() {}),
          ),
          InfoTotal(label: 'Costo de mano de obra', value: formatCop(_total)),
        ],
      );
    },
  );
}

class _HarvestForm extends StatefulWidget {
  const _HarvestForm({required this.app});

  final AppController app;

  @override
  State<_HarvestForm> createState() => _HarvestFormState();
}

class _HarvestFormState extends State<_HarvestForm> {
  late final Future<List<OpenCycleOption>> _data = _load();
  final _quantity = TextEditingController();
  String? _cycleId;
  String _unit = 'kilo';
  String? _quality;
  DateTime _date = DateTime.now();

  Future<List<OpenCycleOption>> _load() async {
    await widget.app.crops();
    final options = await widget.app.production.openCycles(
      widget.app.activeFarm!.id,
    );
    if (options.length == 1) _cycleId = options.first.cycle.id;
    return options;
  }

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<OpenCycleOption>>(
    future: _data,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (snapshot.hasError) {
        return ErrorState(message: errorMessage(snapshot.error!));
      }
      final options = snapshot.requireData;
      if (options.isEmpty) return _noCycles();
      final app = widget.app;
      return FormSheet(
        title: 'Registrar cosecha',
        subtitle: app.activeFarm!.name,
        submitLabel: 'Guardar cosecha',
        onSubmit: () => app.production.createHarvest(
          app.activeFarm!.id,
          cycleId: _cycleId!,
          quantity: parseNumber(_quantity.text),
          unit: _unit,
          date: isoDate(_date),
          quality: _quality,
        ),
        children: [
          LabeledDropdown<String>(
            label: 'Siembra y ciclo',
            value: _cycleId,
            items: {for (final o in options) o.cycle.id: _optionLabel(app, o)},
            validator: (v) => v == null ? 'Elija una siembra.' : null,
            onChanged: (v) => setState(() => _cycleId = v),
          ),
          LabeledField(
            label: 'Cantidad cosechada',
            controller: _quantity,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: positiveNumber,
          ),
          LabeledDropdown<String>(
            label: 'Unidad',
            value: _unit,
            items: const {
              'kilo': 'Kilos',
              'arroba': 'Arrobas (12,5 kg)',
              'carga': 'Cargas',
              'lona': 'Lonas',
              'bulto': 'Bultos',
              'racimo': 'Racimos',
            },
            onChanged: (v) => setState(() => _unit = v ?? 'kilo'),
          ),
          LabeledDropdown<String?>(
            label: 'Calidad (opcional)',
            value: _quality,
            items: const {
              null: 'Sin clasificar',
              'primera': 'Primera',
              'segunda': 'Segunda',
              'tercera': 'Tercera',
            },
            onChanged: (v) => setState(() => _quality = v),
          ),
          DateField(
            label: 'Fecha',
            value: _date,
            lastDate: DateTime.now(),
            onChanged: (d) => setState(() => _date = d),
          ),
        ],
      );
    },
  );
}
