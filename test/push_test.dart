import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landlord_app/core/offline/response_cache.dart';
import 'package:landlord_app/core/push/push_registrar.dart';
import 'package:landlord_app/core/push/push_service.dart';
import 'package:landlord_app/core/storage/secure_store.dart';
import 'package:landlord_app/features/auth/application/auth_controller.dart';
import 'package:landlord_app/features/auth/data/auth_repository.dart';
import 'package:landlord_app/features/auth/domain/app_user.dart';
import 'package:landlord_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class FakePush implements PushService {
  final messagesController = StreamController<PushMessage>.broadcast();
  final refreshController = StreamController<String>.broadcast();
  String? currentToken = 'phone-token-1';

  @override
  Future<String?> token() async => currentToken;

  @override
  Stream<String> get onTokenRefresh => refreshController.stream;

  @override
  Stream<PushMessage> get messages => messagesController.stream;
}

class FakeAuth extends AuthController {
  FakeAuth(this.user);

  final AppUser? user;

  @override
  Future<AppUser?> build() async => user;
}

const landlord = AppUser(id: 1, phone: '+251911000001', pushAvailable: true);

void main() {
  late MockAuthRepository repo;
  late FakePush push;
  final messengerKey = GlobalKey<ScaffoldMessengerState>();

  setUp(() {
    repo = MockAuthRepository();
    push = FakePush();
    when(() => repo.registerDevice(any())).thenAnswer((_) async {});
    when(() => repo.unregisterDevice(any())).thenAnswer((_) async {});
    when(repo.logout).thenAnswer((_) async {});
  });

  Widget app(AppUser? user) => ProviderScope(
    overrides: [
      keyValueStoreProvider.overrideWithValue(
        MemoryKeyValueStore({'locale': 'en'}),
      ),
      authRepositoryProvider.overrideWithValue(repo),
      pushServiceProvider.overrideWithValue(push),
      authControllerProvider.overrideWith(() => FakeAuth(user)),
    ],
    child: MaterialApp(
      scaffoldMessengerKey: messengerKey,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: PushRegistrar(
        messengerKey: messengerKey,
        child: const Scaffold(body: Text('home')),
      ),
    ),
  );

  testWidgets('logged-in landlord registers the phone', (tester) async {
    await tester.pumpWidget(app(landlord));
    await tester.pumpAndSettle();
    verify(() => repo.registerDevice('phone-token-1')).called(1);

    // A refreshed token is registered too.
    push.refreshController.add('phone-token-2');
    await tester.pumpAndSettle();
    verify(() => repo.registerDevice('phone-token-2')).called(1);
  });

  testWidgets('nothing is registered when push is off or unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const AppUser(
          id: 1,
          phone: '+251911000001',
          pushAvailable: true,
          pushEnabled: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(app(const AppUser(id: 1, phone: '+251911000001')));
    await tester.pumpAndSettle();
    await tester.pumpWidget(app(null));
    await tester.pumpAndSettle();
    verifyNever(() => repo.registerDevice(any()));
  });

  testWidgets('an alert that arrives while the app is open shows a snackbar', (
    tester,
  ) async {
    await tester.pumpWidget(app(landlord));
    await tester.pumpAndSettle();

    push.messagesController.add((
      body: 'New repair for Room 1: No water',
      route: '/repairs/5',
      opened: false,
    ));
    await tester.pumpAndSettle();
    expect(find.text('New repair for Room 1: No water'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
  });

  test('logging out unregisters the phone first', () async {
    final container = ProviderContainer(
      overrides: [
        keyValueStoreProvider.overrideWithValue(
          MemoryKeyValueStore({'locale': 'en'}),
        ),
        authRepositoryProvider.overrideWithValue(repo),
        pushServiceProvider.overrideWithValue(push),
        authControllerProvider.overrideWith(() => FakeAuth(landlord)),
        cacheStoreProvider.overrideWithValue(MemoryCacheStore()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.future);
    await container.read(authControllerProvider.notifier).logout();

    verifyInOrder([
      () => repo.unregisterDevice('phone-token-1'),
      () => repo.logout(),
    ]);
    expect(container.read(authControllerProvider).value, isNull);
  });
}
