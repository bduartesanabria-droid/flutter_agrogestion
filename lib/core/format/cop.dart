/// Formatea un número entero con separador de miles colombiano: 10000 -> 10.000
String formatNumero(int valor) {
  final signo = valor < 0 ? '-' : '';
  final digitos = valor.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digitos.length; i++) {
    if (i > 0 && (digitos.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digitos[i]);
  }
  return '$signo$buffer';
}

/// Formatea montos en pesos colombianos: 2160000 -> $2.160.000
String formatCop(int valor) =>
    valor < 0 ? '-\$${formatNumero(valor.abs())}' : '\$${formatNumero(valor)}';
