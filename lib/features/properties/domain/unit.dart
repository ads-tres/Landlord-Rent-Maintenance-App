enum UnitStatus {
  vacant,
  occupied;

  static UnitStatus parse(String? value) =>
      value == 'occupied' ? UnitStatus.occupied : UnitStatus.vacant;
}

/// A room or apartment inside a property.
class Unit {
  const Unit({
    required this.id,
    required this.propertyId,
    required this.label,
    this.bedrooms,
    this.status = UnitStatus.vacant,
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
}
