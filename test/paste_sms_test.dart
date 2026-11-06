import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:landlord_app/core/storage/secure_store.dart';
import 'package:landlord_app/features/leases/data/leases_repository.dart';
import 'package:landlord_app/features/leases/domain/lease.dart';
import 'package:landlord_app/features/payments/domain/payment.dart';
import 'package:landlord_app/features/payments/domain/payment_sms.dart';
import 'package:landlord_app/features/payments/presentation/log_payment_screen.dart';
import 'package:landlord_app/features/payments/presentation/paste_sms_sheet.dart';
import 'package:landlord_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockLeasesRepository extends Mock implements LeasesRepository {}

const telebirrSms =
    'Dear Abel, You have received ETB 10,000.00 from Almaz Tesfaye(2519****5678) '
    'on 15/11/2026 10:23:45. Your transaction number is CKF1A2B3C4. Your current '
    'E-Money Account balance is ETB 12,345.67. Thank you for using telebirr Ethio telecom';

Lease lease(int id, String name, String phone) => Lease.fromJson({
  'id': id,
  'unit_id': id,
  'tenant_id': id,
  'start_date': '2026-01-01',
  'end_date': '2027-12-31',
  'monthly_rent': 1000000,
  'due_day': 1,
  'status': 'active',
  'unit': {
    'id': id,
    'label': 'Room $id',
    'property_id': 1,
    'property_name': 'Bole',
  },
  'tenant': {'id': id, 'full_name': name, 'phone': phone},
});

final localizations = const [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

void mockClipboard(WidgetTester tester, String? text) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async => call.method == 'Clipboard.getData' ? {'text': text} : null,
  );
}

void main() {
  testWidgets('a pasted SMS fills in the payment form', (tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    mockClipboard(tester, telebirrSms);

    final repo = MockLeasesRepository();
    when(() => repo.get(1))
        .thenAnswer((_) async => lease(1, 'Almaz Tesfaye', '+251911235678'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(
            MemoryKeyValueStore({'locale': 'en'}),
          ),
          leasesRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: localizations,
          home: const LogPaymentScreen(leaseId: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pasteSms')));
    await tester.pumpAndSettle();
    // The clipboard text was read straight away.
    expect(find.byKey(const Key('smsPreview')), findsOneWidget);
    expect(find.text('Br 10,000'), findsOneWidget);
    expect(find.text('CKF1A2B3C4'), findsOneWidget);
    await tester.tap(find.byKey(const Key('useSms')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('amountField')))
          .controller!
          .text,
      '10000',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('referenceField')))
          .controller!
          .text,
      'CKF1A2B3C4',
    );
    expect(
      find.text('Filled in from the SMS. Check the details before saving.'),
      findsOneWidget,
    );
  });

  testWidgets('warns when the SMS is from someone else', (tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = MockLeasesRepository();
    when(() => repo.get(2))
        .thenAnswer((_) async => lease(2, 'Abebe Kebede', '+251922000000'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(
            MemoryKeyValueStore({'locale': 'en'}),
          ),
          leasesRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: localizations,
          home: LogPaymentScreen(
            leaseId: 2,
            prefill: parsePaymentSms(
              telebirrSms,
              today: DateTime(2026, 11, 15),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'This message seems to be from Almaz Tesfaye · 2519****5678, not Abebe Kebede. Check before saving.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('from the Rent tab the SMS finds the tenant and opens the form', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    mockClipboard(tester, telebirrSms);
    final repo = MockLeasesRepository();
    when(repo.active).thenAnswer(
      (_) async => [
        lease(2, 'Abebe Kebede', '+251922000000'),
        lease(1, 'Almaz Tesfaye', '+251911235678'),
      ],
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Consumer(
            builder: (context, ref, _) => Scaffold(
              body: TextButton(
                onPressed: () => logPaymentFromSms(context, ref),
                child: const Text('paste'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/payments/new',
          builder: (_, state) {
            final sms = state.extra as PaymentSms?;
            return Text(
              'log ${state.uri.queryParameters['leaseId']} ${sms?.reference} ${sms?.method == PaymentMethod.telebirr}',
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(
            MemoryKeyValueStore({'locale': 'en'}),
          ),
          leasesRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp.router(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: localizations,
          routerConfig: router,
        ),
      ),
    );
    await tester.tap(find.text('paste'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('useSms')));
    await tester.pumpAndSettle();

    expect(find.text('log 1 CKF1A2B3C4 true'), findsOneWidget);
  });

  testWidgets('an unclear sender asks which tenant, likely ones first', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    mockClipboard(
      tester,
      'You have received ETB 5,000.00 from ALMAZ. Ref: TX12345678',
    );
    final repo = MockLeasesRepository();
    when(repo.active).thenAnswer(
      (_) async => [
        lease(2, 'Abebe Kebede', '+251922000000'),
        lease(1, 'Almaz Tesfaye', '+251911235678'),
        lease(3, 'Almaz Bekele', '+251933000000'),
      ],
    );
    late WidgetRef widgetRef;
    late BuildContext buttonContext;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(
            MemoryKeyValueStore({'locale': 'en'}),
          ),
          leasesRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: localizations,
          home: Consumer(
            builder: (context, ref, _) {
              widgetRef = ref;
              buttonContext = context;
              return const Scaffold(body: SizedBox());
            },
          ),
        ),
      ),
    );

    // The picker opens because two tenants are called Almaz; stop before pushing a route.
    logPaymentFromSms(buttonContext, widgetRef);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('useSms')));
    await tester.pumpAndSettle();

    expect(find.text('Which tenant is this payment from?'), findsOneWidget);
    expect(find.text('Likely'), findsNWidgets(2));
    final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    final keys = tiles
        .map((t) => t.key)
        .whereType<ValueKey<String>>()
        .map((k) => k.value)
        .toList();
    expect(keys.take(2), containsAll(['smsLease-1', 'smsLease-3']));
    expect(keys.last, 'smsLease-2');
  });
}
