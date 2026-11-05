import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landlord_app/app.dart';
import 'package:landlord_app/core/storage/secure_store.dart';
import 'package:landlord_app/features/auth/data/auth_repository.dart';
import 'package:landlord_app/features/auth/domain/app_user.dart';
import 'package:landlord_app/features/properties/data/properties_repository.dart';
import 'package:landlord_app/features/properties/domain/property.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockPropertiesRepository extends Mock implements PropertiesRepository {}

void main() {
  late MockAuthRepository auth;
  late MockPropertiesRepository properties;

  setUp(() {
    auth = MockAuthRepository();
    properties = MockPropertiesRepository();
    when(() => properties.list()).thenAnswer((_) async => const <Property>[]);
  });

  Widget app({Map<String, String>? stored}) => ProviderScope(
    overrides: [
      keyValueStoreProvider.overrideWithValue(MemoryKeyValueStore(stored)),
      authRepositoryProvider.overrideWithValue(auth),
      propertiesRepositoryProvider.overrideWithValue(properties),
    ],
    child: const KirayApp(),
  );

  testWidgets(
    'shows the login screen in Amharic by default and validates the phone',
    (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.text('በስልክዎ ይግቡ'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('phoneField')), '12345');
      await tester.tap(find.byKey(const Key('sendCodeButton')));
      await tester.pumpAndSettle();

      expect(find.textContaining('የኢትዮጵያ ሞባይል ቁጥር'), findsOneWidget);
      verifyNever(() => auth.requestCode(any(), locale: any(named: 'locale')));
    },
  );

  testWidgets('switches to English', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Log in with your phone'), findsOneWidget);
  });

  testWidgets('phone and code log the landlord in', (tester) async {
    when(() => auth.requestCode('+251911234567', locale: 'en'))
        .thenAnswer((_) async {});
    when(() => auth.verify('+251911234567', '123456', locale: 'en')).thenAnswer(
      (_) async => const LoginResult(
        token: '1|abc',
        isNew: true,
        user: AppUser(
          id: 1,
          phone: '+251911234567',
          name: 'Abel',
          locale: 'en',
        ),
      ),
    );

    await tester.pumpWidget(app(stored: {'locale': 'en'}));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('phoneField')), '0911 234 567');
    await tester.tap(find.byKey(const Key('sendCodeButton')));
    await tester.pumpAndSettle();

    expect(find.text('We sent a code to 0911 234 567.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('codeField')), '123456');
    await tester.pumpAndSettle();

    expect(find.text('Welcome, Abel'), findsOneWidget);
    expect(find.text('Properties'), findsWidgets);
  });

  testWidgets('a stored token opens the dashboard directly', (tester) async {
    when(() => auth.me()).thenAnswer(
      (_) async => const AppUser(id: 1, phone: '+251911234567', name: 'Abel'),
    );

    await tester.pumpWidget(
      app(stored: {'auth_token': '1|abc', 'locale': 'en'}),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome, Abel'), findsOneWidget);
  });
}
