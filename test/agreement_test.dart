import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landlord_app/core/api/api_client.dart';
import 'package:landlord_app/core/storage/secure_store.dart';
import 'package:landlord_app/features/auth/application/auth_controller.dart';
import 'package:landlord_app/features/home/dashboard_screen.dart';
import 'package:landlord_app/features/leases/data/leases_repository.dart';
import 'package:landlord_app/features/leases/domain/lease.dart';
import 'package:landlord_app/features/leases/presentation/lease_agreement_card.dart';
import 'package:landlord_app/features/leases/presentation/leases_ending_screen.dart';
import 'package:landlord_app/features/payments/data/payments_repository.dart';
import 'package:landlord_app/features/payments/domain/dashboard_summary.dart';
import 'package:landlord_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockLeasesRepository extends Mock implements LeasesRepository {}

class MockPaymentsRepository extends Mock implements PaymentsRepository {}

Map<String, dynamic> leaseJson({Map<String, dynamic> extra = const {}}) => {
  'id': 7,
  'unit_id': 3,
  'tenant_id': 4,
  'start_date': '2026-11-01',
  'end_date': '2028-10-31',
  'monthly_rent': 1000000,
  'deposit': 2000000,
  'due_day': 5,
  'status': 'active',
  'days_until_end': 700,
  'unit': {
    'id': 3,
    'label': 'Room 1',
    'property_id': 1,
    'property_name': 'Bole',
  },
  'tenant': {'id': 4, 'full_name': 'Almaz Tesfaye', 'phone': '+251922000002'},
  'agreement_blanks': ['tenant_address', 'tenant_id_number'],
  'documents': [],
  ...extra,
};

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

Response<dynamic> ok(String path, Map<String, dynamic> data) => Response(
  requestOptions: RequestOptions(path: path),
  data: {'data': data},
);

void main() {
  setUpAll(() => registerFallbackValue(DateTime(2026)));

  test('lease reads the agreement and registration fields', () {
    final l = Lease.fromJson(
      leaseJson(
        extra: {
          'registered_at': '2026-11-10',
          'registration_number': 'BL/03/1234',
          'registration_office': 'Bole Woreda 03',
          'extra_terms': 'No pets.',
          'documents': [
            {'id': 1, 'url': 'https://x/api/v1/attachments/1'},
          ],
        },
      ),
    );
    expect(l.registeredAt, DateTime(2026, 11, 10));
    expect(l.registrationNumber, 'BL/03/1234');
    expect(l.extraTerms, 'No pets.');
    expect(l.agreementBlanks, ['tenant_address', 'tenant_id_number']);
    expect(l.documentUrls, ['https://x/api/v1/attachments/1']);
  });

  test('registration and extra terms are sent cleanly', () async {
    final dio = MockDio();
    when(() => dio.put(any(), data: any(named: 'data'))).thenAnswer(
      (i) async => ok(i.positionalArguments.first as String, leaseJson()),
    );
    final repo = LeasesRepository(ApiClient(dio));

    await repo.recordRegistration(
      7,
      registeredAt: DateTime(2026, 11, 10),
      number: ' BL/03/1234 ',
      office: '',
    );
    await repo.setExtraTerms(7, '   ');

    final calls = verify(
      () => dio.put(captureAny(), data: captureAny(named: 'data')),
    ).captured;
    expect(calls[0], '/leases/7/registration');
    expect(calls[1], {
      'registered_at': '2026-11-10',
      'registration_number': 'BL/03/1234',
      'registration_office': null,
    });
    expect(calls[2], '/leases/7/extra-terms');
    expect(calls[3], {'extra_terms': null});
  });

  testWidgets('card shows what is missing and records the registration', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = MockLeasesRepository();
    when(
      () => repo.recordRegistration(
        7,
        registeredAt: any(named: 'registeredAt'),
        number: any(named: 'number'),
        office: any(named: 'office'),
      ),
    ).thenAnswer((_) async => Lease.fromJson(leaseJson()));
    var changed = 0;

    await tester.pumpWidget(
      harness(
        Scaffold(
          body: LeaseAgreementCard(
            lease: Lease.fromJson(leaseJson()),
            onChanged: () => changed++,
          ),
        ),
        [leasesRepositoryProvider.overrideWithValue(repo)],
      ),
    );

    expect(find.text('Not registered yet'), findsOneWidget);
    expect(
      find.text(
        'Left blank to fill in by hand: tenant address, tenant ID number',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('recordRegistration')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('registrationNumberField')),
      'BL/03/1234',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    verify(
      () => repo.recordRegistration(
        7,
        registeredAt: any(named: 'registeredAt'),
        number: 'BL/03/1234',
        office: '',
      ),
    ).called(1);
    expect(changed, 1);
  });

  testWidgets('registered leases show the date and number', (tester) async {
    await tester.pumpWidget(
      harness(
        Scaffold(
          body: LeaseAgreementCard(
            lease: Lease.fromJson(
              leaseJson(
                extra: {
                  'registered_at': '2026-11-10',
                  'registration_number': 'BL/03/1234',
                  'registration_office': 'Bole Woreda 03',
                  'agreement_blanks': [],
                },
              ),
            ),
            onChanged: () {},
          ),
        ),
        [leasesRepositoryProvider.overrideWithValue(MockLeasesRepository())],
      ),
    );
    final status = tester.widget<Text>(
      find.byKey(const Key('registrationStatus')),
    );
    expect(status.data, contains('No. BL/03/1234 · Bole Woreda 03'));
    expect(find.text('Edit registration'), findsOneWidget);
  });

  for (final caretaker in [false, true]) {
    testWidgets(
      'home banner for unregistered leases ${caretaker ? 'hidden for caretakers' : 'shown to landlords'}',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final payments = MockPaymentsRepository();
        when(payments.dashboard).thenAnswer(
          (_) async => const DashboardSummary(
            collectedThisMonth: 0,
            dueThisMonth: 0,
            outstanding: 0,
            lateTenants: 0,
            openRepairs: 0,
            leasesEndingSoon: 0,
            properties: 1,
            units: 2,
            vacantUnits: 0,
            unregisteredLeases: 2,
          ),
        );

        await tester.pumpWidget(
          harness(const DashboardScreen(), [
            paymentsRepositoryProvider.overrideWithValue(payments),
            isCaretakerProvider.overrideWithValue(caretaker),
          ]),
        );
        await tester.pumpAndSettle();
        expect(
          find.text("2 leases aren't registered yet"),
          caretaker ? findsNothing : findsOneWidget,
        );
      },
    );
  }

  testWidgets('leases to register list', (tester) async {
    final repo = MockLeasesRepository();
    when(repo.unregistered)
        .thenAnswer((_) async => [Lease.fromJson(leaseJson())]);

    await tester.pumpWidget(
      harness(const LeasesEndingScreen(unregistered: true), [
        leasesRepositoryProvider.overrideWithValue(repo),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.text('Leases to register'), findsOneWidget);
    expect(find.text('Almaz Tesfaye · Room 1'), findsOneWidget);
    expect(find.textContaining('Started '), findsOneWidget);
  });
}
