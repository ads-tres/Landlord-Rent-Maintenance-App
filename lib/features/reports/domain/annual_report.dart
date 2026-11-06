/// `GET /reports/annual`. Amounts in santim.
class AnnualMonth {
  const AnnualMonth({
    required this.label,
    required this.income,
    required this.refunded,
    required this.expenses,
    required this.net,
    required this.occupancy,
  });

  factory AnnualMonth.fromJson(Map<String, dynamic> j) => AnnualMonth(
    label: j['label'] as String,
    income: j['income'] as int,
    refunded: j['refunded'] as int,
    expenses: j['expenses'] as int,
    net: j['net'] as int,
    occupancy: j['occupancy'] as int,
  );

  final String label;
  final int income;
  final int refunded;
  final int expenses;
  final int net;

  /// Percent of units with a lease that month.
  final int occupancy;
}

class AnnualReport {
  const AnnualReport({
    required this.year,
    required this.label,
    required this.fromDisplay,
    required this.toDisplay,
    required this.income,
    required this.refunded,
    required this.expenses,
    required this.net,
    required this.averageOccupancy,
    required this.months,
  });

  factory AnnualReport.fromJson(Map<String, dynamic> j) => AnnualReport(
    year: j['year'] as int,
    label: j['label'] as String,
    fromDisplay: j['from_display'] as String,
    toDisplay: j['to_display'] as String,
    income: j['income'] as int,
    refunded: j['refunded'] as int,
    expenses: j['expenses'] as int,
    net: j['net'] as int,
    averageOccupancy: j['average_occupancy'] as int,
    months: [
      for (final m in j['months'] as List<dynamic>)
        AnnualMonth.fromJson(m as Map<String, dynamic>),
    ],
  );

  final int year;
  final String label;
  final String fromDisplay;
  final String toDisplay;
  final int income;
  final int refunded;
  final int expenses;
  final int net;
  final int averageOccupancy;
  final List<AnnualMonth> months;
}
