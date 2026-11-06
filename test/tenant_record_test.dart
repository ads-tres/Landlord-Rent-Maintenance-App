import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landlord_app/core/storage/secure_store.dart';
import 'package:landlord_app/features/auth/data/auth_repository.dart';
import 'package:landlord_app/features/auth/domain/app_user.dart';
import 'package:landlord_app/features/listings/domain/listing.dart';
import 'package:landlord_app/features/tenants/data/tenants_repository.dart';
import 'package:landlord_app/features/tenants/domain/tenant.dart';
import 'package:landlord_app/features/tenants/domain/tenant_record.dart';
import 'package:landlord_app/features/tenants/presentation/tenant_record_screen.dart';
import 'package:landlord_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockTenantsRepository extends Mock implements TenantsRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

final recordJson = {
  'rating': 'poor',
  'charges': 5,
  'on_time': 1,
  'late': 3,
  'unpaid': 1,
  'on_time_percent': 20.0,
  'average_days_late': 14.7,
  'outstanding': 1000000,
  'leases': 1,
  'tenant_since': '2026-01-01',
  'recent': [
    {'period': '2026-01', 'status': 'on_time', 'days_late': null},
    {'period': '2026-02', 'status': 'late', 'days_late': 5},
    {'period': '2026-03', 'status': 'late', 'days_late': 10},
    {'period': '2026-04', 'status': 'late', 'days_late': 29},
    {'period': '2026-05', 'status': 'unpaid', 'days_late': 15},
  ],
  'notes': null,
};

Widget harness(MockTenantsRepository repo, {String role = 'landlord'}) {
  final auth = MockAuthRepository();
  when(auth.me).thenAnswer(
    (_) async =>
        AppUser.fromJson({'id': 1, 'phone': '+251911000000', 'role': role}),
  );
  return ProviderScope(
    overrides: [
      keyValueStoreProvider.overrideWithValue(
        MemoryKeyValueStore({'locale': 'en', 'auth_token': 't'}),
      ),
      authRepositoryProvider.overrideWithValue(auth),
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
      home: TenantRecordScreen(tenantId: 4),
    ),
  );
}

MockTenantsRepository repo({String? notes}) {
  final r = MockTenantsRepository();
  when(() => r.get(4)).thenAnswer(
    (_) async =>
        const Tenant(id: 4, fullName: 'Almaz Tesfaye', phone: '+251911223344'),
  );
  when(() => r.record(4)).thenAnswer(
    (_) async => TenantRecord.fromJson({...recordJson, 'notes': notes}),
  );
  return r;
}

void main() {
  test('record and application summary are read', () {
    final r = TenantRecord.fromJson(recordJson);
    expect(r.rating, PaymentRating.poor);
    expect(r.percentLabel, '20');
    expect(r.recent.last.status, 'unpaid');

    final a = ListingApplication.fromJson({
      'id': 1,
      'full_name': 'Almaz',
      'phone': '+251911223344',
      'status': 'new',
      'former_tenant': {
        'tenant_id': 4,
        'full_name': 'Almaz',
        'rating': 'good',
        'charges': 24,
        'on_time_percent': 95.8,
      },
    });
    expect(a.formerTenant!.rating, PaymentRating.good);
    expect(a.formerTenant!.percentLabel, '95.8');
  });

  testWidgets('record shows months and the landlord saves notes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final r = repo();
    when(() => r.saveNotes(4, any())).thenAnswer((_) async {});

    await tester.pumpWidget(harness(r));
    await tester.pumpAndSettle();

    expect(find.text('Almaz Tesfaye'), findsOneWidget);
    expect(find.textContaining('Often late · 20% on time'), findsOneWidget);
    expect(find.byKey(const Key('month-2026-05')), findsOneWidget);
    expect(find.textContaining('Owes'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tenantNotes')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('notesField')),
      'Calls before paying late.',
    );
    when(() => r.record(4)).thenAnswer(
      (_) async => TenantRecord.fromJson({
        ...recordJson,
        'notes': 'Calls before paying late.',
      }),
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    verify(() => r.saveNotes(4, 'Calls before paying late.')).called(1);
    expect(find.text('Calls before paying late.'), findsOneWidget);
  });

  testWidgets('caretakers do not see the notes', (tester) async {
    await tester.pumpWidget(harness(repo(), role: 'caretaker'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tenantNotes')), findsNothing);
  });
}
