import 'dart:convert';

import 'package:agrogestion/core/api/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('GET sends bearer token and decodes a list response', () async {
    final client = ApiClient(
      baseUrl: 'https://api.example.test/api/v1',
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/fincas');
        expect(request.headers['authorization'], 'Bearer token-de-prueba');
        return http.Response(
          jsonEncode([
            {'id': 'farm-id', 'nombre': 'Finca Norte'},
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final farms = await client.getList('fincas', token: 'token-de-prueba');
    expect(farms.single['nombre'], 'Finca Norte');
    client.close();
  });

  test(
    'maps API error messages without leaking internal response data',
    () async {
      final client = ApiClient(
        baseUrl: 'https://api.example.test',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'error': {
                'code': 'PERMISO_DENEGADO',
                'message': 'No tiene permiso.',
              },
            }),
            403,
          ),
        ),
      );

      await expectLater(
        client.get('fincas', token: 'token'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            'No tiene permiso.',
          ),
        ),
      );
      client.close();
    },
  );
}
