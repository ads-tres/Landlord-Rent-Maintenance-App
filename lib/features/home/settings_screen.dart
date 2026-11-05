import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/locale_controller.dart';
import '../../core/utils/phone_number.dart';
import '../../l10n/app_localizations.dart';
import '../auth/application/auth_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider).value;
    final locale = ref.watch(localeControllerProvider);

    Future<void> sync({String? locale, String? calendarPref}) async {
      try {
        await ref
            .read(authControllerProvider.notifier)
            .updateProfile(locale: locale, calendarPref: calendarPref);
      } on ApiException {
        // Offline: the local choice still applies; it syncs next time.
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        children: [
          if (user != null)
            ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: Text(user.name ?? formatEthiopianPhone(user.phone)),
              subtitle: user.name != null
                  ? Text(formatEthiopianPhone(user.phone))
                  : null,
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'am', label: Text('አማርኛ')),
                ButtonSegment(value: 'en', label: Text('English')),
              ],
              selected: {locale.languageCode},
              onSelectionChanged: (s) {
                ref
                    .read(localeControllerProvider.notifier)
                    .set(Locale(s.first));
                sync(locale: s.first);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: Text(l10n.calendar),
            trailing: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'ethiopian',
                  label: Text(l10n.calendarEthiopian),
                ),
                ButtonSegment(
                  value: 'gregorian',
                  label: Text(l10n.calendarGregorian),
                ),
              ],
              selected: {user?.calendarPref ?? 'ethiopian'},
              onSelectionChanged: (s) => sync(calendarPref: s.first),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l10n.logout),
            onTap: () => ref.read(authControllerProvider.notifier).logout(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.disclaimer,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
