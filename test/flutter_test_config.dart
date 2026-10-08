import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _load(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    final bytes = await File(file).readAsBytes();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _load('PlusJakartaSans', [
    for (final w in [400, 500, 600, 700, 800])
      'assets/fonts/PlusJakartaSans-$w.ttf',
  ]);
  await _load('JetBrainsMono', [
    for (final w in [500, 600, 700]) 'assets/fonts/JetBrainsMono-$w.ttf',
  ]);
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final icons = File(
      '$root/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
    );
    if (icons.existsSync()) await _load('MaterialIcons', [icons.path]);
  }
  await testMain();
}
