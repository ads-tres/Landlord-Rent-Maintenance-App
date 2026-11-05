import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:landlord_app/core/utils/app_dates.dart';
import 'package:landlord_app/core/utils/ethiopian_date.dart';

void main() {
  setUpAll(() => initializeDateFormatting());

  // Same known dates as the backend tests (andegna/calender).
  final known = {
    DateTime(2026, 9, 11): const EthiopianDate(2019, 1, 1),
    DateTime(2027, 1, 7): const EthiopianDate(2019, 4, 29),
    DateTime(2023, 9, 11): const EthiopianDate(2015, 13, 6),
    DateTime(2023, 9, 12): const EthiopianDate(2016, 1, 1),
    DateTime(2026, 7, 8): const EthiopianDate(2018, 11, 1),
    DateTime(2026, 11, 15): const EthiopianDate(2019, 3, 6),
    DateTime(2027, 9, 11): const EthiopianDate(2019, 13, 6),
  };

  test('converts known dates both ways', () {
    known.forEach((gregorian, ethiopian) {
      expect(
        EthiopianDate.fromGregorian(gregorian),
        ethiopian,
        reason: '$gregorian',
      );
      expect(ethiopian.toGregorian(), gregorian, reason: '$ethiopian');
    });
  });

  test('round-trips every day for ten years', () {
    for (
      var d = DateTime(2020, 1, 1);
      d.isBefore(DateTime(2030, 1, 1));
      d = d.add(const Duration(days: 1))
    ) {
      final day = DateTime(d.year, d.month, d.day);
      expect(EthiopianDate.fromGregorian(day).toGregorian(), day);
    }
  });

  test('formats dates and periods in both calendars', () {
    const am = AppDates(locale: 'am', ethiopian: true);
    const en = AppDates(locale: 'en', ethiopian: true);
    const greg = AppDates(locale: 'en', ethiopian: false);

    expect(am.date(DateTime(2026, 11, 15)), '6 ኅዳር 2019');
    expect(en.date(DateTime(2026, 11, 15)), '6 Hidar 2019');
    expect(greg.date(DateTime(2026, 11, 15)), 'Nov 15, 2026');

    expect(am.period('2026-11'), 'ጥቅምት–ኅዳር 2019');
    expect(en.period('2026-09'), 'Nehase 2018–Meskerem 2019');
    expect(greg.period('2026-11'), 'November 2026');
  });
}
