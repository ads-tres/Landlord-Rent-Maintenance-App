import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/utils/dates.dart';
import '../domain/arrears.dart';

class ArrearsRepository {
  ArrearsRepository(this._api);

  final ApiClient _api;

  Arrears _one(dynamic data) => Arrears.fromJson(
    (data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
  );

  Future<List<Arrears>> list() async {
    final data = await _api.get('/arrears') as Map<String, dynamic>;
    return (data['data'] as List<dynamic>)
        .map((a) => Arrears.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  Future<Arrears> get(int leaseId) async =>
      _one(await _api.get('/leases/$leaseId/arrears'));

  /// Texts a friendly reminder or a firm notice, or saves a note.
  Future<Arrears> act(int leaseId, ArrearsStep kind, {String? note}) async =>
      _one(
        await _api.post(
          '/leases/$leaseId/arrears/actions',
          data: {
            'kind': kind == ArrearsStep.note ? 'note' : kind.name,
            'note': ?note,
          },
        ),
      );

  Future<String> downloadDemandLetter(int leaseId) async {
    final bytes = await _api.getBytes('/leases/$leaseId/arrears/demand-letter');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/demand-letter-$leaseId.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<Arrears> createPlan(
    int leaseId,
    List<({DateTime dueDate, int amount})> instalments, {
    bool notifyTenant = true,
  }) async => _one(
    await _api.post(
      '/leases/$leaseId/payment-plan',
      data: {
        'instalments': [
          for (final i in instalments)
            {'due_date': ymd(i.dueDate), 'amount': i.amount},
        ],
        'notify_tenant': notifyTenant,
      },
    ),
  );

  Future<void> cancelPlan(int planId) => _api.delete('/payment-plans/$planId');
}

final arrearsRepositoryProvider = Provider<ArrearsRepository>(
  (ref) => ArrearsRepository(ref.watch(apiClientProvider)),
);

final arrearsListProvider = FutureProvider.autoDispose<List<Arrears>>(
  (ref) => ref.watch(arrearsRepositoryProvider).list(),
);

final arrearsProvider = FutureProvider.autoDispose.family<Arrears, int>(
  (ref, leaseId) => ref.watch(arrearsRepositoryProvider).get(leaseId),
);
