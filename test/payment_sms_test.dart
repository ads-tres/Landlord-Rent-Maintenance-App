import 'package:flutter_test/flutter_test.dart';
import 'package:landlord_app/features/leases/domain/lease.dart';
import 'package:landlord_app/features/payments/domain/payment.dart';
import 'package:landlord_app/features/payments/domain/payment_sms.dart';

final today = DateTime(2026, 11, 15);

PaymentSms parse(String text) => parsePaymentSms(text, today: today);

Lease lease(int id, String name, String phone, {int rent = 1000000}) =>
    Lease.fromJson({
      'id': id,
      'unit_id': id,
      'tenant_id': id,
      'start_date': '2026-01-01',
      'end_date': '2027-12-31',
      'monthly_rent': rent,
      'due_day': 1,
      'status': 'active',
      'unit': {'id': id, 'label': 'Room $id', 'property_id': 1},
      'tenant': {'id': id, 'full_name': name, 'phone': phone},
    });

void main() {
  group('reads', () {
    test('a Telebirr message, skipping the balance', () {
      final sms = parse(
        'Dear Abel, You have received ETB 10,000.00 from Almaz Tesfaye(2519****5678) '
        'on 15/11/2026 10:23:45. Your transaction number is CKF1A2B3C4. Your current '
        'E-Money Account balance is ETB 12,345.67. Thank you for using telebirr Ethio telecom',
      );
      expect(sms.amount, 1000000);
      expect(sms.reference, 'CKF1A2B3C4');
      expect(sms.paidAt, DateTime(2026, 11, 15));
      expect(sms.payerName, 'Almaz Tesfaye');
      expect(sms.payerPhone, '2519****5678');
      expect(sms.method, PaymentMethod.telebirr);
      expect(sms.source, PaymentSmsSource.telebirr);
    });

    test('a CBE credit message', () {
      final sms = parse(
        'Dear Abel your Account 1000*****1234 has been Credited with ETB 12,500.50 from '
        'Almaz Tesfaye, on 14/11/2026 at 09:10:11 with Ref No FT26318ABCDE Your Current '
        'Balance is ETB 40,000.00. Thank you for Banking with CBE!',
      );
      expect(sms.amount, 1250050);
      expect(sms.reference, 'FT26318ABCDE');
      expect(sms.paidAt, DateTime(2026, 11, 14));
      expect(sms.payerName, 'Almaz Tesfaye');
      expect(sms.method, PaymentMethod.bank);
      expect(sms.source, PaymentSmsSource.cbe);
    });

    test('a CBE Birr message with the number before the name', () {
      final sms = parse(
        'You have received 2,500.00 Birr from 0911223344 ALMAZ T. on 13/11/2026. '
        'Transaction ID: 8H2K9L1M0N. Balance: 3,000.00 Birr. CBE Birr',
      );
      expect(sms.amount, 250000);
      expect(sms.reference, '8H2K9L1M0N');
      expect(sms.payerPhone, '0911223344');
      expect(sms.payerName, 'ALMAZ T');
      expect(sms.source, PaymentSmsSource.cbeBirr);
      expect(sms.method, PaymentMethod.bank);
    });

    test('another bank with an ISO date and a numeric reference', () {
      final sms = parse(
        'Dear Customer, your account 0132*****001 has been credited with ETB 5,000.00 '
        'on 2026-11-12. Ref: 1234567890. Available balance ETB 9,000.00',
      );
      expect(sms.amount, 500000);
      expect(sms.reference, '1234567890');
      expect(sms.paidAt, DateTime(2026, 11, 12));
      expect(sms.method, PaymentMethod.bank);
    });

    test('an Amharic message with an Ethiopian calendar date', () {
      final sms = parse(
        'ብር 10,000.00 ከ አልማዝ ተስፋዬ (2519****5678) ተቀብለዋል። የግብይት ቁጥርዎ CKF1A2B3C4 ነው። '
        'ቀን 05/03/2019። ቀሪ ሂሳብ ብር 12,000.00 ቴሌብር',
      );
      expect(sms.amount, 1000000);
      expect(sms.reference, 'CKF1A2B3C4');
      expect(sms.payerName, 'አልማዝ ተስፋዬ');
      expect(sms.payerPhone, '2519****5678');
      expect(sms.paidAt, DateTime(2026, 11, 14)); // 5 Hidar 2019
      expect(sms.method, PaymentMethod.telebirr);
    });

    test('month and day written the US way round', () {
      expect(
        parse('Received ETB 100 on 11/14/2026').paidAt,
        DateTime(2026, 11, 14),
      );
      expect(
        parse('Received ETB 100 on 14-Nov-2026').paidAt,
        DateTime(2026, 11, 14),
      );
      expect(
        parse('Received ETB 100 on Nov 13, 2026').paidAt,
        DateTime(2026, 11, 13),
      );
      // Future dates are not trusted.
      expect(parse('Received ETB 100 on 20/11/2026').paidAt, isNull);
    });

    test('nothing useful in an unrelated message', () {
      final sms = parse('Your OTP is 123456. Do not share it.');
      expect(sms.hasAmount, isFalse);
      expect(sms.reference, isNull);
      expect(sms.method, isNull);
    });
  });

  group('matches leases', () {
    final almaz = lease(1, 'Almaz Tesfaye', '+251911235678');
    final abebe = lease(2, 'Abebe Kebede', '+251922000000');
    final almazB = lease(3, 'Almaz Bekele', '+251933000000');

    test('by masked phone and name', () {
      final matches = matchLeasesToSms(
        const PaymentSms(
          amount: 1000000,
          payerName: 'ALMAZ TESFAYE',
          payerPhone: '2519****5678',
        ),
        [abebe, almaz, almazB],
      );
      expect(matches.first.lease.id, 1);
      expect(matches.first.byPhone, isTrue);
      expect(matches.first.score, 1.0);
      expect(isConfidentMatch(matches), isTrue);
    });

    test('by full name without a phone', () {
      final matches = matchLeasesToSms(
        const PaymentSms(payerName: 'Almaz Tesfaye Gebre'),
        [abebe, almaz, almazB],
      );
      expect(matches.first.lease.id, 1);
      expect(isConfidentMatch(matches), isTrue);
    });

    test('a first name alone is not enough to be sure', () {
      final matches = matchLeasesToSms(const PaymentSms(payerName: 'ALMAZ'), [
        abebe,
        almaz,
        almazB,
      ]);
      expect(matches.map((m) => m.lease.id), containsAll([1, 3]));
      expect(isConfidentMatch(matches), isFalse);
    });

    test('phone numbers in different shapes', () {
      expect(smsPhoneMatches('0911235678', '+251911235678'), isTrue);
      expect(smsPhoneMatches('911235678', '+251911235678'), isTrue);
      expect(smsPhoneMatches('****5678', '+251911235678'), isTrue);
      expect(smsPhoneMatches('2519****5679', '+251911235678'), isFalse);
      expect(smsPhoneMatches('**78', '+251911235678'), isFalse);
    });
  });
}
