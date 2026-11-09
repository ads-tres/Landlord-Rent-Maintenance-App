import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/unit_history.dart';

class UnitHistoryRepository {
  UnitHistoryRepository(this._api);

  final ApiClient _api;

  Future<UnitHistory> history(int unitId) async {
    final data =
        await _api.get('/units/$unitId/history') as Map<String, dynamic>;
    return UnitHistory.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// Without [year], the current one in the landlord's calendar.
  Future<VacancyReport> vacancy({int? year}) async {
    final data = await _api.get(
      '/vacancy',
      query: {'year': ?year},
    ) as Map<String, dynamic>;
    return VacancyReport.fromJson(data['data'] as Map<String, dynamic>);
  }
}

final unitHistoryRepositoryProvider = Provider<UnitHistoryRepository>(
  (ref) => UnitHistoryRepository(ref.watch(apiClientProvider)),
);

final unitHistoryProvider = FutureProvider.autoDispose.family<UnitHistory, int>(
  (ref, unitId) => ref.watch(unitHistoryRepositoryProvider).history(unitId),
);

final vacancyReportProvider = FutureProvider.autoDispose
    .family<VacancyReport, int?>(
      (ref, year) =>
          ref.watch(unitHistoryRepositoryProvider).vacancy(year: year),
    );
