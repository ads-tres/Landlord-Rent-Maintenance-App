import 'package:flutter_test/flutter_test.dart';
import 'package:landlord_app/core/utils/phone_number.dart';

void main() {
  group('normalizeEthiopianPhone', () {
    test('accepts common Ethiopian formats', () {
      expect(normalizeEthiopianPhone('0911234567'), '+251911234567');
      expect(normalizeEthiopianPhone('0911 234 567'), '+251911234567');
      expect(normalizeEthiopianPhone('911234567'), '+251911234567');
      expect(normalizeEthiopianPhone('+251-911-234-567'), '+251911234567');
      expect(normalizeEthiopianPhone('0711234567'), '+251711234567');
    });

    test('rejects invalid numbers', () {
      for (final input in [
        '',
        '12345',
        '0111234567',
        '+1 202 555 0100',
        '09112345678',
      ]) {
        expect(normalizeEthiopianPhone(input), isNull, reason: input);
      }
    });
  });

  test('formatEthiopianPhone shows the local format', () {
    expect(formatEthiopianPhone('+251911234567'), '0911 234 567');
  });
}
