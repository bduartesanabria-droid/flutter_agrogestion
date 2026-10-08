import 'package:agrogestion/app/app_theme.dart';
import 'package:agrogestion/features/home/presentation/widgets/page_frame.dart';
import 'package:agrogestion/features/production/domain/lote_produccion.dart';
import 'package:agrogestion/features/production/presentation/lote_dialogs.dart';
import 'package:flutter/material.dart';

class ProductionPage extends StatefulWidget {
  const ProductionPage({super.key});

  @override
  State<ProductionPage> createState() => _ProductionPageState();
}

class _ProductionPageState extends State<ProductionPage> {
  CategoriaProduccion _categoria = CategoriaProduccion.cultivos;
  FiltroAvance _filtro = FiltroAvance.todas;
  final List<LoteProduccion> _lotes = List.of(seedProduccion);

  List<LoteProduccion> get _visibles => _lotes
      .where((l) => l.categoria == _categoria && _filtro.coincide(l.estado))
      .toList();

  Future<void> _registrar() async {
    final nuevo = await showDialog<LoteProduccion>(
      context: context,
      builder: (_) => NuevoLoteDialog(categoria: _categoria),
    );
    if (nuevo == null || !mounted) return;
    setState(() => _lotes.add(nuevo));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${nuevo.nombre} quedó registrado.')),
    );
  }

  Future<void> _abrirDetalle(LoteProduccion lote) async {
    final actualizado = await showDialog<LoteProduccion>(
      context: context,
      builder: (_) => DetalleLoteDialog(lote: lote),
    );
    if (actualizado == null || !mounted) return;
    setState(() {
      final indice = _lotes.indexWhere((l) => l.id == actualizado.id);
      if (indice >= 0) _lotes[indice] = actualizado;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibles = _visibles;
    return PageFrame(
      title: 'Producción',
      subtitle: 'Controle sus cultivos, procesos y animales.',
      action: FilledButton.icon(
        onPressed: _registrar,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Registrar'),
      ),
      children: [
        SegmentedButton<CategoriaProduccion>(
          segments: [
            for (final c in CategoriaProduccion.values)
              ButtonSegment(value: c, label: Text(c.label)),
          ],
          selected: {_categoria},
          onSelectionChanged: (seleccion) =>
              setState(() => _categoria = seleccion.first),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final f in FiltroAvance.values)
              ChoiceChip(
                label: Text(f.label),
                selected: _filtro == f,
                onSelected: (_) => setState(() => _filtro = f),
              ),
          ],
        ),
        const SizedBox(height: 22),
        SectionTitle(
          title: '${_categoria.label} en seguimiento',
          actionLabel: _filtro == FiltroAvance.todas ? null : 'Ver todas',
          onAction: () => setState(() => _filtro = FiltroAvance.todas),
        ),
        const SizedBox(height: 12),
        if (visibles.isEmpty)
          EmptyState(
            icon: Icons.eco_outlined,
            mensaje: 'No hay registros en esta vista.',
            accion: 'Registrar',
            onAccion: _registrar,
          )
        else
          for (final lote in visibles) ...[
            _LoteCard(lote: lote, onTap: () => _abrirDetalle(lote)),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _LoteCard extends StatelessWidget {
  const _LoteCard({required this.lote, required this.onTap});

  final LoteProduccion lote;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final alDia = lote.estado == EstadoAvance.alDia;
    final color = alDia ? agroGreen : const Color(0xFFD47B27);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(Icons.eco_outlined, color: color),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lote.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${lote.finca} · ${lote.fase}',
                          style: const TextStyle(
                            color: agroMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      lote.estado.label,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: lote.avance,
                        minHeight: 7,
                        color: color,
                        backgroundColor: const Color(0xFFE7ECE8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(lote.avance * 100).round()}%',
                    style: TextStyle(color: color, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
