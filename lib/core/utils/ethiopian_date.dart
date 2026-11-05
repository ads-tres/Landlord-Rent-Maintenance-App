/// Ethiopian calendar conversion through the Julian Day Number.
///
/// Mirrors `App\Support\EthiopianDate` on the backend. Ethiopian years have 12 months
/// of 30 days plus Pagume (5 days, 6 in a leap year). Dates are stored in Gregorian;
/// this is for display only.
class EthiopianDate {
  const EthiopianDate(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  static const _epoch = 1723856; // JDN offset of the Amete Mihret era

  static const monthsAm = [
    'መስከረም', 'ጥቅምት', 'ኅዳር', 'ታኅሣሥ', 'ጥር', 'የካቲት', //
    'መጋቢት', 'ሚያዝያ', 'ግንቦት', 'ሰኔ', 'ሐምሌ', 'ነሐሴ', 'ጳጉሜን',
  ];

  static const monthsEn = [
    'Meskerem', 'Tikimt', 'Hidar', 'Tahsas', 'Tir', 'Yekatit', //
    'Megabit', 'Miyazia', 'Ginbot', 'Sene', 'Hamle', 'Nehase', 'Pagume',
  ];

  static String monthName(int month, String locale) =>
      (locale == 'am' ? monthsAm : monthsEn)[month - 1];

  factory EthiopianDate.fromGregorian(DateTime date) {
    final jdn = _gregorianToJdn(date.year, date.month, date.day);
    final r = (jdn - _epoch) % 1461;
    final n = r % 365 + 365 * (r ~/ 1460);
    final year = 4 * ((jdn - _epoch) ~/ 1461) + r ~/ 365 - r ~/ 1460;
    return EthiopianDate(year, n ~/ 30 + 1, n % 30 + 1);
  }

  DateTime toGregorian() {
    final jdn =
        (_epoch + 365) + 365 * (year - 1) + year ~/ 4 + 30 * month + day - 31;
    return _jdnToGregorian(jdn);
  }

  static bool isLeapYear(int year) => year % 4 == 3;

  String format(String locale) => '$day ${monthName(month, locale)} $year';

  @override
  bool operator ==(Object other) =>
      other is EthiopianDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => 'EthiopianDate($year-$month-$day)';

  static int _gregorianToJdn(int y, int m, int d) {
    final a = (14 - m) ~/ 12;
    final yy = y + 4800 - a;
    final mm = m + 12 * a - 3;
    return d +
        (153 * mm + 2) ~/ 5 +
        365 * yy +
        yy ~/ 4 -
        yy ~/ 100 +
        yy ~/ 400 -
        32045;
  }

  static DateTime _jdnToGregorian(int jdn) {
    final a = jdn + 32044;
    final b = (4 * a + 3) ~/ 146097;
    final c = a - 146097 * b ~/ 4;
    final d = (4 * c + 3) ~/ 1461;
    final e = c - 1461 * d ~/ 4;
    final m = (5 * e + 2) ~/ 153;
    final day = e - (153 * m + 2) ~/ 5 + 1;
    final month = m + 3 - 12 * (m ~/ 10);
    final year = 100 * b + d - 4800 + m ~/ 10;
    return DateTime(year, month, day);
  }
}
