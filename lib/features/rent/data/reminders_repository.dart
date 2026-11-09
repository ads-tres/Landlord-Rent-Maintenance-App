import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/bulk_reminder.dart';

class RemindersRepository {
  RemindersRepository(this._api);

  final ApiClient _api;

  /// [period] is YYYY-MM.
  Future<ReminderPreview> preview(String period) async {
    final data = await _api.get(
      '/rent/reminders',
      query: {'period': period},
    ) as Map<String, dynamic>;
    return ReminderPreview.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// Returns how many were sent.
  Future<int> send(String period, List<int> leaseIds) async {
    final data = await _api.post(
      '/rent/reminders',
      data: {'period': period, 'lease_ids': leaseIds},
    ) as Map<String, dynamic>;
    return (data['data'] as Map<String, dynamic>)['sent'] as int;
  }
}

final remindersRepositoryProvider = Provider<RemindersRepository>(
  (ref) => RemindersRepository(ref.watch(apiClientProvider)),
);
