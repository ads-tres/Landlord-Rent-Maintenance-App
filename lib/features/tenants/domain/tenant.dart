class Tenant {
  const Tenant({
    required this.id,
    required this.fullName,
    required this.phone,
    this.address,
    this.hasIdNumber = false,
    this.telegramLinked = false,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) => Tenant(
    id: json['id'] as int,
    fullName: json['full_name'] as String,
    phone: json['phone'] as String,
    address: json['address'] as String?,
    hasIdNumber: json['has_id_number'] as bool? ?? false,
    telegramLinked: json['telegram_linked'] as bool? ?? false,
  );

  final int id;
  final String fullName;
  final String phone;
  final String? address;
  final bool hasIdNumber;
  final bool telegramLinked;
}
