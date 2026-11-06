import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/tenant.dart';
import '../domain/tenant_record.dart';

class TenantsRepository {
  TenantsRepository(this._api);

  final ApiClient _api;

  Future<List<Tenant>> list({String? query}) async {
    final data = await _api.get(
      '/tenants',
      query: {if (query != null && query.isNotEmpty) 'q': query},
    ) as Map<String, dynamic>;
    return (data['data'] as List<dynamic>)
        .map((t) => Tenant.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  /// [privacyNoticeShown] must be true: the landlord confirms the tenant was
  /// told how their data is stored (Proclamation 1321/2024).
  Future<Tenant> create({
    required String fullName,
    required String phone,
    String? idNumber,
    String? address,
    required bool privacyNoticeShown,
    required String noticeLocale,
  }) async {
    final data = await _api.post(
      '/tenants',
      data: {
        'full_name': fullName,
        'phone': phone,
        if (idNumber != null && idNumber.isNotEmpty) 'id_number': idNumber,
        if (address != null && address.isNotEmpty) 'address': address,
        'privacy_notice_shown': privacyNoticeShown,
        'notice_locale': noticeLocale,
      },
    ) as Map<String, dynamic>;
    return Tenant.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _api.delete('/tenants/$id');

  Future<Tenant> get(int id) async {
    final data = await _api.get('/tenants/$id') as Map<String, dynamic>;
    return Tenant.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<Tenant> setRemindersOptOut(int id, bool optOut) async {
    final data = await _api.patch(
      '/tenants/$id',
      data: {'reminders_opt_out': optOut},
    ) as Map<String, dynamic>;
    return Tenant.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<List<TenantMessage>> messages(int id) async {
    final data =
        await _api.get('/tenants/$id/messages') as Map<String, dynamic>;
    return (data['data'] as List<dynamic>)
        .map((m) => TenantMessage.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<TenantRecord> record(int id) async {
    final data = await _api.get('/tenants/$id/record') as Map<String, dynamic>;
    return TenantRecord.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// The landlord's private notes; empty clears them.
  Future<void> saveNotes(int id, String notes) =>
      _api.put('/tenants/$id/notes', data: {'notes': notes.trim()});

  /// The tenant's data as JSON text (right of access, Proclamation 1321/2024).
  Future<String> export(int id) async =>
      jsonEncode(await _api.get('/tenants/$id/export'));

  /// Removes personal details; payment amounts stay. Refused while a lease is active.
  Future<Tenant> anonymize(int id) async {
    final data =
        await _api.post('/tenants/$id/anonymize') as Map<String, dynamic>;
    return Tenant.fromJson(data['data'] as Map<String, dynamic>);
  }
}

final tenantsRepositoryProvider = Provider<TenantsRepository>(
  (ref) => TenantsRepository(ref.watch(apiClientProvider)),
);

final tenantSearchProvider = NotifierProvider<TenantSearch, String>(
  TenantSearch.new,
);

class TenantSearch extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query.trim();
}

final tenantsProvider = FutureProvider.autoDispose<List<Tenant>>(
  (ref) => ref
      .watch(tenantsRepositoryProvider)
      .list(query: ref.watch(tenantSearchProvider)),
);

final tenantRecordProvider = FutureProvider.autoDispose
    .family<TenantRecord, int>(
      (ref, id) => ref.watch(tenantsRepositoryProvider).record(id),
    );

final tenantProvider = FutureProvider.autoDispose.family<Tenant, int>(
  (ref, id) => ref.watch(tenantsRepositoryProvider).get(id),
);

final tenantMessagesProvider = FutureProvider.autoDispose
    .family<List<TenantMessage>, int>(
      (ref, id) => ref.watch(tenantsRepositoryProvider).messages(id),
    );
