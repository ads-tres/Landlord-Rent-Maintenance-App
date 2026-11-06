import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/utils/dates.dart';
import '../domain/compound.dart';

/// Amounts are sent and received in santim.
class CompoundRepository {
  CompoundRepository(this._api);

  final ApiClient _api;

  List<Map<String, dynamic>> _list(dynamic data) =>
      ((data as Map<String, dynamic>)['data'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

  Map<String, dynamic> _one(dynamic data) =>
      (data as Map<String, dynamic>)['data'] as Map<String, dynamic>;

  Future<List<Meter>> meters(int propertyId) async =>
      _list(await _api.get('/properties/$propertyId/meters'))
          .map(Meter.fromJson)
          .toList();

  Future<Meter> meter(int id) async =>
      Meter.fromJson(_one(await _api.get('/meters/$id')));

  Future<Meter> createMeter(
    int propertyId, {
    required String name,
    required MeterKind kind,
    required SplitMethod method,
    required Map<int, double?> units,
  }) async => Meter.fromJson(
    _one(
      await _api.post(
        '/properties/$propertyId/meters',
        data: {
          'name': name,
          'kind': kind.name,
          'split_method': method.name,
          'units': [
            for (final e in units.entries)
              {'unit_id': e.key, 'share_percent': ?e.value},
          ],
        },
      ),
    ),
  );

  Future<List<UtilityBill>> bills(int meterId) async =>
      _list(await _api.get('/meters/$meterId/bills'))
          .map(UtilityBill.fromJson)
          .toList();

  Map<String, dynamic> _billFields({
    required String period,
    required int amount,
    required DateTime dueDate,
    required Map<int, (double, double)> readings,
  }) => {
    'period': period,
    'amount': amount,
    'due_date': ymd(dueDate),
    for (final e in readings.entries) ...{
      'readings[${e.key}][previous]': e.value.$1,
      'readings[${e.key}][current]': e.value.$2,
    },
  };

  Future<SplitPreview> previewBill(
    int meterId, {
    required String period,
    required int amount,
    required DateTime dueDate,
    Map<int, (double, double)> readings = const {},
  }) async => SplitPreview.fromJson(
    _one(
      await _api.post(
        '/meters/$meterId/bills',
        data: FormData.fromMap({
          ..._billFields(
            period: period,
            amount: amount,
            dueDate: dueDate,
            readings: readings,
          ),
          'dry_run': 1,
        }),
      ),
    ),
  );

  Future<UtilityBill> createBill(
    int meterId, {
    required String period,
    required int amount,
    required DateTime dueDate,
    Map<int, (double, double)> readings = const {},
    String? photoPath,
    bool notifyTenants = true,
  }) async => UtilityBill.fromJson(
    _one(
      await _api.post(
        '/meters/$meterId/bills',
        data: FormData.fromMap({
          ..._billFields(
            period: period,
            amount: amount,
            dueDate: dueDate,
            readings: readings,
          ),
          'notify_tenants': notifyTenants ? 1 : 0,
          if (photoPath != null)
            'photo': await MultipartFile.fromFile(photoPath),
        }),
      ),
    ),
  );

  Future<void> deleteBill(int billId) => _api.delete('/bills/$billId');

  /// All equipment, or only what is due within [dueWithinDays] when given.
  Future<List<Asset>> allAssets({int? dueWithinDays}) async => _list(
    await _api.get('/assets', query: {'due_within_days': ?dueWithinDays}),
  ).map(Asset.fromJson).toList();

  Future<List<Asset>> assets(int propertyId) async =>
      _list(await _api.get('/properties/$propertyId/assets'))
          .map(Asset.fromJson)
          .toList();

  Future<Asset> createAsset(
    int propertyId, {
    required AssetKind kind,
    required String name,
    required int intervalDays,
    DateTime? lastServicedOn,
  }) async => Asset.fromJson(
    _one(
      await _api.post(
        '/properties/$propertyId/assets',
        data: {
          'kind': kind.apiValue,
          'name': name,
          'service_interval_days': intervalDays,
          if (lastServicedOn != null) 'last_serviced_on': ymd(lastServicedOn),
        },
      ),
    ),
  );

  Future<Asset> logService(
    int assetId, {
    required DateTime servicedOn,
    int? cost,
    String? notes,
  }) async => Asset.fromJson(
    _one(
      await _api.post(
        '/assets/$assetId/services',
        data: {
          'serviced_on': ymd(servicedOn),
          'cost': ?cost,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      ),
    ),
  );

  Future<AnnouncementPreview> previewAnnouncement(
    int propertyId,
    String body,
  ) async => AnnouncementPreview.fromJson(
    _one(
      await _api.post(
        '/properties/$propertyId/announcements/preview',
        data: {'body': body},
      ),
    ),
  );

  Future<void> sendAnnouncement(int propertyId, String body) =>
      _api.post('/properties/$propertyId/announcements', data: {'body': body});
}

final compoundRepositoryProvider = Provider<CompoundRepository>(
  (ref) => CompoundRepository(ref.watch(apiClientProvider)),
);

final metersProvider = FutureProvider.autoDispose.family<List<Meter>, int>(
  (ref, propertyId) => ref.watch(compoundRepositoryProvider).meters(propertyId),
);

final meterProvider = FutureProvider.autoDispose.family<Meter, int>(
  (ref, id) => ref.watch(compoundRepositoryProvider).meter(id),
);

final billsProvider = FutureProvider.autoDispose.family<List<UtilityBill>, int>(
  (ref, meterId) => ref.watch(compoundRepositoryProvider).bills(meterId),
);

/// Equipment for one property, or for all properties when the key is null (only what is due soon).
final assetsProvider = FutureProvider.autoDispose.family<List<Asset>, int?>(
  (ref, propertyId) => propertyId == null
      ? ref.watch(compoundRepositoryProvider).allAssets(dueWithinDays: 7)
      : ref.watch(compoundRepositoryProvider).assets(propertyId),
);
