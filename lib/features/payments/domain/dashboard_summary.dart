/// Home-screen totals from `GET /dashboard`. Amounts in santim.
class DashboardSummary {
  const DashboardSummary({
    required this.collectedThisMonth,
    required this.dueThisMonth,
    required this.outstanding,
    required this.lateTenants,
    required this.openRepairs,
    required this.leasesEndingSoon,
    this.servicesDue = 0,
    this.expensesThisMonth = 0,
    required this.properties,
    required this.units,
    required this.vacantUnits,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> j) => DashboardSummary(
    collectedThisMonth: j['collected_this_month'] as int,
    dueThisMonth: j['due_this_month'] as int,
    outstanding: j['outstanding'] as int,
    lateTenants: j['late_tenants'] as int,
    openRepairs: j['open_repairs'] as int,
    leasesEndingSoon: j['leases_ending_soon'] as int,
    servicesDue: j['services_due'] as int? ?? 0,
    expensesThisMonth: j['expenses_this_month'] as int? ?? 0,
    properties: j['properties'] as int,
    units: j['units'] as int,
    vacantUnits: j['vacant_units'] as int,
  );

  final int collectedThisMonth;
  final int dueThisMonth;
  final int outstanding;
  final int lateTenants;
  final int openRepairs;
  final int leasesEndingSoon;

  /// Generator / water tank / pump services due within a week.
  final int servicesDue;

  /// Money spent on properties this month, in santim.
  final int expensesThisMonth;
  final int properties;
  final int units;
  final int vacantUnits;
}
