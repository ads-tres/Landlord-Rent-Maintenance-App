import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landlord_app/core/api/api_client.dart';
import 'package:landlord_app/core/api/api_exception.dart';
import 'package:landlord_app/core/offline/outbox.dart';
import 'package:landlord_app/core/storage/secure_store.dart';
import 'package:landlord_app/features/home/presentation/sync_screen.dart';
import 'package:landlord_app/features/repairs/data/repairs_repository.dart';
import 'package:landlord_app/features/repairs/domain/repair.dart';
import 'package:landlord_app/features/repairs/presentation/add_repair_screen.dart';
import 'package:landlord_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockRepairsRepository extends Mock implements RepairsRepository {}

/// Keeps "photos" as-is and remembers what was removed.
class FakeFiles implements OutboxFiles {
  final kept = <String>[];
  final removed = <String>[];

  @override
  Future<String> keep(String path) async {
    kept.add(path);
    return 'kept/$path';
  }

  @override
  Future<void> remove(List<String> paths) async => removed.addAll(paths);
}

OutboxItem repair(String ref, {List<String> photos = const []}) => OutboxItem(
  kind: OutboxKind.repair,
  clientRef: ref,
  fields: {'unit_id': 3, 'title': 'Leaking tap', 'category': 'plumbing'},
  title: 'Leaking tap',
  subtitle: 'Unit 3',
  createdAt: DateTime(2026, 11, 6),
  photos: photos,
);

OutboxItem expense(String ref) => OutboxItem(
  kind: OutboxKind.expense,
  clientRef: ref,
  fields: {'property_id': 1, 'category': 'repair', 'amount': 150000},
  title: 'Repair · Br 1,500',
  createdAt: DateTime(2026, 11, 6),
);

ApiException offline() =>
    ApiException(message: 'offline', isNetworkError: true);

void main() {
  late MemoryKeyValueStore store;
  late FakeFiles files;
  late MockApiClient api;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(FormData());
    registerFallbackValue(RepairCategory.other);
  });

  setUp(() {
    store = MemoryKeyValueStore();
    files = FakeFiles();
    api = MockApiClient();
    container = ProviderContainer(
      overrides: [
        keyValueStoreProvider.overrideWithValue(store),
        outboxFilesProvider.overrideWithValue(files),
        apiClientProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);
  });

  Outbox outbox() => container.read(outboxProvider.notifier);

  test('saved items survive a restart, with their photos kept', () async {
    await container.read(outboxProvider.future);
    await outbox().add(repair('r1', photos: ['/tmp/a.jpg']));

    expect(files.kept, ['/tmp/a.jpg']);
    expect(await store.read(outboxKey), contains('kept//tmp/a.jpg'));

    final fresh = ProviderContainer(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
    );
    addTearDown(fresh.dispose);
    final items = await fresh.read(outboxProvider.future);
    expect(items.single.clientRef, 'r1');
    expect(items.single.subtitle, 'Unit 3');
  });

  test('sync sends each item once with its client_ref', () async {
    final sent = <(String, Map<String, dynamic>)>[];
    when(() => api.post(any(), data: any(named: 'data')))
        .thenAnswer((inv) async {
          final form = inv.namedArguments[#data] as FormData;
          sent.add((
            inv.positionalArguments.first as String,
            {for (final f in form.fields) f.key: f.value},
          ));
          return {'data': {}};
        });
    await container.read(outboxProvider.future);
    await outbox().add(repair('r1'));
    await outbox().add(expense('e1'));

    final before = container.read(outboxSyncedProvider);
    expect(await outbox().sync(), 2);

    expect(sent.map((s) => s.$1), ['/maintenance', '/expenses']);
    expect(sent.first.$2['client_ref'], 'r1');
    expect(sent.first.$2['title'], 'Leaking tap');
    expect(sent.last.$2['amount'], '150000');
    expect(container.read(outboxProvider).value, isEmpty);
    expect(await store.read(outboxKey), isNull);
    expect(container.read(outboxSyncedProvider), before + 1);
  });

  test('still offline: stops and keeps everything', () async {
    when(() => api.post(any(), data: any(named: 'data'))).thenThrow(offline());
    await container.read(outboxProvider.future);
    await outbox().add(repair('r1'));
    await outbox().add(repair('r2'));

    expect(await outbox().sync(), 0);
    verify(() => api.post(any(), data: any(named: 'data'))).called(1);
    final items = container.read(outboxProvider).value!;
    expect(items.map((i) => i.clientRef), ['r1', 'r2']);
    expect(items.every((i) => i.lastError == null), isTrue);
  });

  test('a refused item keeps the reason and the rest still go', () async {
    var calls = 0;
    when(() => api.post(any(), data: any(named: 'data'))).thenAnswer((_) async {
      if (calls++ == 0) {
        throw ApiException(
          message: 'invalid',
          statusCode: 422,
          fieldErrors: {'unit_id': 'The selected unit is invalid.'},
        );
      }
      return {'data': {}};
    });
    await container.read(outboxProvider.future);
    await outbox().add(repair('r1', photos: ['/tmp/a.jpg']));
    await outbox().add(expense('e1'));

    expect(await outbox().sync(), 1);
    final left = container.read(outboxProvider).value!.single;
    expect(left.clientRef, 'r1');
    expect(left.lastError, 'The selected unit is invalid.');
    expect(files.removed, isEmpty);

    await outbox().discard('r1');
    expect(files.removed, ['kept//tmp/a.jpg']);
    expect(container.read(outboxProvider).value, isEmpty);
  });

  testWidgets('a repair logged with no connection is kept on the phone', (
    tester,
  ) async {
    final repairs = MockRepairsRepository();
    when(repairs.units).thenAnswer(
      (_) async => [
        const UnitOption(id: 3, label: 'Unit 3', propertyName: 'Bole House'),
      ],
    );
    when(
      () => repairs.create(
        unitId: any(named: 'unitId'),
        title: any(named: 'title'),
        category: any(named: 'category'),
        description: any(named: 'description'),
        photoPaths: any(named: 'photoPaths'),
        clientRef: any(named: 'clientRef'),
      ),
    ).thenThrow(offline());

    final kv = MemoryKeyValueStore({'locale': 'en'});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(kv),
          outboxFilesProvider.overrideWithValue(files),
          repairsRepositoryProvider.overrideWithValue(repairs),
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
          home: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  const QueuedEntries(kind: OutboxKind.repair),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AddRepairScreen(unitId: 3),
                      ),
                    ),
                    child: const Text('open'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Leaking tap');
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();

    expect(find.text('Saved on this phone'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.byType(AddRepairScreen), findsNothing);
    expect(find.text('Leaking tap'), findsOneWidget);
    expect(find.textContaining('Unit 3 · Bole House'), findsOneWidget);
    expect(await kv.read(outboxKey), contains('"unit_id":3'));
  });
}
