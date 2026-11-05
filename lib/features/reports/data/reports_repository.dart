import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/api/api_client.dart';
import '../domain/quarterly_report.dart';

class ReportsRepository {
  ReportsRepository(this._api);

  final ApiClient _api;

  /// Without [year] and [quarter], the server returns the current quarter
  /// in the landlord's calendar.
  Future<QuarterlyReport> quarterly({int? year, int? quarter}) async {
    final data = await _api.get(
      '/reports/quarterly',
      query: {'year': ?year, 'quarter': ?quarter},
    ) as Map<String, dynamic>;
    return QuarterlyReport.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// Downloads the report PDF into the temp folder and returns its path.
  Future<String> downloadPdf({required int year, required int quarter}) async {
    final bytes = await _api.getBytes(
      '/reports/quarterly',
      query: {'year': year, 'quarter': quarter, 'format': 'pdf'},
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/rent-income-$year-Q$quarter.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepository(ref.watch(apiClientProvider)),
);

final quarterlyReportProvider = FutureProvider.autoDispose
    .family<QuarterlyReport, QuarterKey>(
      (ref, key) => ref
          .watch(reportsRepositoryProvider)
          .quarterly(year: key.year, quarter: key.quarter),
    );
