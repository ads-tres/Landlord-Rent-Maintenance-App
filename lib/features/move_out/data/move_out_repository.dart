import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/utils/dates.dart';
import '../domain/move_out.dart';

class MoveOutRepository {
  MoveOutRepository(this._api);

  final ApiClient _api;

  MoveOut _one(dynamic data) => MoveOut.fromJson(
    (data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
  );

  /// Starts the lease's move-out, or returns the one already started.
  Future<MoveOut> start(int leaseId, {required DateTime movedOutOn}) async =>
      _one(
        await _api.post(
          '/leases/$leaseId/move-out',
          data: {'moved_out_on': ymd(movedOutOn)},
        ),
      );

  Future<MoveOut> get(int id) async => _one(await _api.get('/move-outs/$id'));

  Future<MoveOut> update(
    int id, {
    DateTime? movedOutOn,
    String? conditionNotes,
    bool? keysReturned,
  }) async => _one(
    await _api.patch(
      '/move-outs/$id',
      data: {
        if (movedOutOn != null) 'moved_out_on': ymd(movedOutOn),
        'condition_notes': ?conditionNotes,
        'keys_returned': ?keysReturned,
      },
    ),
  );

  Future<MoveOut> addDeduction(
    int id, {
    required DeductionKind kind,
    required String description,
    required int amount,
  }) async => _one(
    await _api.post(
      '/move-outs/$id/deductions',
      data: {
        'kind': kind.apiValue,
        'description': description,
        'amount': amount,
      },
    ),
  );

  Future<MoveOut> removeDeduction(int deductionId) async =>
      _one(await _api.delete('/move-out-deductions/$deductionId'));

  Future<MoveOut> addPhoto(int id, String path) async => _one(
    await _api.post(
      '/move-outs/$id/photos',
      data: FormData.fromMap({'photo': await MultipartFile.fromFile(path)}),
    ),
  );

  Future<MoveOut> settle(
    int id, {
    String? refundMethod,
    String? refundReference,
    bool notifyTenant = true,
  }) async => _one(
    await _api.post(
      '/move-outs/$id/settle',
      data: {
        'refund_method': ?refundMethod,
        if (refundReference != null && refundReference.isNotEmpty)
          'refund_reference': refundReference,
        'notify_tenant': notifyTenant,
      },
    ),
  );

  Future<void> sendStatement(int id) => _api.post('/move-outs/$id/send');

  Future<String> downloadStatement(int id) async {
    final bytes = await _api.getBytes('/move-outs/$id/statement');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/deposit-statement-$id.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}

final moveOutRepositoryProvider = Provider<MoveOutRepository>(
  (ref) => MoveOutRepository(ref.watch(apiClientProvider)),
);

final moveOutProvider = FutureProvider.autoDispose.family<MoveOut, int>(
  (ref, id) => ref.watch(moveOutRepositoryProvider).get(id),
);
