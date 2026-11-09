import '../../../core/utils/dates.dart';
import '../../tenants/domain/tenant_record.dart';

enum ListingStatus {
  draft,
  live,
  closed,
  suspended;

  static ListingStatus parse(String? v) => ListingStatus.values.firstWhere(
    (s) => s.name == v,
    orElse: () => ListingStatus.draft,
  );
}

class RentCheck {
  const RentCheck({
    this.lastRent,
    this.maxAllowed,
    this.exceeds = false,
    this.capPercent = 11.5,
  });

  factory RentCheck.fromJson(Map<String, dynamic> j) => RentCheck(
    lastRent: j['last_rent'] as int?,
    maxAllowed: j['max_allowed'] as int?,
    exceeds: j['exceeds'] as bool? ?? false,
    capPercent: (j['cap_percent'] as num?)?.toDouble() ?? 11.5,
  );

  final int? lastRent;
  final int? maxAllowed;
  final bool exceeds;
  final double capPercent;
}

/// A vacant unit offered through a shareable link. Amounts in santim.
class Listing {
  const Listing({
    required this.id,
    required this.unitId,
    required this.askingRent,
    required this.availableFrom,
    required this.status,
    required this.url,
    this.unitLabel,
    this.propertyName,
    this.description,
    this.expiresAt,
    this.reportCount = 0,
    this.applicationsCount = 0,
    this.rentCheck,
    this.shareText = const {},
    this.photos = const [],
  });

  factory Listing.fromJson(Map<String, dynamic> j) => Listing(
    id: j['id'] as int,
    unitId: j['unit_id'] as int,
    askingRent: j['asking_rent'] as int,
    availableFrom: parseYmd(j['available_from'] as String),
    status: ListingStatus.parse(j['status'] as String?),
    url: j['url'] as String,
    unitLabel: j['unit_label'] as String?,
    propertyName: j['property_name'] as String?,
    description: j['description'] as String?,
    expiresAt: j['expires_at'] == null
        ? null
        : DateTime.parse(j['expires_at'] as String).toLocal(),
    reportCount: j['report_count'] as int? ?? 0,
    applicationsCount: j['applications_count'] as int? ?? 0,
    rentCheck: j['rent_check'] == null
        ? null
        : RentCheck.fromJson(j['rent_check'] as Map<String, dynamic>),
    shareText: (j['share_text'] as Map<String, dynamic>? ?? {}).map(
      (k, v) => MapEntry(k, v as String),
    ),
    photos: (j['photos'] as List<dynamic>? ?? [])
        .map((p) => (p as Map<String, dynamic>)['url'] as String)
        .toList(),
  );

  final int id;
  final int unitId;
  final int askingRent;
  final DateTime availableFrom;
  final ListingStatus status;
  final String url;
  final String? unitLabel;
  final String? propertyName;
  final String? description;
  final DateTime? expiresAt;
  final int reportCount;
  final int applicationsCount;
  final RentCheck? rentCheck;

  /// Ready-to-post text by language ('am', 'en').
  final Map<String, String> shareText;
  final List<String> photos;
}

enum ApplicationStatus {
  newApp,
  shortlisted,
  rejected,
  approved;

  static ApplicationStatus parse(String? v) => switch (v) {
    'shortlisted' => ApplicationStatus.shortlisted,
    'rejected' => ApplicationStatus.rejected,
    'approved' => ApplicationStatus.approved,
    _ => ApplicationStatus.newApp,
  };

  String get apiValue => this == ApplicationStatus.newApp ? 'new' : name;
}

class ListingApplication {
  const ListingApplication({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.status,
    this.householdSize,
    this.moveInDate,
    this.message,
    this.leaseId,
    this.formerTenant,
  });

  factory ListingApplication.fromJson(Map<String, dynamic> j) =>
      ListingApplication(
        id: j['id'] as int,
        fullName: j['full_name'] as String,
        phone: j['phone'] as String,
        status: ApplicationStatus.parse(j['status'] as String?),
        householdSize: j['household_size'] as int?,
        moveInDate: j['move_in_date'] == null
            ? null
            : parseYmd(j['move_in_date'] as String),
        message: j['message'] as String?,
        leaseId: j['lease_id'] as int?,
        formerTenant: j['former_tenant'] == null
            ? null
            : TenantRecord.fromJson(j['former_tenant'] as Map<String, dynamic>),
      );

  final int id;
  final String fullName;
  final String phone;
  final ApplicationStatus status;
  final int? householdSize;
  final DateTime? moveInDate;
  final String? message;

  /// The draft lease created when approved.
  final int? leaseId;

  /// Set when the applicant rented from this landlord before: how they paid.
  final TenantRecord? formerTenant;
}
