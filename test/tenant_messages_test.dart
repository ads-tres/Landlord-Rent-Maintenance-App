import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landlord_app/core/storage/secure_store.dart';
import 'package:landlord_app/features/tenants/data/tenants_repository.dart';
import 'package:landlord_app/features/tenants/domain/tenant.dart';
import 'package:landlord_app/features/tenants/presentation/tenant_messages_screen.dart';
import 'package:landlord_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockTenantsRepository extends Mock implements TenantsRepository {}

Tenant tenant({bool optOut = false}) => Tenant.fromJson({
  'id': 4,
  'full_name': 'Almaz Tesfaye',
  'phone': '+251922000002',
  'reminders_opt_out': optOut,
});

void main() {
  test('message reads status, channel and quiet-hours time', () {
    final m = TenantMessage.fromJson({
      'kind': 'receipt',
      'channel': 'telegram',
      'status': 'queued',
      'body': 'Received Br 10,000',
      'created_at': '2026-11-28T19:30:00Z',
      'send_after': '2026-11-29T04:00:00Z',
    });
    expect(m.isTelegram, isTrue);
    expect(m.sendAfter, isNotNull);
    expect(tenant(optOut: true).remindersOptOut, isTrue);
  });

  testWidgets('shows the log and turns reminders off', (tester) async {
    final repo = MockTenantsRepository();
    var current = tenant();
    when(() => repo.get(4)).thenAnswer((_) async => current);
    when(() => repo.messages(4)).thenAnswer(
      (_) async => [
        TenantMessage.fromJson({
          'kind': 'receipt',
          'channel': 'sms',
          'status': 'sent',
          'body': 'Received Br 10,000 for Room 1',
          'created_at': '2026-11-28T07:30:00Z',
        }),
        TenantMessage.fromJson({
          'kind': 'reminder_before',
          'channel': 'sms',
          'status': 'failed',
          'body': 'Reminder: rent due',
          'error': 'Invalid number',
          'created_at': '2026-11-27T07:30:00Z',
        }),
      ],
    );
    when(() => repo.setRemindersOptOut(4, true)).thenAnswer((_) async {
      current = tenant(optOut: true);
      return current;
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(
            MemoryKeyValueStore({'locale': 'en'}),
          ),
          tenantsRepositoryProvider.overrideWithValue(repo),
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
          home: TenantMessagesScreen(tenantId: 4),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Received Br 10,000 for Room 1'), findsOneWidget);
    expect(find.text('Sent'), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
    expect(find.textContaining('Invalid number'), findsOneWidget);
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('remindersSwitch')))
          .value,
      isTrue,
    );

    await tester.tap(find.byKey(const Key('remindersSwitch')));
    await tester.pumpAndSettle();
    verify(() => repo.setRemindersOptOut(4, true)).called(1);
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('remindersSwitch')))
          .value,
      isFalse,
    );
  });
}
