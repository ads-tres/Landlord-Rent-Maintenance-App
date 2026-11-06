import '../../../core/utils/ethiopian_date.dart';
import '../../../core/utils/money.dart';
import '../../leases/domain/lease.dart';
import 'payment.dart';

/// Who sent the confirmation message.
enum PaymentSmsSource { telebirr, cbe, cbeBirr, bank, unknown }

/// What a payment confirmation SMS (Telebirr, CBE, CBE Birr or another bank) says.
///
/// Read on the phone so it also works offline. Formats differ between providers and change
/// over time, so every field is optional and the landlord checks the form before saving.
class PaymentSms {
  const PaymentSms({
    this.amount,
    this.reference,
    this.paidAt,
    this.method,
    this.payerName,
    this.payerPhone,
    this.source = PaymentSmsSource.unknown,
  });

  /// Santim.
  final int? amount;
  final String? reference;
  final DateTime? paidAt;
  final PaymentMethod? method;
  final String? payerName;

  /// Digits as shown in the SMS, with `*` where it hides them (e.g. `2519****5678`).
  final String? payerPhone;
  final PaymentSmsSource source;

  bool get hasAmount => amount != null;
  bool get hasPayer => payerName != null || payerPhone != null;
}

const _money = r'([0-9][0-9,]*(?:\.[0-9]{1,2})?)';
final _amountBefore = RegExp(
  r'(?:ETB|Birr|Br\.?|ብር)\s*' + _money,
  caseSensitive: false,
);
final _amountAfter = RegExp(
  _money + r'\s*(?:ETB|Birr|ብር|Br\b)',
  caseSensitive: false,
);

/// Words just before an amount that mean it is not the money received.
final _notReceived = RegExp(
  r'balance|bal[\s.:]|ቀሪ|fee|charge|vat|commission|service',
  caseSensitive: false,
);

final _referencePatterns = [
  RegExp(
    r'transaction\s*(?:number|no\.?|id|ref(?:erence)?)\s*(?:is|:|#)?\s*([A-Z0-9]{6,24})',
    caseSensitive: false,
  ),
  RegExp(
    r'\bref(?:erence)?\.?\s*(?:no\.?|number|id)?\s*[:#.]?\s*([A-Z0-9]{6,24})',
    caseSensitive: false,
  ),
  RegExp(
    r'\b(?:txn|trx|tx)\s*(?:id|no\.?)?\s*[:#]?\s*([A-Z0-9]{6,24})',
    caseSensitive: false,
  ),
  RegExp(
    r'(?:የግብይት\s*ቁጥር(?:ዎ)?|የግብይት\s*መለያ|ማጣቀሻ(?:\s*ቁጥር)?)\s*[:፦]?\s*([A-Z0-9]{6,24})',
    caseSensitive: false,
  ),
  RegExp(r'\b(FT[0-9A-Z]{8,16})\b'),
];

/// Last resort: an uppercase code mixing letters and digits, like most transaction ids.
final _codeLike = RegExp(r'\b([A-Z0-9]{8,20})\b');

final _dayMonthYear = RegExp(
  r'\b(\d{1,2})[/.\-](\d{1,2})[/.\-](\d{4}|\d{2})\b',
);
final _yearMonthDay = RegExp(r'\b(\d{4})[/.\-](\d{1,2})[/.\-](\d{1,2})\b');
const _monthNames = 'jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec';
final _dayMonthName = RegExp(
  r'\b(\d{1,2})[\s\-]+(' + _monthNames + r')[a-z]*\.?[\s\-,]+(\d{4})\b',
  caseSensitive: false,
);
final _monthNameDay = RegExp(
  r'\b(' + _monthNames + r')[a-z]*\.?\s+(\d{1,2}),?\s+(\d{4})\b',
  caseSensitive: false,
);

final _payerPatterns = <(RegExp, int?, int?)>[
  // ከ አልማዝ ተስፋዬ (2519****5678)
  (RegExp(r'ከ\s*([^\(\)\d]{2,60}?)\s*\(\s*(\+?[0-9*xX ]{6,16})\s*\)'), 1, 2),
  // from ALMAZ TESFAYE(2519****5678)
  (
    RegExp(
      r"from\s+([A-Za-z][A-Za-z .'\-]{1,60}?)\s*\(\s*(\+?[0-9*xX ]{6,16})\s*\)",
      caseSensitive: false,
    ),
    1,
    2,
  ),
  // from 0911223344 ALMAZ T.
  (
    RegExp(
      r"from\s+(\+?[0-9*xX]{9,13})\s*[-,]?\s*([A-Za-z][A-Za-z .'\-]{1,60}?)(?=\s*[.,]|\s+on\b|\s+with\b|\s+to\b|$)",
      caseSensitive: false,
    ),
    2,
    1,
  ),
  // from Almaz Tesfaye, on …  /  by ALMAZ TESFAYE on …
  (
    RegExp(
      r"\b(?:from|by)\s+([A-Za-z][A-Za-z .'\-]{1,60}?)(?=\s*[,.(]|\s+on\b|\s+with\b|\s+to\b|\s+at\b|\s+for\b|$)",
      caseSensitive: false,
    ),
    1,
    null,
  ),
  // from 0911223344
  (RegExp(r'\bfrom\s+(\+?[0-9*xX]{9,13})\b', caseSensitive: false), null, 1),
];

const _notNames = {'your account', 'account', 'you', 'telebirr', 'cbe birr'};

/// Reads a payment confirmation SMS. [today] is for tests.
PaymentSms parsePaymentSms(String text, {DateTime? today}) {
  final now = today ?? DateTime.now();
  final (source, method) = _source(text);
  final reference = _reference(text);
  final payer = _payer(text);
  return PaymentSms(
    amount: _amount(text),
    reference: reference,
    paidAt: _date(text, DateTime(now.year, now.month, now.day)),
    method: method,
    payerName: payer.$1,
    payerPhone: payer.$2,
    source:
        reference != null &&
            reference.startsWith('FT') &&
            source == PaymentSmsSource.bank
        ? PaymentSmsSource.cbe
        : source,
  );
}

(PaymentSmsSource, PaymentMethod?) _source(String text) {
  final t = text.toLowerCase();
  if (t.contains('telebirr') ||
      t.contains('tele birr') ||
      t.contains('e-money') ||
      text.contains('ቴሌብር')) {
    return (PaymentSmsSource.telebirr, PaymentMethod.telebirr);
  }
  if (t.contains('cbe birr') ||
      t.contains('cbebirr') ||
      t.contains('cbe-birr')) {
    return (PaymentSmsSource.cbeBirr, PaymentMethod.bank);
  }
  if (t.contains('cbe') || t.contains('commercial bank')) {
    return (PaymentSmsSource.cbe, PaymentMethod.bank);
  }
  if (t.contains('bank') ||
      t.contains('credited') ||
      t.contains('account') ||
      text.contains('ባንክ')) {
    return (PaymentSmsSource.bank, PaymentMethod.bank);
  }
  return (PaymentSmsSource.unknown, null);
}

int? _amount(String text) {
  final found = <(int, String)>[
    for (final m in _amountBefore.allMatches(text)) (m.start, m.group(1)!),
    for (final m in _amountAfter.allMatches(text)) (m.start, m.group(1)!),
  ]..sort((a, b) => a.$1.compareTo(b.$1));

  int? first;
  for (final (start, value) in found) {
    final santim = parseBirr(value);
    if (santim == null || santim <= 0) continue;
    first ??= santim;
    final before = text.substring(start < 40 ? 0 : start - 40, start);
    if (!_notReceived.hasMatch(before)) return santim;
  }
  return first;
}

bool _looksLikeReference(String s) =>
    s.length >= 6 && s.length <= 24 && RegExp(r'\d').hasMatch(s);

String? _reference(String text) {
  for (final pattern in _referencePatterns) {
    for (final m in pattern.allMatches(text)) {
      final ref = m.group(1)!.toUpperCase();
      if (_looksLikeReference(ref)) return ref;
    }
  }
  for (final m in _codeLike.allMatches(text)) {
    final ref = m.group(1)!;
    final letters = RegExp(r'[A-Z]').allMatches(ref).length;
    final digits = RegExp(r'\d').allMatches(ref).length;
    if (letters >= 2 && digits >= 2) return ref;
  }
  return null;
}

DateTime? _date(String text, DateTime today) {
  final candidates = <(int, int, int)>[]; // year, month, day
  for (final m in _yearMonthDay.allMatches(text)) {
    candidates.add((int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!)));
  }
  for (final m in _dayMonthYear.allMatches(text)) {
    var year = int.parse(m[3]!);
    if (year < 100) year += 2000;
    candidates.add((year, int.parse(m[2]!), int.parse(m[1]!)));
  }
  for (final m in _dayMonthName.allMatches(text)) {
    candidates.add((int.parse(m[3]!), _month(m[2]!), int.parse(m[1]!)));
  }
  for (final m in _monthNameDay.allMatches(text)) {
    candidates.add((int.parse(m[3]!), _month(m[1]!), int.parse(m[2]!)));
  }

  for (final (year, month, day) in candidates) {
    final date =
        _resolve(year, month, day, today) ??
        (day <= 12
            ? _resolve(year, day, month, today)
            : null); // month/day the US way round
    if (date != null) return date;
  }
  return null;
}

int _month(String name) =>
    _monthNames.split('|').indexOf(name.toLowerCase().substring(0, 3)) + 1;

/// A real date that isn't in the future; years far in the past are Ethiopian calendar years.
DateTime? _resolve(int year, int month, int day, DateTime today) {
  DateTime? date;
  if (year >= 1990 && year <= today.year - 6) {
    if (month >= 1 && month <= 13 && day >= 1 && day <= 30) {
      date = EthiopianDate(year, month, day).toGregorian();
    }
  } else if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
    final d = DateTime(year, month, day);
    if (d.month == month && d.day == day) date = d;
  }
  if (date == null || date.isAfter(today)) return null;
  return date;
}

(String?, String?) _payer(String text) {
  for (final (pattern, nameGroup, phoneGroup) in _payerPatterns) {
    final m = pattern.firstMatch(text);
    if (m == null) continue;
    final name = nameGroup == null ? null : _cleanName(m.group(nameGroup)!);
    final phone = phoneGroup == null
        ? null
        : m
              .group(phoneGroup)!
              .replaceAll(RegExp(r'[\s+]'), '')
              .replaceAll(RegExp('[xX]'), '*');
    if (name == null && phone == null) continue;
    return (name, phone);
  }
  return (null, null);
}

String? _cleanName(String raw) {
  final name = raw
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .replaceAll(RegExp(r"[\s.,'\-]+$"), '');
  if (name.length < 2 || _notNames.contains(name.toLowerCase())) return null;
  return name;
}

/// A lease the payment probably belongs to, with how sure we are (0–1).
class LeaseMatch {
  const LeaseMatch(
    this.lease,
    this.score, {
    this.byPhone = false,
    this.byName = false,
  });

  final Lease lease;
  final double score;
  final bool byPhone;
  final bool byName;
}

/// Ranks [leases] by how well the SMS sender matches the tenant (phone, then name, then amount).
List<LeaseMatch> matchLeasesToSms(PaymentSms sms, List<Lease> leases) {
  final matches = <LeaseMatch>[];
  for (final lease in leases) {
    final phone =
        sms.payerPhone != null &&
        lease.tenantPhone != null &&
        smsPhoneMatches(sms.payerPhone!, lease.tenantPhone!);
    final name = sms.payerName == null || lease.tenantName == null
        ? 0.0
        : _nameScore(sms.payerName!, lease.tenantName!);
    var score = phone ? 0.9 : name;
    if (phone && name > 0) score += 0.1;
    if (score > 0 && sms.amount != null && sms.amount == lease.monthlyRent) {
      score += 0.05;
    }
    if (score >= 0.4) {
      matches.add(
        LeaseMatch(
          lease,
          score > 1 ? 1 : score,
          byPhone: phone,
          byName: name > 0,
        ),
      );
    }
  }
  return matches..sort((a, b) => b.score.compareTo(a.score));
}

/// True when the top match is clearly the one: strong, and well ahead of the next.
bool isConfidentMatch(List<LeaseMatch> matches) =>
    matches.isNotEmpty &&
    matches.first.score >= 0.85 &&
    (matches.length == 1 || matches.first.score - matches[1].score >= 0.2);

/// Compares a possibly masked SMS number (`2519****5678`, `0911223344`) with an E.164 number.
bool smsPhoneMatches(String smsPhone, String tenantPhone) {
  var p = smsPhone.replaceAll(RegExp(r'[^0-9*]'), '');
  final t = tenantPhone.replaceAll(RegExp(r'\D'), '');
  if (p.startsWith('0')) {
    p = '251${p.substring(1)}';
  } else if (p.length == 9 && (p.startsWith('9') || p.startsWith('7'))) {
    p = '251$p';
  }
  if (p.replaceAll('*', '').length < 4) return false;
  if (p.length == t.length) {
    for (var i = 0; i < p.length; i++) {
      if (p[i] != '*' && p[i] != t[i]) return false;
    }
    return true;
  }
  final tail = RegExp(r'(\d{4,})$').firstMatch(p)?.group(1);
  return tail != null && t.endsWith(tail);
}

List<String> _nameTokens(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-zሀ-፿ ]'), ' ')
    .split(RegExp(r'\s+'))
    .where((t) => t.length >= 2)
    .toList();

double _nameScore(String smsName, String tenantName) {
  final sms = _nameTokens(smsName).toSet();
  final tenant = _nameTokens(tenantName);
  if (sms.isEmpty || tenant.isEmpty) return 0;
  final matched = tenant.where(sms.contains).length;
  if (matched >= 2) return 0.85;
  if (matched == 1 && sms.contains(tenant.first)) return 0.45;
  return 0;
}
