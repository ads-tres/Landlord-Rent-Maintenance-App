import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landlord_app/core/api/api_client.dart';
import 'package:landlord_app/core/storage/secure_store.dart';
import 'package:landlord_app/features/leases/data/leases_repository.dart';
import 'package:landlord_app/features/leases/domain/lease.dart';
import 'package:landlord_app/features/leases/domain/renewal.dart';
import 'package:landlord_app/features/leases/presentation/lease_detail_screen.dart';
import 'package:landlord_app/features/leases/presentation/leases_ending_screen.dart';
import 'package:landlord_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockLeasesRepository extends Mock implements LeasesRepository {}

Map<String, dynamic> leaseJson({int daysUntilEnd = 45}) => {
  'id': 7,
  'unit_id': 3,
  'tenant_id': 4,
  'start_date': '2025-01-01',
  'end_date': '2026-12-31',
  'monthly_rent': 1000000,
  'deposit': 2000000,
  'due_day': 1,
  'status': 'active',
  'days_until_end': daysUntilEnd,
  'unit': {
    'id': 3,
    'label': 'Room 1',
    'property_id': 1,
    'property_name': 'Bole',
  },
  'tenant': {'id': 4, 'full_name': 'Almaz Tesfaye', 'phone': '+251911234567'},
  'rent_changes': [],
};

final check = RenewalCheck.fromJson({
  'current_end_date': '2026-12-31',
  'suggested_end_date': '2028-12-31',
  'rent_from': '2027-01-01',
  'current_rent': 1000000,
  'max_rent': 1115000,
  'cap_percent': 11.5,
  'can_renew_from': '2026-07-04',
});

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

  test('renew posts the new end date and rent', () async {
    final dio = MockDio();
    when(() => dio.post('/leases/7/renew', data: any(named: 'data')))
        .thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/leases/7/renew'),
            statusCode: 201,
            data: {
              'data': {
                'id': 2,
                'new_end_date': '2028-12-31',
                'new_rent': 1100000,
                'rent_from': '2027-01-01',
              },
            },
          ),
        );

    final r = await LeasesRepository(ApiClient(dio))
        .renew(7, newEndDate: DateTime(2028, 12, 31), newRent: 1100000);

    expect(r.newRent, 1100000);
    expect(
      verify(() => dio.post('/leases/7/renew', data: captureAny(named: 'data')))
          .captured
          .single,
      {
        'new_end_date': '2028-12-31',
        'new_rent': 1100000,
        'notify_tenant': true,
      },
    );
  });

  testWidgets('renewing from the lease screen checks the cap', (tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = MockLeasesRepository();
    when(() => repo.get(7))
        .thenAnswer((_) async => Lease.fromJson(leaseJson()));
    when(() => repo.charges(leaseId: 7)).thenAnswer((_) async => []);
    when(() => repo.renewalCheck(7)).thenAnswer((_) async => check);
    when(
      () => repo.renew(
        7,
        newEndDate: any(named: 'newEndDate'),
        newRent: any(named: 'newRent'),
        notifyTenant: any(named: 'notifyTenant'),
      ),
    ).thenAnswer(
      (_) async => LeaseRenewal(
        id: 2,
        newEndDate: DateTime(2028, 12, 31),
        newRent: 1100000,
        rentFrom: DateTime(2027),
      ),
    );

    await tester.pumpWidget(harness(const LeaseDetailScreen(leaseId: 7), repo));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('renewLeaseCard')), findsOneWidget);
    await tester.tap(find.byKey(const Key('renewLeaseButton')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Up to Br 11,150'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('renewRentField')), '12000');
    await tester.pump();
    expect(find.text('Above the yearly limit.'), findsWidgets);
    await tester.tap(find.text('Renew').last);
    await tester.pumpAndSettle();
    verifyNever(
      () => repo.renew(
        any(),
        newEndDate: any(named: 'newEndDate'),
        newRent: any(named: 'newRent'),
        notifyTenant: any(named: 'notifyTenant'),
      ),
    );

    await tester.enterText(find.byKey(const Key('renewRentField')), '11000');
    await tester.pump();
    await tester.tap(find.text('Renew').last);
    await tester.pumpAndSettle();

    verify(
      () => repo.renew(
        7,
        newEndDate: DateTime(2028, 12, 31),
        newRent: 1100000,
        notifyTenant: true,
      ),
    ).called(1);
    expect(find.text('Lease renewed'), findsOneWidget);
    expect(find.byKey(const Key('shareAddendum')), findsOneWidget);
  });

  testWidgets('no renew card when the end is far away', (tester) async {
    final repo = MockLeasesRepository();
    when(() => repo.get(7))
        .thenAnswer((_) async => Lease.fromJson(leaseJson(daysUntilEnd: 400)));
    when(() => repo.charges(leaseId: 7)).thenAnswer((_) async => []);

    await tester.pumpWidget(harness(const LeaseDetailScreen(leaseId: 7), repo));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('renewLeaseCard')), findsNothing);
  });

  testWidgets('leases ending list', (tester) async {
    final repo = MockLeasesRepository();
    when(repo.ending).thenAnswer((_) async => [Lease.fromJson(leaseJson())]);

    await tester.pumpWidget(harness(const LeasesEndingScreen(), repo));
    await tester.pumpAndSettle();
    expect(find.text('Almaz Tesfaye · Room 1'), findsOneWidget);
    expect(find.byKey(const Key('endingLease-7')), findsOneWidget);
  });
}
