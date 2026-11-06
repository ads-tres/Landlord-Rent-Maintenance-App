import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landlord_app/core/api/api_client.dart';
import 'package:landlord_app/core/storage/secure_store.dart';
import 'package:landlord_app/features/leases/data/leases_repository.dart';
import 'package:landlord_app/features/leases/domain/charge.dart';
import 'package:landlord_app/features/leases/domain/lease.dart';
import 'package:landlord_app/features/leases/domain/rent_rules.dart';
import 'package:landlord_app/features/leases/presentation/lease_detail_screen.dart';
import 'package:landlord_app/features/rent/presentation/rent_screen.dart';
import 'package:landlord_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockLeasesRepository extends Mock implements LeasesRepository {}

final leaseJson = {
  'id': 7,
  'unit_id': 3,
  'tenant_id': 4,
  'start_date': '2026-09-05',
  'end_date': '2028-09-04',
  'terminated_on': null,
  'monthly_rent': 1000000,
  'deposit': 2000000,
  'due_day': 5,
  'due_calendar': 'gregorian',
  'condition_notes': 'Good',
  'registered_at': null,
  'status': 'active',
  'days_until_end': 600,
  'unit': {
    'id': 3,
    'label': 'Room 3',
    'property_id': 1,
    'property_name': 'Bole Compound',
  },
  'tenant': {'id': 4, 'full_name': 'Almaz Tesfaye', 'phone': '+251911234567'},
  'directive_check': {
    'complete': false,
    'missing': ['tenant_address'],
  },
  'balance': {'charged': 3000000, 'paid': 1000000, 'outstanding': 2000000},
  'rent_changes': [],
};

Charge charge(
  int id,
  String status, {
  int paid = 0,
  String period = '2026-11',
}) => Charge(
  id: id,
  leaseId: 7,
  period: period,
  amountDue: 1000000,
  amountPaid: paid,
  balance: 1000000 - paid,
  dueDate: DateTime(2026, 11, 5),
  status: ChargeStatus.parse(status),
  daysLate: status == 'late' ? 10 : 0,
  tenantName: 'Tenant $id',
  unitLabel: 'Room $id',
  propertyName: 'Bole Compound',
);

Widget harness(Widget child, MockLeasesRepository repo) => ProviderScope(
  overrides: [
    keyValueStoreProvider.overrideWithValue(
      MemoryKeyValueStore({'locale': 'en'}),
    ),
    leasesRepositoryProvider.overrideWithValue(repo),
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
  setUpAll(() => registerFallbackValue(DateTime(2026)));

  test('lease JSON is parsed with balance and directive check', () async {
    final dio = MockDio();
    when(
      () =>
          dio.get('/leases/7', queryParameters: any(named: 'queryParameters')),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/leases/7'),
        data: {'data': leaseJson},
      ),
    );

    final lease = await LeasesRepository(ApiClient(dio)).get(7);

    expect(lease.status, LeaseStatus.active);
    expect(lease.tenantName, 'Almaz Tesfaye');
    expect(lease.missingFields, ['tenant_address']);
    expect(lease.balance!.outstanding, 2000000);
  });

  test('creating a lease sends dates and santim amounts', () async {
    final dio = MockDio();
    when(() => dio.post('/leases', data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/leases'),
        data: {'data': leaseJson},
        statusCode: 201,
      ),
    );

    await LeasesRepository(ApiClient(dio)).create(
      unitId: 3,
      tenantId: 4,
      startDate: DateTime(2026, 9, 5),
      endDate: DateTime(2028, 9, 4),
      monthlyRent: 1000000,
      deposit: 0,
      dueDay: 5,
      conditionNotes: 'Good',
    );

    final sent =
        verify(() => dio.post('/leases', data: captureAny(named: 'data')))
                .captured
                .single
            as Map;
    expect(sent['start_date'], '2026-09-05');
    expect(sent['end_date'], '2028-09-04');
    expect(sent['monthly_rent'], 1000000);
    expect(sent.containsKey('registered_at'), isFalse);
  });

  testWidgets('rent screen shows month totals and filters charges', (
    tester,
  ) async {
    final repo = MockLeasesRepository();
    when(() => repo.charges(period: any(named: 'period'))).thenAnswer(
      (_) async => [
        charge(1, 'paid', paid: 1000000),
        charge(2, 'late'),
        charge(3, 'partial', paid: 400000),
      ],
    );

    await tester.pumpWidget(harness(const RentScreen(), repo));
    await tester.pumpAndSettle();

    expect(find.text('Br 30,000'), findsOneWidget); // due
    expect(find.text('Br 14,000'), findsOneWidget); // collected
    expect(find.text('Br 16,000'), findsOneWidget); // outstanding
    expect(find.text('Tenant 1'), findsOneWidget);
    expect(find.text('Room 2 · Bole Compound\n10 days late'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Unpaid'));
    await tester.pumpAndSettle();

    expect(find.text('Tenant 1'), findsNothing);
    expect(find.text('Tenant 2'), findsOneWidget);
    expect(find.text('Tenant 3'), findsOneWidget);
  });

  testWidgets('lease detail warns before a rent change above the cap', (
    tester,
  ) async {
    final repo = MockLeasesRepository();
    when(() => repo.get(7)).thenAnswer((_) async => Lease.fromJson(leaseJson));
    when(() => repo.charges(leaseId: 7))
        .thenAnswer((_) async => [charge(1, 'due')]);
    when(() => repo.rules()).thenAnswer(
      (_) async => const RentRules(capPercent: 11.5, minLeaseYears: 2),
    );

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(const LeaseDetailScreen(leaseId: 7), repo));
    await tester.pumpAndSettle();

    expect(find.text('Almaz Tesfaye'), findsOneWidget);
    expect(
      find.text('Missing for the directive: tenant address'),
      findsOneWidget,
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change rent'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('newRentField')), '11200');
    await tester.pump();
    expect(
      find.text('Above the 11.5% yearly cap. The most allowed is Br 11,150.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    verifyNever(
      () => repo.changeRent(
        any(),
        newRent: any(named: 'newRent'),
        effectiveDate: any(named: 'effectiveDate'),
      ),
    );

    await tester.enterText(find.byKey(const Key('newRentField')), '11000');
    await tester.pump();
    expect(find.text('Increase of 10.0% (cap 11.5%).'), findsOneWidget);
  });

  testWidgets('lease detail shows a move-out in progress and offers move out', (
    tester,
  ) async {
    final repo = MockLeasesRepository();
    when(() => repo.get(7)).thenAnswer(
      (_) async => Lease.fromJson({
        ...leaseJson,
        'move_out': {'id': 4, 'status': 'draft'},
      }),
    );
    when(() => repo.charges(leaseId: 7)).thenAnswer((_) async => []);

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(const LeaseDetailScreen(leaseId: 7), repo));
    await tester.pumpAndSettle();

    expect(find.text('Move-out in progress'), findsOneWidget);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('moveOutMenuItem')), findsOneWidget);
    expect(Lease.fromJson(leaseJson).moveOutId, isNull);
  });

  testWidgets('tenant page card sends and resets the link', (tester) async {
    final repo = MockLeasesRepository();
    when(() => repo.get(7)).thenAnswer(
      (_) async => Lease.fromJson({
        ...leaseJson,
        'portal_url': 'https://kiray.test/t/abcdefghij',
      }),
    );
    when(() => repo.charges(leaseId: 7)).thenAnswer((_) async => []);
    when(() => repo.sendPortalLink(7)).thenAnswer((_) async {});
    when(() => repo.resetPortalLink(7)).thenAnswer((_) async {});

    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(const LeaseDetailScreen(leaseId: 7), repo));
    await tester.pumpAndSettle();

    expect(find.text('https://kiray.test/t/abcdefghij'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sendPortalLink')));
    await tester.pumpAndSettle();
    verify(() => repo.sendPortalLink(7)).called(1);
    expect(find.text('Link sent to the tenant.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('resetPortalLink')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmResetPortalLink')));
    await tester.pumpAndSettle();
    verify(() => repo.resetPortalLink(7)).called(1);
  });

  test('tenant page link is optional', () {
    expect(Lease.fromJson(leaseJson).portalUrl, isNull);
    expect(
      Lease.fromJson({...leaseJson, 'portal_url': 'https://x/t/1'}).portalUrl,
      'https://x/t/1',
    );
  });
}
