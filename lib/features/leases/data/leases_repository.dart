import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/utils/dates.dart';
import '../domain/charge.dart';
import '../domain/lease.dart';
import '../domain/renewal.dart';
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

  /// Active leases ending within [days], soonest first.
  Future<List<Lease>> ending({int days = 60}) async {
    final data = await _api.get(
      '/leases',
      query: {'ending_within_days': days},
    ) as Map<String, dynamic>;
    return (data['data'] as List<dynamic>)
        .map((l) => Lease.fromJson(l as Map<String, dynamic>))
        .toList();
  }

  Future<RenewalCheck> renewalCheck(int leaseId) async {
    final data = await _api.get(
      '/leases/$leaseId/renewal-check',
    ) as Map<String, dynamic>;
    return RenewalCheck.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// Extends the lease; a rent change applies from the day after the old end.
  Future<LeaseRenewal> renew(
    int leaseId, {
    required DateTime newEndDate,
    required int newRent,
    bool notifyTenant = true,
  }) async {
    final data = await _api.post(
      '/leases/$leaseId/renew',
      data: {
        'new_end_date': ymd(newEndDate),
        'new_rent': newRent,
        'notify_tenant': notifyTenant,
      },
    ) as Map<String, dynamic>;
    return LeaseRenewal.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// The renewal addendum PDF, saved to a temporary file for sharing.
  Future<String> downloadAddendum(int renewalId) async {
    final bytes = await _api.getBytes('/lease-renewals/$renewalId/addendum');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/lease-renewal-$renewalId.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
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

final endingLeasesProvider = FutureProvider.autoDispose<List<Lease>>(
  (ref) => ref.watch(leasesRepositoryProvider).ending(),
);
