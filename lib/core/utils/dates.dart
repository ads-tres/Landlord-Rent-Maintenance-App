import 'package:intl/intl.dart';

/// Dates are stored and sent in the Gregorian calendar (`YYYY-MM-DD`).
/// Ethiopian-calendar display comes with the calendar feature.

String ymd(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

DateTime parseYmd(String value) => DateTime.parse(value);

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String formatDate(DateTime date, String locale) =>
    DateFormat.yMMMd(locale).format(date);

/// `2026-11` → `November 2026` (localized).
String formatPeriod(String period, String locale) =>
    DateFormat.yMMMM(locale).format(DateTime.parse('$period-01'));

String periodOf(DateTime date) => DateFormat('yyyy-MM').format(date);

/// Adds whole years, keeping Feb 29 → Feb 28 in non-leap years.
DateTime addYears(DateTime d, int years) {
  final year = d.year + years;
  final lastDay = DateTime(year, d.month + 1, 0).day;
  return DateTime(year, d.month, d.day > lastDay ? lastDay : d.day);
}

/// Earliest end date the Addis directive allows: start + [years] years − 1 day.
DateTime minimumLeaseEnd(DateTime start, int years) =>
    addYears(start, years).subtract(const Duration(days: 1));
