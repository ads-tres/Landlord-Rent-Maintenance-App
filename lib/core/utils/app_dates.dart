import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../features/auth/application/auth_controller.dart';
import '../locale_controller.dart';
import 'ethiopian_date.dart';

/// Formats stored Gregorian dates in the landlord's language and calendar
/// (Settings → Calendar). Mirrors `App\Support\DateDisplay` on the backend.
class AppDates {
  const AppDates({required this.locale, required this.ethiopian});

  final String locale;
  final bool ethiopian;

  String date(DateTime d) => ethiopian
      ? EthiopianDate.fromGregorian(d).format(locale)
      : DateFormat.yMMMd(locale).format(d);

  /// A rent period (Gregorian month `YYYY-MM`). In the Ethiopian calendar it spans two
  /// Ethiopian months, shown as e.g. "ጥቅምት–ኅዳር 2019".
  String period(String period) {
    final first = DateTime.parse('$period-01');
    if (!ethiopian) return DateFormat.yMMMM(locale).format(first);

    final last = DateTime(first.year, first.month + 1, 0);
    return _span(
      EthiopianDate.fromGregorian(first),
      EthiopianDate.fromGregorian(last),
    );
  }

  /// A month for the month picker on the Rent tab.
  String month(DateTime firstOfMonth) =>
      period(DateFormat('yyyy-MM').format(firstOfMonth));

  String _span(EthiopianDate a, EthiopianDate b) {
    final from = EthiopianDate.monthName(a.month, locale);
    final to = EthiopianDate.monthName(b.month, locale);
    if (a.year == b.year) {
      return a.month == b.month ? '$from ${a.year}' : '$from–$to ${b.year}';
    }
    return '$from ${a.year}–$to ${b.year}';
  }
}

final appDatesProvider = Provider<AppDates>((ref) {
  final locale = ref.watch(localeControllerProvider).languageCode;
  final pref = ref.watch(
    authControllerProvider.select((u) => u.value?.calendarPref ?? 'ethiopian'),
  );
  return AppDates(locale: locale, ethiopian: pref == 'ethiopian');
});
