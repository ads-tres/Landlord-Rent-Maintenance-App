import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:landlord_app/core/storage/secure_store.dart';
import 'package:landlord_app/features/onboarding/data/onboarding_repository.dart';
import 'package:landlord_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:landlord_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockOnboardingRepository extends Mock implements OnboardingRepository {}

Onboarding onboarding({bool dismissed = false, bool completed = false}) =>
    Onboarding.fromJson({
      'steps': [
        {'key': 'profile', 'done': true, 'optional': false},
        {'key': 'property', 'done': true, 'optional': false},
        {'key': 'units', 'done': false, 'optional': false},
        {'key': 'telegram', 'done': false, 'optional': true},
      ],
      'done_count': completed ? 3 : 2,
      'total': 3,
      'completed': completed,
      'dismissed': dismissed,
      'first_lease_id': null,
    });

Widget app(
  MockOnboardingRepository repo,
  Widget home, {
  List<String>? visited,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      GoRoute(path: '/setup', builder: (_, _) => const OnboardingScreen()),
      GoRoute(
        path: '/properties',
        builder: (_, _) {
          visited?.add('/properties');
          return const Text('properties');
        },
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      keyValueStoreProvider.overrideWithValue(
        MemoryKeyValueStore({'locale': 'en'}),
      ),
      onboardingRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp.router(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    ),
  );
}

void main() {
  testWidgets('home card shows progress and opens the checklist', (
    tester,
  ) async {
    final repo = MockOnboardingRepository();
    when(repo.get).thenAnswer((_) async => onboarding());
    final visited = <String>[];

    await tester.pumpWidget(
      app(repo, const Scaffold(body: OnboardingCard()), visited: visited),
    );
    await tester.pumpAndSettle();
    expect(find.text('2 of 3 done'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboardingCard')));
    await tester.pumpAndSettle();
    expect(find.text('Add the rooms or apartments'), findsOneWidget);
    expect(find.text('Connect Telegram (optional)'), findsOneWidget);

    // A done step can't be tapped; an open one goes to the right screen.
    await tester.tap(find.byKey(const Key('setupStep-units')));
    await tester.pumpAndSettle();
    expect(visited, ['/properties']);
  });

  testWidgets('card is hidden once dismissed or complete', (tester) async {
    for (final o in [
      onboarding(dismissed: true),
      onboarding(completed: true),
    ]) {
      final repo = MockOnboardingRepository();
      when(repo.get).thenAnswer((_) async => o);
      await tester.pumpWidget(
        app(repo, const Scaffold(body: OnboardingCard())),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('onboardingCard')), findsNothing);
    }
  });

  testWidgets('hide dismisses the checklist', (tester) async {
    final repo = MockOnboardingRepository();
    when(repo.get).thenAnswer((_) async => onboarding());
    when(repo.dismiss).thenAnswer((_) async => onboarding(dismissed: true));

    await tester.pumpWidget(app(repo, const Scaffold(body: OnboardingCard())));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboardingCard')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('hideSetup')));
    await tester.pumpAndSettle();
    verify(repo.dismiss).called(1);
  });
}
