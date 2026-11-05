import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/property.dart';
import '../domain/unit.dart';

class PropertiesRepository {
  PropertiesRepository(this._api);

  final ApiClient _api;

  Future<List<Property>> list() async {
    final data = await _api.get('/properties') as Map<String, dynamic>;
    return (data['data'] as List<dynamic>)
        .map((p) => Property.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<Property> get(int id) async {
    final data = await _api.get('/properties/$id') as Map<String, dynamic>;
    return Property.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<Property> create({
    required String name,
    String? subCity,
    String? woreda,
    String? address,
  }) async {
    final data = await _api.post(
      '/properties',
      data: {
        'name': name,
        'sub_city': subCity,
        'woreda': woreda,
        'address': address,
      },
    ) as Map<String, dynamic>;
    return Property.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _api.delete('/properties/$id');

  Future<Unit> addUnit(
    int propertyId, {
    required String label,
    int? bedrooms,
  }) async {
    final data = await _api.post(
      '/properties/$propertyId/units',
      data: {'label': label, 'bedrooms': bedrooms},
    ) as Map<String, dynamic>;
    return Unit.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteUnit(int unitId) => _api.delete('/units/$unitId');
}

final propertiesRepositoryProvider = Provider<PropertiesRepository>(
  (ref) => PropertiesRepository(ref.watch(apiClientProvider)),
);

final propertiesProvider = FutureProvider.autoDispose<List<Property>>(
  (ref) => ref.watch(propertiesRepositoryProvider).list(),
);

final propertyProvider = FutureProvider.autoDispose.family<Property, int>(
  (ref, id) => ref.watch(propertiesRepositoryProvider).get(id),
);
