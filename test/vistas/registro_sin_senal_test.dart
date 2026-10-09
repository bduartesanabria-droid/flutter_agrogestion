import 'package:agrogestion/app/app_scope.dart';
import 'package:agrogestion/features/home/presentation/app_shell.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';

void main() {
  for (final size in allSizes) {
    testWidgets(
      'un registro sin señal queda pendiente y se envía en ${size.width.toInt()} px',
      (tester) async {
        final fake = await pumpApp(tester, role: 'admin', size: size);
        final app = tester.element(find.byType(AppShell)).app;
        fake.offline = true;

        await app.money.createExpense(
          'f0000000-0000-4000-8000-000000000001',
          category: 'Transporte',
          amount: 80000,
          date: '2026-10-09',
        );
        await settle(tester);
        expect(find.textContaining('1 registro pendiente'), findsOneWidget);
        expect(find.text('Enviar ahora'), findsOneWidget);
        expectNoErrors(tester);

        fake.offline = false;
        await tester.tap(find.text('Enviar ahora'));
        await settle(tester);
        expect(find.text('Enviar ahora'), findsNothing);
        expect(
          fake.calls.where(
            (c) => c.startsWith('POST') && c.endsWith('/gastos'),
          ),
          isNotEmpty,
        );
        expectNoErrors(tester);
      },
    );
  }
}
