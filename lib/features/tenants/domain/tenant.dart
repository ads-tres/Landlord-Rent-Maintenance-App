class Tenant {
  const Tenant({
    required this.id,
    required this.fullName,
    required this.phone,
    this.address,
    this.hasIdNumber = false,
    this.telegramLinked = false,
    this.remindersOptOut = false,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) => Tenant(
    id: json['id'] as int,
    fullName: json['full_name'] as String,
    phone: json['phone'] as String,
    address: json['address'] as String?,
    hasIdNumber: json['has_id_number'] as bool? ?? false,
    telegramLinked: json['telegram_linked'] as bool? ?? false,
    remindersOptOut: json['reminders_opt_out'] as bool? ?? false,
  );

  final int id;
  final String fullName;
  final String phone;
  final String? address;
  final bool hasIdNumber;
  final bool telegramLinked;

  /// The tenant asked not to get rent reminders.
  final bool remindersOptOut;
}

/// A message sent to a tenant (`GET /tenants/{id}/messages`).
class TenantMessage {
  const TenantMessage({
    required this.kind,
    required this.channel,
    required this.status,
    required this.body,
    required this.createdAt,
    this.error,
    this.sendAfter,
  });

  factory TenantMessage.fromJson(Map<String, dynamic> j) => TenantMessage(
    kind: j['kind'] as String,
    channel: j['channel'] as String? ?? 'sms',
    status: j['status'] as String,
    body: j['body'] as String,
    createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
    error: j['error'] as String?,
    sendAfter: j['send_after'] == null
        ? null
        : DateTime.parse(j['send_after'] as String).toLocal(),
  );

  final String kind;
  final String channel;

  /// queued, sent or failed.
  final String status;
  final String body;
  final DateTime createdAt;
  final String? error;

  /// Held for quiet hours until this time.
  final DateTime? sendAfter;

  bool get isTelegram => channel == 'telegram';
}
