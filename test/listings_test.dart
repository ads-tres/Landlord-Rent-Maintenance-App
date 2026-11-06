import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landlord_app/core/storage/secure_store.dart';
import 'package:landlord_app/features/leases/data/leases_repository.dart';
import 'package:landlord_app/features/leases/domain/lease.dart';
import 'package:landlord_app/features/leases/presentation/lease_detail_screen.dart';
import 'package:landlord_app/features/listings/data/listings_repository.dart';
import 'package:landlord_app/features/listings/domain/listing.dart';
import 'package:landlord_app/features/listings/presentation/listings_screens.dart';
import 'package:landlord_app/features/payments/data/payments_repository.dart';
import 'package:landlord_app/features/properties/domain/unit.dart';
import 'package:landlord_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockListingsRepository extends Mock implements ListingsRepository {}

class MockLeasesRepository extends Mock implements LeasesRepository {}

class MockPaymentsRepository extends Mock implements PaymentsRepository {}

Widget harness(Widget child, List overrides) => ProviderScope(
  overrides: [
    keyValueStoreProvider.overrideWithValue(
      MemoryKeyValueStore({'locale': 'en'}),
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

Map<String, dynamic> listingJson({
  String status = 'live',
  bool exceeds = false,
}) => {
  'id': 4,
  'unit_id': 3,
  'unit_label': 'Room 3',
  'property_name': 'Bole Compound',
  'asking_rent': exceeds ? 1200000 : 1100000,
  'available_from': '2026-12-01',
  'description': 'Sunny',
  'status': status,
  'url': 'https://kiray.et/l/abcdefgh',
  'expires_at': '2026-12-15T10:00:00Z',
  'report_count': 0,
  'applications_count': 1,
  'rent_check': {
    'last_rent': 1000000,
    'max_allowed': 1115000,
    'exceeds': exceeds,
    'cap_percent': 11.5,
  },
  'share_text': {'am': 'ለኪራይ', 'en': 'For rent'},
  'photos': [],
};

void main() {
  setUpAll(() => registerFallbackValue(ApplicationStatus.newApp));

  test('listing and unit JSON', () {
    final l = Listing.fromJson(listingJson(exceeds: true));
    expect(l.status, ListingStatus.live);
    expect(l.rentCheck!.exceeds, isTrue);
    expect(l.shareText['en'], 'For rent');

    final u = Unit.fromJson({
      'id': 3,
      'property_id': 1,
      'label': 'Room 3',
      'status': 'vacant',
      'open_listing': {'id': 4, 'status': 'live'},
    });
    expect(u.openListingId, 4);
    expect(ApplicationStatus.parse('new').apiValue, 'new');
  });

  testWidgets(
    'listing detail warns about rent above the cap and approves an applicant',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final repo = MockListingsRepository();
      when(
        () => repo.get(4),
      ).thenAnswer((_) async => Listing.fromJson(listingJson(exceeds: true)));
      when(() => repo.applications(4)).thenAnswer(
        (_) async => [
          ListingApplication.fromJson({
            'id': 9,
            'full_name': 'Mulu',
            'phone': '+251922000001',
            'status': 'shortlisted',
            'household_size': 3,
            'move_in_date': '2026-12-01',
          }),
        ],
      );
      when(() => repo.setApplicationStatus(9, ApplicationStatus.approved))
          .thenAnswer(
            (_) async => ListingApplication.fromJson({
              'id': 9,
              'full_name': 'Mulu',
              'phone': '+251922000001',
              'status': 'approved',
            }),
          );

      await tester.pumpWidget(
        harness(const ListingDetailScreen(listingId: 4), [
          listingsRepositoryProvider.overrideWithValue(repo),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('rentCheckCard')), findsOneWidget);
      expect(
        find.textContaining(
          'Above the allowed rent: the last rent was Br 10,000',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Br 11,150'), findsOneWidget);
      expect(find.text('Share listing'), findsOneWidget);
      expect(find.text('Mulu'), findsOneWidget);
      expect(find.textContaining('3 people'), findsOneWidget);

      await tester.tap(find.byKey(const Key('approve-9')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('This creates the tenant and a draft lease'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Approve').last);
      await tester.pumpAndSettle();

      verify(() => repo.setApplicationStatus(9, ApplicationStatus.approved))
          .called(1);
    },
  );

  testWidgets('draft listing offers publish', (tester) async {
    final repo = MockListingsRepository();
    when(
      () => repo.get(4),
    ).thenAnswer((_) async => Listing.fromJson(listingJson(status: 'draft')));
    when(() => repo.applications(4)).thenAnswer((_) async => []);
    when(() => repo.setStatus(4, 'live'))
        .thenAnswer((_) async => Listing.fromJson(listingJson()));

    await tester.pumpWidget(
      harness(const ListingDetailScreen(listingId: 4), [
        listingsRepositoryProvider.overrideWithValue(repo),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Last rent Br 10,000'), findsOneWidget);
    await tester.tap(find.byKey(const Key('publishButton')));
    await tester.pumpAndSettle();
    verify(() => repo.setStatus(4, 'live')).called(1);
  });

  testWidgets('a draft lease shows the activate step', (tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final leases = MockLeasesRepository();
    final payments = MockPaymentsRepository();
    when(() => leases.get(7)).thenAnswer(
      (_) async => Lease.fromJson({
        'id': 7,
        'unit_id': 3,
        'tenant_id': 4,
        'start_date': '2026-12-01',
        'end_date': '2028-11-30',
        'monthly_rent': 1100000,
        'deposit': 0,
        'due_day': 1,
        'status': 'draft',
        'unit': {
          'id': 3,
          'label': 'Room 3',
          'property_id': 1,
          'property_name': 'Bole Compound',
        },
        'tenant': {'id': 4, 'full_name': 'Mulu', 'phone': '+251922000001'},
      }),
    );
    when(() => leases.charges(leaseId: 7)).thenAnswer((_) async => []);
    when(() => payments.forLease(7)).thenAnswer((_) async => []);

    await tester.pumpWidget(
      harness(const LeaseDetailScreen(leaseId: 7), [
        leasesRepositoryProvider.overrideWithValue(leases),
        paymentsRepositoryProvider.overrideWithValue(payments),
      ]),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Draft lease from an approved application'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('activateLeaseButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('activateConditionField')), findsOneWidget);
  });
}
