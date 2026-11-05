import 'package:intl/intl.dart';

/// Money is handled as integers in santim (1 birr = 100 santim), like the API.

/// `1250000` → `Br 12,500` (or `ብር 12,500` in Amharic); cents are shown only when present.
String formatBirr(int santim, {String locale = 'en'}) {
  final prefix = locale == 'am' ? 'ብር' : 'Br';
  final whole = santim % 100 == 0;
  final format = NumberFormat(whole ? '#,##0' : '#,##0.00', 'en');
  final sign = santim < 0 ? '-' : '';
  return '$sign$prefix ${format.format(santim.abs() / 100)}';
}

/// `"12,500.50"` → `1250050`. Returns null for empty or invalid input.
int? parseBirr(String input) {
  final cleaned = input.replaceAll(RegExp(r'[,\s]'), '');
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(cleaned)) return null;
  final parts = cleaned.split('.');
  final birr = int.parse(parts[0]);
  final cents = parts.length > 1 ? int.parse(parts[1].padRight(2, '0')) : 0;
  return birr * 100 + cents;
}

/// `1250050` → `"12500.5"` for prefilling a text field.
String santimToInput(int santim) {
  final birr = santim ~/ 100;
  final cents = santim % 100;
  if (cents == 0) return '$birr';
  return '$birr.${cents.toString().padLeft(2, '0')}'.replaceFirst(
    RegExp(r'0$'),
    '',
  );
}
