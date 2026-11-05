import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_exception.dart';
import '../../core/config.dart';
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

    Future<void> sync({
      String? locale,
      String? calendarPref,
      bool? smsReminders,
    }) async {
      try {
        await ref
            .read(authControllerProvider.notifier)
            .updateProfile(
              locale: locale,
              calendarPref: calendarPref,
              smsReminders: smsReminders,
            );
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
          SwitchListTile(
            secondary: const Icon(Icons.sms_outlined),
            title: Text(l10n.smsReminders),
            subtitle: Text(l10n.smsRemindersHelp),
            value: user?.smsReminders ?? true,
            onChanged: (v) => sync(smsReminders: v),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l10n.logout),
            onTap: () => ref.read(authControllerProvider.notifier).logout(),
          ),
          if (AppConfig.feedbackUrl.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.feedback_outlined),
              title: Text(l10n.sendFeedback),
              subtitle: Text(l10n.sendFeedbackHelp),
              onTap: () => launchUrl(
                Uri.parse(AppConfig.feedbackUrl),
                mode: LaunchMode.externalApplication,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.disclaimer,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const _VersionLine(),
        ],
      ),
    );
  }
}

/// App version, so pilot feedback can say which build it is about.
class _VersionLine extends StatelessWidget {
  const _VersionLine();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        if (info == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            AppLocalizations.of(context)
                .appVersion('${info.version} (${info.buildNumber})'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      },
    );
  }
}
