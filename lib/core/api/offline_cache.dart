import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class OfflineCache {
  const OfflineCache(this.scope);

  final String scope;

  static const _prefix = 'cache:';

  String _key(String id) => '$_prefix$scope:$id';

  Future<void> save(String id, Object? data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(id), jsonEncode(data));
    } catch (_) {}
  }

  Future<Object?> read(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(id));
      return raw == null ? null : jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys().where((k) => k.startsWith(_prefix))) {
        await prefs.remove(key);
      }
    } catch (_) {}
  }
}
