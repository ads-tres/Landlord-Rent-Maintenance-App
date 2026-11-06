import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/utils/dates.dart';
import '../domain/listing.dart';

/// Amounts in santim.
class ListingsRepository {
  ListingsRepository(this._api);

  final ApiClient _api;

  Map<String, dynamic> _one(dynamic d) =>
      (d as Map<String, dynamic>)['data'] as Map<String, dynamic>;

  Future<List<Listing>> list() async =>
      ((await _api.get('/listings') as Map<String, dynamic>)['data']
              as List<dynamic>)
          .map((l) => Listing.fromJson(l as Map<String, dynamic>))
          .toList();

  Future<Listing> get(int id) async =>
      Listing.fromJson(_one(await _api.get('/listings/$id')));

  Future<Listing> create(
    int unitId, {
    required int askingRent,
    required DateTime availableFrom,
    String? description,
  }) async => Listing.fromJson(
    _one(
      await _api.post(
        '/units/$unitId/listing',
        data: {
          'asking_rent': askingRent,
          'available_from': ymd(availableFrom),
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      ),
    ),
  );

  /// [status] 'live' publishes for 30 days, 'closed' closes.
  Future<Listing> setStatus(int id, String status) async => Listing.fromJson(
    _one(await _api.patch('/listings/$id', data: {'status': status})),
  );

  Future<Listing> addPhoto(int id, String path) async => Listing.fromJson(
    _one(
      await _api.post(
        '/listings/$id/photos',
        data: FormData.fromMap({'photo': await MultipartFile.fromFile(path)}),
      ),
    ),
  );

  Future<List<ListingApplication>> applications(int listingId) async =>
      ((await _api.get('/listings/$listingId/applications')
                  as Map<String, dynamic>)['data']
              as List<dynamic>)
          .map((a) => ListingApplication.fromJson(a as Map<String, dynamic>))
          .toList();

  Future<ListingApplication> setApplicationStatus(
    int id,
    ApplicationStatus status,
  ) async => ListingApplication.fromJson(
    _one(
      await _api.patch('/applications/$id', data: {'status': status.apiValue}),
    ),
  );

  Future<void> activateLease(
    int leaseId, {
    required String conditionNotes,
    required DateTime startDate,
    required DateTime endDate,
    int? deposit,
  }) => _api.post(
    '/leases/$leaseId/activate',
    data: {
      'condition_notes': conditionNotes,
      'start_date': ymd(startDate),
      'end_date': ymd(endDate),
      'deposit': ?deposit,
    },
  );
}

final listingsRepositoryProvider = Provider<ListingsRepository>(
  (ref) => ListingsRepository(ref.watch(apiClientProvider)),
);

final listingsProvider = FutureProvider.autoDispose<List<Listing>>(
  (ref) => ref.watch(listingsRepositoryProvider).list(),
);

final listingProvider = FutureProvider.autoDispose.family<Listing, int>(
  (ref, id) => ref.watch(listingsRepositoryProvider).get(id),
);

final applicationsProvider = FutureProvider.autoDispose
    .family<List<ListingApplication>, int>(
      (ref, listingId) =>
          ref.watch(listingsRepositoryProvider).applications(listingId),
    );
