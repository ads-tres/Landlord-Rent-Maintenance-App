import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landlord_app/core/storage/secure_store.dart';
import 'package:landlord_app/features/auth/application/auth_controller.dart';
import 'package:landlord_app/features/auth/domain/app_user.dart';
import 'package:landlord_app/features/home/dashboard_screen.dart';
import 'package:landlord_app/features/payments/data/payments_repository.dart';
import 'package:landlord_app/features/payments/domain/dashboard_summary.dart';
import 'package:landlord_app/features/payments/domain/payment.dart';
import 'package:landlord_app/features/repairs/domain/repair.dart';
import 'package:landlord_app/features/team/data/team_repository.dart';
import 'package:landlord_app/features/team/presentation/team_screen.dart';
import 'package:landlord_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockTeamRepository extends Mock implements TeamRepository {}

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

const summary = DashboardSummary(
  collectedThisMonth: 4500000,
  dueThisMonth: 6000000,
  outstanding: 0,
  lateTenants: 0,
  openRepairs: 1,
  leasesEndingSoon: 0,
  properties: 1,
  units: 6,
  vacantUnits: 1,
);

void main() {
  test('caretaker and attribution fields are parsed', () {
    final u = AppUser.fromJson({
      'id': 2,
      'phone': '+251922000002',
      'role': 'caretaker',
      'landlord_name': 'Abel',
    });
    expect(u.isCaretaker, isTrue);
    expect(u.landlordName, 'Abel');
    expect(
      AppUser.fromJson({'id': 1, 'phone': '+251911000001'}).isCaretaker,
      isFalse,
    );

    final p = Payment.fromJson({
      'id': 1,
      'tenant_id': 4,
      'lease_id': 7,
      'amount': 1000000,
      'paid_at': '2026-11-15',
      'method': 'cash',
      'receipt_number': 'R-000001',
      'recorded_by_name': 'Bekele',
      'allocations': [],
    });
    expect(p.recordedByName, 'Bekele');

    final r = Repair.fromJson({
      'id': 5,
      'unit_id': 3,
      'title': 'Tap',
      'category': 'plumbing',
      'status': 'in_progress',
      'source': 'tenant',
      'opened_at': '2026-11-14T08:00:00.000000Z',
      'handled_by_name': 'Bekele',
    });
    expect(r.handledByName, 'Bekele');
  });

  testWidgets('landlord invites and removes a caretaker', (tester) async {
    final repo = MockTeamRepository();
    var members = <TeamMember>[];
    when(repo.list).thenAnswer((_) async => members);
    when(() => repo.invite(name: 'Bekele', phone: '0922000002'))
        .thenAnswer((_) async {
          members = [
            const TeamMember(id: 9, phone: '+251922000002', name: 'Bekele'),
          ];
          return members.first;
        });
    when(() => repo.remove(9)).thenAnswer((_) async => members = []);

    await tester.pumpWidget(
      harness(const TeamScreen(), [
        teamRepositoryProvider.overrideWithValue(repo),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.text('No caretakers yet.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('inviteCaretaker')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('caretakerNameField')),
      'Bekele',
    );
    await tester.enterText(
      find.byKey(const Key('caretakerPhoneField')),
      '0922000002',
    );
    await tester.tap(find.text('Send invite'));
    await tester.pumpAndSettle();

    verify(() => repo.invite(name: 'Bekele', phone: '0922000002')).called(1);
    expect(find.text('Bekele'), findsOneWidget);
    expect(find.textContaining('Invited, not logged in yet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('removeMember-9')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmRemoveMember')));
    await tester.pumpAndSettle();
    verify(() => repo.remove(9)).called(1);
    expect(find.text('No caretakers yet.'), findsOneWidget);
  });

  for (final caretaker in [false, true]) {
    testWidgets(
      'dashboard ${caretaker ? 'hides' : 'shows'} report and expenses',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final payments = MockPaymentsRepository();
        when(payments.dashboard).thenAnswer((_) async => summary);

        await tester.pumpWidget(
          harness(const DashboardScreen(), [
            paymentsRepositoryProvider.overrideWithValue(payments),
            isCaretakerProvider.overrideWithValue(caretaker),
          ]),
        );
        await tester.pumpAndSettle();

        final matcher = caretaker ? findsNothing : findsOneWidget;
        expect(find.byKey(const Key('openReport')), matcher);
        expect(find.byKey(const Key('expensesTile')), matcher);
        expect(find.text('Br 45,000'), findsOneWidget);
      },
    );
  }
}
