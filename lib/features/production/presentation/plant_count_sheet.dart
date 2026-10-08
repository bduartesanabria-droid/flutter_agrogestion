import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_scope.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/forms.dart';

Future<bool> showPlantCountSheet(
  BuildContext context,
  String plantingId,
) async {
  final app = context.app;
  final result = await showAgroSheet<bool>(
    context,
    builder: (_) => _PlantCountForm(plantingId: plantingId, app: app),
  );
  if (result == true) app.markChanged();
  return result == true;
}

class _PlantCountForm extends StatefulWidget {
  const _PlantCountForm({required this.plantingId, required this.app});

  final String plantingId;
  final AppController app;

  @override
  State<_PlantCountForm> createState() => _PlantCountFormState();
}

class _PlantCountFormState extends State<_PlantCountForm> {
  final _alive = TextEditingController();
  final _dead = TextEditingController(text: '0');
  final _replanted = TextEditingController(text: '0');
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _alive.dispose();
    _dead.dispose();
    _replanted.dispose();
    super.dispose();
  }

  String? _count(String? value) {
    final n = int.tryParse((value ?? '').trim());
    return n == null || n < 0 ? 'Escriba un número entero.' : null;
  }

  @override
  Widget build(BuildContext context) => FormSheet(
    title: 'Registrar conteo de plantas',
    subtitle: 'Cuente las plantas del lote para actualizar los índices.',
    submitLabel: 'Guardar conteo',
    onSubmit: () => widget.app.production.addCount(
      widget.plantingId,
      date: isoDate(_date),
      alive: int.parse(_alive.text.trim()),
      dead: int.parse(_dead.text.trim()),
      replanted: int.parse(_replanted.text.trim()),
    ),
    children: [
      DateField(
        label: 'Fecha del conteo',
        value: _date,
        lastDate: DateTime.now(),
        onChanged: (d) => setState(() => _date = d),
      ),
      LabeledField(
        label: 'Plantas vivas',
        controller: _alive,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: _count,
      ),
      LabeledField(
        label: 'Plantas muertas',
        controller: _dead,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: _count,
      ),
      LabeledField(
        label: 'Resiembras',
        controller: _replanted,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: _count,
      ),
    ],
  );
}
