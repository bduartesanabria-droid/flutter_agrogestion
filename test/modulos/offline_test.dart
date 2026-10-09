import 'dart:convert';

import 'package:agrogestion/core/api/api_client.dart';
import 'package:agrogestion/core/api/backend.dart';
import 'package:agrogestion/core/api/offline_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Backend _backend(bool Function() online, {OfflineCache? cache}) {
  final client = MockClient((request) async {
    if (!online()) throw http.ClientException('sin red');
    if (request.url.path.endsWith('/rota')) {
      return http.Response(
        jsonEncode({
          'error': {'message': 'falla'},
        }),
        500,
      );
    }
    return http.Response(
      jsonEncode([
        {'id': 'a', 'nombre': 'Finca La Esperanza'},
      ]),
      200,
    );
  });
  return Backend(
    ApiClient(baseUrl: 'http://api.test', client: client),
    'token-x',
    cache: cache,
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('sin red devuelve lo último guardado y avisa', () async {
    var online = true;
    final backend = _backend(() => online, cache: const OfflineCache('u1'));
    expect(
      (await backend.getList('fincas')).single['nombre'],
      'Finca La Esperanza',
    );
    expect(backend.offline.value, isFalse);
    await Future<void>.delayed(Duration.zero);

    online = false;
    final saved = await backend.getList('fincas');
    expect(saved.single['id'], 'a');
    expect(backend.offline.value, isTrue);

    online = true;
    await backend.getList('fincas');
    expect(backend.offline.value, isFalse);
  });

  test('sin red y sin nada guardado falla como antes', () async {
    final backend = _backend(() => false, cache: const OfflineCache('u1'));
    expect(
      () => backend.getList('fincas'),
      throwsA(isA<http.ClientException>()),
    );
  });

  test('sin caché configurada no inventa datos', () async {
    final backend = _backend(() => false);
    expect(
      () => backend.getList('fincas'),
      throwsA(isA<http.ClientException>()),
    );
  });

  test('un error del servidor no se tapa con datos viejos', () async {
    var online = true;
    final backend = _backend(() => online, cache: const OfflineCache('u1'));
    await backend.getList('fincas');
    await Future<void>.delayed(Duration.zero);
    expect(() => backend.getList('fincas/rota'), throwsA(isA<ApiException>()));
    expect(backend.offline.value, isFalse);
  });

  test('cada usuario guarda lo suyo y cerrar sesión lo borra', () async {
    var online = true;
    final first = _backend(() => online, cache: const OfflineCache('u1'));
    await first.getList('fincas');
    await Future<void>.delayed(Duration.zero);
    online = false;

    final other = _backend(() => online, cache: const OfflineCache('u2'));
    expect(() => other.getList('fincas'), throwsA(isA<http.ClientException>()));

    await OfflineCache.clearAll();
    expect(() => first.getList('fincas'), throwsA(isA<http.ClientException>()));
  });
}
