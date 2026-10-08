import 'dart:math';

import 'api_client.dart';

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
  const Backend(this.api, this.token);

  final ApiClient api;
  final String token;

  Future<Json> getJson(String path, {Map<String, String>? query}) async {
    final data = await api.getAny(path, token: token, query: query);
    if (data is Json) return data;
    throw const ApiException('La respuesta del servidor no se pudo leer.');
  }

  Future<List<Json>> getList(String path, {Map<String, String>? query}) async {
    final data = await api.getAny(path, token: token, query: query);
    if (data is List) return data.whereType<Json>().toList();
    if (data is Json && data['items'] is List) {
      return (data['items'] as List).whereType<Json>().toList();
    }
    throw const ApiException('La respuesta del servidor no se pudo leer.');
  }

  Future<Paged> getPage(String path, {Map<String, String>? query}) async {
    final data = await api.getAny(path, token: token, query: query);
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
  }) async {
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
