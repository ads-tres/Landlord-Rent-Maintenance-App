/// Legal values from `GET /rules`. They change yearly, so they come from the server.
class RentRules {
  const RentRules({required this.capPercent, required this.minLeaseYears});

  factory RentRules.fromJson(Map<String, dynamic> json) => RentRules(
    capPercent: (json['rent_cap_percent'] as num).toDouble(),
    minLeaseYears: json['min_lease_years'] as int,
  );

  /// Used until the server answers: 2026/27 cap and the directive's minimum term.
  static const fallback = RentRules(capPercent: 11.5, minLeaseYears: 2);

  final double capPercent;
  final int minLeaseYears;

  static double increasePercent(int oldRent, int newRent) =>
      oldRent > 0 ? ((newRent - oldRent) / oldRent * 1000).round() / 10 : 0;

  bool exceedsCap(int oldRent, int newRent) =>
      oldRent > 0 && (newRent - oldRent) / oldRent * 100 > capPercent + 1e-9;

  int maxAllowedRent(int oldRent) => (oldRent * (1 + capPercent / 100)).floor();

  /// `11.5` → `"11.5"`, `15.0` → `"15"`.
  String get capLabel => capPercent == capPercent.roundToDouble()
      ? capPercent.toStringAsFixed(0)
      : '$capPercent';
}
