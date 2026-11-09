import '../../../core/utils/dates.dart';

/// Vacancy for a period, from `GET /units/{id}/history` (year) or `GET /vacancy`.
class VacancyFigures {
  const VacancyFigures({
    required this.trackedDays,
    required this.vacantDays,
    required this.lost,
    this.occupancyPercent,
    this.priced = true,
  });

  factory VacancyFigures.fromJson(Map<String, dynamic> j) => VacancyFigures(
    trackedDays: j['tracked_days'] as int? ?? 0,
    vacantDays: j['vacant_days'] as int,
    lost: j['lost'] as int,
    occupancyPercent: (j['occupancy_percent'] as num?)?.toDouble(),
    priced: j['priced'] as bool? ?? true,
  );

  final int trackedDays;
  final int vacantDays;

  /// Rent lost while empty, in santim.
  final int lost;
  final double? occupancyPercent;

  /// False when part of the empty time had no rent to price it (never let or listed).
  final bool priced;
}

enum UnitEventType { leaseStarted, leaseEnded, rentChanged, repair, vacant }

/// One line of a unit's timeline. Fields depend on [type].
class UnitEvent {
  const UnitEvent({
    required this.type,
    required this.date,
    this.until,
    this.leaseId,
    this.repairId,
    this.tenant,
    this.rent,
    this.oldRent,
    this.newRent,
    this.title,
    this.status,
    this.cost,
    this.days,
    this.lost,
    this.early = false,
    this.upcoming = false,
  });

  factory UnitEvent.fromJson(Map<String, dynamic> j) => UnitEvent(
    type: switch (j['type']) {
      'lease_started' => UnitEventType.leaseStarted,
      'lease_ended' => UnitEventType.leaseEnded,
      'rent_changed' => UnitEventType.rentChanged,
      'repair' => UnitEventType.repair,
      _ => UnitEventType.vacant,
    },
    date: parseYmd(j['date'] as String),
    until: j['until'] == null ? null : parseYmd(j['until'] as String),
    leaseId: j['lease_id'] as int?,
    repairId: j['repair_id'] as int?,
    tenant: j['tenant'] as String?,
    rent: j['rent'] as int?,
    oldRent: j['old_rent'] as int?,
    newRent: j['new_rent'] as int?,
    title: j['title'] as String?,
    status: j['status'] as String?,
    cost: j['cost'] as int?,
    days: j['days'] as int?,
    lost: j['lost'] as int?,
    early: j['early'] as bool? ?? false,
    upcoming: j['upcoming'] as bool? ?? false,
  );

  final UnitEventType type;
  final DateTime date;

  /// End of an empty spell; null while the unit is still empty.
  final DateTime? until;
  final int? leaseId;
  final int? repairId;
  final String? tenant;
  final int? rent;
  final int? oldRent;
  final int? newRent;
  final String? title;
  final String? status;
  final int? cost;
  final int? days;
  final int? lost;

  /// A lease ended before its end date.
  final bool early;

  /// A rent change that hasn't started.
  final bool upcoming;
}

class UnitHistory {
  const UnitHistory({
    required this.unitId,
    required this.label,
    required this.propertyName,
    required this.status,
    required this.trackedSince,
    required this.year,
    required this.yearLabel,
    required this.repairCostThisYear,
    required this.tenants,
    required this.repairCost,
    required this.events,
    this.averageStayMonths,
    this.currentRent,
  });

  factory UnitHistory.fromJson(Map<String, dynamic> j) {
    final unit = j['unit'] as Map<String, dynamic>;
    final year = j['year'] as Map<String, dynamic>;
    final totals = j['totals'] as Map<String, dynamic>;
    return UnitHistory(
      unitId: unit['id'] as int,
      label: unit['label'] as String,
      propertyName: unit['property_name'] as String? ?? '',
      status: unit['status'] as String,
      trackedSince: parseYmd(unit['tracked_since'] as String),
      year: VacancyFigures.fromJson(year),
      yearLabel: year['year'] as int,
      repairCostThisYear: year['repair_cost'] as int? ?? 0,
      tenants: totals['tenants'] as int? ?? 0,
      averageStayMonths: (totals['average_stay_months'] as num?)?.toDouble(),
      repairCost: totals['repair_cost'] as int? ?? 0,
      currentRent: totals['current_rent'] as int?,
      events: (j['events'] as List<dynamic>)
          .map((e) => UnitEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final int unitId;
  final String label;
  final String propertyName;
  final String status;

  /// When the unit was added to the app; empty time is counted from here.
  final DateTime trackedSince;
  final VacancyFigures year;
  final int yearLabel;
  final int repairCostThisYear;
  final int tenants;
  final double? averageStayMonths;
  final int repairCost;
  final int? currentRent;

  /// Newest first.
  final List<UnitEvent> events;
}

class UnitVacancy {
  const UnitVacancy({
    required this.id,
    required this.label,
    required this.propertyName,
    required this.vacant,
    required this.figures,
    this.vacantSince,
  });

  factory UnitVacancy.fromJson(Map<String, dynamic> j) => UnitVacancy(
    id: j['id'] as int,
    label: j['label'] as String,
    propertyName: j['property_name'] as String? ?? '',
    vacant: j['status'] == 'vacant',
    vacantSince: j['vacant_since'] == null
        ? null
        : parseYmd(j['vacant_since'] as String),
    figures: VacancyFigures.fromJson(j),
  );

  final int id;
  final String label;
  final String propertyName;
  final bool vacant;
  final DateTime? vacantSince;
  final VacancyFigures figures;
}

/// `GET /vacancy`: the year's empty days and rent lost, worst unit first.
class VacancyReport {
  const VacancyReport({
    required this.year,
    required this.from,
    required this.to,
    required this.lost,
    required this.vacantDays,
    required this.unpricedUnits,
    required this.units,
    this.occupancyPercent,
  });

  factory VacancyReport.fromJson(Map<String, dynamic> j) => VacancyReport(
    year: j['year'] as int,
    from: parseYmd(j['from'] as String),
    to: parseYmd(j['to'] as String),
    lost: j['lost'] as int,
    vacantDays: j['vacant_days'] as int,
    occupancyPercent: (j['occupancy_percent'] as num?)?.toDouble(),
    unpricedUnits: j['unpriced_units'] as int? ?? 0,
    units: (j['units'] as List<dynamic>)
        .map((u) => UnitVacancy.fromJson(u as Map<String, dynamic>))
        .toList(),
  );

  final int year;
  final DateTime from;
  final DateTime to;
  final int lost;
  final int vacantDays;
  final double? occupancyPercent;
  final int unpricedUnits;
  final List<UnitVacancy> units;
}
