import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'offline_cache.dart';
import 'offline_queue.dart';

typedef Json = Map<String, dynamic>;

class Paged {
  const Paged({
    required this.items,
    required this.total,
    required this.hasMore,
  });

  final List<Json> items;
  final int total;
  final bool hasMore;
}

String newIdempotencyKey() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

class Backend {
  Backend(this.api, this.token, {this.cache, this.queue}) {
    unawaited(_refreshPending());
  }

  final ApiClient api;
  final String token;
  final OfflineCache? cache;
  final OfflineQueue? queue;
  final ValueNotifier<bool> offline = ValueNotifier(false);
  final ValueNotifier<int> pending = ValueNotifier(0);
  final ValueNotifier<String?> notice = ValueNotifier(null);
  bool _syncing = false;

  Future<void> _refreshPending() async {
    pending.value = (await queue?.load())?.length ?? 0;
  }

  Future<Json> _enqueue(String label, List<QueueStep> steps) async {
    await queue!.add(PendingOp(newIdempotencyKey(), label, steps));
    await _refreshPending();
    offline.value = true;
    notice.value = 'Guardado en el celular. Se enviará cuando haya señal.';
    return {'pendiente': true};
  }

  Future<Json> _sendStep(QueueStep step) async {
    final data = await api.send(
      'POST',
      step.path,
      body: step.body,
      token: token,
      idempotencyKey: step.key,
    );
    return data is Json ? data : <String, dynamic>{};
  }

  Future<Json> chain(String label, List<QueueStep> steps) async {
    Json? last;
    for (var i = 0; i < steps.length; i++) {
      final step = steps[i].bound(last);
      try {
        last = await _sendStep(step);
      } on ApiException {
        rethrow;
      } catch (_) {
        if (queue == null) rethrow;
        return _enqueue(label, [step, ...steps.skip(i + 1)]);
      }
    }
    return last ?? <String, dynamic>{};
  }

  Future<int> syncPending() async {
    if (_syncing || queue == null) return 0;
    _syncing = true;
    var sent = 0;
    try {
      for (final op in await queue!.load()) {
        Json? last;
        var steps = List<QueueStep>.of(op.steps);
        var stop = false;
        var rejected = false;
        while (steps.isNotEmpty) {
          final step = steps.first.bound(last);
          try {
            last = await _sendStep(step);
            steps = steps.skip(1).toList();
            if (steps.isNotEmpty) await queue!.replaceSteps(op.id, steps);
          } on ApiException catch (error) {
            if (error.statusCode == 401) {
              stop = true;
            } else {
              steps = [];
              rejected = true;
              notice.value =
                  'No se pudo enviar "${op.label}": ${error.message}';
            }
            break;
          } catch (_) {
            stop = true;
            break;
          }
        }
        if (stop) break;
        await queue!.remove(op.id);
        if (!rejected) sent++;
      }
    } finally {
      _syncing = false;
      await _refreshPending();
    }
    if (sent > 0) {
      notice.value = sent == 1
          ? 'Se envió 1 registro pendiente.'
          : 'Se enviaron $sent registros pendientes.';
    }
    return sent;
  }

  Future<Object?> _read(String path, Map<String, String>? query) async {
    final sorted = (query ?? const <String, String>{}).entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final id = [path, for (final e in sorted) '${e.key}=${e.value}'].join('|');
    try {
      final data = await api
          .getAny(path, token: token, query: query)
          .timeout(const Duration(seconds: 20));
      offline.value = false;
      unawaited(cache?.save(id, data));
      if (pending.value > 0) unawaited(syncPending());
      return data;
    } on ApiException {
      rethrow;
    } catch (_) {
      final saved = await cache?.read(id);
      if (saved == null) rethrow;
      offline.value = true;
      return saved;
    }
  }

  Future<Json> getJson(String path, {Map<String, String>? query}) async {
    final data = await _read(path, query);
    if (data is Json) return data;
    throw const ApiException('La respuesta del servidor no se pudo leer.');
  }

  Future<List<Json>> getList(String path, {Map<String, String>? query}) async {
    final data = await _read(path, query);
    if (data is List) return data.whereType<Json>().toList();
    if (data is Json && data['items'] is List) {
      return (data['items'] as List).whereType<Json>().toList();
    }
    throw const ApiException('La respuesta del servidor no se pudo leer.');
  }

  Future<Paged> getPage(String path, {Map<String, String>? query}) async {
    final data = await _read(path, query);
    if (data is Json && data['items'] is List) {
      final items = (data['items'] as List).whereType<Json>().toList();
      return Paged(
        items: items,
        total: (data['total'] as num?)?.toInt() ?? items.length,
        hasMore: data['has_more'] == true,
      );
    }
    if (data is List) {
      final items = data.whereType<Json>().toList();
      return Paged(items: items, total: items.length, hasMore: false);
    }
    throw const ApiException('La respuesta del servidor no se pudo leer.');
  }

  Future<Json> post(
    String path, {
    Object? body,
    bool idempotent = false,
    String? queueAs,
  }) async {
    if (queueAs != null && body is Map<String, dynamic>) {
      return chain(queueAs, [QueueStep(path, body, newIdempotencyKey())]);
    }
    final data = await api.send(
      'POST',
      path,
      body: body,
      token: token,
      idempotencyKey: idempotent ? newIdempotencyKey() : null,
    );
    return data is Json ? data : <String, dynamic>{};
  }

  Future<Json> patch(String path, {Object? body}) async {
    final data = await api.send('PATCH', path, body: body, token: token);
    return data is Json ? data : <String, dynamic>{};
  }

  Future<Json> put(String path, {Object? body}) async {
    final data = await api.send('PUT', path, body: body, token: token);
    return data is Json ? data : <String, dynamic>{};
  }
}
