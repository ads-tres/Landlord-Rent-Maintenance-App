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

AppUser user({String? id, String? address, String role = 'landlord'}) =>
    AppUser.fromJson({
      'id': 1,
      'phone': '+251911000000',
      'name': 'Abel Kebede',
      'role': role,
      'id_number': id,
      'address': address,
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

void main() {
  test('profile reads ID number and address', () {
    final u = user(id: 'AA-998877', address: 'Bole');
    expect(u.idNumber, 'AA-998877');
    expect(u.address, 'Bole');
  });

  testWidgets('landlord saves details for documents', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final auth = MockAuthRepository();
    when(auth.me).thenAnswer((_) async => user());
    when(
      () => auth.updateMe(
        name: any(named: 'name'),
        idNumber: any(named: 'idNumber'),
        address: any(named: 'address'),
      ),
    ).thenAnswer(
      (_) async => user(id: 'AA-998877', address: 'Bole, Woreda 03'),
    );

    await tester.pumpWidget(harness(auth));
    await tester.pumpAndSettle();
    expect(
      find.text(
        "Add your ID number and address so agreements don't print blanks.",
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('documentDetails')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('profileIdField')),
      'AA-998877',
    );
    await tester.enterText(
      find.byKey(const Key('profileAddressField')),
      'Bole, Woreda 03',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    verify(
      () => auth.updateMe(
        name: 'Abel Kebede',
        idNumber: 'AA-998877',
        address: 'Bole, Woreda 03',
      ),
    ).called(1);
    expect(
      find.text(
        'Your name, ID number and address, printed on lease agreements and letters.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('caretakers do not see it', (tester) async {
    final auth = MockAuthRepository();
    when(auth.me).thenAnswer((_) async => user(role: 'caretaker'));
    await tester.pumpWidget(harness(auth));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('documentDetails')), findsNothing);
  });
}
