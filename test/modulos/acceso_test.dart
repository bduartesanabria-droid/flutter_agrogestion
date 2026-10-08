import 'package:agrogestion/core/access/access.dart';
import 'package:agrogestion/features/auth/domain/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';

Access _access(String role, List<(String, String)> permissions) => Access(
  AuthSession(
    token: 't',
    userId: 'u',
    email: '$role@demo.com',
    name: role,
    role: role,
    permissions: [
      for (final p in permissions) Permission(method: p.$1, route: p.$2),
    ],
  ),
);

void main() {
  const production = [('GET', '/siembras'), ('POST', '/siembras')];

  test('el administrador gestiona todo', () {
    final access = _access('admin', [
      ...production,
      ('GET', '/cultivos'),
      ('POST', '/usuarios'),
    ]);
    expect(access.seesProduction, isTrue);
    expect(access.managesProduction, isTrue);
    expect(access.managesUsers, isTrue);
    expect(access.seesProfit, isTrue);
    expect(access.cancelsMoney, isTrue);
  });

  test('el agricultor registra pero no ve utilidad ni anula', () {
    final access = _access('agricultor', [...production, ('GET', '/cultivos')]);
    expect(access.registersFieldWork, isTrue);
    expect(access.registersMoney, isTrue);
    expect(access.seesProfit, isFalse);
    expect(access.cancelsMoney, isFalse);
    expect(access.managesUsers, isFalse);
  });

  test('el contador lee producción y lleva el dinero', () {
    final access = _access('contador', [('GET', '/siembras')]);
    expect(access.seesProduction, isTrue);
    expect(access.managesProduction, isFalse);
    expect(access.registersFieldWork, isFalse);
    expect(access.seesProfit, isTrue);
    expect(access.paysWorkers, isTrue);
    expect(access.canQuickRegister, isTrue);
  });

  test('el experto no ve dinero ni producción', () {
    final access = _access('experto', const []);
    expect(access.seesProduction, isFalse);
    expect(access.seesMoney, isFalse);
    expect(access.seesWorkers, isFalse);
    expect(access.canQuickRegister, isFalse);
    expect(access.roleLabel, 'Experto');
  });

  test('los permisos del servidor mandan sobre el rol', () {
    final access = _access('agricultor', const []);
    expect(access.seesProduction, isFalse);
    expect(access.seesRisks, isFalse);
  });
}
