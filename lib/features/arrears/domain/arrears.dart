import '../../../core/utils/dates.dart';
import '../../../l10n/app_localizations.dart';

enum ArrearsStep {
  reminder,
  notice,
  demandLetter,
  plan,
  note;

  static ArrearsStep? parse(String? v) => switch (v) {
    'reminder' => reminder,
    'notice' => notice,
    'demand_letter' => demandLetter,
    'plan' => plan,
    'note' => note,
    _ => null,
  };

  String label(AppLocalizations l10n) => switch (this) {
    reminder => l10n.arrearsReminder,
    notice => l10n.arrearsNotice,
    demandLetter => l10n.arrearsDemandLetter,
    plan => l10n.arrearsPlan,
    note => l10n.arrearsNote,
  };
}

class PlanInstalment {
  const PlanInstalment({
    required this.dueDate,
    required this.amount,
    this.covered = false,
    this.overdue = false,
  });

  factory PlanInstalment.fromJson(Map<String, dynamic> j) => PlanInstalment(
    dueDate: parseYmd(j['due_date'] as String),
    amount: j['amount'] as int,
    covered: j['covered'] as bool? ?? false,
    overdue: j['overdue'] as bool? ?? false,
  );

  final DateTime dueDate;
  final int amount;
  final bool covered;
  final bool overdue;
}

class PaymentPlanSummary {
  const PaymentPlanSummary({
    required this.id,
    required this.total,
    required this.paid,
    required this.instalments,
  });

  factory PaymentPlanSummary.fromJson(Map<String, dynamic> j) =>
      PaymentPlanSummary(
        id: j['id'] as int,
        total: j['total'] as int,
        paid: j['paid'] as int,
        instalments: [
          for (final i in j['instalments'] as List<dynamic>)
            PlanInstalment.fromJson(i as Map<String, dynamic>),
        ],
      );

  final int id;
  final int total;
  final int paid;
  final List<PlanInstalment> instalments;

  PlanInstalment? get next => instalments.where((i) => !i.covered).firstOrNull;
}

class ArrearsActionEntry {
  const ArrearsActionEntry({
    required this.kind,
    required this.amountOwed,
    required this.createdAt,
    this.note,
    this.by,
  });

  factory ArrearsActionEntry.fromJson(Map<String, dynamic> j) =>
      ArrearsActionEntry(
        kind: ArrearsStep.parse(j['kind'] as String?) ?? ArrearsStep.note,
        amountOwed: j['amount_owed'] as int,
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
        note: j['note'] as String?,
        by: j['by'] as String?,
      );

  final ArrearsStep kind;
  final int amountOwed;
  final DateTime createdAt;
  final String? note;
  final String? by;
}

/// A late lease: `GET /arrears` rows and `GET /leases/{id}/arrears`.
class Arrears {
  const Arrears({
    required this.leaseId,
    required this.owed,
    required this.daysOverdue,
    required this.monthsBehind,
    this.tenantName,
    this.unitLabel,
    this.propertyName,
    this.suggested,
    this.lastAction,
    this.plan,
    this.actions = const [],
  });

  factory Arrears.fromJson(Map<String, dynamic> j) => Arrears(
    leaseId: j['lease_id'] as int,
    owed: j['owed'] as int,
    daysOverdue: j['days_overdue'] as int,
    monthsBehind: j['months_behind'] as int? ?? 0,
    tenantName: j['tenant_name'] as String?,
    unitLabel: j['unit_label'] as String?,
    propertyName: j['property_name'] as String?,
    suggested: ArrearsStep.parse(j['suggested'] as String?),
    lastAction: ArrearsStep.parse(
      (j['last_action'] as Map<String, dynamic>?)?['kind'] as String?,
    ),
    plan: j['plan'] == null
        ? null
        : PaymentPlanSummary.fromJson(j['plan'] as Map<String, dynamic>),
    actions: [
      for (final a in j['actions'] as List<dynamic>? ?? [])
        ArrearsActionEntry.fromJson(a as Map<String, dynamic>),
    ],
  );

  final int leaseId;
  final int owed;
  final int daysOverdue;
  final int monthsBehind;
  final String? tenantName;
  final String? unitLabel;
  final String? propertyName;
  final ArrearsStep? suggested;
  final ArrearsStep? lastAction;
  final PaymentPlanSummary? plan;
  final List<ArrearsActionEntry> actions;
}
