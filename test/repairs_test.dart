import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landlord_app/core/api/api_client.dart';
import 'package:landlord_app/core/storage/secure_store.dart';
import 'package:landlord_app/features/repairs/data/repairs_repository.dart';
import 'package:landlord_app/features/repairs/domain/repair.dart';
import 'package:landlord_app/features/repairs/presentation/repair_detail_screen.dart';
import 'package:landlord_app/features/repairs/presentation/repairs_screen.dart';
import 'package:landlord_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockRepairsRepository extends Mock implements RepairsRepository {}

Map<String, dynamic> repairJson({
  String status = 'open',
  String category = 'plumbing',
  String source = 'tenant',
}) => {
  'id': 5,
  'unit_id': 3,
  'lease_id': 7,
  'title': 'Kitchen sink leaking',
  'category': category,
  'description': 'Water under the sink',
  'resolution_note': null,
  'status': status,
  'source': source,
  'opened_at': '2026-11-14T08:00:00.000000Z',
  'closed_at': null,
  'unit': {'id': 3, 'label': 'Room 3', 'property_name': 'Bole Compound'},
  'tenant': {'id': 4, 'full_name': 'Almaz Tesfaye', 'phone': '+251911234567'},
  'photos_count': 1,
  'photos': [],
};

Widget harness(Widget child, MockRepairsRepository repo) => ProviderScope(
  overrides: [
    keyValueStoreProvider.overrideWithValue(
      MemoryKeyValueStore({'locale': 'en'}),
    ),
    repairsRepositoryProvider.overrideWithValue(repo),
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

void main() {
  setUpAll(() => registerFallbackValue(RepairStatus.open));

  test('repair JSON maps API values', () {
    final r = Repair.fromJson(
      repairJson(status: 'in_progress', category: 'door_lock'),
    );
    expect(r.status, RepairStatus.inProgress);
    expect(r.category, RepairCategory.doorLock);
    expect(r.category.apiValue, 'door_lock');
    expect(r.fromTenant, isTrue);
    expect(r.tenantName, 'Almaz Tesfaye');
  });

  test('status update sends API value, note and SMS flag', () async {
    final dio = MockDio();
    when(() => dio.patch('/maintenance/5', data: any(named: 'data')))
        .thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/maintenance/5'),
            data: {'data': repairJson(status: 'in_progress')},
          ),
        );

    await RepairsRepository(ApiClient(dio))
        .updateStatus(5, RepairStatus.inProgress, note: 'Plumber at 3pm');

    final sent =
        verify(
              () =>
                  dio.patch('/maintenance/5', data: captureAny(named: 'data')),
            ).captured.single
            as Map;
    expect(sent, {
      'status': 'in_progress',
      'note': 'Plumber at 3pm',
      'notify_tenant': true,
    });
  });

  test('creating a repair posts multipart form data', () async {
    final dio = MockDio();
    when(() => dio.post('/maintenance', data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/maintenance'),
        statusCode: 201,
        data: {'data': repairJson(source: 'landlord')},
      ),
    );

    await RepairsRepository(ApiClient(dio)).create(
      unitId: 3,
      title: 'Broken lock',
      category: RepairCategory.doorLock,
    );

    final form =
        verify(() => dio.post('/maintenance', data: captureAny(named: 'data')))
                .captured
                .single
            as FormData;
    final fields = Map.fromEntries(form.fields);
    expect(fields['unit_id'], '3');
    expect(fields['category'], 'door_lock');
    expect(form.files, isEmpty);
  });

  testWidgets('repairs tab lists requests and switches filter', (tester) async {
    final repo = MockRepairsRepository();
    when(() => repo.list(status: 'active'))
        .thenAnswer((_) async => [Repair.fromJson(repairJson())]);
    when(() => repo.list(status: 'done')).thenAnswer((_) async => []);

    await tester.pumpWidget(harness(const RepairsScreen(), repo));
    await tester.pumpAndSettle();

    expect(find.text('Kitchen sink leaking'), findsOneWidget);
    expect(find.textContaining('From tenant'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Done'));
    await tester.pumpAndSettle();

    expect(find.text('No repairs here.'), findsOneWidget);
    verify(() => repo.list(status: 'done')).called(1);
  });

  testWidgets('starting work asks for a note and texts the tenant', (
    tester,
  ) async {
    final repo = MockRepairsRepository();
    when(() => repo.get(5))
        .thenAnswer((_) async => Repair.fromJson(repairJson()));
    when(
      () => repo.updateStatus(
        any(),
        any(),
        note: any(named: 'note'),
        notifyTenant: any(named: 'notifyTenant'),
      ),
    ).thenAnswer(
      (_) async => Repair.fromJson(repairJson(status: 'in_progress')),
    );

    await tester.pumpWidget(
      harness(const RepairDetailScreen(repairId: 5), repo),
    );
    await tester.pumpAndSettle();

    expect(find.text('Water under the sink'), findsOneWidget);

    await tester.tap(find.byKey(const Key('startRepair')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('repairNoteField')),
      'Plumber at 3pm',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    verify(
      () => repo.updateStatus(
        5,
        RepairStatus.inProgress,
        note: 'Plumber at 3pm',
        notifyTenant: true,
      ),
    ).called(1);
  });
}
