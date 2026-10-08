import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/forms.dart';
import '../../../core/widgets/states.dart';
import '../../farms/domain/farm.dart';
import '../domain/production.dart';
import 'labels.dart';

Future<bool> showPlantingForm(BuildContext context) async {
  final app = context.app;
  final farm = app.activeFarm;
  if (farm == null) {
    showSnack(context, 'Primero registre una finca.', error: true);
    return false;
  }
  final result = await showAgroSheet<bool>(
    context,
    builder: (_) => _PlantingForm(app: app, farm: farm),
  );
  return result == true;
}

class _PlantingData {
  const _PlantingData(this.lots, this.crops);

  final List<Lot> lots;
  final List<Crop> crops;
}

class _PlantingForm extends StatefulWidget {
  const _PlantingForm({required this.app, required this.farm});

  final AppController app;
  final Farm farm;

  @override
  State<_PlantingForm> createState() => _PlantingFormState();
}

class _PlantingFormState extends State<_PlantingForm> {
  late final Future<_PlantingData> _data = _load();
  final _area = TextEditingController();
  final _plants = TextEditingController();
  final _budget = TextEditingController();
  String? _lotId;
  String? _cropId;
  String _method = 'semilla';
  DateTime _date = DateTime.now();

  Future<_PlantingData> _load() async {
    final lots = await widget.app.farmsRepo.lots(widget.farm.id);
    final crops = await widget.app.production.crops();
    return _PlantingData(lots, crops);
  }

  @override
  void dispose() {
    _area.dispose();
    _plants.dispose();
    _budget.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_PlantingData>(
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
      if (data.lots.isEmpty) {
        return const EmptyState(
          icon: Icons.grid_view_rounded,
          title: 'Esta finca aún no tiene lotes',
          message: 'Agregue un lote en el detalle de la finca antes de planear una siembra.',
        );
      }
      return FormSheet(
        title: 'Planear siembra',
        subtitle: widget.farm.name,
        submitLabel: 'Planear siembra',
        onSubmit: () => widget.app.production.createPlanting(
          farmId: widget.farm.id,
          lotId: _lotId!,
          cropId: _cropId!,
          method: _method,
          areaHa: parseNumber(_area.text),
          planDate: isoDate(_date),
          plants: _plants.text.trim().isEmpty
              ? null
              : int.parse(_plants.text.trim()),
          budget: _budget.text.trim().isEmpty
              ? null
              : parseNumber(_budget.text),
        ),
        children: [
          LabeledDropdown<String>(
            label: 'Lote',
            value: _lotId,
            items: {
              for (final l in data.lots)
                l.id: '${l.name} · ${formatHa(l.areaHa)}',
            },
            validator: (v) => v == null ? 'Elija un lote.' : null,
            onChanged: (v) => setState(() => _lotId = v),
          ),
          LabeledDropdown<String>(
            label: 'Cultivo',
            value: _cropId,
            items: {for (final c in data.crops) c.id: c.name},
            validator: (v) => v == null ? 'Elija un cultivo.' : null,
            onChanged: (v) => setState(() => _cropId = v),
          ),
          LabeledDropdown<String>(
            label: 'Forma de propagación',
            value: _method,
            items: {for (final m in plantingMethods) m: methodLabel(m)},
            onChanged: (v) => setState(() => _method = v ?? 'semilla'),
          ),
          LabeledField(
            label: 'Área sembrada (hectáreas)',
            controller: _area,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: positiveNumber,
          ),
          LabeledField(
            label: 'Plantas sembradas (opcional)',
            controller: _plants,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          DateField(
            label: 'Fecha planeada',
            value: _date,
            onChanged: (d) => setState(() => _date = d),
          ),
          LabeledField(
            label: 'Presupuesto en pesos (opcional)',
            controller: _budget,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixText: '\$ ',
            inputFormatters: moneyFormatters,
          ),
        ],
      );
    },
  );
}
