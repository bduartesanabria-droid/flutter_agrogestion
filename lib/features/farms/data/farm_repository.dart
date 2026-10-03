// The repository keeps its API client private behind the public constructor.
// ignore_for_file: prefer_initializing_formals

import '../../../core/api/api_client.dart';
import '../domain/farm.dart';

class FarmRepository {
  const FarmRepository({required ApiClient api}) : _api = api;

  final ApiClient _api;

  Future<List<Farm>> list(String token) async {
    final response = await _api.getList('fincas', token: token);
    return response.map(Farm.fromJson).toList();
  }

  Future<Farm> create(String token, String name) async {
    final response = await _api.post(
      'fincas',
      token: token,
      body: {'nombre': name},
    );
    return Farm.fromJson(response);
  }
}
