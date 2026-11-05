import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/tenant.dart';

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
