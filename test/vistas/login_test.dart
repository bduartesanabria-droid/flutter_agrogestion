import 'package:agrogestion/core/api/api_client.dart';
import 'package:agrogestion/features/auth/data/auth_repository.dart';
import 'package:agrogestion/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows AgroGestion sign in form', (tester) async {
    await tester.pumpWidget(_testApp());

    expect(find.text('AgroGestión'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.byKey(const Key('login_email')), findsOneWidget);
    expect(find.byKey(const Key('login_password')), findsOneWidget);
    expect(find.byKey(const Key('login_submit')), findsOneWidget);
  });

  testWidgets('validates required and malformed credentials locally', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.ensureVisible(find.byKey(const Key('login_submit')));
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();
    expect(find.text('Escriba un correo válido.'), findsOneWidget);
    expect(find.text('Escriba su contraseña.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('login_email')),
      'no-es-correo',
    );
    await tester.enterText(find.byKey(const Key('login_password')), 'secreto');
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();
    expect(find.text('Escriba un correo válido.'), findsOneWidget);
  });

  testWidgets('can toggle password visibility', (tester) async {
    await tester.pumpWidget(_testApp());
    expect(find.byTooltip('Mostrar contraseña'), findsOneWidget);

    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
  });
}

Widget _testApp() {
  final repository = AuthRepository(
    api: ApiClient(baseUrl: 'http://localhost:8000'),
    storage: const FlutterSecureStorage(),
  );
  return MaterialApp(
    home: LoginScreen(authRepository: repository, onSignedIn: (_) {}),
  );
}
