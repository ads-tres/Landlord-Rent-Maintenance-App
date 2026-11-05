import '../../../core/utils/dates.dart';

enum ChargeStatus {
  due,
  partial,
  paid,
  late;

  static ChargeStatus parse(String? v) => ChargeStatus.values.firstWhere(
    (s) => s.name == v,
    orElse: () => ChargeStatus.due,
  );
}

/// One month's rent for a lease. Amounts are in santim.
class Charge {
  const Charge({
    required this.id,
    required this.leaseId,
    required this.period,
    required this.amountDue,
    required this.amountPaid,
    required this.balance,
    required this.dueDate,
    required this.status,
    this.daysLate = 0,
    this.tenantName,
    this.unitLabel,
    this.propertyName,
  });

  factory Charge.fromJson(Map<String, dynamic> j) {
    final tenant = j['tenant'] as Map<String, dynamic>?;
    final unit = j['unit'] as Map<String, dynamic>?;
    return Charge(
      id: j['id'] as int,
      leaseId: j['lease_id'] as int,
      period: j['period'] as String,
      amountDue: j['amount_due'] as int,
      amountPaid: j['amount_paid'] as int? ?? 0,
      balance: j['balance'] as int? ?? 0,
      dueDate: parseYmd(j['due_date'] as String),
      status: ChargeStatus.parse(j['status'] as String?),
      daysLate: j['days_late'] as int? ?? 0,
      tenantName: tenant?['full_name'] as String?,
      unitLabel: unit?['label'] as String?,
      propertyName: unit?['property_name'] as String?,
    );
  }

  final int id;
  final int leaseId;
  final String period;
  final int amountDue;
  final int amountPaid;
  final int balance;
  final DateTime dueDate;
  final ChargeStatus status;
  final int daysLate;
  final String? tenantName;
  final String? unitLabel;
  final String? propertyName;
}
