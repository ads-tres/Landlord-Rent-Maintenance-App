import '../../../core/utils/dates.dart';

enum LeaseStatus {
  draft,
  active,
  ended;

  static LeaseStatus parse(String? v) => LeaseStatus.values.firstWhere(
    (s) => s.name == v,
    orElse: () => LeaseStatus.active,
  );
}

class RentChange {
  const RentChange({
    this.id = 0,
    required this.oldRent,
    required this.newRent,
    required this.effectiveDate,
    required this.capPercent,
    this.noticeDays,
    this.tenantAgreed = false,
    this.tenantNotified = false,
    this.upcoming = false,
  });

  factory RentChange.fromJson(Map<String, dynamic> j) => RentChange(
    id: j['id'] as int? ?? 0,
    oldRent: j['old_rent'] as int,
    newRent: j['new_rent'] as int,
    effectiveDate: parseYmd(j['effective_date'] as String),
    capPercent: (j['cap_percent'] as num).toDouble(),
    noticeDays: j['notice_days'] as int?,
    tenantAgreed: j['tenant_agreed'] as bool? ?? false,
    tenantNotified: j['notified_at'] != null,
    upcoming: j['upcoming'] as bool? ?? false,
  );

  final int id;

  final int oldRent;
  final int newRent;
  final DateTime effectiveDate;
  final double capPercent;

  /// Days between saving the change and the new rent starting.
  final int? noticeDays;
  final bool tenantAgreed;

  /// The tenant was sent the notice by SMS or Telegram.
  final bool tenantNotified;

  /// Not started yet, so it can still be cancelled.
  final bool upcoming;

  bool get isIncrease => newRent > oldRent;
}

class LeaseBalance {
  const LeaseBalance({
    required this.charged,
    required this.paid,
    required this.outstanding,
  });

  factory LeaseBalance.fromJson(Map<String, dynamic> j) => LeaseBalance(
    charged: j['charged'] as int,
    paid: j['paid'] as int,
    outstanding: j['outstanding'] as int,
  );

  final int charged;
  final int paid;
  final int outstanding;
}

/// Amounts are in santim.
class Lease {
  const Lease({
    required this.id,
    required this.unitId,
    required this.tenantId,
    required this.startDate,
    required this.endDate,
    required this.monthlyRent,
    required this.deposit,
    required this.dueDay,
    required this.status,
    this.terminatedOn,
    this.conditionNotes,
    this.registeredAt,
    this.registrationNumber,
    this.registrationOffice,
    this.extraTerms,
    this.agreementBlanks = const [],
    this.documentUrls = const [],
    this.daysUntilEnd,
    this.repairUrl,
    this.portalUrl,
    this.payUrl,
    this.unitLabel,
    this.propertyId,
    this.propertyName,
    this.tenantName,
    this.tenantPhone,
    this.missingFields = const [],
    this.balance,
    this.rentChanges = const [],
    this.moveOutId,
    this.moveOutSettled = false,
  });

  factory Lease.fromJson(Map<String, dynamic> j) {
    final unit = j['unit'] as Map<String, dynamic>?;
    final tenant = j['tenant'] as Map<String, dynamic>?;
    final check = j['directive_check'] as Map<String, dynamic>?;
    final balance = j['balance'] as Map<String, dynamic>?;
    return Lease(
      id: j['id'] as int,
      unitId: j['unit_id'] as int,
      tenantId: j['tenant_id'] as int,
      startDate: parseYmd(j['start_date'] as String),
      endDate: parseYmd(j['end_date'] as String),
      terminatedOn: j['terminated_on'] == null
          ? null
          : parseYmd(j['terminated_on'] as String),
      monthlyRent: j['monthly_rent'] as int,
      deposit: j['deposit'] as int? ?? 0,
      dueDay: j['due_day'] as int? ?? 1,
      status: LeaseStatus.parse(j['status'] as String?),
      conditionNotes: j['condition_notes'] as String?,
      registeredAt: j['registered_at'] == null
          ? null
          : parseYmd(j['registered_at'] as String),
      registrationNumber: j['registration_number'] as String?,
      registrationOffice: j['registration_office'] as String?,
      extraTerms: j['extra_terms'] as String?,
      agreementBlanks: (j['agreement_blanks'] as List<dynamic>? ?? [])
          .cast<String>(),
      documentUrls: [
        for (final d in j['documents'] as List<dynamic>? ?? [])
          (d as Map<String, dynamic>)['url'] as String,
      ],
      daysUntilEnd: j['days_until_end'] as int?,
      repairUrl: j['repair_url'] as String?,
      portalUrl: j['portal_url'] as String?,
      payUrl: j['pay_url'] as String?,
      unitLabel: unit?['label'] as String?,
      propertyId: unit?['property_id'] as int?,
      propertyName: unit?['property_name'] as String?,
      tenantName: tenant?['full_name'] as String?,
      tenantPhone: tenant?['phone'] as String?,
      missingFields: (check?['missing'] as List<dynamic>? ?? []).cast<String>(),
      balance: balance == null ? null : LeaseBalance.fromJson(balance),
      moveOutId: (j['move_out'] as Map<String, dynamic>?)?['id'] as int?,
      moveOutSettled:
          (j['move_out'] as Map<String, dynamic>?)?['status'] == 'settled',
      rentChanges: (j['rent_changes'] as List<dynamic>? ?? [])
          .map((c) => RentChange.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  final int id;
  final int unitId;
  final int tenantId;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? terminatedOn;
  final int monthlyRent;
  final int deposit;
  final int dueDay;

  /// The tenant's own page (balance, receipts, repairs); null once it has closed.
  final String? portalUrl;

  /// The lease's move-out, once started.
  final int? moveOutId;
  final bool moveOutSettled;
  final LeaseStatus status;
  final String? conditionNotes;
  final DateTime? registeredAt;
  final String? registrationNumber;
  final String? registrationOffice;

  /// Extra clauses printed in the lease agreement.
  final String? extraTerms;

  /// Details that will print as blank lines in the agreement.
  final List<String> agreementBlanks;

  /// Photos of the signed agreement.
  final List<String> documentUrls;
  final int? daysUntilEnd;
  final String? repairUrl;

  /// Tenant's online rent page; null unless the landlord accepts online rent.
  final String? payUrl;
  final String? unitLabel;
  final int? propertyId;
  final String? propertyName;
  final String? tenantName;
  final String? tenantPhone;
  final List<String> missingFields;
  final LeaseBalance? balance;
  final List<RentChange> rentChanges;

  bool get isActive => status == LeaseStatus.active;
}
