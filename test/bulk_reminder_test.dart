import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landlord_app/core/storage/secure_store.dart';
import 'package:landlord_app/features/rent/data/reminders_repository.dart';
import 'package:landlord_app/features/rent/domain/bulk_reminder.dart';
import 'package:landlord_app/features/rent/presentation/bulk_reminder_sheet.dart';
import 'package:landlord_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockRemindersRepository extends Mock implements RemindersRepository {}

final previewJson = {
  'period': '2026-11',
  'will_send': 2,
  'skipped': 1,
  'total_owed': 2600000,
  'sample':
      'Rent of Br 10,000 for Room A (November 2026) is still unpaid. - Abel',
  'items': [
    {
      'lease_id': 1,
      'tenant': 'Tenant A',
      'unit': 'Room A',
      'property': 'Bole House',
      'owed': 1000000,
      'due_date': '2026-11-05',
      'skip': null,
    },
    {
      'lease_id': 2,
      'tenant': 'Tenant B',
      'unit': 'Room B',
      'property': 'Bole House',
      'owed': 600000,
      'due_date': '2026-11-05',
      'skip': null,
    },
    {
      'lease_id': 4,
      'tenant': 'Tenant D',
      'unit': 'Room D',
      'property': 'Bole House',
      'owed': 1000000,
      'due_date': '2026-11-05',
      'skip': 'opted_out',
    },
  ],
};

void main() {
  testWidgets('preview shows the message and sends to the ticked tenants', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = MockRemindersRepository();
    when(() => repo.preview('2026-11'))
        .thenAnswer((_) async => ReminderPreview.fromJson(previewJson));
    when(() => repo.send('2026-11', any())).thenAnswer((_) async => 1);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(
            MemoryKeyValueStore({'locale': 'en'}),
          ),
          remindersRepositoryProvider.overrideWithValue(repo),
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
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showBulkReminderSheet(context, DateTime(2026, 11)),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sampleSms')), findsOneWidget);
    expect(find.textContaining('owed by 3 tenants'), findsOneWidget);
    expect(find.textContaining('turned reminders off'), findsOneWidget);
    expect(find.text('Send 2 reminders'), findsOneWidget);

    // Leave Tenant A out.
    await tester.tap(find.byKey(const Key('remind-1')));
    await tester.pump();
    expect(find.text('Send 1 reminder'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sendReminders')));
    await tester.pumpAndSettle();
    expect(find.text('Text 1 tenant now?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirmSendReminders')));
    await tester.pumpAndSettle();

    verify(() => repo.send('2026-11', [2])).called(1);
    expect(find.text('1 reminder sent'), findsOneWidget);
    expect(find.byKey(const Key('sampleSms')), findsNothing);
  });
}
