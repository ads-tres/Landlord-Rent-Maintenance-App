import '../../../core/utils/dates.dart';

/// One tenant who still owes for the month. [skip] is opted_out, reminded_today or no_tenant.
class ReminderCandidate {
  const ReminderCandidate({
    required this.leaseId,
    required this.unit,
    required this.owed,
    required this.dueDate,
    this.tenant,
    this.property,
    this.skip,
  });

  factory ReminderCandidate.fromJson(Map<String, dynamic> j) =>
      ReminderCandidate(
        leaseId: j['lease_id'] as int,
        tenant: j['tenant'] as String?,
        unit: j['unit'] as String? ?? '',
        property: j['property'] as String?,
        owed: j['owed'] as int,
        dueDate: parseYmd(j['due_date'] as String),
        skip: j['skip'] as String?,
      );

  final int leaseId;
  final String? tenant;
  final String unit;
  final String? property;
  final int owed;
  final DateTime dueDate;
  final String? skip;
}

/// `GET /rent/reminders`: who would get a reminder, with a sample message.
class ReminderPreview {
  const ReminderPreview({
    required this.period,
    required this.willSend,
    required this.skipped,
    required this.totalOwed,
    required this.items,
    this.sample,
  });

  factory ReminderPreview.fromJson(Map<String, dynamic> j) => ReminderPreview(
    period: j['period'] as String,
    willSend: j['will_send'] as int,
    skipped: j['skipped'] as int,
    totalOwed: j['total_owed'] as int,
    sample: j['sample'] as String?,
    items: (j['items'] as List<dynamic>)
        .map((i) => ReminderCandidate.fromJson(i as Map<String, dynamic>))
        .toList(),
  );

  final String period;
  final int willSend;
  final int skipped;
  final int totalOwed;
  final String? sample;
  final List<ReminderCandidate> items;
}
