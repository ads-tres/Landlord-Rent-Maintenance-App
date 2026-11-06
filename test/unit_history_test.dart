import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landlord_app/core/storage/secure_store.dart';
import 'package:landlord_app/features/units/data/unit_history_repository.dart';
import 'package:landlord_app/features/units/domain/unit_history.dart';
import 'package:landlord_app/features/units/presentation/unit_history_screen.dart';
import 'package:landlord_app/features/units/presentation/vacancy_screen.dart';
import 'package:landlord_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockUnitHistoryRepository extends Mock implements UnitHistoryRepository {}

final historyJson = {
  'unit': {
    'id': 1,
    'label': 'Unit 1',
    'status': 'occupied',
    'property_id': 1,
    'property_name': 'Bole House',
    'tracked_since': '2026-01-01',
  },
  'year': {
    'year': 2026,
    'from': '2026-01-01',
    'to': '2026-12-31',
    'tracked_days': 365,
    'vacant_days': 89,
    'occupancy_percent': 75.6,
    'lost': 3166667,
    'priced': true,
    'repair_cost': 50000,
  },
  'totals': {
    'tenants': 2,
    'average_stay_months': 3,
    'repair_cost': 50000,
    'current_rent': 1300000,
  },
  'events': [
    {
      'type': 'rent_changed',
      'date': '2026-10-01',
      'lease_id': 2,
      'old_rent': 1200000,
      'new_rent': 1300000,
      'upcoming': false,
    },
    {
      'type': 'lease_started',
      'date': '2026-07-01',
      'lease_id': 2,
      'tenant': 'Almaz',
      'rent': 1200000,
    },
    {
      'type': 'vacant',
      'date': '2026-06-01',
      'until': '2026-06-30',
      'days': 30,
      'lost': 1200000,
    },
    {
      'type': 'lease_ended',
      'date': '2026-05-31',
      'lease_id': 1,
      'tenant': 'Kebede',
      'early': true,
    },
    {
      'type': 'repair',
      'date': '2026-04-10',
      'repair_id': 5,
      'title': 'Broken window',
      'status': 'done',
      'cost': 50000,
    },
  ],
};

final vacancyJson = {
  'year': 2026,
  'from': '2026-01-01',
  'to': '2026-12-31',
  'lost': 8873334,
  'vacant_days': 364,
  'occupancy_percent': 55.2,
  'unpriced_units': 1,
  'units': [
    {
      'id': 2,
      'label': 'Unit 2',
      'property_name': 'Bole House',
      'status': 'vacant',
      'vacant_since': '2026-06-01',
      'tracked_days': 214,
      'vacant_days': 214,
      'occupancy_percent': 0.0,
      'lost': 5706667,
      'priced': true,
    },
    {
      'id': 3,
      'label': 'Unit 3',
      'property_name': 'Bole House',
      'status': 'vacant',
      'vacant_since': null,
      'tracked_days': 61,
      'vacant_days': 61,
      'occupancy_percent': 0.0,
      'lost': 0,
      'priced': false,
    },
  ],
};

Widget harness(MockUnitHistoryRepository repo, Widget home) => ProviderScope(
  overrides: [
    keyValueStoreProvider.overrideWithValue(
      MemoryKeyValueStore({'locale': 'en', 'calendar': 'gregorian'}),
    ),
    unitHistoryRepositoryProvider.overrideWithValue(repo),
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
    home: home,
  ),
);

void main() {
  test('history JSON is read with events newest first', () {
    final h = UnitHistory.fromJson(historyJson);
    expect(h.year.vacantDays, 89);
    expect(h.year.occupancyPercent, 75.6);
    expect(h.events.first.type, UnitEventType.rentChanged);
    expect(h.events[2].type, UnitEventType.vacant);
    expect(h.events[2].until, DateTime(2026, 6, 30));
    expect(h.events[3].early, isTrue);
    expect(h.averageStayMonths, 3.0);
  });

  testWidgets('unit history shows the year and the timeline', (tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = MockUnitHistoryRepository();
    when(() => repo.history(1))
        .thenAnswer((_) async => UnitHistory.fromJson(historyJson));

    await tester.pumpWidget(harness(repo, const UnitHistoryScreen(unitId: 1)));
    await tester.pumpAndSettle();

    expect(find.text('Unit 1 · Bole House'), findsOneWidget);
    expect(find.text('75.6%'), findsOneWidget);
    expect(find.text('89'), findsOneWidget);
    expect(find.byKey(const Key('unitLost')), findsOneWidget);
    expect(find.text('Almaz moved in'), findsOneWidget);
    expect(find.text('Kebede left'), findsOneWidget);
    expect(find.text('Empty for 30 days'), findsOneWidget);
    expect(find.text('Broken window'), findsOneWidget);
    expect(find.textContaining('Ended early'), findsOneWidget);
  });

  testWidgets('vacancy screen totals the year and flags unpriced units', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = MockUnitHistoryRepository();
    when(() => repo.vacancy(year: any(named: 'year')))
        .thenAnswer((_) async => VacancyReport.fromJson(vacancyJson));

    await tester.pumpWidget(harness(repo, const VacancyScreen()));
    await tester.pumpAndSettle();

    expect(find.text('2026'), findsOneWidget);
    expect(find.byKey(const Key('vacancyTotal')), findsOneWidget);
    expect(find.textContaining('364 days empty'), findsOneWidget);
    expect(
      find.text("1 unit was never let or listed, so it isn't priced."),
      findsOneWidget,
    );
    expect(find.byKey(const Key('vacancyUnit-2')), findsOneWidget);
    expect(find.text('—'), findsOneWidget);

    await tester.tap(find.byKey(const Key('previousYear')));
    await tester.pumpAndSettle();
    verify(() => repo.vacancy(year: 2025)).called(1);
  });
}
