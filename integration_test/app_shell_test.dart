import 'package:agrogestion/core/api/api_client.dart';
import 'package:agrogestion/features/auth/data/auth_repository.dart';
import 'package:agrogestion/features/auth/domain/auth_session.dart';
import 'package:agrogestion/features/home/presentation/app_shell.dart';
import 'package:agrogestion/features/farms/data/farm_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('navega por el panel principal y sus modulos', (tester) async {
    final api = ApiClient(baseUrl: 'http://localhost:8000');
    final auth = AuthRepository(
      api: api,
      storage: const FlutterSecureStorage(),
    );
    final session = const AuthSession(
      token: 'frontend-test-token',
      userId: 'frontend-test-user',
      email: 'agricultor@prueba.com',
      name: 'Cristian Agricultor',
      role: 'agricultor',
    );

    await tester.pumpWidget(
      TestApp(
        session: session,
        authRepository: auth,
        farmRepository: FarmRepository(api: api),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Buenos días, Cristian'), findsOneWidget);
    expect(find.text('Resumen de hoy'), findsOneWidget);

    await tester.tap(find.text('Producción'));
    await tester.pumpAndSettle();
    expect(find.text('Siembras en curso'), findsOneWidget);
    expect(find.text('Café · Lote 2'), findsOneWidget);

    await tester.tap(find.text('Dinero'));
    await tester.pumpAndSettle();
    expect(find.text('Movimientos recientes'), findsOneWidget);

    api.close();
  });
}

class TestApp extends StatelessWidget {
  const TestApp({
    required this.session,
    required this.authRepository,
    required this.farmRepository,
    super.key,
  });

  final AuthSession session;
  final AuthRepository authRepository;
  final FarmRepository farmRepository;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: AppShell(
      session: session,
      authRepository: authRepository,
      farmRepository: farmRepository,
      onSignOut: () async {},
    ),
  );
}
