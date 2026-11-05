import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landlord_app/core/api/api_exception.dart';
import 'package:landlord_app/core/offline/response_cache.dart';
import 'package:landlord_app/core/storage/secure_store.dart';
import 'package:landlord_app/features/payments/application/pending_payments.dart';
import 'package:landlord_app/features/payments/data/payments_repository.dart';
import 'package:landlord_app/features/payments/domain/payment.dart';
import 'package:mocktail/mocktail.dart';

class MockPaymentsRepository extends Mock implements PaymentsRepository {}

/// Answers requests from a script: data, or a connection error when null.
class ScriptedAdapter implements HttpClientAdapter {
  ScriptedAdapter(this.next);

  String? Function(RequestOptions) next;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = next(options);
    if (body == null) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

PendingPayment pending(String ref, {int amount = 1000000}) => PendingPayment(
  clientRef: ref,
  leaseId: 7,
  amount: amount,
  paidAt: DateTime(2026, 11, 14),
  method: PaymentMethod.cash,
  tenantName: 'Almaz',
);

Payment saved() => Payment(
  id: 1,
  receiptNumber: 'R-000001',
  amount: 1000000,
  paidAt: DateTime(2026, 11, 14),
  method: PaymentMethod.cash,
);

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(PaymentMethod.cash);
  });

  group('response cache', () {
    late MemoryCacheStore store;
    late List<bool> offlineChanges;
    late ScriptedAdapter adapter;
    late Dio dio;

    setUp(() {
      store = MemoryCacheStore();
      offlineChanges = [];
      adapter = ScriptedAdapter((_) => '{"data":[{"id":1}]}');
      dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter
        ..interceptors.add(
          ResponseCacheInterceptor(
            store: store,
            onOfflineChanged: offlineChanges.add,
          ),
        );
    });

    test('serves the saved copy when offline and flags offline', () async {
      final online = await dio.get('/tenants', queryParameters: {'q': 'al'});
      expect(online.data['data'][0]['id'], 1);
      await Future<void>.delayed(Duration.zero);

      adapter.next = (_) => null;
      final offline = await dio.get('/tenants', queryParameters: {'q': 'al'});

      expect(offline.data['data'][0]['id'], 1);
      expect(offline.extra['fromCache'], isTrue);
      expect(offlineChanges.last, isTrue);
    });

    test(
      'does not cache writes or unknown paths, and errors without a saved copy',
      () async {
        await dio.post('/payments', data: {});
        await dio.get('/auth/otp');
        await Future<void>.delayed(Duration.zero);
        expect(store.values, isEmpty);

        adapter.next = (_) => null;
        expect(() => dio.get('/charges'), throwsA(isA<DioException>()));
      },
    );
  });

  group('pending payments', () {
    late MockPaymentsRepository repo;
    late ProviderContainer container;

    setUp(() {
      repo = MockPaymentsRepository();
      container = ProviderContainer(
        overrides: [
          keyValueStoreProvider.overrideWithValue(MemoryKeyValueStore()),
          paymentsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
    });

    Future<void> create(String ref) =>
        container.read(pendingPaymentsProvider.notifier).add(pending(ref));

    When<Future<Payment>> whenCreate() => when(
      () => repo.create(
        leaseId: any(named: 'leaseId'),
        amount: any(named: 'amount'),
        paidAt: any(named: 'paidAt'),
        method: any(named: 'method'),
        reference: any(named: 'reference'),
        notes: any(named: 'notes'),
        sendSms: any(named: 'sendSms'),
        clientRef: any(named: 'clientRef'),
      ),
    );

    test(
      'sends saved payments with their client_ref and clears them',
      () async {
        await create('ref-1');
        await create('ref-2');
        whenCreate().thenAnswer((_) async => saved());

        final sent = await container
            .read(pendingPaymentsProvider.notifier)
            .sync();

        expect(sent, 2);
        expect(await container.read(pendingPaymentsProvider.future), isEmpty);
        verify(
          () => repo.create(
            leaseId: 7,
            amount: 1000000,
            paidAt: DateTime(2026, 11, 14),
            method: PaymentMethod.cash,
            reference: null,
            notes: null,
            sendSms: true,
            clientRef: 'ref-1',
          ),
        ).called(1);
      },
    );

    test('keeps payments while still offline', () async {
      await create('ref-1');
      whenCreate().thenThrow(
        ApiException(message: 'offline', isNetworkError: true),
      );

      expect(await container.read(pendingPaymentsProvider.notifier).sync(), 0);
      expect(
        (await container.read(pendingPaymentsProvider.future)).single.lastError,
        isNull,
      );
    });

    test(
      'marks payments the server refused so the landlord can fix them',
      () async {
        await create('ref-1');
        whenCreate().thenThrow(
          ApiException(
            message: 'invalid',
            statusCode: 422,
            fieldErrors: {'reference': 'The reference has already been taken.'},
          ),
        );

        await container.read(pendingPaymentsProvider.notifier).sync();

        expect(
          (await container.read(pendingPaymentsProvider.future))
              .single
              .lastError,
          'The reference has already been taken.',
        );
      },
    );

    test('survives an app restart and can be discarded', () async {
      final store = MemoryKeyValueStore();
      final first = ProviderContainer(
        overrides: [keyValueStoreProvider.overrideWithValue(store)],
      );
      await first.read(pendingPaymentsProvider.notifier).add(pending('ref-9'));
      first.dispose();

      final second = ProviderContainer(
        overrides: [keyValueStoreProvider.overrideWithValue(store)],
      );
      addTearDown(second.dispose);
      expect(
        (await second.read(pendingPaymentsProvider.future)).single.clientRef,
        'ref-9',
      );

      await second.read(pendingPaymentsProvider.notifier).discard('ref-9');
      expect(await second.read(pendingPaymentsProvider.future), isEmpty);
      expect(await store.read(pendingPaymentsKey), isNull);
    });
  });

  test('client refs are random 32-character hex', () {
    final a = newClientRef();
    expect(a, matches(RegExp(r'^[0-9a-f]{32}$')));
    expect(newClientRef(), isNot(a));
  });
}
