class Permission {
  const Permission({required this.method, required this.route});

  final String method;
  final String route;

  factory Permission.fromJson(Map<String, dynamic> json) => Permission(
    method: (json['metodo'] as String? ?? '').toUpperCase(),
    route: json['ruta'] as String? ?? '',
  );
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.userId,
    required this.email,
    required this.name,
    required this.role,
    this.farmIds = const [],
    this.permissions = const [],
  });

  final String token;
  final String userId;
  final String email;
  final String name;
  final String role;
  final List<String> farmIds;
  final List<Permission> permissions;

  factory AuthSession.fromApi({
    required String token,
    required Map<String, dynamic> profile,
  }) {
    return AuthSession(
      token: token,
      userId: profile['id'] as String? ?? '',
      email: profile['email'] as String? ?? '',
      name: profile['nombre'] as String? ?? 'Usuario',
      role: profile['rol'] as String? ?? 'agricultor',
      farmIds: (profile['fincas'] as List? ?? const [])
          .whereType<String>()
          .toList(),
      permissions: (profile['permisos'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Permission.fromJson)
          .toList(),
    );
  }
}
