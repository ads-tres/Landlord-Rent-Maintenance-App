import '../../../core/utils/dates.dart';

enum PaymentRating {
  newTenant,
  good,
  fair,
  poor;

  static PaymentRating parse(String? v) => switch (v) {
    'good' => good,
    'fair' => fair,
    'poor' => poor,
    _ => newTenant,
  };
}

/// One rent month: on_time, late or unpaid.
class RecordMonth {
  const RecordMonth({
    required this.period,
    required this.status,
    this.daysLate,
  });

  factory RecordMonth.fromJson(Map<String, dynamic> j) => RecordMonth(
    period: j['period'] as String,
    status: j['status'] as String,
    daysLate: j['days_late'] as int?,
  );

  /// YYYY-MM.
  final String period;
  final String status;
  final int? daysLate;
}

/// How a tenant has paid rent, from `GET /tenants/{id}/record`, or the short version
/// on renewals and applications. Amounts in santim.
class TenantRecord {
  const TenantRecord({
    required this.rating,
    required this.charges,
    this.onTime = 0,
    this.late = 0,
    this.unpaid = 0,
    this.onTimePercent,
    this.averageDaysLate,
    this.outstanding = 0,
    this.leases = 0,
    this.tenantSince,
    this.recent = const [],
    this.notes,
  });

  factory TenantRecord.fromJson(Map<String, dynamic> j) => TenantRecord(
    rating: PaymentRating.parse(j['rating'] as String?),
    charges: j['charges'] as int? ?? 0,
    onTime: j['on_time'] as int? ?? 0,
    late: j['late'] as int? ?? 0,
    unpaid: j['unpaid'] as int? ?? 0,
    onTimePercent: (j['on_time_percent'] as num?)?.toDouble(),
    averageDaysLate: (j['average_days_late'] as num?)?.toDouble(),
    outstanding: j['outstanding'] as int? ?? 0,
    leases: j['leases'] as int? ?? 0,
    tenantSince: j['tenant_since'] == null
        ? null
        : parseYmd(j['tenant_since'] as String),
    recent: (j['recent'] as List<dynamic>? ?? const [])
        .map((m) => RecordMonth.fromJson(m as Map<String, dynamic>))
        .toList(),
    notes: j['notes'] as String?,
  );

  final PaymentRating rating;

  /// Rent months already due.
  final int charges;
  final int onTime;
  final int late;
  final int unpaid;
  final double? onTimePercent;
  final double? averageDaysLate;
  final int outstanding;
  final int leases;
  final DateTime? tenantSince;

  /// The last 12 months due, oldest first.
  final List<RecordMonth> recent;

  /// The landlord's private notes; null for caretakers.
  final String? notes;

  /// `92.5` → `"92.5"`, `20.0` → `"20"`.
  String get percentLabel {
    final p = onTimePercent ?? 0;
    return p == p.roundToDouble() ? p.toStringAsFixed(0) : '$p';
  }
}
