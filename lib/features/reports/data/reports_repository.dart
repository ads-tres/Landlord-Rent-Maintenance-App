import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/api/api_client.dart';
import '../domain/annual_report.dart';
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
  Future<String> downloadPdf({required int year, required int quarter}) =>
      _download(year, quarter, 'pdf', 'rent-income-$year-Q$quarter.pdf');

  /// Downloads the Excel workbook (summary, payments, expenses, rent roll).
  Future<String> downloadExcel({required int year, required int quarter}) =>
      _download(
        year,
        quarter,
        'xlsx',
        'rent-and-expenses-$year-Q$quarter.xlsx',
      );

  /// Without [year], the server returns the current one in the landlord's calendar.
  Future<AnnualReport> annual({int? year}) async {
    final data = await _api.get(
      '/reports/annual',
      query: {'year': ?year},
    ) as Map<String, dynamic>;
    return AnnualReport.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// The annual summary as `pdf` or `xlsx`.
  Future<String> downloadAnnual(int year, String format) =>
      _download(year, null, format, 'annual-summary-$year.$format');

  Future<String> _download(
    int year,
    int? quarter,
    String format,
    String name,
  ) async {
    final bytes = await _api.getBytes(
      quarter == null ? '/reports/annual' : '/reports/quarterly',
      query: {'year': year, 'quarter': ?quarter, 'format': format},
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
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

final annualReportProvider = FutureProvider.autoDispose
    .family<AnnualReport, int?>(
      (ref, year) => ref.watch(reportsRepositoryProvider).annual(year: year),
    );
