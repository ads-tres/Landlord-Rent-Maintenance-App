import '../../../core/utils/dates.dart';
import '../../tenants/domain/tenant_record.dart';

/// `GET /leases/{id}/renewal-check`. Amounts in santim.
class RenewalCheck {
  const RenewalCheck({
    required this.currentEndDate,
    required this.suggestedEndDate,
    required this.rentFrom,
    required this.currentRent,
    required this.maxRent,
    required this.capPercent,
    required this.canRenewFrom,
    this.tenantRecord,
  });

  factory RenewalCheck.fromJson(Map<String, dynamic> j) => RenewalCheck(
    currentEndDate: parseYmd(j['current_end_date'] as String),
    suggestedEndDate: parseYmd(j['suggested_end_date'] as String),
    rentFrom: parseYmd(j['rent_from'] as String),
    currentRent: j['current_rent'] as int,
    maxRent: j['max_rent'] as int,
    capPercent: (j['cap_percent'] as num).toDouble(),
    canRenewFrom: parseYmd(j['can_renew_from'] as String),
    tenantRecord: j['tenant_record'] == null
        ? null
        : TenantRecord.fromJson(j['tenant_record'] as Map<String, dynamic>),
  );

  final DateTime currentEndDate;
  final DateTime suggestedEndDate;
  final DateTime rentFrom;
  final int currentRent;
  final int maxRent;
  final double capPercent;
  final DateTime canRenewFrom;

  /// How the tenant has paid so far.
  final TenantRecord? tenantRecord;
}

class LeaseRenewal {
  const LeaseRenewal({
    required this.id,
    required this.newEndDate,
    required this.newRent,
    required this.rentFrom,
  });

  factory LeaseRenewal.fromJson(Map<String, dynamic> j) => LeaseRenewal(
    id: j['id'] as int,
    newEndDate: parseYmd(j['new_end_date'] as String),
    newRent: j['new_rent'] as int,
    rentFrom: parseYmd(j['rent_from'] as String),
  );

  final int id;
  final DateTime newEndDate;
  final int newRent;
  final DateTime rentFrom;
}
