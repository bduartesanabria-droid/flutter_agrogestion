class AuthSession {
  const AuthSession({
    required this.token,
    required this.userId,
    required this.email,
    required this.name,
    required this.role,
  });

  final String token;
  final String userId;
  final String email;
  final String name;
  final String role;

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
    );
  }
}
