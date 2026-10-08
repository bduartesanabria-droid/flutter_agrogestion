class Farm {
  const Farm({
    required this.id,
    required this.name,
    this.departmentCode,
    this.municipalityCode,
    this.areaHa,
  });

  final String id;
  final String name;
  final String? departmentCode;
  final String? municipalityCode;
  final double? areaHa;

  factory Farm.fromJson(Map<String, dynamic> json) => Farm(
    id: json['id'] as String,
    name: json['nombre'] as String,
    departmentCode: json['departamento_dane'] as String?,
    municipalityCode: json['municipio_dane'] as String?,
    areaHa: double.tryParse('${json['area_ha']}'),
  );
}

class Lot {
  const Lot({
    required this.id,
    required this.farmId,
    required this.name,
    required this.areaHa,
    this.notes,
  });

  final String id;
  final String farmId;
  final String name;
  final double areaHa;
  final String? notes;

  factory Lot.fromJson(Map<String, dynamic> json) => Lot(
    id: json['id'] as String,
    farmId: json['finca_id'] as String,
    name: json['nombre'] as String,
    areaHa: double.tryParse('${json['area']}') ?? 0,
    notes: json['notas'] as String?,
  );
}
