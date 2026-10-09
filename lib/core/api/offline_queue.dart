import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class QueueStep {
  const QueueStep(this.path, this.body, this.key, {this.bindField});

  final String path;
  final Map<String, dynamic> body;
  final String key;
  final String? bindField;

  QueueStep bound(Map<String, dynamic>? previous) {
    if (bindField == null || previous == null) return this;
    return QueueStep(path, {...body, bindField!: previous['id']}, key);
  }

  Map<String, dynamic> toJson() => {
    'path': path,
    'body': body,
    'key': key,
    'bind': bindField,
  };

  factory QueueStep.fromJson(Map<String, dynamic> json) => QueueStep(
    json['path'] as String,
    Map<String, dynamic>.from(json['body'] as Map),
    json['key'] as String,
    bindField: json['bind'] as String?,
  );
}

class PendingOp {
  const PendingOp(this.id, this.label, this.steps);

  final String id;
  final String label;
  final List<QueueStep> steps;

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'steps': steps.map((s) => s.toJson()).toList(),
  };

  factory PendingOp.fromJson(Map<String, dynamic> json) => PendingOp(
    json['id'] as String,
    json['label'] as String,
    (json['steps'] as List)
        .map((s) => QueueStep.fromJson(Map<String, dynamic>.from(s as Map)))
        .toList(),
  );
}

class OfflineQueue {
  const OfflineQueue(this.scope);

  final String scope;

  String get _key => 'queue:$scope';

  Future<List<PendingOp>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return [];
      return (jsonDecode(raw) as List)
          .map((o) => PendingOp.fromJson(Map<String, dynamic>.from(o as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(List<PendingOp> ops) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(ops.map((o) => o.toJson()).toList()),
    );
  }

  Future<void> add(PendingOp op) async => _save([...await load(), op]);

  Future<void> remove(String id) async =>
      _save((await load()).where((o) => o.id != id).toList());

  Future<void> replaceSteps(String id, List<QueueStep> steps) async => _save([
    for (final o in await load())
      o.id == id ? PendingOp(id, o.label, steps) : o,
  ]);
}
