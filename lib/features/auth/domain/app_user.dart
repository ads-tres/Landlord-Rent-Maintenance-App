class AppUser {
  const AppUser({
    required this.id,
    required this.phone,
    this.name,
    this.locale = 'am',
    this.calendarPref = 'ethiopian',
    this.smsReminders = true,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as int,
    phone: json['phone'] as String,
    name: json['name'] as String?,
    locale: json['locale'] as String? ?? 'am',
    calendarPref: json['calendar_pref'] as String? ?? 'ethiopian',
  );

  final int id;
  final String phone;
  final String? name;
  final String locale;
  final String calendarPref;
  final bool smsReminders;
}
