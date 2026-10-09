import 'package:agrogestion/features/auth/data/auth_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_api.dart';

void main() {
  test('sin internet la sesión guardada se recupera sin pedir clave', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final fake = FakeBackend();
    final repo = AuthRepository(
      api: fake.client(),
      storage: const FlutterSecureStorage(),
    );
    final first = await repo.signIn(
      email: 'agricultor@demo.com',
      password: '1234',
    );

    fake.offline = true;
    final restored = await repo.restoreSession();
    expect(restored, isNotNull);
    expect(restored!.email, first.email);
    expect(restored.role, 'agricultor');
  });

  test('sin internet y sin sesión guardada no entra', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final fake = FakeBackend()..offline = true;
    final repo = AuthRepository(
      api: fake.client(),
      storage: const FlutterSecureStorage(),
    );
    expect(await repo.restoreSession(), isNull);
  });

  test('si el servidor rechaza el token se cierra la sesión', () async {
    FlutterSecureStorage.setMockInitialValues({
      'agrogestion_access_token': 'caducado',
    });
    final fake = FakeBackend();
    final repo = AuthRepository(
      api: fake.client(),
      storage: const FlutterSecureStorage(),
    );
    expect(await repo.restoreSession(), isNull);
  });
}
