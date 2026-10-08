String _group(String digits) {
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write('.');
    out.write(digits[i]);
  }
  return out.toString();
}

num? _asNum(Object? value) => value is num ? value : num.tryParse('$value');

String formatNumber(Object? value, {int decimals = 0}) {
  final number = _asNum(value);
  if (number == null) return '—';
  final fixed = number.abs().toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final text = decimals > 0
      ? '${_group(parts[0])},${parts[1]}'
      : _group(parts[0]);
  return number < 0 ? '-$text' : text;
}

String formatCop(Object? value) {
  final number = _asNum(value);
  if (number == null) return '—';
  return '\$ ${formatNumber(number.round())}';
}

String formatHa(Object? value) {
  final number = _asNum(value);
  if (number == null) return '—';
  final whole = number == number.roundToDouble();
  return '${formatNumber(number, decimals: whole ? 0 : 1)} ha';
}

const _months = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

DateTime? _asDate(Object? value) =>
    value is DateTime ? value : DateTime.tryParse('$value');

String formatDate(Object? value) {
  final date = _asDate(value);
  if (date == null) return '—';
  return '${date.day} ${_months[date.month - 1]} ${date.year}';
}

String formatDateShort(Object? value) {
  final date = _asDate(value);
  if (date == null) return '—';
  return '${date.day} ${_months[date.month - 1]}';
}

String greeting([DateTime? now]) {
  final hour = (now ?? DateTime.now()).hour;
  if (hour < 12) return 'Buenos días';
  if (hour < 19) return 'Buenas tardes';
  return 'Buenas noches';
}

String capitalize(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

String humanize(String code) => capitalize(code.replaceAll('_', ' '));

String firstName(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+'));
  return parts.first;
}
