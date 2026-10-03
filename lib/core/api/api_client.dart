import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl =
          (baseUrl ??
                  const String.fromEnvironment(
                    'API_BASE_URL',
                    defaultValue: 'http://localhost:8000',
                  ))
              .replaceFirst(RegExp(r'/+$'), '');

  final http.Client _client;
  final String _baseUrl;

  Future<Map<String, dynamic>> get(
    String path, {
    String? token,
    Map<String, String>? query,
  }) async {
    final uri = _uri(path, query);
    final response = await _client.get(uri, headers: _headers(token));
    return _decode(response);
  }

  Future<List<Map<String, dynamic>>> getList(
    String path, {
    String? token,
    Map<String, String>? query,
  }) async {
    final response = await _client.get(
      _uri(path, query),
      headers: _headers(token),
    );
    final decoded = _decodeBody(response);
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().toList();
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      throw const ApiException(
        'La respuesta del servidor tiene un formato inesperado.',
      );
    }
    _throwApiError(response.statusCode, decoded);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    String? token,
    String? idempotencyKey,
  }) async {
    final headers = _headers(token);
    if (idempotencyKey != null) headers['Idempotency-Key'] = idempotencyKey;
    final response = await _client.post(
      _uri(path),
      headers: headers,
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$_baseUrl/$path');
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  Map<String, String> _headers(String? token) => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Map<String, dynamic> _decode(http.Response response) {
    final decoded = _decodeBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) return decoded;
      throw const ApiException(
        'La respuesta del servidor tiene un formato inesperado.',
      );
    }
    _throwApiError(response.statusCode, decoded);
  }

  Object? _decodeBody(http.Response response) {
    try {
      return response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
    } on FormatException {
      throw const ApiException(
        'El servidor devolvió una respuesta que no se pudo leer.',
      );
    }
  }

  Never _throwApiError(int statusCode, Object? decoded) {
    final error = decoded is Map<String, dynamic> ? decoded['error'] : null;
    final message = error is Map<String, dynamic> && error['message'] is String
        ? error['message'] as String
        : switch (statusCode) {
            401 => 'El correo o la contraseña no son válidos.',
            403 => 'No tiene permiso para realizar esta acción.',
            404 => 'No encontramos ese recurso.',
            409 => 'La operación entra en conflicto con los datos actuales.',
            _ => 'No se pudo completar la solicitud. Intente de nuevo.',
          };

    throw ApiException(message, statusCode: statusCode);
  }

  void close() => _client.close();
}
