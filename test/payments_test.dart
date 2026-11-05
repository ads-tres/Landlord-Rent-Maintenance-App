import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landlord_app/core/api/api_client.dart';
import 'package:landlord_app/core/storage/secure_store.dart';
import 'package:landlord_app/features/home/dashboard_screen.dart';
import 'package:landlord_app/features/leases/data/leases_repository.dart';
import 'package:landlord_app/features/leases/domain/lease.dart';
import 'package:landlord_app/features/payments/data/payments_repository.dart';
import 'package:landlord_app/features/payments/domain/dashboard_summary.dart';
import 'package:landlord_app/features/payments/domain/payment.dart';
import 'package:landlord_app/features/payments/presentation/log_payment_screen.dart';
import 'package:landlord_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockLeasesRepository extends Mock implements LeasesRepository {}

class MockPaymentsRepository extends Mock implements PaymentsRepository {}

final lease = Lease(
  id: 7,
  unitId: 3,
  tenantId: 4,
  startDate: DateTime(2026, 9, 1),
  endDate: DateTime(2028, 8, 31),
  monthlyRent: 1000000,
  deposit: 0,
  dueDay: 1,
  status: LeaseStatus.active,
  unitLabel: 'Room 3',
  propertyName: 'Bole Compound',
  tenantName: 'Almaz Tesfaye',
  balance: const LeaseBalance(
    charged: 3000000,
    paid: 500000,
    outstanding: 2500000,
  ),
);

final savedPayment = Payment(
  id: 1,
  receiptNumber: 'R-000001',
  leaseId: 7,
  amount: 2500000,
  paidAt: DateTime(2026, 11, 15),
  method: PaymentMethod.telebirr,
  reference: 'TB123',
  receiptUrl: 'https://kiray.et/r/abcdefghij',
  allocations: const [
    PaymentAllocation(period: '2026-09', amount: 500000),
    PaymentAllocation(period: '2026-10', amount: 1000000),
    PaymentAllocation(period: '2026-11', amount: 1000000),
  ],
  smsStatus: 'sent',
);

Widget harness(
  Widget child, {
  MockLeasesRepository? leases,
  MockPaymentsRepository? payments,
}) => ProviderScope(
  overrides: [
    keyValueStoreProvider.overrideWithValue(
      MemoryKeyValueStore({'locale': 'en'}),
    ),
    if (leases != null) leasesRepositoryProvider.overrideWithValue(leases),
    if (payments != null)
      paymentsRepositoryProvider.overrideWithValue(payments),
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

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(PaymentMethod.cash);
  });

  test('payment create sends santim, method and SMS flag', () async {
    final dio = MockDio();
    when(() => dio.post('/payments', data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/payments'),
        statusCode: 201,
        data: {
          'data': {
            'id': 1,
            'receipt_number': 'R-000001',
            'lease_id': 7,
            'amount': 1000000,
            'paid_at': '2026-11-15',
            'method': 'cash',
            'source': 'manual',
            'allocations': [
              {'charge_id': 1, 'period': '2026-09', 'amount': 1000000},
            ],
          },
        },
      ),
    );

    final payment = await PaymentsRepository(ApiClient(dio)).create(
      leaseId: 7,
      amount: 1000000,
      paidAt: DateTime(2026, 11, 15),
      method: PaymentMethod.cash,
      sendSms: false,
    );

    expect(payment.allocations.single.period, '2026-09');
    final sent =
        verify(() => dio.post('/payments', data: captureAny(named: 'data')))
                .captured
                .single
            as Map;
    expect(sent['method'], 'cash');
    expect(sent['amount'], 1000000);
    expect(sent['send_sms'], isFalse);
    expect(sent.containsKey('reference'), isFalse);
  });

  testWidgets(
    'log payment: prefilled balance, reference rules and saved receipt',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final leases = MockLeasesRepository();
      final payments = MockPaymentsRepository();
      when(() => leases.get(7)).thenAnswer((_) async => lease);
      when(
        () => payments.create(
          leaseId: any(named: 'leaseId'),
          amount: any(named: 'amount'),
          paidAt: any(named: 'paidAt'),
          method: any(named: 'method'),
          reference: any(named: 'reference'),
          notes: any(named: 'notes'),
          sendSms: any(named: 'sendSms'),
          clientRef: any(named: 'clientRef'),
        ),
      ).thenAnswer((_) async => savedPayment);

      await tester.pumpWidget(
        harness(
          const LogPaymentScreen(leaseId: 7),
          leases: leases,
          payments: payments,
        ),
      );
      await tester.pumpAndSettle();

      // Amount starts at the outstanding balance.
      expect(find.widgetWithText(TextFormField, '25000'), findsOneWidget);

      // Quick chip sets two months of rent.
      await tester.tap(find.text('2 months'));
      await tester.pump();
      expect(find.widgetWithText(TextFormField, '20000'), findsOneWidget);

      // Telebirr needs a reference.
      await tester.tap(find.byKey(const Key('savePaymentButton')));
      await tester.pumpAndSettle();
      expect(find.text('Required'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('referenceField')), 'TB123');
      await tester.tap(find.text('Balance Br 25,000'));
      await tester.tap(find.byKey(const Key('savePaymentButton')));
      await tester.pumpAndSettle();

      verify(
        () => payments.create(
          leaseId: 7,
          amount: 2500000,
          paidAt: any(named: 'paidAt'),
          method: PaymentMethod.telebirr,
          reference: 'TB123',
          notes: '',
          sendSms: true,
          clientRef: any(named: 'clientRef'),
        ),
      ).called(1);

      expect(find.text('Payment saved'), findsOneWidget);
      expect(find.text('Receipt R-000001'), findsOneWidget);
      expect(
        find.text(
          'Covers Nehase 2018–Meskerem 2019, Meskerem–Tikimt 2019, Tikimt–Hidar 2019',
        ),
        findsOneWidget,
      );
      expect(find.text('Share receipt link'), findsOneWidget);
    },
  );

  testWidgets('cash payments hide the reference field', (tester) async {
    final leases = MockLeasesRepository();
    when(() => leases.get(7)).thenAnswer((_) async => lease);

    await tester.pumpWidget(
      harness(const LogPaymentScreen(leaseId: 7), leases: leases),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('referenceField')), findsOneWidget);
    await tester.tap(find.text('Cash'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('referenceField')), findsNothing);
  });

  testWidgets('dashboard shows money and counts', (tester) async {
    final payments = MockPaymentsRepository();
    when(() => payments.dashboard()).thenAnswer(
      (_) async => const DashboardSummary(
        collectedThisMonth: 4500000,
        dueThisMonth: 6000000,
        outstanding: 1500000,
        lateTenants: 2,
        openRepairs: 1,
        leasesEndingSoon: 0,
        properties: 1,
        units: 6,
        vacantUnits: 1,
      ),
    );

    await tester.pumpWidget(
      harness(const DashboardScreen(), payments: payments),
    );
    await tester.pumpAndSettle();

    expect(find.text('Br 45,000'), findsOneWidget);
    expect(find.text('Due this month: Br 60,000'), findsOneWidget);
    expect(find.text('Br 15,000'), findsOneWidget);
    expect(find.text('Late tenants'), findsOneWidget);
  });
}
