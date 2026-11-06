import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landlord_app/core/api/api_client.dart';
import 'package:landlord_app/core/storage/secure_store.dart';
import 'package:landlord_app/features/arrears/data/arrears_repository.dart';
import 'package:landlord_app/features/arrears/domain/arrears.dart';
import 'package:landlord_app/features/arrears/presentation/arrears_detail_screen.dart';
import 'package:landlord_app/features/arrears/presentation/arrears_screen.dart';
import 'package:landlord_app/features/auth/application/auth_controller.dart';
import 'package:landlord_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockArrearsRepository extends Mock implements ArrearsRepository {}

Map<String, dynamic> arrearsJson({
  String? suggested = 'reminder',
  Map<String, dynamic>? plan,
  List<Map<String, dynamic>> actions = const [],
}) => {
  'lease_id': 7,
  'tenant_name': 'Almaz Tesfaye',
  'unit_label': 'Room 1',
  'property_name': 'Bole Compound',
  'owed': 2000000,
  'days_overdue': 50,
  'months_behind': 2,
  'suggested': suggested,
  'last_action': null,
  'plan': plan,
  'actions': actions,
  'charges': [],
};

Widget harness(
  Widget child,
  MockArrearsRepository repo, {
  bool caretaker = false,
}) => ProviderScope(
  overrides: [
    keyValueStoreProvider.overrideWithValue(
      MemoryKeyValueStore({'locale': 'en'}),
    ),
    arrearsRepositoryProvider.overrideWithValue(repo),
    isCaretakerProvider.overrideWithValue(caretaker),
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
  setUpAll(() => registerFallbackValue(ArrearsStep.note));

  test('plans split evenly by month with the remainder last', () {
    final parts = splitPlan(1000001, 3, DateTime(2026, 11, 30));
    expect(parts.map((p) => p.amount), [333333, 333333, 333335]);
    expect(parts.map((p) => p.dueDate), [
      DateTime(2026, 11, 30),
      DateTime(2026, 12, 30),
      DateTime(2027, 1, 30),
    ]);
  });

  test('creating a plan sends instalment dates and amounts', () async {
    final dio = MockDio();
    when(() => dio.post('/leases/7/payment-plan', data: any(named: 'data')))
        .thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/leases/7/payment-plan'),
            data: {'data': arrearsJson()},
          ),
        );
    await ArrearsRepository(ApiClient(dio)).createPlan(7, [
      (dueDate: DateTime(2026, 11, 25), amount: 1000000),
      (dueDate: DateTime(2026, 12, 25), amount: 1000000),
    ]);
    expect(
      verify(
        () =>
            dio.post('/leases/7/payment-plan', data: captureAny(named: 'data')),
      ).captured.single,
      {
        'instalments': [
          {'due_date': '2026-11-25', 'amount': 1000000},
          {'due_date': '2026-12-25', 'amount': 1000000},
        ],
        'notify_tenant': true,
      },
    );
  });

  testWidgets('list shows who is behind and the next step', (tester) async {
    final repo = MockArrearsRepository();
    when(repo.list).thenAnswer((_) async => [Arrears.fromJson(arrearsJson())]);

    await tester.pumpWidget(harness(const ArrearsScreen(), repo));
    await tester.pumpAndSettle();

    expect(find.text('Almaz Tesfaye · Room 1'), findsOneWidget);
    expect(find.text('Br 20,000'), findsOneWidget);
    expect(find.textContaining('Next step: Friendly reminder'), findsOneWidget);
  });

  testWidgets('sending a reminder asks first, then logs it', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = MockArrearsRepository();
    when(() => repo.get(7))
        .thenAnswer((_) async => Arrears.fromJson(arrearsJson()));
    when(() => repo.act(7, any(), note: any(named: 'note'))).thenAnswer(
      (_) async => Arrears.fromJson(arrearsJson(suggested: 'notice')),
    );

    await tester.pumpWidget(
      harness(const ArrearsDetailScreen(leaseId: 7), repo),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('suggestedStep')), findsOneWidget);
    expect(find.byKey(const Key('demandLetter')), findsOneWidget);

    await tester.tap(find.byKey(const Key('sendReminder')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmSend')));
    await tester.pumpAndSettle();

    verify(() => repo.act(7, ArrearsStep.reminder)).called(1);
    expect(find.text('Sent to the tenant.'), findsOneWidget);
  });

  testWidgets('caretakers can remind but not issue letters or plans', (
    tester,
  ) async {
    final repo = MockArrearsRepository();
    when(() => repo.get(7))
        .thenAnswer((_) async => Arrears.fromJson(arrearsJson()));

    await tester.pumpWidget(
      harness(const ArrearsDetailScreen(leaseId: 7), repo, caretaker: true),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sendReminder')), findsOneWidget);
    expect(find.byKey(const Key('demandLetter')), findsNothing);
    expect(find.byKey(const Key('createPlan')), findsNothing);
  });

  testWidgets('an active plan shows progress instead of steps', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = MockArrearsRepository();
    when(() => repo.get(7)).thenAnswer(
      (_) async => Arrears.fromJson(
        arrearsJson(
          suggested: null,
          plan: {
            'id': 3,
            'total': 2000000,
            'paid': 1000000,
            'instalments': [
              {
                'due_date': '2026-11-25',
                'amount': 1000000,
                'covered': true,
                'overdue': false,
              },
              {
                'due_date': '2026-12-25',
                'amount': 1000000,
                'covered': false,
                'overdue': false,
              },
            ],
            'next': null,
          },
        ),
      ),
    );

    await tester.pumpWidget(
      harness(const ArrearsDetailScreen(leaseId: 7), repo),
    );
    await tester.pumpAndSettle();
    expect(find.text('Plan: Br 10,000 of Br 20,000 paid'), findsOneWidget);
    expect(find.byKey(const Key('sendReminder')), findsNothing);
    expect(find.byKey(const Key('cancelPlan')), findsOneWidget);
  });
}
