// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/api/api_client.dart';
import '../domain/auth_session.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient api,
    required FlutterSecureStorage storage,
  }) : _api = api,
       _storage = storage;

  static const _tokenKey = 'agrogestion_access_token';
  static const _profileKey = 'agrogestion_profile';

  final ApiClient _api;
  final FlutterSecureStorage _storage;

  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      'auth/login',
      body: {'email': email.trim(), 'password': password},
    );
    final token = response['access_token'];
    if (token is! String || token.isEmpty) {
      throw const ApiException('El servidor no entregó una sesión válida.');
    }

    final profile = await _api.get('auth/me', token: token);
    final session = AuthSession.fromApi(token: token, profile: profile);
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _profileKey, value: jsonEncode(profile));
    return session;
  }

  Future<AuthSession?> restoreSession() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) return null;

    try {
      final profile = await _api.get('auth/me', token: token);
      await _storage.write(key: _profileKey, value: jsonEncode(profile));
      return AuthSession.fromApi(token: token, profile: profile);
    } on ApiException {
      await _clear();
      return null;
    } catch (_) {
      final saved = await _storage.read(key: _profileKey);
      if (saved == null) return null;
      return AuthSession.fromApi(
        token: token,
        profile: jsonDecode(saved) as Map<String, dynamic>,
      );
    }
  }

  Future<void> signOut() => _clear();

  Future<void> _clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _profileKey);
  }
}
