import 'package:agrogestion/core/api/api_client.dart';
import 'package:agrogestion/features/auth/data/auth_repository.dart';
import 'package:agrogestion/features/auth/domain/auth_session.dart';
import 'package:agrogestion/features/farms/data/farm_repository.dart';
import 'package:agrogestion/features/home/presentation/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('navega por el panel principal y sus modulos', (tester) async {
    // Ancho móvil: la navegación inferior es la que se usa en CI.
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = ApiClient(baseUrl: 'http://localhost:8000');
    final auth = AuthRepository(
      api: api,
      storage: const FlutterSecureStorage(),
    );
    const session = AuthSession(
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

    // IndexedStack mantiene todas las páginas montadas: las pestañas se buscan
    // dentro de la barra de navegación para no confundirlas con los títulos.
    final barra = find.byType(NavigationBar);
    await tester.tap(
      find.descendant(of: barra, matching: find.text('Producción')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cultivos en seguimiento'), findsOneWidget);
    expect(find.text('Café · Lote 2'), findsOneWidget);

    await tester.tap(find.descendant(of: barra, matching: find.text('Dinero')));
    await tester.pumpAndSettle();
    expect(find.text('Movimientos'), findsOneWidget);

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
