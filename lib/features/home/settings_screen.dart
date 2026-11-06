import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_exception.dart';
import '../../core/config.dart';
import '../../core/locale_controller.dart';
import '../../core/utils/phone_number.dart';
import '../../l10n/app_localizations.dart';
import '../../core/widgets/async_views.dart';
import '../auth/application/auth_controller.dart';
import '../auth/data/auth_repository.dart';

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
          if (user?.onlineRentAvailable ?? false)
            ListTile(
              key: const Key('onlineRentTile'),
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: Text(l10n.onlineRent),
              subtitle: Text(
                user!.onlineRentEnabled
                    ? l10n.onlineRentOn
                    : l10n.onlineRentHelp,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/online-rent'),
            ),
          if (user?.telegramAvailable ?? false)
            ListTile(
              key: const Key('telegramTile'),
              leading: const Icon(Icons.telegram),
              title: Text(
                user!.telegramLinked ? l10n.telegram : l10n.telegramConnect,
              ),
              subtitle: Text(
                user.telegramLinked
                    ? l10n.telegramConnected
                    : l10n.telegramNotConnected,
              ),
              trailing: user.telegramLinked
                  ? const Icon(Icons.check_circle_outline)
                  : const Icon(Icons.open_in_new),
              onTap: () => user.telegramLinked
                  ? _disconnectTelegram(context, ref)
                  : _connectTelegram(context, ref),
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

Future<void> _connectTelegram(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    final url = await ref.read(authRepositoryProvider).telegramLinkUrl();
    messenger.showSnackBar(SnackBar(content: Text(l10n.telegramOpenHint)));
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    // The link is confirmed in Telegram; refresh when the landlord comes back.
  } on ApiException catch (e) {
    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(friendlyError(context, e))),
      );
    }
  }
}

Future<void> _disconnectTelegram(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(l10n.telegramDisconnectConfirm),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.telegramDisconnect),
        ),
      ],
    ),
  );
  if (ok != true) return;
  try {
    await ref.read(authRepositoryProvider).telegramUnlink();
  } on ApiException {
    // Refresh below shows the real state either way.
  }
  await ref.read(authControllerProvider.notifier).refreshUser();
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
