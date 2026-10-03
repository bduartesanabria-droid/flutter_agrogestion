import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app/agrogestion_app.dart';
import 'core/api/api_client.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/farms/data/farm_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  const storage = FlutterSecureStorage();
  final api = ApiClient();
  final authRepository = AuthRepository(api: api, storage: storage);
  final farmRepository = FarmRepository(api: api);

  runApp(
    AgroGestionApp(
      authRepository: authRepository,
      farmRepository: farmRepository,
    ),
  );
}
