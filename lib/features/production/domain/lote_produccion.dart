enum CategoriaProduccion {
  cultivos('Cultivos'),
  procesos('Procesos'),
  animales('Animales');

  const CategoriaProduccion(this.label);
  final String label;
}

enum EstadoAvance {
  alDia('Al día'),
  atrasada('Atrasada');

  const EstadoAvance(this.label);
  final String label;
}

enum FiltroAvance {
  todas('Todas'),
  alDia('Al día'),
  atrasadas('Atrasadas');

  const FiltroAvance(this.label);
  final String label;

  bool coincide(EstadoAvance estado) => switch (this) {
    FiltroAvance.todas => true,
    FiltroAvance.alDia => estado == EstadoAvance.alDia,
    FiltroAvance.atrasadas => estado == EstadoAvance.atrasada,
  };
}

class LoteProduccion {
  const LoteProduccion({
    required this.id,
    required this.nombre,
    required this.finca,
    required this.fase,
    required this.categoria,
    required this.avance,
    required this.estado,
  });

  final String id;
  final String nombre;
  final String finca;
  final String fase;
  final CategoriaProduccion categoria;

  /// Avance entre 0 y 1.
  final double avance;
  final EstadoAvance estado;

  LoteProduccion copyWith({EstadoAvance? estado}) => LoteProduccion(
    id: id,
    nombre: nombre,
    finca: finca,
    fase: fase,
    categoria: categoria,
    avance: avance,
    estado: estado ?? this.estado,
  );
}

/// Datos de ejemplo mientras el módulo de producción se conecta a la API.
const seedProduccion = <LoteProduccion>[
  LoteProduccion(
    id: '1',
    nombre: 'Café · Lote 2',
    finca: 'El Porvenir',
    fase: 'Mantenimiento',
    categoria: CategoriaProduccion.cultivos,
    avance: .68,
    estado: EstadoAvance.alDia,
  ),
  LoteProduccion(
    id: '2',
    nombre: 'Plátano · Lote 1',
    finca: 'La Esperanza',
    fase: 'Producción 2',
    categoria: CategoriaProduccion.cultivos,
    avance: .42,
    estado: EstadoAvance.atrasada,
  ),
  LoteProduccion(
    id: '3',
    nombre: 'Maíz · Lote 3',
    finca: 'Los Naranjos',
    fase: 'Cosecha',
    categoria: CategoriaProduccion.cultivos,
    avance: .86,
    estado: EstadoAvance.alDia,
  ),
  LoteProduccion(
    id: '4',
    nombre: 'Secado de bijao · Lote 1',
    finca: 'El Porvenir',
    fase: 'Secado al sol',
    categoria: CategoriaProduccion.procesos,
    avance: .6,
    estado: EstadoAvance.alDia,
  ),
  LoteProduccion(
    id: '5',
    nombre: 'Lote de aves 1',
    finca: 'La Esperanza',
    fase: 'Postura',
    categoria: CategoriaProduccion.animales,
    avance: .8,
    estado: EstadoAvance.alDia,
  ),
];
