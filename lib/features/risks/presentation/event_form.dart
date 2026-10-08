import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/forms.dart';
import '../../../core/widgets/states.dart';
import '../../production/domain/production.dart';
import '../data/risks_repository.dart';

Future<bool> showEventForm(BuildContext context) async {
  final app = context.app;
  final farm = app.activeFarm;
  if (farm == null) {
    showSnack(context, 'Primero registre una finca.', error: true);
    return false;
  }
  final result = await showAgroSheet<bool>(
    context,
    builder: (_) => _EventForm(app: app),
  );
  if (result == true) app.markChanged();
  return result == true;
}

class _EventData {
  const _EventData(this.risks, this.plantings);

  final List<RiskType> risks;
  final List<Planting> plantings;
}

class _EventForm extends StatefulWidget {
  const _EventForm({required this.app});

  final AppController app;

  @override
  State<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<_EventForm> {
  late final Future<_EventData> _data = _load();
  final _area = TextEditingController();
  final _loss = TextEditingController();
  final _notes = TextEditingController();
  String? _riskId;
  String? _plantingId;
  String _severity = 'moderada';
  DateTime _date = DateTime.now();

  Future<_EventData> _load() async {
    final app = widget.app;
    await app.crops();
    final risks = await app.risks.catalog();
    var plantings = <Planting>[];
    try {
      final all = await app.production.plantings();
      plantings = all.items
          .where(
            (p) => p.farmId == app.activeFarm!.id && p.status == 'en_curso',
          )
          .toList();
    } catch (_) {}
    return _EventData(risks, plantings);
  }

  @override
  void dispose() {
    _area.dispose();
    _loss.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_EventData>(
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
      final app = widget.app;
      return FormSheet(
        title: 'Registrar evento adverso',
        subtitle: app.activeFarm!.name,
        submitLabel: 'Guardar evento',
        onSubmit: () => app.risks.create(
          farmId: app.activeFarm!.id,
          riskId: _riskId!,
          start: isoDate(_date),
          severity: _severity,
          plantingId: _plantingId,
          affectedArea: _area.text.trim().isEmpty
              ? null
              : parseNumber(_area.text),
          estimatedLoss: _loss.text.trim().isEmpty
              ? null
              : parseNumber(_loss.text),
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        ),
        children: [
          LabeledDropdown<String>(
            label: 'Qué ocurrió',
            value: _riskId,
            items: {for (final r in data.risks) r.id: r.name},
            validator: (v) => v == null ? 'Elija el tipo de evento.' : null,
            onChanged: (v) => setState(() => _riskId = v),
          ),
          if (data.plantings.isNotEmpty)
            LabeledDropdown<String?>(
              label: 'Siembra afectada (opcional)',
              value: _plantingId,
              items: {
                null: 'Toda la finca',
                for (final p in data.plantings) p.id: app.cropName(p.cropId),
              },
              onChanged: (v) => setState(() => _plantingId = v),
            ),
          LabeledDropdown<String>(
            label: 'Severidad',
            value: _severity,
            items: const {
              'leve': 'Leve',
              'moderada': 'Moderada',
              'severa': 'Severa',
            },
            onChanged: (v) => setState(() => _severity = v ?? 'moderada'),
          ),
          DateField(
            label: 'Fecha de inicio',
            value: _date,
            lastDate: DateTime.now(),
            onChanged: (d) => setState(() => _date = d),
          ),
          LabeledField(
            label: 'Área afectada en hectáreas (opcional)',
            controller: _area,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          LabeledField(
            label: 'Pérdida estimada en pesos (opcional)',
            controller: _loss,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixText: 'COP \$ ',
            inputFormatters: moneyFormatters,
          ),
          LabeledField(
            label: 'Notas (opcional)',
            controller: _notes,
            maxLines: 3,
            maxLength: 2000,
          ),
        ],
      );
    },
  );
}
