import '../../../core/utils/dates.dart';

enum PaymentMethod {
  cash,
  telebirr,
  bank,
  chapa,

  /// Paid from the deposit at move-out.
  deposit;

  static PaymentMethod parse(String? v) => PaymentMethod.values.firstWhere(
    (m) => m.name == v,
    orElse: () => PaymentMethod.cash,
  );

  /// Methods a landlord logs by hand (Chapa arrives online in phase 2).
  static const manual = [
    PaymentMethod.cash,
    PaymentMethod.telebirr,
    PaymentMethod.bank,
  ];

  bool get needsReference => this != PaymentMethod.cash;
}

class PaymentAllocation {
  const PaymentAllocation({required this.period, required this.amount});

  factory PaymentAllocation.fromJson(Map<String, dynamic> j) =>
      PaymentAllocation(
        period: j['period'] as String,
        amount: j['amount'] as int,
      );

  final String period;
  final int amount;
}

/// A logged payment. Amounts are in santim.
class Payment {
  const Payment({
    required this.id,
    required this.receiptNumber,
    required this.amount,
    required this.paidAt,
    required this.method,
    this.leaseId,
    this.reference,
    this.notes,
    this.source = 'manual',
    this.receiptUrl,
    this.tenantName,
    this.allocations = const [],
    this.smsStatus,
  });

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
    id: j['id'] as int,
    receiptNumber: j['receipt_number'] as String,
    leaseId: j['lease_id'] as int?,
    amount: j['amount'] as int,
    paidAt: parseYmd(j['paid_at'] as String),
    method: PaymentMethod.parse(j['method'] as String?),
    reference: j['reference'] as String?,
    notes: j['notes'] as String?,
    source: j['source'] as String? ?? 'manual',
    receiptUrl: j['receipt_url'] as String?,
    tenantName: j['tenant_name'] as String?,
    allocations: (j['allocations'] as List<dynamic>? ?? [])
        .map((a) => PaymentAllocation.fromJson(a as Map<String, dynamic>))
        .toList(),
    smsStatus: j['sms_status'] as String?,
  );

  final int id;
  final String receiptNumber;
  final int? leaseId;
  final int amount;
  final DateTime paidAt;
  final PaymentMethod method;
  final String? reference;
  final String? notes;
  final String source;
  final String? receiptUrl;
  final String? tenantName;
  final List<PaymentAllocation> allocations;
  final String? smsStatus;

  bool get isManual => source == 'manual';
}
