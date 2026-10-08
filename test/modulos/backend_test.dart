import 'dart:convert';

import 'package:agrogestion/core/api/api_client.dart';
import 'package:agrogestion/core/api/backend.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Backend _backend(
  Future<http.Response> Function(http.Request) handler, {
  void Function()? onUnauthorized,
}) {
  final api = ApiClient(baseUrl: 'http://api.test', client: MockClient(handler))
    ..onUnauthorized = onUnauthorized;
  return Backend(api, 'token-x');
}

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);

void main() {
  test('envía el token y lee una página con total', () async {
    final backend = _backend((request) async {
      expect(request.headers['authorization'], 'Bearer token-x');
      return _json({
        'items': [
          {'id': 'a'},
        ],
        'total': 7,
        'has_more': true,
      });
    });
    final page = await backend.getPage('siembras');
    expect(page.items.single['id'], 'a');
    expect(page.total, 7);
    expect(page.hasMore, isTrue);
  });

  test('getList acepta lista directa o página', () async {
    final direct = _backend(
      (_) async => _json([
        {'id': 1},
      ]),
    );
    expect((await direct.getList('x')).length, 1);
    final paged = _backend(
      (_) async => _json({
        'items': [
          {'id': 1},
          {'id': 2},
        ],
      }),
    );
    expect((await paged.getList('x')).length, 2);
  });

  test(
    'los registros llevan clave de idempotencia distinta cada vez',
    () async {
      final keys = <String?>[];
      final backend = _backend((request) async {
        keys.add(request.headers['Idempotency-Key']);
        return _json({'ok': true}, 201);
      });
      await backend.post('gastos', body: {'monto': 1}, idempotent: true);
      await backend.post('gastos', body: {'monto': 1}, idempotent: true);
      expect(keys.first, isNotNull);
      expect(keys.first, isNot(keys.last));
    },
  );

  test('un 401 avisa para cerrar la sesión', () async {
    var called = false;
    final backend = _backend(
      (_) async => _json({
        'error': {'code': 'TOKEN_INVALIDO', 'message': 'Sesión inválida.'},
      }, 401),
      onUnauthorized: () => called = true,
    );
    await expectLater(
      backend.getJson('auth/me'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', 'TOKEN_INVALIDO')
            .having((e) => e.statusCode, 'status', 401),
      ),
    );
    expect(called, isTrue);
  });

  test('PATCH y PUT usan el método correcto', () async {
    final methods = <String>[];
    final backend = _backend((request) async {
      methods.add(request.method);
      return _json({});
    });
    await backend.patch('eventos-adversos/1', body: {'fin': '2026-10-01'});
    await backend.put('cultivos/1', body: {});
    expect(methods, ['PATCH', 'PUT']);
  });

  test('una respuesta ilegible da un error claro', () async {
    final backend = _backend((_) async => http.Response('no es json', 200));
    await expectLater(backend.getJson('x'), throwsA(isA<ApiException>()));
  });
}
