import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landlord_app/core/api/api_client.dart';
import 'package:landlord_app/core/storage/secure_store.dart';
import 'package:landlord_app/features/compound/data/compound_repository.dart';
import 'package:landlord_app/features/compound/domain/compound.dart';
import 'package:landlord_app/features/compound/presentation/announce_screen.dart';
import 'package:landlord_app/features/compound/presentation/assets_screen.dart';
import 'package:landlord_app/features/compound/presentation/meter_detail_screen.dart';
import 'package:landlord_app/features/leases/data/leases_repository.dart';
import 'package:landlord_app/features/leases/domain/charge.dart';
import 'package:landlord_app/features/rent/presentation/rent_screen.dart';
import 'package:landlord_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockCompoundRepository extends Mock implements CompoundRepository {}

class MockLeasesRepository extends Mock implements LeasesRepository {}

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

const submeter = Meter(
  id: 3,
  propertyId: 1,
  name: 'Main electricity',
  kind: MeterKind.electricity,
  splitMethod: SplitMethod.submeter,
  units: [
    MeterUnitShare(unitId: 10, label: 'Room 1', occupied: true),
    MeterUnitShare(unitId: 11, label: 'Room 2'),
  ],
);

void main() {
  setUpAll(() => registerFallbackValue(DateTime(2026)));

  test('bill readings are sent as readings[unit][previous|current]', () async {
    final dio = MockDio();
    when(() => dio.post('/meters/3/bills', data: any(named: 'data')))
        .thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/meters/3/bills'),
            data: {
              'data': {'amount': 100000, 'landlord_share': 0, 'lines': []},
            },
          ),
        );

    await CompoundRepository(ApiClient(dio)).previewBill(
      3,
      period: '2026-11',
      amount: 100000,
      dueDate: DateTime(2026, 11, 25),
      readings: {10: (100, 160)},
    );

    final form =
        verify(
              () =>
                  dio.post('/meters/3/bills', data: captureAny(named: 'data')),
            ).captured.single
            as FormData;
    final fields = Map.fromEntries(form.fields);
    expect(fields['readings[10][previous]'], '100.0');
    expect(fields['readings[10][current]'], '160.0');
    expect(fields['dry_run'], '1');
    expect(fields['due_date'], '2026-11-25');
  });

  testWidgets('entering a bill shows the split before saving', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = MockCompoundRepository();
    when(
      () => repo.previewBill(
        3,
        period: any(named: 'period'),
        amount: 100000,
        dueDate: any(named: 'dueDate'),
        readings: {10: (100.0, 160.0), 11: (50.0, 50.0)},
      ),
    ).thenAnswer(
      (_) async => const SplitPreview(
        amount: 100000,
        landlordShare: 0,
        lines: [
          SplitLine(unitLabel: 'Room 1', amount: 100000, tenantName: 'Almaz'),
          SplitLine(unitLabel: 'Room 2', amount: 0, vacant: true),
        ],
      ),
    );

    await tester.pumpWidget(
      harness(const EnterBillScreen(meter: submeter), [
        compoundRepositoryProvider.overrideWithValue(repo),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('billAmountField')), '1000');
    await tester.enterText(find.byKey(const Key('reading-10-0')), '100');
    await tester.enterText(find.byKey(const Key('reading-10-1')), '160');
    await tester.enterText(find.byKey(const Key('reading-11-0')), '50');
    await tester.enterText(find.byKey(const Key('reading-11-1')), '50');
    await tester.tap(find.byKey(const Key('previewSplitButton')));
    await tester.pumpAndSettle();

    expect(find.text('Room 1 · Almaz'), findsOneWidget);
    expect(find.text('Room 2 · vacant'), findsOneWidget);
    expect(find.text('Br 1,000'), findsOneWidget);
  });

  testWidgets('announcement shows recipients and SMS cost, then sends', (
    tester,
  ) async {
    final repo = MockCompoundRepository();
    when(() => repo.previewAnnouncement(1, 'No water tomorrow')).thenAnswer(
      (_) async => const AnnouncementPreview(
        recipients: 3,
        telegram: 1,
        sms: 2,
        smsSegments: 2,
        estimatedCost: 70,
        text: 'Bole Compound: No water tomorrow - Abel',
      ),
    );
    when(() => repo.sendAnnouncement(1, 'No water tomorrow'))
        .thenAnswer((_) async {});

    await tester.pumpWidget(
      harness(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AnnounceScreen(propertyId: 1),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
        [compoundRepositoryProvider.overrideWithValue(repo)],
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('announcementField')),
      'No water tomorrow',
    );
    await tester.tap(find.byKey(const Key('checkAnnouncement')));
    await tester.pumpAndSettle();

    expect(find.text('3 tenants'), findsOneWidget);
    expect(find.text('1 on Telegram (free) · 2 by SMS'), findsOneWidget);
    expect(find.text('2 SMS · About Br 0.70'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sendAnnouncement')));
    await tester.pumpAndSettle();
    verify(() => repo.sendAnnouncement(1, 'No water tomorrow')).called(1);
    expect(find.text('open'), findsOneWidget); // back on the previous screen
  });

  testWidgets('equipment list highlights overdue and upcoming services', (
    tester,
  ) async {
    final repo = MockCompoundRepository();
    when(() => repo.assets(1)).thenAnswer(
      (_) async => [
        Asset.fromJson({
          'id': 1,
          'property_id': 1,
          'kind': 'generator',
          'name': 'Generator',
          'service_interval_days': 90,
          'last_serviced_on': '2026-08-20',
          'next_service_on': '2026-11-18',
          'days_until_service': 3,
        }),
        Asset.fromJson({
          'id': 2,
          'property_id': 1,
          'kind': 'water_tank',
          'name': 'Water tank',
          'service_interval_days': 180,
        }),
      ],
    );

    await tester.pumpWidget(
      harness(const AssetsScreen(propertyId: 1), [
        compoundRepositoryProvider.overrideWithValue(repo),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Service due in 3 days'), findsOneWidget);
    expect(find.text('Service overdue'), findsOneWidget);
    expect(find.textContaining('Not serviced yet'), findsOneWidget);
  });

  testWidgets('rent list labels utility shares', (tester) async {
    final leases = MockLeasesRepository();
    when(() => leases.charges(period: any(named: 'period'))).thenAnswer(
      (_) async => [
        Charge.fromJson({
          'id': 1,
          'lease_id': 7,
          'period': '2026-11',
          'type': 'utility',
          'utility_kind': 'water',
          'amount_due': 25000,
          'amount_paid': 0,
          'balance': 25000,
          'due_date': '2026-11-25',
          'status': 'due',
          'tenant': {'id': 1, 'full_name': 'Almaz'},
        }),
      ],
    );

    await tester.pumpWidget(
      harness(const RentScreen(), [
        leasesRepositoryProvider.overrideWithValue(leases),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Almaz · Water'), findsOneWidget);
  });
}
