import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landlord_app/core/storage/secure_store.dart';
import 'package:landlord_app/features/auth/data/auth_repository.dart';
import 'package:landlord_app/features/auth/domain/app_user.dart';
import 'package:landlord_app/features/leases/data/leases_repository.dart';
import 'package:landlord_app/features/leases/domain/lease.dart';
import 'package:landlord_app/features/leases/presentation/lease_detail_screen.dart';
import 'package:landlord_app/features/online_rent/data/online_rent_repository.dart';
import 'package:landlord_app/features/online_rent/presentation/online_rent_screen.dart';
import 'package:landlord_app/features/payments/data/payments_repository.dart';
import 'package:landlord_app/features/payments/domain/payment.dart';
import 'package:landlord_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockOnlineRentRepository extends Mock implements OnlineRentRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockLeasesRepository extends Mock implements LeasesRepository {}

class MockPaymentsRepository extends Mock implements PaymentsRepository {}

Widget harness(Widget child, List overrides) => ProviderScope(
  overrides: [
    keyValueStoreProvider.overrideWithValue(
      MemoryKeyValueStore({'locale': 'en', 'auth_token': 't'}),
    ),
    ...overrides,
  ],
  child: MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  ),
);

AppUser user({bool enabled = false}) => AppUser.fromJson({
  'id': 1,
  'phone': '+251911000000',
  'online_rent_available': true,
  'online_rent_enabled': enabled,
});

void main() {
  test('profile carries online rent state', () {
    expect(user(enabled: true).onlineRentEnabled, isTrue);
    expect(user().onlineRentAvailable, isTrue);
    expect(
      AppUser.fromJson({'id': 1, 'phone': '+251911000000'}).onlineRentAvailable,
      isFalse,
    );
  });

  testWidgets(
    'switch stays off until a payout account is active; saving sends the details',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final repo = MockOnlineRentRepository();
      final auth = MockAuthRepository();
      when(() => auth.me()).thenAnswer((_) async => user());
      when(() => repo.payoutAccount()).thenAnswer((_) async => null);
      when(() => repo.banks()).thenAnswer(
        (_) async => const [
          Bank(id: '946', name: 'Commercial Bank of Ethiopia'),
        ],
      );
      when(
        () => repo.savePayoutAccount(
          bankCode: any(named: 'bankCode'),
          bankName: any(named: 'bankName'),
          accountName: any(named: 'accountName'),
          accountNumber: any(named: 'accountNumber'),
        ),
      ).thenAnswer(
        (_) async => const PayoutAccount(
          bankCode: '946',
          accountName: 'Abel',
          accountNumber: '•••6789',
          status: 'active',
        ),
      );

      await tester.pumpWidget(
        harness(const OnlineRentScreen(), [
          onlineRentRepositoryProvider.overrideWithValue(repo),
          authRepositoryProvider.overrideWithValue(auth),
        ]),
      );
      await tester.pumpAndSettle();

      final sw = tester.widget<SwitchListTile>(
        find.byKey(const Key('onlineRentSwitch')),
      );
      expect(sw.onChanged, isNull);

      await tester.tap(find.byKey(const Key('bankDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Commercial Bank of Ethiopia').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('accountNameField')),
        'Abel Kebede',
      );
      await tester.enterText(
        find.byKey(const Key('accountNumberField')),
        '1000123456789',
      );
      await tester.tap(find.byKey(const Key('saveAccountButton')));
      await tester.pumpAndSettle();

      verify(
        () => repo.savePayoutAccount(
          bankCode: '946',
          bankName: 'Commercial Bank of Ethiopia',
          accountName: 'Abel Kebede',
          accountNumber: '1000123456789',
        ),
      ).called(1);
    },
  );

  testWidgets('lease shows the pay link and marks online payments', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final leases = MockLeasesRepository();
    final payments = MockPaymentsRepository();
    when(() => leases.get(7)).thenAnswer(
      (_) async => Lease.fromJson({
        'id': 7,
        'unit_id': 3,
        'tenant_id': 4,
        'start_date': '2026-10-01',
        'end_date': '2028-09-30',
        'monthly_rent': 1000000,
        'deposit': 0,
        'due_day': 1,
        'status': 'active',
        'pay_url': 'https://kiray.et/pay/abcdefghij',
        'unit': {
          'id': 3,
          'label': 'Room 3',
          'property_id': 1,
          'property_name': 'Bole',
        },
        'tenant': {'id': 4, 'full_name': 'Almaz', 'phone': '+251911234567'},
      }),
    );
    when(() => leases.charges(leaseId: 7)).thenAnswer((_) async => []);
    when(() => payments.forLease(7)).thenAnswer(
      (_) async => [
        Payment(
          id: 1,
          receiptNumber: 'R-000001',
          amount: 1000000,
          paidAt: DateTime(2026, 11, 15),
          method: PaymentMethod.chapa,
          source: 'chapa',
          reference: 'APxyz',
        ),
      ],
    );

    await tester.pumpWidget(
      harness(const LeaseDetailScreen(leaseId: 7), [
        leasesRepositoryProvider.overrideWithValue(leases),
        paymentsRepositoryProvider.overrideWithValue(payments),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('payLinkCard')), findsOneWidget);
    expect(find.text('https://kiray.et/pay/abcdefghij'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
  });
}
