import 'unit.dart';

/// A compound or building.
class Property {
  const Property({
    required this.id,
    required this.name,
    this.subCity,
    this.woreda,
    this.address,
    this.unitsCount = 0,
    this.vacantUnitsCount = 0,
    this.units = const [],
  });

  factory Property.fromJson(Map<String, dynamic> json) => Property(
    id: json['id'] as int,
    name: json['name'] as String,
    subCity: json['sub_city'] as String?,
    woreda: json['woreda'] as String?,
    address: json['address'] as String?,
    unitsCount: json['units_count'] as int? ?? 0,
    vacantUnitsCount: json['vacant_units_count'] as int? ?? 0,
    units: (json['units'] as List<dynamic>? ?? [])
        .map((u) => Unit.fromJson(u as Map<String, dynamic>))
        .toList(),
  );

  final int id;
  final String name;
  final String? subCity;
  final String? woreda;
  final String? address;
  final int unitsCount;
  final int vacantUnitsCount;
  final List<Unit> units;

  String get location => [
    subCity,
    if (woreda != null && woreda!.isNotEmpty) 'W. $woreda',
  ].whereType<String>().where((s) => s.isNotEmpty).join(', ');
}
