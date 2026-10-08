import 'package:agrogestion/core/api/api_client.dart';
import 'package:agrogestion/features/proyecciones/domain/proyeccion_models.dart';

class ProyeccionesRepository {
  const ProyeccionesRepository({required this.api});

  final ApiClient api;

  /// Calcula la proyección agrícola de un cultivo para un área dada.
  /// Lanza [ApiException] si el servidor rechaza la petición.
  Future<ProyeccionResponse> calcularAgricola(
    ProyeccionRequest request, {
    required String token,
  }) async {
    final json = await api.post(
      'proyecciones/agricola',
      body: request.toJson(),
      token: token,
    );
    return ProyeccionResponse.fromJson(json);
  }
}
