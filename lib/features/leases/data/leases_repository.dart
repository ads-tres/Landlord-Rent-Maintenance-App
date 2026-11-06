import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/utils/dates.dart';
import '../domain/charge.dart';
import '../domain/lease.dart';
import '../domain/rent_rules.dart';

/// Amounts are sent and received in santim.
class LeasesRepository {
  LeasesRepository(this._api);

  final ApiClient _api;

  Future<RentRules> rules() async {
    final data = await _api.get('/rules') as Map<String, dynamic>;
    return RentRules.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<Lease> get(int id) async {
    final data = await _api.get('/leases/$id') as Map<String, dynamic>;
    return Lease.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<Lease> create({
    required int unitId,
    required int tenantId,
    required DateTime startDate,
    required DateTime endDate,
    required int monthlyRent,
    required int deposit,
    required int dueDay,
    required String conditionNotes,
    DateTime? registeredAt,
  }) async {
    final data = await _api.post(
      '/leases',
      data: {
        'unit_id': unitId,
        'tenant_id': tenantId,
        'start_date': ymd(startDate),
        'end_date': ymd(endDate),
        'monthly_rent': monthlyRent,
        'deposit': deposit,
        'due_day': dueDay,
        'condition_notes': conditionNotes,
        if (registeredAt != null) 'registered_at': ymd(registeredAt),
      },
    ) as Map<String, dynamic>;
    return Lease.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<Lease> changeRent(
    int leaseId, {
    required int newRent,
    required DateTime effectiveDate,
  }) async {
    final data = await _api.post(
      '/leases/$leaseId/rent-change',
      data: {'new_rent': newRent, 'effective_date': ymd(effectiveDate)},
    ) as Map<String, dynamic>;
    return Lease.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// Texts the tenant their page link.
  Future<void> sendPortalLink(int leaseId) =>
      _api.post('/leases/$leaseId/portal-link/send');

  /// Replaces the tenant page link; the old one stops working.
  Future<void> resetPortalLink(int leaseId) =>
      _api.post('/leases/$leaseId/portal-link/reset');

  Future<Lease> end(int leaseId, {required DateTime endedOn}) async {
    final data = await _api.post(
      '/leases/$leaseId/end',
      data: {'ended_on': ymd(endedOn)},
    ) as Map<String, dynamic>;
    return Lease.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// [status] is one of due, partial, paid, late or unpaid.
  Future<List<Charge>> charges({
    String? period,
    String? status,
    int? leaseId,
  }) async {
    final data = await _api.get(
      '/charges',
      query: {'period': ?period, 'status': ?status, 'lease_id': ?leaseId},
    ) as Map<String, dynamic>;
    return (data['data'] as List<dynamic>)
        .map((c) => Charge.fromJson(c as Map<String, dynamic>))
        .toList();
  }
}

final leasesRepositoryProvider = Provider<LeasesRepository>(
  (ref) => LeasesRepository(ref.watch(apiClientProvider)),
);

/// Cap and minimum term; falls back to known values if offline.
final rentRulesProvider = FutureProvider<RentRules>((ref) async {
  try {
    return await ref.watch(leasesRepositoryProvider).rules();
  } catch (_) {
    return RentRules.fallback;
  }
});

final leaseProvider = FutureProvider.autoDispose.family<Lease, int>(
  (ref, id) => ref.watch(leasesRepositoryProvider).get(id),
);

final leaseChargesProvider = FutureProvider.autoDispose
    .family<List<Charge>, int>(
      (ref, leaseId) =>
          ref.watch(leasesRepositoryProvider).charges(leaseId: leaseId),
    );
