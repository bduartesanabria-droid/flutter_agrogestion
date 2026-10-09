import 'dart:convert';

import 'package:agrogestion/core/api/api_client.dart';
import 'package:agrogestion/core/api/backend.dart';
import 'package:agrogestion/core/api/offline_queue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Server {
  bool online = true;
  bool rejectJornal = false;
  final List<String> calls = [];
  final List<String?> keys = [];

  Backend backend() => Backend(
    ApiClient(
      baseUrl: 'http://api.test',
      client: MockClient((request) async {
        if (!online) throw http.ClientException('sin red');
        calls.add('${request.method} ${request.url.path}');
        keys.add(request.headers['Idempotency-Key']);
        if (request.url.path.endsWith('/jornales') && rejectJornal) {
          return http.Response(
            jsonEncode({
              'error': {'message': 'Datos no válidos.'},
            }),
            422,
          );
        }
        final body = request.body.isEmpty ? {} : jsonDecode(request.body);
        if (request.url.path.endsWith('/actividades')) {
          return http.Response(jsonEncode({'id': 'act-9'}), 201);
        }
        return http.Response(jsonEncode({'echo': body}), 201);
      }),
    ),
    'token-x',
    queue: const OfflineQueue('u1'),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('un gasto sin red queda pendiente y se envía al volver', () async {
    final server = _Server()..online = false;
    final backend = server.backend();
    final result = await backend.post(
      'fincas/f1/gastos',
      body: {'categoria': 'Transporte', 'monto': 50000},
      idempotent: true,
      queueAs: 'Gasto de Transporte',
    );
    expect(result['pendiente'], isTrue);
    expect(backend.pending.value, 1);
    expect(backend.notice.value, contains('Guardado en el celular'));

    server.online = true;
    expect(await backend.syncPending(), 1);
    expect(backend.pending.value, 0);
    expect(server.calls, ['POST /fincas/f1/gastos']);
    expect(server.keys.single, isNotEmpty);
  });

  test('con red el registro se envía directo y no queda cola', () async {
    final server = _Server();
    final backend = server.backend();
    final result = await backend.post(
      'fincas/f1/gastos',
      body: {'categoria': 'Transporte', 'monto': 50000},
      queueAs: 'Gasto',
    );
    expect(result['pendiente'], isNull);
    expect(backend.pending.value, 0);
  });

  test(
    'una labor sin red guarda los dos pasos y enlaza la actividad',
    () async {
      final server = _Server()..online = false;
      final backend = server.backend();
      await backend.chain('Labor Socola', [
        QueueStep('fincas/f1/actividades', {'nombre': 'Socola'}, 'k1'),
        QueueStep(
          'fincas/f1/jornales',
          {'dias': 2},
          'k2',
          bindField: 'actividad_id',
        ),
      ]);
      expect(backend.pending.value, 1);

      server.online = true;
      await backend.syncPending();
      expect(server.calls, [
        'POST /fincas/f1/actividades',
        'POST /fincas/f1/jornales',
      ]);
      expect(server.keys, ['k1', 'k2']);
      expect(backend.pending.value, 0);
    },
  );

  test('si la red se cae a mitad, solo queda el paso que falta', () async {
    final server = _Server();
    final backend = server.backend();
    final steps = [
      QueueStep('fincas/f1/actividades', {'nombre': 'Socola'}, 'k1'),
      QueueStep(
        'fincas/f1/jornales',
        {'dias': 2},
        'k2',
        bindField: 'actividad_id',
      ),
    ];
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/jornales')) {
        throw http.ClientException('sin red');
      }
      return http.Response(jsonEncode({'id': 'act-1'}), 201);
    });
    final partial = Backend(
      ApiClient(baseUrl: 'http://api.test', client: client),
      'token-x',
      queue: const OfflineQueue('u1'),
    );
    await partial.chain('Labor', steps);
    final saved = await const OfflineQueue('u1').load();
    expect(saved.single.steps, hasLength(1));
    expect(saved.single.steps.single.body['actividad_id'], 'act-1');

    await backend.syncPending();
    expect(server.calls, ['POST /fincas/f1/jornales']);
  });

  test(
    'un registro rechazado por el servidor se descarta y se avisa',
    () async {
      final server = _Server()..rejectJornal = true;
      final backend = server.backend();
      server.online = false;
      await backend.chain('Labor', [
        QueueStep('fincas/f1/jornales', {'dias': 2}, 'k2'),
      ]);
      server.online = true;
      await backend.syncPending();
      expect(backend.pending.value, 0);
      expect(backend.notice.value, contains('No se pudo enviar "Labor"'));
    },
  );

  test('los registros de cada usuario son suyos', () async {
    final server = _Server()..online = false;
    await server.backend().post(
      'fincas/f1/gastos',
      body: {'monto': 1},
      queueAs: 'Gasto',
    );
    expect(await const OfflineQueue('u2').load(), isEmpty);
    expect(await const OfflineQueue('u1').load(), hasLength(1));
  });
}
