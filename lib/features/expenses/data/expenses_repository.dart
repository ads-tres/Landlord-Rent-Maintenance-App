import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/offline/outbox.dart';
import '../../../core/utils/dates.dart';
import '../domain/expense.dart';

class ExpensesRepository {
  ExpensesRepository(this._api);

  final ApiClient _api;

  Expense _one(dynamic data) => Expense.fromJson(
    (data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
  );

  Future<ExpenseList> list({int? propertyId}) async {
    final data = await _api.get(
      '/expenses',
      query: {'property_id': ?propertyId},
    ) as Map<String, dynamic>;
    return (
      items: (data['data'] as List<dynamic>)
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (data['meta'] as Map<String, dynamic>?)?['total'] as int? ?? 0,
    );
  }

  /// Sent as multipart so a receipt photo can go with it.
  Future<Expense> create({
    required int propertyId,
    int? unitId,
    required ExpenseCategory category,
    required int amount,
    required DateTime spentOn,
    String? description,
    String? vendor,
    String? photoPath,
    String? clientRef,
  }) async => _one(
    await _api.post(
      '/expenses',
      data: FormData.fromMap({
        'property_id': propertyId,
        'unit_id': ?unitId,
        'category': category.apiValue,
        'amount': amount,
        'spent_on': ymd(spentOn),
        if (description != null && description.isNotEmpty)
          'description': description,
        if (vendor != null && vendor.isNotEmpty) 'vendor': vendor,
        'client_ref': ?clientRef,
        if (photoPath != null) 'photo': await MultipartFile.fromFile(photoPath),
      }),
    ),
  );

  Future<Expense> addPhoto(int id, String path) async => _one(
    await _api.post(
      '/expenses/$id/photos',
      data: FormData.fromMap({'photo': await MultipartFile.fromFile(path)}),
    ),
  );

  Future<void> delete(int id) => _api.delete('/expenses/$id');
}

final expensesRepositoryProvider = Provider<ExpensesRepository>(
  (ref) => ExpensesRepository(ref.watch(apiClientProvider)),
);

/// Expenses for one property, or all of them when null.
final expensesProvider = FutureProvider.autoDispose.family<ExpenseList, int?>((
  ref,
  propertyId,
) {
  ref.watch(outboxSyncedProvider); // refetch once offline expenses are sent
  return ref.watch(expensesRepositoryProvider).list(propertyId: propertyId);
});
