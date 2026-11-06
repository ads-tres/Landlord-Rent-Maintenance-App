import '../../../core/utils/dates.dart';
import '../../../l10n/app_localizations.dart';

enum DeductionKind {
  unpaidRent('unpaid_rent'),
  unpaidUtility('unpaid_utility'),
  damage('damage'),
  cleaning('cleaning'),
  keys('keys'),
  other('other');

  const DeductionKind(this.apiValue);

  final String apiValue;

  /// Kinds the landlord adds; unpaid rent and utilities come from the lease.
  static const manual = [damage, cleaning, keys, other];

  static DeductionKind parse(String? v) =>
      values.firstWhere((k) => k.apiValue == v, orElse: () => other);

  String label(AppLocalizations l10n) => switch (this) {
    unpaidRent => l10n.deductionUnpaidRent,
    unpaidUtility => l10n.deductionUnpaidUtility,
    damage => l10n.deductionDamage,
    cleaning => l10n.deductionCleaning,
    keys => l10n.deductionKeys,
    other => l10n.deductionOther,
  };
}

class Deduction {
  const Deduction({
    required this.id,
    required this.kind,
    required this.amount,
    this.description,
    this.fromCharge = false,
  });

  factory Deduction.fromJson(Map<String, dynamic> j) => Deduction(
    id: j['id'] as int,
    kind: DeductionKind.parse(j['kind'] as String?),
    amount: j['amount'] as int,
    description: j['description'] as String?,
    fromCharge: j['from_charge'] as bool? ?? false,
  );

  final int id;
  final DeductionKind kind;
  final int amount;
  final String? description;

  /// An unpaid charge on the lease: paid from the deposit or left owed.
  final bool fromCharge;
}

/// `GET /move-outs/{id}`. Amounts in santim.
class MoveOut {
  const MoveOut({
    required this.id,
    required this.leaseId,
    required this.settled,
    required this.movedOutOn,
    required this.deposit,
    required this.depositApplied,
    required this.depositKept,
    required this.refundAmount,
    required this.balanceOwed,
    required this.statementUrl,
    this.conditionNotes,
    this.keysReturned = false,
    this.refundMethod,
    this.refundReference,
    this.deductions = const [],
    this.photoUrls = const [],
    this.tenantName,
    this.unitLabel,
    this.unitId,
  });

  factory MoveOut.fromJson(Map<String, dynamic> j) => MoveOut(
    id: j['id'] as int,
    leaseId: j['lease_id'] as int,
    settled: j['status'] == 'settled',
    movedOutOn: parseYmd(j['moved_out_on'] as String),
    conditionNotes: j['condition_notes'] as String?,
    keysReturned: j['keys_returned'] as bool? ?? false,
    deposit: j['deposit'] as int,
    depositApplied: j['deposit_applied'] as int,
    depositKept: j['deposit_kept'] as int,
    refundAmount: j['refund_amount'] as int,
    balanceOwed: j['balance_owed'] as int,
    refundMethod: j['refund_method'] as String?,
    refundReference: j['refund_reference'] as String?,
    statementUrl: j['statement_url'] as String,
    deductions: [
      for (final d in j['deductions'] as List<dynamic>? ?? [])
        Deduction.fromJson(d as Map<String, dynamic>),
    ],
    photoUrls: [
      for (final p in j['photos'] as List<dynamic>? ?? [])
        (p as Map<String, dynamic>)['url'] as String,
    ],
    tenantName: j['tenant_name'] as String?,
    unitLabel: j['unit_label'] as String?,
    unitId: j['unit_id'] as int?,
  );

  final int id;
  final int leaseId;
  final bool settled;
  final DateTime movedOutOn;
  final String? conditionNotes;
  final bool keysReturned;
  final int deposit;
  final int depositApplied;
  final int depositKept;
  final int refundAmount;
  final int balanceOwed;
  final String? refundMethod;
  final String? refundReference;
  final String statementUrl;
  final List<Deduction> deductions;
  final List<String> photoUrls;
  final String? tenantName;
  final String? unitLabel;
  final int? unitId;

  int get deductionsTotal => deductions.fold(0, (s, d) => s + d.amount);
}
