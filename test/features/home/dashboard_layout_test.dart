import 'package:agrogestion/core/api/api_client.dart';
import 'package:agrogestion/features/auth/data/auth_repository.dart';
import 'package:agrogestion/features/auth/domain/auth_session.dart';
import 'package:agrogestion/features/farms/data/farm_repository.dart';
import 'package:agrogestion/features/home/presentation/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Flutter falla la prueba ante cualquier RenderFlex desbordado.
  for (final tamano in [const Size(800, 600), const Size(1280, 800)]) {
    testWidgets(
      'el panel principal no desborda en ${tamano.width.toInt()}x${tamano.height.toInt()}',
      (tester) async {
        tester.view.physicalSize = tamano;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final api = ApiClient(baseUrl: 'http://localhost:8000');
        await tester.pumpWidget(
          MaterialApp(
            home: AppShell(
              session: const AuthSession(
                token: 't',
                userId: 'u',
                email: 'agricultor@prueba.com',
                name: 'Cristian Agricultor',
                role: 'agricultor',
              ),
              authRepository: AuthRepository(
                api: api,
                storage: const FlutterSecureStorage(),
              ),
              farmRepository: FarmRepository(api: api),
              onSignOut: () async {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Resumen de hoy'), findsOneWidget);
        api.close();
      },
    );
  }
}
