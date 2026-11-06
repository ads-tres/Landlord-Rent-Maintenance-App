enum RepairStatus {
  open,
  inProgress,
  done;

  static RepairStatus parse(String? v) => switch (v) {
    'in_progress' => RepairStatus.inProgress,
    'done' => RepairStatus.done,
    _ => RepairStatus.open,
  };

  String get apiValue => switch (this) {
    RepairStatus.open => 'open',
    RepairStatus.inProgress => 'in_progress',
    RepairStatus.done => 'done',
  };
}

enum RepairCategory {
  water,
  electric,
  plumbing,
  doorLock,
  roof,
  appliance,
  other;

  static RepairCategory parse(String? v) => switch (v) {
    'door_lock' => RepairCategory.doorLock,
    _ => RepairCategory.values.firstWhere(
      (c) => c.name == v,
      orElse: () => RepairCategory.other,
    ),
  };

  String get apiValue => this == RepairCategory.doorLock ? 'door_lock' : name;
}

class RepairPhoto {
  const RepairPhoto({required this.id, required this.url});

  factory RepairPhoto.fromJson(Map<String, dynamic> j) =>
      RepairPhoto(id: j['id'] as int, url: j['url'] as String);

  final int id;
  final String url;
}

/// A maintenance request, from the tenant's repair link or recorded by the landlord.
class Repair {
  const Repair({
    required this.id,
    required this.unitId,
    required this.title,
    required this.category,
    required this.status,
    required this.fromTenant,
    required this.openedAt,
    this.description,
    this.resolutionNote,
    this.cost,
    this.closedAt,
    this.unitLabel,
    this.propertyName,
    this.tenantName,
    this.tenantPhone,
    this.photosCount = 0,
    this.photos = const [],
    this.voiceNotes = const [],
  });

  factory Repair.fromJson(Map<String, dynamic> j) {
    final unit = j['unit'] as Map<String, dynamic>?;
    final tenant = j['tenant'] as Map<String, dynamic>?;
    final photos = (j['photos'] as List<dynamic>? ?? [])
        .map((p) => RepairPhoto.fromJson(p as Map<String, dynamic>))
        .toList();
    return Repair(
      id: j['id'] as int,
      unitId: j['unit_id'] as int,
      title: j['title'] as String,
      category: RepairCategory.parse(j['category'] as String?),
      status: RepairStatus.parse(j['status'] as String?),
      fromTenant: j['source'] == 'tenant',
      openedAt: DateTime.parse(j['opened_at'] as String).toLocal(),
      closedAt: j['closed_at'] == null
          ? null
          : DateTime.parse(j['closed_at'] as String).toLocal(),
      description: j['description'] as String?,
      resolutionNote: j['resolution_note'] as String?,
      cost: j['cost'] as int?,
      unitLabel: unit?['label'] as String?,
      propertyName: unit?['property_name'] as String?,
      tenantName: tenant?['full_name'] as String?,
      tenantPhone: tenant?['phone'] as String?,
      photosCount: j['photos_count'] as int? ?? photos.length,
      photos: photos,
      voiceNotes: (j['voice_notes'] as List<dynamic>? ?? [])
          .map((p) => RepairPhoto.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  final int id;
  final int unitId;
  final String title;
  final RepairCategory category;
  final RepairStatus status;
  final bool fromTenant;
  final DateTime openedAt;
  final DateTime? closedAt;
  final String? description;
  final String? resolutionNote;

  /// What the repair cost, in santim; recorded as an expense.
  final int? cost;
  final String? unitLabel;
  final String? propertyName;
  final String? tenantName;
  final String? tenantPhone;
  final int photosCount;
  final List<RepairPhoto> photos;

  /// Voice notes sent by the tenant on Telegram; `url` is a short-lived signed link.
  final List<RepairPhoto> voiceNotes;
}

/// A unit for pickers (`GET /units`).
class UnitOption {
  const UnitOption({
    required this.id,
    required this.label,
    required this.propertyName,
    this.tenantName,
  });

  factory UnitOption.fromJson(Map<String, dynamic> j) => UnitOption(
    id: j['id'] as int,
    label: j['label'] as String,
    propertyName: j['property_name'] as String,
    tenantName: j['tenant_name'] as String?,
  );

  final int id;
  final String label;
  final String propertyName;
  final String? tenantName;
}
