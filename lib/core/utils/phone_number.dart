/// Normalises Ethiopian mobile numbers to E.164 (`+2519XXXXXXXX` / `+2517XXXXXXXX`).
///
/// Mirrors `App\Support\PhoneNumber` on the backend. Accepts `09…`, `07…`,
/// `9…`, `2519…` and `+2519…`, with spaces or dashes.
String? normalizeEthiopianPhone(String input) {
  var digits = input.replaceAll(RegExp(r'\D'), '');

  if (digits.startsWith('251')) {
    digits = digits.substring(3);
  } else if (digits.startsWith('0')) {
    digits = digits.substring(1);
  }

  if (!RegExp(r'^[79]\d{8}$').hasMatch(digits)) return null;

  return '+251$digits';
}

/// Formats `+251911234567` as `0911 234 567` for display.
String formatEthiopianPhone(String e164) {
  final normalized = normalizeEthiopianPhone(e164);
  if (normalized == null) return e164;
  final local = '0${normalized.substring(4)}';
  return '${local.substring(0, 4)} ${local.substring(4, 7)} ${local.substring(7)}';
}
