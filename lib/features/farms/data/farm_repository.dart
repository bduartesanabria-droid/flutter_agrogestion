import '../../../core/api/backend.dart';
import '../domain/farm.dart';

class FarmRepository {
  const FarmRepository(this._backend);

  final Backend _backend;

  Future<List<Farm>> list() async =>
      (await _backend.getList('fincas')).map(Farm.fromJson).toList();

  Future<Farm> create({
    required String name,
    double? areaHa,
    String? departmentCode,
    String? municipalityCode,
  }) async {
    final response = await _backend.post(
      'fincas',
      body: {
        'nombre': name,
        'area_ha': ?areaHa,
        'departamento_dane': ?departmentCode,
        'municipio_dane': ?municipalityCode,
      },
    );
    return Farm.fromJson(response);
  }

  Future<List<Lot>> lots(String farmId) async =>
      (await _backend.getList('fincas/$farmId/lotes'))
          .map(Lot.fromJson)
          .toList();

  Future<Lot> createLot(
    String farmId, {
    required String name,
    required double areaHa,
    String? notes,
  }) async {
    final response = await _backend.post(
      'fincas/$farmId/lotes',
      body: {'nombre': name, 'area': areaHa, 'notas': ?notes},
    );
    return Lot.fromJson(response);
  }
}
