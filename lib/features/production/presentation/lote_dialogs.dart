import 'package:agrogestion/app/app_theme.dart';
import 'package:agrogestion/features/production/domain/lote_produccion.dart';
import 'package:flutter/material.dart';

String? _requerido(String? valor) =>
    valor == null || valor.trim().isEmpty ? 'Este campo es obligatorio.' : null;

/// Formulario para registrar un nuevo lote. Devuelve el [LoteProduccion] creado.
class NuevoLoteDialog extends StatefulWidget {
  const NuevoLoteDialog({required this.categoria, super.key});

  final CategoriaProduccion categoria;

  @override
  State<NuevoLoteDialog> createState() => _NuevoLoteDialogState();
}

class _NuevoLoteDialogState extends State<NuevoLoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _finca = TextEditingController();
  final _fase = TextEditingController(text: 'Preparación del terreno');

  @override
  void dispose() {
    _nombre.dispose();
    _finca.dispose();
    _fase.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      LoteProduccion(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        nombre: _nombre.text.trim(),
        finca: _finca.text.trim(),
        fase: _fase.text.trim(),
        categoria: widget.categoria,
        avance: 0,
        estado: EstadoAvance.alDia,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Nuevo registro · ${widget.categoria.label}'),
    content: SizedBox(
      width: 420,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('lote_nombre'),
              controller: _nombre,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: _requerido,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('lote_finca'),
              controller: _finca,
              decoration: const InputDecoration(labelText: 'Finca'),
              validator: _requerido,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fase,
              decoration: const InputDecoration(labelText: 'Fase actual'),
              validator: _requerido,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _guardar, child: const Text('Guardar')),
    ],
  );
}

/// Muestra el detalle de un lote. Devuelve el lote con el estado cambiado, o null.
class DetalleLoteDialog extends StatelessWidget {
  const DetalleLoteDialog({required this.lote, super.key});

  final LoteProduccion lote;

  @override
  Widget build(BuildContext context) {
    final alDia = lote.estado == EstadoAvance.alDia;
    return AlertDialog(
      title: Text(lote.nombre),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Finca: ${lote.finca}'),
            const SizedBox(height: 6),
            Text('Fase actual: ${lote.fase}'),
            const SizedBox(height: 6),
            Text('Categoría: ${lote.categoria.label}'),
            const SizedBox(height: 6),
            Text('Estado: ${lote.estado.label}'),
            const SizedBox(height: 16),
            Text('Avance: ${(lote.avance * 100).round()}%'),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: lote.avance,
              minHeight: 8,
              color: agroGreen,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.pop(
            context,
            lote.copyWith(
              estado: alDia ? EstadoAvance.atrasada : EstadoAvance.alDia,
            ),
          ),
          child: Text(alDia ? 'Marcar como atrasada' : 'Marcar al día'),
        ),
      ],
    );
  }
}
