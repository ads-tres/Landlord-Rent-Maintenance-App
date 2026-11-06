import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landlord_app/core/storage/secure_store.dart';
import 'package:landlord_app/core/utils/dates.dart';
import 'package:landlord_app/features/leases/data/leases_repository.dart';
import 'package:landlord_app/features/leases/domain/lease.dart';
import 'package:landlord_app/features/leases/domain/rent_rules.dart';
import 'package:landlord_app/features/leases/presentation/lease_detail_screen.dart';
import 'package:landlord_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockLeasesRepository extends Mock implements LeasesRepository {}

Map<String, dynamic> leaseJson({
  List<Map<String, dynamic>> changes = const [],
}) => {
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
  'rent_changes': changes,
};

Widget harness(MockLeasesRepository repo) => ProviderScope(
  overrides: [
    keyValueStoreProvider.overrideWithValue(
      MemoryKeyValueStore({'locale': 'en'}),
    ),
    leasesRepositoryProvider.overrideWithValue(repo),
  ],
  child: const MaterialApp(
    locale: Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: LeaseDetailScreen(leaseId: 7),
  ),
);

void bigScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() => registerFallbackValue(DateTime(2026)));

  test('rules give the notice period and earliest start', () {
    final rules = RentRules.fromJson({
      'rent_cap_percent': 11.5,
      'min_lease_years': 2,
      'rent_notice_days': 30,
    });
    expect(rules.noticeDays, 30);
    expect(
      rules.earliestIncreaseDate(DateTime(2026, 11, 6)),
      DateTime(2026, 12, 6),
    );
    expect(RentRules.fallback.noticeDays, 30);
  });

  test('rent change reads its notice details', () {
    final c = RentChange.fromJson({
      'id': 9,
      'old_rent': 1000000,
      'new_rent': 1100000,
      'effective_date': '2027-01-01',
      'cap_percent': 11.5,
      'notice_days': 56,
      'tenant_agreed': false,
      'notified_at': '2026-11-06T10:00:00Z',
      'upcoming': true,
    });
    expect(c.id, 9);
    expect(c.isIncrease, isTrue);
    expect(c.noticeDays, 56);
    expect(c.tenantNotified, isTrue);
    expect(c.upcoming, isTrue);
  });

  testWidgets(
    'an increase starts at the earliest notice date and texts the tenant',
    (tester) async {
      bigScreen(tester);
      final repo = MockLeasesRepository();
      when(() => repo.get(7))
          .thenAnswer((_) async => Lease.fromJson(leaseJson()));
      when(() => repo.charges(leaseId: 7)).thenAnswer((_) async => []);
      when(() => repo.rules()).thenAnswer(
        (_) async =>
            const RentRules(capPercent: 11.5, minLeaseYears: 2, noticeDays: 30),
      );
      when(
        () => repo.changeRent(
          any(),
          newRent: any(named: 'newRent'),
          effectiveDate: any(named: 'effectiveDate'),
          tenantAgreed: any(named: 'tenantAgreed'),
          notifyTenant: any(named: 'notifyTenant'),
        ),
      ).thenAnswer((_) async => Lease.fromJson(leaseJson()));

      await tester.pumpWidget(harness(repo));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change rent'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('newRentField')), '11000');
      await tester.pump();
      expect(find.byKey(const Key('rentNoticeHint')), findsOneWidget);
      expect(find.byKey(const Key('tenantAgreedSwitch')), findsNothing);
      expect(find.byKey(const Key('notifyTenantSwitch')), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final earliest = const RentRules(
        capPercent: 11.5,
        minLeaseYears: 2,
      ).earliestIncreaseDate(dateOnly(DateTime.now()));
      verify(
        () => repo.changeRent(
          7,
          newRent: 1100000,
          effectiveDate: earliest,
          tenantAgreed: false,
          notifyTenant: true,
        ),
      ).called(1);
    },
  );

  testWidgets(
    'a planned change offers the notice letter and can be cancelled',
    (tester) async {
      bigScreen(tester);
      final repo = MockLeasesRepository();
      final planned = leaseJson(
        changes: [
          {
            'id': 9,
            'old_rent': 1000000,
            'new_rent': 1100000,
            'effective_date': '2027-01-01',
            'cap_percent': 11.5,
            'notice_days': 56,
            'tenant_agreed': false,
            'notified_at': '2026-11-06T10:00:00Z',
            'upcoming': true,
          },
        ],
      );
      when(() => repo.get(7)).thenAnswer((_) async => Lease.fromJson(planned));
      when(() => repo.charges(leaseId: 7)).thenAnswer((_) async => []);
      when(() => repo.cancelRentChange(7, 9))
          .thenAnswer((_) async => Lease.fromJson(leaseJson()));

      await tester.pumpWidget(harness(repo));
      await tester.pumpAndSettle();

      expect(find.textContaining('Upcoming'), findsOneWidget);
      expect(find.textContaining("56 days' notice"), findsOneWidget);
      expect(find.textContaining('Tenant texted'), findsOneWidget);

      await tester.tap(find.byKey(const Key('rentChangeMenu-9')));
      await tester.pumpAndSettle();
      expect(find.text('Notice letter'), findsOneWidget);
      await tester.tap(find.text('Cancel change'));
      await tester.pumpAndSettle();

      expect(find.textContaining('they will get a text'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirmCancelRentChange')));
      await tester.pumpAndSettle();

      verify(() => repo.cancelRentChange(7, 9)).called(1);
      expect(find.text('Rent change cancelled'), findsOneWidget);
    },
  );
}
