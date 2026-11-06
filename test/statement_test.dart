import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landlord_app/core/storage/secure_store.dart';
import 'package:landlord_app/features/leases/data/leases_repository.dart';
import 'package:landlord_app/features/leases/domain/statement.dart';
import 'package:landlord_app/features/leases/presentation/statement_screen.dart';
import 'package:landlord_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockLeasesRepository extends Mock implements LeasesRepository {}

final statement = LeaseStatementData.fromJson({
  'from': '2026-09-01',
  'to': '2026-12-10',
  'opening': 0,
  'charged': 4000000,
  'paid': 2500000,
  'closing': 1500000,
  'lines': [
    {
      'date': '2026-09-01',
      'kind': 'charge',
      'description': 'Rent for September 2026',
      'charge': 1000000,
      'payment': 0,
      'balance': 1000000,
    },
    {
      'date': '2026-10-05',
      'kind': 'payment',
      'description': 'Payment (Telebirr), receipt R-000002 · TB55',
      'charge': 0,
      'payment': 1500000,
      'balance': -500000,
    },
  ],
});

void main() {
  setUpAll(() => registerFallbackValue(DateTime(2026)));

  test('statement lines read charges and payments', () {
    expect(statement.lines.first.isPayment, isFalse);
    expect(statement.lines.last.isPayment, isTrue);
    expect(statement.lines.last.amount, 1500000);
    expect(statement.lines.last.balance, -500000);
  });

  testWidgets('shows the balance and switches period', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = MockLeasesRepository();
    when(
      () => repo.statement(
        7,
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => statement);

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
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const StatementScreen(leaseId: 7),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('closingBalance'))).data,
      'Br 15,000 owed',
    );
    expect(find.text('Rent for September 2026'), findsOneWidget);
    expect(find.textContaining('Br 5,000 paid ahead'), findsOneWidget);
    verify(() => repo.statement(7, from: null, to: null)).called(1);

    await tester.tap(find.text('This year'));
    await tester.pumpAndSettle();
    final captured = verify(
      () => repo.statement(
        7,
        from: captureAny(named: 'from'),
        to: captureAny(named: 'to'),
      ),
    ).captured;
    expect(captured.first, DateTime(DateTime.now().year));
  });
}
