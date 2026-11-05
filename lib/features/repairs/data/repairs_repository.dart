import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/repair.dart';

class RepairsRepository {
  RepairsRepository(this._api);

  final ApiClient _api;

  /// [status] is open, in_progress, done or active (not done).
  Future<List<Repair>> list({String status = 'active'}) async {
    final data = await _api.get(
      '/maintenance',
      query: {'status': status},
    ) as Map<String, dynamic>;
    return (data['data'] as List<dynamic>)
        .map((r) => Repair.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<Repair> get(int id) async {
    final data = await _api.get('/maintenance/$id') as Map<String, dynamic>;
    return Repair.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<Repair> create({
    required int unitId,
    required String title,
    required RepairCategory category,
    String? description,
    List<String> photoPaths = const [],
  }) async {
    final form = FormData.fromMap({
      'unit_id': unitId,
      'title': title,
      'category': category.apiValue,
      if (description != null && description.isNotEmpty)
        'description': description,
      'photos[]': [for (final p in photoPaths) await MultipartFile.fromFile(p)],
    });
    final data =
        await _api.post('/maintenance', data: form) as Map<String, dynamic>;
    return Repair.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<Repair> updateStatus(
    int id,
    RepairStatus status, {
    String? note,
    bool notifyTenant = true,
  }) async {
    final data = await _api.patch(
      '/maintenance/$id',
      data: {
        'status': status.apiValue,
        if (note != null && note.isNotEmpty) 'note': note,
        'notify_tenant': notifyTenant,
      },
    ) as Map<String, dynamic>;
    return Repair.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<Repair> addPhoto(int id, String path) async {
    final form = FormData.fromMap({
      'photo': await MultipartFile.fromFile(path),
    });
    final data = await _api.post(
      '/maintenance/$id/photos',
      data: form,
    ) as Map<String, dynamic>;
    return Repair.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<List<UnitOption>> units() async {
    final data = await _api.get('/units') as Map<String, dynamic>;
    return (data['data'] as List<dynamic>)
        .map((u) => UnitOption.fromJson(u as Map<String, dynamic>))
        .toList();
  }

  Future<void> sendRepairLink(int leaseId) =>
      _api.post('/leases/$leaseId/repair-link/send');

  Future<void> resetRepairLink(int leaseId) =>
      _api.post('/leases/$leaseId/repair-link/reset');
}

final repairsRepositoryProvider = Provider<RepairsRepository>(
  (ref) => RepairsRepository(ref.watch(apiClientProvider)),
);

/// Selected filter on the Repairs tab: active, open, in_progress or done.
class RepairFilter extends Notifier<String> {
  @override
  String build() => 'active';

  void set(String value) => state = value;
}

final repairFilterProvider = NotifierProvider<RepairFilter, String>(
  RepairFilter.new,
);

final repairsProvider = FutureProvider.autoDispose<List<Repair>>(
  (ref) => ref
      .watch(repairsRepositoryProvider)
      .list(status: ref.watch(repairFilterProvider)),
);

final repairProvider = FutureProvider.autoDispose.family<Repair, int>(
  (ref, id) => ref.watch(repairsRepositoryProvider).get(id),
);

final unitOptionsProvider = FutureProvider.autoDispose<List<UnitOption>>(
  (ref) => ref.watch(repairsRepositoryProvider).units(),
);
