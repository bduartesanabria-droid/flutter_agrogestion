import 'package:agrogestion/app/agrogestion_app.dart';
import 'package:agrogestion/features/auth/data/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_api.dart';

const phone = Size(390, 844);
const smallPhone = Size(320, 640);
const tablet = Size(820, 1180);
const desktop = Size(1280, 800);
const allSizes = [smallPhone, phone, tablet, desktop];

Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
  const Duration(milliseconds: 100),
  EnginePhase.sendSemanticsUpdate,
  const Duration(seconds: 10),
);

Future<FakeBackend> pumpApp(
  WidgetTester tester, {
  String role = 'agricultor',
  Size size = phone,
  FakeBackend? backend,
  double textScale = 1,
}) async {
  await tester.pumpWidget(const SizedBox());
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  FlutterSecureStorage.setMockInitialValues({
    'agrogestion_access_token': 'token-$role',
  });
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final fake = backend ?? FakeBackend();
  final api = fake.client();
  final auth = AuthRepository(api: api, storage: const FlutterSecureStorage());
  await tester.pumpWidget(AgroGestionApp(api: api, authRepository: auth));
  await settle(tester);
  return fake;
}

Future<void> tapText(
  WidgetTester tester,
  String text, {
  bool last = false,
}) async {
  final all = find.text(text);
  final finder = last ? all.last : all.first;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await settle(tester);
}

Future<void> goBack(WidgetTester tester) async {
  await tester.pageBack();
  await settle(tester);
}

void expectNoErrors(WidgetTester tester) {
  final error = tester.takeException();
  expect(error, isNull, reason: '$error');
}

Future<void> pumpLogin(WidgetTester tester, Size size) async {
  FlutterSecureStorage.setMockInitialValues({});
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final api = FakeBackend().client();
  final auth = AuthRepository(api: api, storage: const FlutterSecureStorage());
  await tester.pumpWidget(AgroGestionApp(api: api, authRepository: auth));
  await settle(tester);
}

List<String> verticalTexts() {
  final found = <String>[];
  void visit(RenderObject node) {
    if (node is RenderParagraph) {
      final text = node.text.toPlainText();
      if (text.trim().length >= 6 && node.size.height >= node.size.width * 3) {
        found.add('"$text" ${node.size.width.toStringAsFixed(0)} px');
      }
    }
    node.visitChildren(visit);
  }

  visit(WidgetsBinding.instance.rootElement!.renderObject!);
  return found;
}
