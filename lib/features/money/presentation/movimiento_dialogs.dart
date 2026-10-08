import 'package:agrogestion/app/app_theme.dart';
import 'package:agrogestion/core/format/cop.dart';
import 'package:agrogestion/features/money/domain/movimiento.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Formulario de un gasto o ingreso. Devuelve el [Movimiento] creado.
class NuevoMovimientoDialog extends StatefulWidget {
  const NuevoMovimientoDialog({super.key});

  @override
  State<NuevoMovimientoDialog> createState() => _NuevoMovimientoDialogState();
}

class _NuevoMovimientoDialogState extends State<NuevoMovimientoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descripcion = TextEditingController();
  final _categoria = TextEditingController();
  final _monto = TextEditingController();
  TipoMovimiento _tipo = TipoMovimiento.gasto;

  @override
  void dispose() {
    _descripcion.dispose();
    _categoria.dispose();
    _monto.dispose();
    super.dispose();
  }

  String? _requerido(String? valor) => valor == null || valor.trim().isEmpty
      ? 'Este campo es obligatorio.'
      : null;

  String? _validarMonto(String? valor) {
    final monto = int.tryParse(valor ?? '');
    if (monto == null || monto <= 0) return 'Ingrese un valor mayor a cero.';
    return null;
  }

  void _guardar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      Movimiento(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        descripcion: _descripcion.text.trim(),
        categoria: _categoria.text.trim(),
        fecha: fechaHoy(),
        monto: int.parse(_monto.text),
        tipo: _tipo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Nuevo movimiento'),
    content: SizedBox(
      width: 420,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<TipoMovimiento>(
              segments: [
                for (final t in TipoMovimiento.values)
                  ButtonSegment(value: t, label: Text(t.label)),
              ],
              selected: {_tipo},
              onSelectionChanged: (s) => setState(() => _tipo = s.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('movimiento_descripcion'),
              controller: _descripcion,
              decoration: const InputDecoration(labelText: 'Descripción'),
              validator: _requerido,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('movimiento_categoria'),
              controller: _categoria,
              decoration: const InputDecoration(labelText: 'Categoría'),
              validator: _requerido,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('movimiento_monto'),
              controller: _monto,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Monto en pesos',
                prefixText: r'$ ',
              ),
              validator: _validarMonto,
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

/// Detalle de un movimiento. Devuelve el motivo si se anula, o null si solo se cierra.
class DetalleMovimientoDialog extends StatefulWidget {
  const DetalleMovimientoDialog({required this.movimiento, super.key});

  final Movimiento movimiento;

  @override
  State<DetalleMovimientoDialog> createState() =>
      _DetalleMovimientoDialogState();
}

class _DetalleMovimientoDialogState extends State<DetalleMovimientoDialog> {
  final _motivo = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  void _anular() {
    final texto = _motivo.text.trim();
    if (texto.isEmpty) {
      setState(() => _error = 'Escriba el motivo de la anulación.');
      return;
    }
    Navigator.pop(context, texto);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.movimiento;
    return AlertDialog(
      title: Text(m.descripcion),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Dato('Tipo', m.tipo.label),
            _Dato('Categoría', m.categoria),
            _Dato('Fecha', m.fecha),
            _Dato('Monto', formatCop(m.monto)),
            _Dato('Estado', m.activo ? 'Registrado' : 'Anulado'),
            if (m.motivoAnulacion != null)
              _Dato('Motivo de anulación', m.motivoAnulacion!),
            if (m.activo) ...[
              const SizedBox(height: 16),
              TextField(
                key: const Key('movimiento_motivo'),
                controller: _motivo,
                decoration: InputDecoration(
                  labelText: 'Motivo de la anulación',
                  errorText: _error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
        if (m.activo)
          FilledButton(
            onPressed: _anular,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB13B32),
            ),
            child: const Text('Anular'),
          ),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.etiqueta, this.valor);

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        SizedBox(
          width: 150,
          child: Text(etiqueta, style: const TextStyle(color: agroMuted)),
        ),
        Expanded(
          child: Text(
            valor,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
