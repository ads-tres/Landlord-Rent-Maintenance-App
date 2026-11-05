import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landlord_app/core/storage/secure_store.dart';
import 'package:landlord_app/features/auth/data/auth_repository.dart';
import 'package:landlord_app/features/auth/domain/app_user.dart';
import 'package:landlord_app/features/home/settings_screen.dart';
import 'package:landlord_app/features/repairs/data/repairs_repository.dart';
import 'package:landlord_app/features/repairs/domain/repair.dart';
import 'package:landlord_app/features/repairs/presentation/repair_detail_screen.dart';
import 'package:landlord_app/features/tenants/data/tenants_repository.dart';
import 'package:landlord_app/features/tenants/domain/tenant.dart';
import 'package:landlord_app/features/tenants/presentation/tenants_screen.dart';
import 'package:landlord_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockTenantsRepository extends Mock implements TenantsRepository {}

class MockRepairsRepository extends Mock implements RepairsRepository {}

Widget harness(Widget child, List overrides) => ProviderScope(
  overrides: [
    keyValueStoreProvider.overrideWithValue(
      MemoryKeyValueStore({'locale': 'en', 'auth_token': 't'}),
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

AppUser user({bool available = true, bool linked = false}) => AppUser.fromJson({
  'id': 1,
  'phone': '+251911000000',
  'name': 'Abel',
  'locale': 'en',
  'calendar_pref': 'ethiopian',
  'sms_reminders': true,
  'telegram_linked': linked,
  'telegram_available': available,
});

void main() {
  test('profile JSON carries Telegram state', () {
    expect(user(linked: true).telegramLinked, isTrue);
    // Regression: the SMS reminders setting used to be ignored when parsing.
    expect(
      AppUser.fromJson({
        'id': 1,
        'phone': '+251911000000',
        'sms_reminders': false,
      }).smsReminders,
      isFalse,
    );
    expect(
      AppUser.fromJson({'id': 1, 'phone': '+251911000000'}).telegramAvailable,
      isFalse,
    );
  });

  testWidgets(
    'settings offers Connect Telegram only when the server has a bot',
    (tester) async {
      final auth = MockAuthRepository();
      when(() => auth.me()).thenAnswer((_) async => user());

      await tester.pumpWidget(
        harness(const SettingsScreen(), [
          authRepositoryProvider.overrideWithValue(auth),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.text('Connect Telegram'), findsOneWidget);
      expect(
        find.text('Get an alert when a tenant reports a repair'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'settings shows connected state, and hides the tile without a bot',
    (tester) async {
      final auth = MockAuthRepository();
      when(() => auth.me()).thenAnswer((_) async => user(linked: true));

      await tester.pumpWidget(
        harness(const SettingsScreen(), [
          authRepositoryProvider.overrideWithValue(auth),
        ]),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Connected: repair alerts come to Telegram'),
        findsOneWidget,
      );
    },
  );

  testWidgets('settings hides Telegram when the server has no bot', (
    tester,
  ) async {
    final auth = MockAuthRepository();
    when(() => auth.me()).thenAnswer((_) async => user(available: false));

    await tester.pumpWidget(
      harness(const SettingsScreen(), [
        authRepositoryProvider.overrideWithValue(auth),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('telegramTile')), findsNothing);
  });

  testWidgets('tenants on Telegram get a badge', (tester) async {
    final tenants = MockTenantsRepository();
    when(() => tenants.list(query: any(named: 'query'))).thenAnswer(
      (_) async => [
        Tenant.fromJson({
          'id': 1,
          'full_name': 'Almaz',
          'phone': '+251911234567',
          'telegram_linked': true,
        }),
        Tenant.fromJson({
          'id': 2,
          'full_name': 'Dawit',
          'phone': '+251922334455',
        }),
      ],
    );

    await tester.pumpWidget(
      harness(const TenantsScreen(), [
        tenantsRepositoryProvider.overrideWithValue(tenants),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.telegram), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is Icon && w.semanticLabel == 'Gets messages on Telegram',
      ),
      findsOneWidget,
    );
  });

  testWidgets('repair detail lists voice notes from Telegram', (tester) async {
    final repairs = MockRepairsRepository();
    when(() => repairs.get(5)).thenAnswer(
      (_) async => Repair.fromJson({
        'id': 5,
        'unit_id': 3,
        'title': 'Voice note from Telegram',
        'category': 'other',
        'status': 'open',
        'source': 'tenant',
        'opened_at': '2026-11-14T08:00:00Z',
        'photos': [],
        'voice_notes': [
          {
            'id': 9,
            'url': 'https://api.test/api/v1/attachments/9/signed?signature=abc',
          },
        ],
      }),
    );

    await tester.pumpWidget(
      harness(const RepairDetailScreen(repairId: 5), [
        repairsRepositoryProvider.overrideWithValue(repairs),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Voice notes'), findsOneWidget);
    expect(find.text('Voice note 1'), findsOneWidget);
  });
}
