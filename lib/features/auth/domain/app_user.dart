class AppUser {
  const AppUser({
    required this.id,
    required this.phone,
    this.name,
    this.locale = 'am',
    this.calendarPref = 'ethiopian',
    this.smsReminders = true,
    this.telegramLinked = false,
    this.telegramAvailable = false,
    this.onlineRentAvailable = false,
    this.onlineRentEnabled = false,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as int,
    phone: json['phone'] as String,
    name: json['name'] as String?,
    locale: json['locale'] as String? ?? 'am',
    calendarPref: json['calendar_pref'] as String? ?? 'ethiopian',
    smsReminders: json['sms_reminders'] as bool? ?? true,
    telegramLinked: json['telegram_linked'] as bool? ?? false,
    telegramAvailable: json['telegram_available'] as bool? ?? false,
    onlineRentAvailable: json['online_rent_available'] as bool? ?? false,
    onlineRentEnabled: json['online_rent_enabled'] as bool? ?? false,
  );

  final int id;
  final String phone;
  final String? name;
  final String locale;
  final String calendarPref;
  final bool smsReminders;
  final bool telegramLinked;

  /// The server has a Telegram bot configured.
  final bool telegramAvailable;

  /// The server has Chapa set up.
  final bool onlineRentAvailable;

  /// This landlord accepts online rent (payout account active and switched on).
  final bool onlineRentEnabled;
}
