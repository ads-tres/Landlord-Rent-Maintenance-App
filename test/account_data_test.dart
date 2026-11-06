import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landlord_app/core/storage/secure_store.dart';
import 'package:landlord_app/features/auth/data/auth_repository.dart';
import 'package:landlord_app/features/auth/domain/app_user.dart';
import 'package:landlord_app/features/home/settings_screen.dart';
import 'package:landlord_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

AppUser user({String? deletion, String role = 'landlord'}) => AppUser.fromJson({
  'id': 1,
  'phone': '+251911000000',
  'name': 'Abel Kebede',
  'role': role,
  'deletion_scheduled_for': deletion,
});

Widget harness(MockAuthRepository auth) => ProviderScope(
  overrides: [
    keyValueStoreProvider.overrideWithValue(
      MemoryKeyValueStore({'locale': 'en', 'auth_token': 't'}),
    ),
    authRepositoryProvider.overrideWithValue(auth),
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
    home: SettingsScreen(),
  ),
);

void bigScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  test('reads the scheduled deletion date', () {
    expect(
      user(deletion: '2026-12-06').deletionScheduledFor,
      DateTime(2026, 12, 6),
    );
    expect(user().deletionScheduledFor, isNull);
  });

  testWidgets('landlord asks to delete after typing their phone', (
    tester,
  ) async {
    bigScreen(tester);
    final auth = MockAuthRepository();
    when(auth.me).thenAnswer((_) async => user());
    when(() => auth.requestDeletion(any()))
        .thenAnswer((_) async => user(deletion: '2026-12-06'));

    await tester.pumpWidget(harness(auth));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('exportData')), findsOneWidget);

    await tester.tap(find.byKey(const Key('deleteAccount')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('confirmPhoneField')),
      '0911000000',
    );
    await tester.tap(find.text('Delete in 30 days'));
    await tester.pumpAndSettle();

    verify(() => auth.requestDeletion('0911000000')).called(1);
    expect(find.byKey(const Key('deletionBanner')), findsOneWidget);
    expect(find.byKey(const Key('deleteAccount')), findsNothing);
  });

  testWidgets('landlord keeps the account', (tester) async {
    bigScreen(tester);
    final auth = MockAuthRepository();
    when(auth.me).thenAnswer((_) async => user(deletion: '2026-12-06'));
    when(auth.cancelDeletion).thenAnswer((_) async => user());

    await tester.pumpWidget(harness(auth));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cancelDeletion')));
    await tester.pumpAndSettle();

    verify(auth.cancelDeletion).called(1);
    expect(find.byKey(const Key('deletionBanner')), findsNothing);
    expect(find.byKey(const Key('deleteAccount')), findsOneWidget);
  });

  testWidgets('caretakers do not see it', (tester) async {
    bigScreen(tester);
    final auth = MockAuthRepository();
    when(auth.me).thenAnswer((_) async => user(role: 'caretaker'));
    await tester.pumpWidget(harness(auth));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('exportData')), findsNothing);
    expect(find.byKey(const Key('deleteAccount')), findsNothing);
  });
}
