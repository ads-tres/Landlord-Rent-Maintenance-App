import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landlord_app/core/api/api_client.dart';
import 'package:landlord_app/core/storage/secure_store.dart';
import 'package:landlord_app/features/move_out/data/move_out_repository.dart';
import 'package:landlord_app/features/move_out/domain/move_out.dart';
import 'package:landlord_app/features/move_out/presentation/move_out_screen.dart';
import 'package:landlord_app/features/payments/domain/payment.dart';
import 'package:landlord_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockMoveOutRepository extends Mock implements MoveOutRepository {}

Map<String, dynamic> moveOutJson({bool settled = false}) => {
  'id': 4,
  'lease_id': 7,
  'status': settled ? 'settled' : 'draft',
  'moved_out_on': '2026-11-30',
  'condition_notes': 'Wall paint scratched',
  'keys_returned': true,
  'deposit': 2000000,
  'unpaid_total': 1000000,
  'other_total': 50000,
  'deposit_applied': 1000000,
  'deposit_kept': 50000,
  'refund_amount': 950000,
  'balance_owed': 0,
  'refund_method': settled ? 'telebirr' : null,
  'refund_reference': settled ? 'TX123' : null,
  'statement_url': 'https://example.test/mo/abcdefghij',
  'deductions': [
    {
      'id': 1,
      'kind': 'unpaid_rent',
      'description': 'November 2026',
      'amount': 1000000,
      'from_charge': true,
    },
    {
      'id': 2,
      'kind': 'cleaning',
      'description': 'Deep clean',
      'amount': 50000,
      'from_charge': false,
    },
  ],
  'photos': [],
  'tenant_name': 'Almaz Tesfaye',
  'unit_label': 'Room 1',
  'unit_id': 10,
};

Widget harness(Widget child, MockMoveOutRepository repo) => ProviderScope(
  overrides: [
    keyValueStoreProvider.overrideWithValue(
      MemoryKeyValueStore({'locale': 'en'}),
    ),
    moveOutRepositoryProvider.overrideWithValue(repo),
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
  setUpAll(() => registerFallbackValue(DeductionKind.other));

  test('move-out parses deductions and the deposit method', () {
    final m = MoveOut.fromJson(moveOutJson());
    expect(m.settled, isFalse);
    expect(m.deductions.first.fromCharge, isTrue);
    expect(m.deductions.last.kind, DeductionKind.cleaning);
    expect(m.deductionsTotal, 1050000);
    expect(PaymentMethod.parse('deposit'), PaymentMethod.deposit);
  });

  test('settling sends the refund method and the notify flag', () async {
    final dio = MockDio();
    when(() => dio.post('/move-outs/4/settle', data: any(named: 'data')))
        .thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/move-outs/4/settle'),
            data: {'data': moveOutJson(settled: true)},
          ),
        );

    await MoveOutRepository(ApiClient(dio)).settle(
      4,
      refundMethod: 'telebirr',
      refundReference: '',
      notifyTenant: false,
    );

    expect(
      verify(
        () => dio.post('/move-outs/4/settle', data: captureAny(named: 'data')),
      ).captured.single,
      {'refund_method': 'telebirr', 'notify_tenant': false},
    );
  });

  testWidgets('draft move-out: add a deduction and settle with a refund', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = MockMoveOutRepository();
    when(() => repo.get(4))
        .thenAnswer((_) async => MoveOut.fromJson(moveOutJson()));
    when(
      () => repo.addDeduction(
        4,
        kind: any(named: 'kind'),
        description: any(named: 'description'),
        amount: any(named: 'amount'),
      ),
    ).thenAnswer((_) async => MoveOut.fromJson(moveOutJson()));
    when(
      () => repo.settle(
        4,
        refundMethod: any(named: 'refundMethod'),
        refundReference: any(named: 'refundReference'),
        notifyTenant: any(named: 'notifyTenant'),
      ),
    ).thenAnswer((_) async => MoveOut.fromJson(moveOutJson(settled: true)));

    await tester.pumpWidget(harness(const MoveOutScreen(moveOutId: 4), repo));
    await tester.pumpAndSettle();

    expect(find.text('Almaz Tesfaye · Room 1'), findsOneWidget);
    expect(find.text('November 2026'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('refundAmount'))).data,
      'Br 9,500',
    );
    // Unpaid rent can't be removed; the cleaning deduction can.
    expect(
      find.descendant(
        of: find.byKey(const Key('deduction-1')),
        matching: find.byIcon(Icons.close),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('deduction-2')),
        matching: find.byIcon(Icons.close),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('addDeduction')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('deductionDescriptionField')),
      'Repaint wall',
    );
    await tester.enterText(
      find.byKey(const Key('deductionAmountField')),
      '1500',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    verify(
      () => repo.addDeduction(
        4,
        kind: DeductionKind.damage,
        description: 'Repaint wall',
        amount: 150000,
      ),
    ).called(1);

    await tester.tap(find.byKey(const Key('settleMoveOut')));
    await tester.pumpAndSettle();
    expect(find.text('Refund to the tenant: Br 9,500'), findsOneWidget);
    await tester.tap(find.text('Telebirr'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settle'));
    await tester.pumpAndSettle();

    verify(
      () => repo.settle(
        4,
        refundMethod: 'telebirr',
        refundReference: '',
        notifyTenant: true,
      ),
    ).called(1);
  });

  testWidgets('settled move-out is read-only and can resend the statement', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = MockMoveOutRepository();
    when(() => repo.get(4))
        .thenAnswer((_) async => MoveOut.fromJson(moveOutJson(settled: true)));
    when(() => repo.sendStatement(4)).thenAnswer((_) async {});

    await tester.pumpWidget(harness(const MoveOutScreen(moveOutId: 4), repo));
    await tester.pumpAndSettle();

    expect(find.text('Settled. The lease has ended.'), findsOneWidget);
    expect(find.text('Refunded by Telebirr · TX123'), findsOneWidget);
    expect(find.byKey(const Key('settleMoveOut')), findsNothing);
    expect(find.byKey(const Key('addDeduction')), findsNothing);
    expect(find.byKey(const Key('listUnitAfterMoveOut')), findsOneWidget);

    await tester.tap(find.byKey(const Key('sendStatement')));
    await tester.pumpAndSettle();
    verify(() => repo.sendStatement(4)).called(1);
    expect(find.text('Statement sent to the tenant.'), findsOneWidget);
  });
}
