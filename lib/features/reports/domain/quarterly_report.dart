/// `GET /reports/quarterly`. Amounts in santim.
class QuarterlyReport {
  const QuarterlyReport({
    required this.year,
    required this.quarter,
    required this.calendar,
    required this.label,
    required this.fromDisplay,
    required this.toDisplay,
    required this.total,
    required this.paymentsCount,
    required this.byMonth,
    required this.byProperty,
    required this.byMethod,
    this.expensesTotal = 0,
    this.expensesCount = 0,
    this.expensesByCategory = const [],
  });

  /// Rent received minus expenses.
  int get net => total - expensesTotal;

  factory QuarterlyReport.fromJson(Map<String, dynamic> j) => QuarterlyReport(
    year: j['year'] as int,
    quarter: j['quarter'] as int,
    calendar: j['calendar'] as String,
    label: j['label'] as String,
    fromDisplay: j['from_display'] as String,
    toDisplay: j['to_display'] as String,
    total: j['total'] as int,
    paymentsCount: j['payments_count'] as int,
    byMonth: [
      for (final m in j['by_month'] as List<dynamic>)
        (label: m['label'] as String, total: m['total'] as int),
    ],
    byProperty: [
      for (final p in j['by_property'] as List<dynamic>)
        (
          property: p['property'] as String,
          total: p['total'] as int,
          units: [
            for (final u in p['units'] as List<dynamic>)
              (unit: u['unit'] as String, total: u['total'] as int),
          ],
        ),
    ],
    byMethod: [
      for (final m in j['by_method'] as List<dynamic>)
        (method: m['method'] as String, total: m['total'] as int),
    ],
    expensesTotal: j['expenses_total'] as int? ?? 0,
    expensesCount: j['expenses_count'] as int? ?? 0,
    expensesByCategory: [
      for (final c in j['expenses_by_category'] as List<dynamic>? ?? [])
        (category: c['category'] as String, total: c['total'] as int),
    ],
  );

  final int year;
  final int quarter;
  final String calendar;
  final String label;
  final String fromDisplay;
  final String toDisplay;
  final int total;
  final int paymentsCount;
  final List<({String label, int total})> byMonth;
  final List<
    ({String property, int total, List<({String unit, int total})> units})
  >
  byProperty;
  final List<({String method, int total})> byMethod;
  final int expensesTotal;
  final int expensesCount;
  final List<({String category, int total})> expensesByCategory;
}

/// A quarter to show; null year means "the current quarter".
typedef QuarterKey = ({int? year, int? quarter});

QuarterKey previousQuarter(int year, int quarter) => quarter == 1
    ? (year: year - 1, quarter: 4)
    : (year: year, quarter: quarter - 1);

QuarterKey nextQuarter(int year, int quarter) => quarter == 4
    ? (year: year + 1, quarter: 1)
    : (year: year, quarter: quarter + 1);
