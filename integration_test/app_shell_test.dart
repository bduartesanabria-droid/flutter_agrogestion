import 'package:agrogestion/app/agrogestion_app.dart';
import 'package:agrogestion/features/auth/data/auth_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/fake_api.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('el agricultor recorre las pestañas principales', (tester) async {
    final api = FakeBackend().client();
    final auth = AuthRepository(
      api: api,
      storage: const FlutterSecureStorage(),
    );
    await auth.signIn(email: 'agricultor@demo.com', password: '1234');

    await tester.pumpWidget(AgroGestionApp(api: api, authRepository: auth));
    await tester.pumpAndSettle();
    expect(find.text('RESUMEN DE HOY'), findsOneWidget);

    await tester.tap(find.text('Producción'));
    await tester.pumpAndSettle();
    expect(find.text('BALANCE OPERATIVO ACTUAL'), findsOneWidget);

    await tester.tap(find.text('Dinero'));
    await tester.pumpAndSettle();
    expect(find.text('DISTRIBUCIÓN DEL GASTO'), findsOneWidget);

    api.close();
  });
}
