import 'package:agrogestion/core/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el dinero usa punto de miles y el signo de pesos', () {
    expect(formatCop(1850000), r'$ 1.850.000');
    expect(formatCop('4248000.00'), r'$ 4.248.000');
    expect(formatCop(-215000), r'$ -215.000');
    expect(formatCop(null), '—');
  });

  test('los números llevan coma decimal', () {
    expect(formatNumber(18.5, decimals: 1), '18,5');
    expect(formatNumber(1234567), '1.234.567');
    expect(formatNumber(0), '0');
  });

  test('las hectáreas omiten el decimal cuando es entero', () {
    expect(formatHa(14), '14 ha');
    expect(formatHa(4.5), '4,5 ha');
  });

  test('las fechas salen en español', () {
    expect(formatDate('2026-10-07'), '7 oct 2026');
    expect(formatDateShort('2026-09-27'), '27 sep');
    expect(formatDate('no es fecha'), '—');
  });

  test('el saludo cambia según la hora', () {
    expect(greeting(DateTime(2026, 1, 1, 8)), 'Buenos días');
    expect(greeting(DateTime(2026, 1, 1, 15)), 'Buenas tardes');
    expect(greeting(DateTime(2026, 1, 1, 21)), 'Buenas noches');
  });

  test('humanize y firstName', () {
    expect(humanize('en_curso'), 'En curso');
    expect(firstName('Hernando Gómez Restrepo'), 'Hernando');
  });
}
