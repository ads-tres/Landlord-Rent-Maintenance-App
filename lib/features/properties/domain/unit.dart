enum UnitStatus {
  vacant,
  occupied;

  static UnitStatus parse(String? value) =>
      value == 'occupied' ? UnitStatus.occupied : UnitStatus.vacant;
}

/// The current lease on a unit, as returned with the property's units.
class ActiveLeaseSummary {
  const ActiveLeaseSummary({
    required this.id,
    required this.monthlyRent,
    required this.endDate,
    this.tenantName,
  });

  factory ActiveLeaseSummary.fromJson(Map<String, dynamic> json) =>
      ActiveLeaseSummary(
        id: json['id'] as int,
        monthlyRent: json['monthly_rent'] as int,
        endDate: DateTime.parse(json['end_date'] as String),
        tenantName: json['tenant_name'] as String?,
      );

  final int id;
  final int monthlyRent;
  final DateTime endDate;
  final String? tenantName;
}

/// A room or apartment inside a property.
class Unit {
  const Unit({
    required this.id,
    required this.propertyId,
    required this.label,
    this.bedrooms,
    this.status = UnitStatus.vacant,
    this.activeLease,
  });

  factory Unit.fromJson(Map<String, dynamic> json) => Unit(
    id: json['id'] as int,
    propertyId: json['property_id'] as int,
    label: json['label'] as String,
    bedrooms: json['bedrooms'] as int?,
    status: UnitStatus.parse(json['status'] as String?),
  );

  final int id;
  final int propertyId;
  final String label;
  final int? bedrooms;
  final UnitStatus status;
  final ActiveLeaseSummary? activeLease;
}
