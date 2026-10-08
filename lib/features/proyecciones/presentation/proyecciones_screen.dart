import 'package:agrogestion/app/app_theme.dart';
import 'package:agrogestion/core/api/api_client.dart';
import 'package:agrogestion/core/format/cop.dart';
import 'package:agrogestion/features/auth/domain/auth_session.dart';
import 'package:agrogestion/features/home/presentation/widgets/page_frame.dart';
import 'package:agrogestion/features/proyecciones/data/proyecciones_repository.dart';
import 'package:agrogestion/features/proyecciones/domain/proyeccion_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProyeccionesScreen extends StatefulWidget {
  const ProyeccionesScreen({
    required this.session,
    required this.repository,
    this.cultivos = cultivosDemo,
    super.key,
  });

  final AuthSession session;
  final ProyeccionesRepository repository;
  final List<CultivoOpcion> cultivos;

  @override
  State<ProyeccionesScreen> createState() => _ProyeccionesScreenState();
}

class _ProyeccionesScreenState extends State<ProyeccionesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _areaController = TextEditingController(text: '10000');
  late CultivoOpcion _cultivo;

  ProyeccionResponse? _resultado;
  String? _error;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _cultivo = widget.cultivos.first;
  }

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  /// Acepta coma o punto decimal, según el teclado del dispositivo.
  double? _parsearArea(String texto) =>
      double.tryParse(texto.trim().replaceAll(',', '.'));

  String? _validarArea(String? valor) {
    final area = _parsearArea(valor ?? '');
    if (area == null || area <= 0) {
      return 'Ingrese un área mayor a cero, en metros cuadrados.';
    }
    return null;
  }

  Future<void> _calcular() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final area = _parsearArea(_areaController.text);
    if (area == null) return;

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final resultado = await widget.repository.calcularAgricola(
        ProyeccionRequest(cultivoId: _cultivo.id, areaM2: area),
        token: widget.session.token,
      );
      if (!mounted) return;
      setState(() => _resultado = resultado);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No se pudo calcular la proyección. Revise su conexión e intente de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final area = _parsearArea(_areaController.text);
    final hectareas = area == null ? null : area / 10000;

    return PageFrame(
      title: 'Simulador de proyecciones',
      subtitle: 'Estime plantas, costos e ingresos antes de sembrar.',
      children: [
        Panel(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle(title: 'Datos de la siembra'),
                const SizedBox(height: 16),
                DropdownButtonFormField<CultivoOpcion>(
                  initialValue: _cultivo,
                  decoration: const InputDecoration(
                    labelText: 'Cultivo',
                    prefixIcon: Icon(Icons.eco_outlined),
                  ),
                  items: [
                    for (final c in widget.cultivos)
                      DropdownMenuItem(value: c, child: Text(c.nombre)),
                  ],
                  onChanged: _cargando
                      ? null
                      : (nuevo) {
                          if (nuevo != null) setState(() => _cultivo = nuevo);
                        },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('proyeccion_area'),
                  controller: _areaController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Área de siembra',
                    hintText: 'Ej: 10000',
                    suffixText: 'm²',
                    prefixIcon: const Icon(Icons.square_foot_outlined),
                    helperText: hectareas == null
                        ? null
                        : '≈ ${hectareas.toStringAsFixed(2)} hectáreas',
                  ),
                  validator: _validarArea,
                  onChanged: (_) => setState(() {}),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  _MensajeError(texto: _error!),
                ],
                const SizedBox(height: 22),
                FilledButton.icon(
                  key: const Key('proyeccion_calcular'),
                  onPressed: _cargando ? null : _calcular,
                  icon: _cargando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.calculate_outlined),
                  label: Text(
                    _cargando ? 'Calculando…' : 'Calcular Proyección',
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_resultado != null) ...[
          const SizedBox(height: 28),
          _ResultadosProyeccion(resultado: _resultado!),
        ],
      ],
    );
  }
}

class _MensajeError extends StatelessWidget {
  const _MensajeError({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF0EE),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: Color(0xFF9C3025)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(texto, style: const TextStyle(color: Color(0xFF9C3025))),
        ),
      ],
    ),
  );
}

class _ResultadosProyeccion extends StatelessWidget {
  const _ResultadosProyeccion({required this.resultado});

  final ProyeccionResponse resultado;

  @override
  Widget build(BuildContext context) {
    final r = resultado;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _UtilidadHero(resultado: r),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columnas = constraints.maxWidth >= 720 ? 2 : 1;
            final ancho =
                (constraints.maxWidth - 16 * (columnas - 1)) / columnas;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: ancho,
                  child: _TarjetaDato(
                    icono: Icons.grass_outlined,
                    titulo: 'Plantas a sembrar',
                    valor: formatNumero(r.plantasEstimadas),
                    detalle:
                        '${r.cultivoNombre} · ${formatNumero(r.areaM2.round())} m²',
                    color: agroGreen,
                  ),
                ),
                SizedBox(
                  width: ancho,
                  child: _TarjetaDato(
                    icono: Icons.schedule_outlined,
                    titulo: 'Primera cosecha',
                    valor: '${r.mesesPrimeraCosecha} meses',
                    detalle:
                        'Cosechas por año: ${r.cosechasPorAnio.toStringAsFixed(1)}',
                    color: const Color(0xFF3567C8),
                  ),
                ),
                SizedBox(
                  width: ancho,
                  child: _CostosCard(resultado: r),
                ),
                SizedBox(
                  width: ancho,
                  child: _IngresosCard(resultado: r),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _UtilidadHero extends StatelessWidget {
  const _UtilidadHero({required this.resultado});

  final ProyeccionResponse resultado;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [agroGreen, agroGreenDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.trending_up_rounded, color: Colors.white70),
            SizedBox(width: 8),
            Text(
              'Utilidad neta estimada al año',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          formatCop(resultado.utilidadEstimadaAnual.round()),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ingreso anual de ${formatCop(resultado.ingresoEstimadoAnual.round())} '
          'menos costos de semilla y abono.',
          style: const TextStyle(color: Colors.white70, height: 1.4),
        ),
      ],
    ),
  );
}

class _TarjetaDato extends StatelessWidget {
  const _TarjetaDato({
    required this.icono,
    required this.titulo,
    required this.valor,
    required this.detalle,
    required this.color,
  });

  final IconData icono;
  final String titulo;
  final String valor;
  final String detalle;
  final Color color;

  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icono, color: color),
        ),
        const SizedBox(height: 14),
        Text(titulo, style: const TextStyle(color: agroMuted, fontSize: 13)),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: agroInk,
          ),
        ),
        const SizedBox(height: 4),
        Text(detalle, style: const TextStyle(color: agroMuted, fontSize: 12)),
      ],
    ),
  );
}

class _CostosCard extends StatelessWidget {
  const _CostosCard({required this.resultado});

  final ProyeccionResponse resultado;

  @override
  Widget build(BuildContext context) {
    final total = resultado.costoTotal;
    double fraccion(double parte) => total <= 0 ? 0 : parte / total;

    return Panel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Costos de establecimiento'),
          const SizedBox(height: 16),
          _FilaCosto(
            etiqueta: 'Semilla',
            valor: formatCop(resultado.costoSemillaEstimado.round()),
            fraccion: fraccion(resultado.costoSemillaEstimado),
            color: const Color(0xFF4E83CC),
          ),
          const SizedBox(height: 14),
          _FilaCosto(
            etiqueta: 'Abono',
            valor: formatCop(resultado.costoAbonoEstimado.round()),
            fraccion: fraccion(resultado.costoAbonoEstimado),
            color: const Color(0xFFD47B27),
          ),
          const Divider(height: 28),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Costo total',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                formatCop(total.round()),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilaCosto extends StatelessWidget {
  const _FilaCosto({
    required this.etiqueta,
    required this.valor,
    required this.fraccion,
    required this.color,
  });

  final String etiqueta;
  final String valor;
  final double fraccion;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(child: Text(etiqueta)),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: LinearProgressIndicator(
          value: fraccion,
          minHeight: 8,
          color: color,
          backgroundColor: const Color(0xFFE7ECE8),
        ),
      ),
    ],
  );
}

class _IngresosCard extends StatelessWidget {
  const _IngresosCard({required this.resultado});

  final ProyeccionResponse resultado;

  @override
  Widget build(BuildContext context) {
    final ingreso = resultado.ingresoEstimadoAnual;
    final margen = ingreso <= 0
        ? 0.0
        : resultado.utilidadEstimadaAnual / ingreso;

    return Panel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Ingresos proyectados'),
          const SizedBox(height: 16),
          _FilaDato(
            etiqueta: 'Ingreso estimado al año',
            valor: formatCop(ingreso.round()),
          ),
          const SizedBox(height: 12),
          _FilaDato(
            etiqueta: 'Utilidad neta al año',
            valor: formatCop(resultado.utilidadEstimadaAnual.round()),
            destacado: true,
          ),
          const SizedBox(height: 12),
          _FilaDato(
            etiqueta: 'Margen de utilidad',
            valor: '${(margen * 100).round()}%',
          ),
        ],
      ),
    );
  }
}

class _FilaDato extends StatelessWidget {
  const _FilaDato({
    required this.etiqueta,
    required this.valor,
    this.destacado = false,
  });

  final String etiqueta;
  final String valor;
  final bool destacado;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(etiqueta, style: const TextStyle(color: agroMuted)),
      ),
      Text(
        valor,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: destacado ? agroGreen : agroInk,
        ),
      ),
    ],
  );
}
