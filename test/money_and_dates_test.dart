import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:landlord_app/core/utils/dates.dart';
import 'package:landlord_app/core/utils/money.dart';
import 'package:landlord_app/features/leases/domain/rent_rules.dart';

void main() {
  setUpAll(() => initializeDateFormatting());

  group('money', () {
    test('formats santim as birr', () {
      expect(formatBirr(1250000), 'Br 12,500');
      expect(formatBirr(1250050), 'Br 12,500.50');
      expect(formatBirr(0), 'Br 0');
      expect(formatBirr(1250000, locale: 'am'), 'ብር 12,500');
    });

    test('parses birr input to santim', () {
      expect(parseBirr('12500'), 1250000);
      expect(parseBirr('12,500.5'), 1250050);
      expect(parseBirr(' 99.99 '), 9999);
      expect(parseBirr(''), isNull);
      expect(parseBirr('12.345'), isNull);
      expect(parseBirr('abc'), isNull);
    });

    test('prefills inputs without trailing zeros', () {
      expect(santimToInput(1250000), '12500');
      expect(santimToInput(1250050), '12500.5');
      expect(santimToInput(1250005), '12500.05');
    });
  });

  group('dates', () {
    test('minimum lease end is start + 2 years - 1 day', () {
      expect(ymd(minimumLeaseEnd(DateTime(2026, 11, 5), 2)), '2028-11-04');
      expect(ymd(minimumLeaseEnd(DateTime(2026, 7, 1), 2)), '2028-06-30');
      expect(ymd(minimumLeaseEnd(DateTime(2028, 2, 29), 2)), '2030-02-27');
    });

    test('formats periods by locale', () {
      expect(formatPeriod('2026-11', 'en'), 'November 2026');
      expect(periodOf(DateTime(2026, 3, 15)), '2026-03');
    });
  });

  group('rent cap', () {
    const rules = RentRules(capPercent: 11.5, minLeaseYears: 2);

    test('allows increases up to the cap', () {
      expect(rules.exceedsCap(1000000, 1115000), isFalse);
      expect(rules.exceedsCap(1000000, 1115001), isTrue);
      expect(rules.exceedsCap(1000000, 900000), isFalse);
      expect(rules.maxAllowedRent(1000000), 1115000);
    });

    test('labels and percentages', () {
      expect(rules.capLabel, '11.5');
      expect(const RentRules(capPercent: 15, minLeaseYears: 2).capLabel, '15');
      expect(RentRules.increasePercent(1000000, 1080000), 8.0);
    });
  });
}
