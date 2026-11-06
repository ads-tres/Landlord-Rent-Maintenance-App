import '../../../core/utils/dates.dart';

/// Shared meters, utility bills, equipment and announcements. Amounts in santim.

enum MeterKind {
  electricity,
  water;

  static MeterKind parse(String? v) =>
      v == 'water' ? MeterKind.water : MeterKind.electricity;
}

enum SplitMethod {
  equal,
  percent,
  submeter;

  static SplitMethod parse(String? v) => SplitMethod.values.firstWhere(
    (m) => m.name == v,
    orElse: () => SplitMethod.equal,
  );
}

class MeterUnitShare {
  const MeterUnitShare({
    required this.unitId,
    required this.label,
    this.sharePercent,
    this.occupied = false,
  });

  factory MeterUnitShare.fromJson(Map<String, dynamic> j) => MeterUnitShare(
    unitId: j['unit_id'] as int,
    label: j['label'] as String? ?? '',
    sharePercent: (j['share_percent'] as num?)?.toDouble(),
    occupied: j['occupied'] as bool? ?? false,
  );

  final int unitId;
  final String label;
  final double? sharePercent;
  final bool occupied;
}

class Meter {
  const Meter({
    required this.id,
    required this.propertyId,
    required this.name,
    required this.kind,
    required this.splitMethod,
    this.units = const [],
    this.lastBillPeriod,
    this.lastBillAmount,
  });

  factory Meter.fromJson(Map<String, dynamic> j) {
    final last = j['last_bill'] as Map<String, dynamic>?;
    return Meter(
      id: j['id'] as int,
      propertyId: j['property_id'] as int,
      name: j['name'] as String,
      kind: MeterKind.parse(j['kind'] as String?),
      splitMethod: SplitMethod.parse(j['split_method'] as String?),
      units: (j['units'] as List<dynamic>? ?? [])
          .map((u) => MeterUnitShare.fromJson(u as Map<String, dynamic>))
          .toList(),
      lastBillPeriod: last?['period'] as String?,
      lastBillAmount: last?['amount'] as int?,
    );
  }

  final int id;
  final int propertyId;
  final String name;
  final MeterKind kind;
  final SplitMethod splitMethod;
  final List<MeterUnitShare> units;
  final String? lastBillPeriod;
  final int? lastBillAmount;
}

class SplitLine {
  const SplitLine({
    required this.unitLabel,
    required this.amount,
    this.tenantName,
    this.vacant = false,
  });

  factory SplitLine.fromJson(Map<String, dynamic> j) => SplitLine(
    unitLabel: j['unit_label'] as String? ?? '',
    amount: j['amount'] as int,
    tenantName: j['tenant_name'] as String?,
    vacant: j['vacant'] as bool? ?? false,
  );

  final String unitLabel;
  final int amount;
  final String? tenantName;
  final bool vacant;
}

class SplitPreview {
  const SplitPreview({
    required this.amount,
    required this.landlordShare,
    required this.lines,
  });

  factory SplitPreview.fromJson(Map<String, dynamic> j) => SplitPreview(
    amount: j['amount'] as int,
    landlordShare: j['landlord_share'] as int,
    lines: (j['lines'] as List<dynamic>)
        .map((l) => SplitLine.fromJson(l as Map<String, dynamic>))
        .toList(),
  );

  final int amount;
  final int landlordShare;
  final List<SplitLine> lines;
}

class UtilityBill {
  const UtilityBill({
    required this.id,
    required this.period,
    required this.amount,
    required this.dueDate,
    required this.landlordShare,
    this.lines = const [],
  });

  factory UtilityBill.fromJson(Map<String, dynamic> j) => UtilityBill(
    id: j['id'] as int,
    period: j['period'] as String,
    amount: j['amount'] as int,
    dueDate: parseYmd(j['due_date'] as String),
    landlordShare: j['landlord_share'] as int? ?? 0,
    lines: (j['charges'] as List<dynamic>? ?? [])
        .map(
          (c) => SplitLine(
            unitLabel:
                (c as Map<String, dynamic>)['unit_label'] as String? ?? '',
            amount: c['amount'] as int,
            tenantName: c['tenant_name'] as String?,
          ),
        )
        .toList(),
  );

  final int id;
  final String period;
  final int amount;
  final DateTime dueDate;
  final int landlordShare;
  final List<SplitLine> lines;
}

enum AssetKind {
  generator,
  waterTank,
  pump,
  other;

  static AssetKind parse(String? v) => switch (v) {
    'generator' => AssetKind.generator,
    'water_tank' => AssetKind.waterTank,
    'pump' => AssetKind.pump,
    _ => AssetKind.other,
  };

  String get apiValue => this == AssetKind.waterTank ? 'water_tank' : name;
}

class Asset {
  const Asset({
    required this.id,
    required this.propertyId,
    required this.kind,
    required this.name,
    required this.serviceIntervalDays,
    this.propertyName,
    this.lastServicedOn,
    this.nextServiceOn,
    this.daysUntilService,
  });

  factory Asset.fromJson(Map<String, dynamic> j) => Asset(
    id: j['id'] as int,
    propertyId: j['property_id'] as int,
    kind: AssetKind.parse(j['kind'] as String?),
    name: j['name'] as String,
    serviceIntervalDays: j['service_interval_days'] as int,
    propertyName: j['property_name'] as String?,
    lastServicedOn: j['last_serviced_on'] == null
        ? null
        : parseYmd(j['last_serviced_on'] as String),
    nextServiceOn: j['next_service_on'] == null
        ? null
        : parseYmd(j['next_service_on'] as String),
    daysUntilService: j['days_until_service'] as int?,
  );

  final int id;
  final int propertyId;
  final AssetKind kind;
  final String name;
  final int serviceIntervalDays;
  final String? propertyName;
  final DateTime? lastServicedOn;
  final DateTime? nextServiceOn;
  final int? daysUntilService;

  /// Never serviced, or past the next service date.
  bool get overdue => nextServiceOn == null || (daysUntilService ?? 0) < 0;
}

class AnnouncementPreview {
  const AnnouncementPreview({
    required this.recipients,
    required this.telegram,
    required this.sms,
    required this.smsSegments,
    required this.text,
    this.estimatedCost,
  });

  factory AnnouncementPreview.fromJson(Map<String, dynamic> j) =>
      AnnouncementPreview(
        recipients: j['recipients'] as int,
        telegram: j['telegram'] as int,
        sms: j['sms'] as int,
        smsSegments: j['sms_segments'] as int,
        text: j['text'] as String,
        estimatedCost: j['estimated_cost'] as int?,
      );

  final int recipients;
  final int telegram;
  final int sms;
  final int smsSegments;
  final String text;
  final int? estimatedCost;
}
