import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/utils/app_dates.dart';
import '../../../core/widgets/async_views.dart';
import '../../../l10n/app_localizations.dart';
import '../data/tenants_repository.dart';
import '../domain/tenant.dart';

/// Everything sent to a tenant by SMS or Telegram, and whether they get rent reminders.
class TenantMessagesScreen extends ConsumerWidget {
  const TenantMessagesScreen({super.key, required this.tenantId});

  final int tenantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tenant = ref.watch(tenantProvider(tenantId));
    final messages = ref.watch(tenantMessagesProvider(tenantId));

    return Scaffold(
      appBar: AppBar(title: Text(tenant.value?.fullName ?? l10n.messages)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(tenantProvider(tenantId));
          final _ = await ref.refresh(tenantMessagesProvider(tenantId).future);
        },
        child: ListView(
          children: [
            if (tenant.value != null)
              SwitchListTile(
                key: const Key('remindersSwitch'),
                secondary: const Icon(Icons.notifications_active_outlined),
                title: Text(l10n.rentReminders),
                subtitle: Text(l10n.rentRemindersHelp),
                value: !tenant.value!.remindersOptOut,
                onChanged: (on) async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await ref
                        .read(tenantsRepositoryProvider)
                        .setRemindersOptOut(tenantId, !on);
                    ref.invalidate(tenantProvider(tenantId));
                    ref.invalidate(tenantsProvider);
                  } on ApiException catch (e) {
                    if (context.mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(friendlyError(context, e))),
                      );
                    }
                  }
                },
              ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.bedtime_outlined),
              title: Text(l10n.quietHoursNote),
            ),
            const Divider(),
            ...messages.when(
              loading: () => [
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (e, _) => [
                ErrorView(
                  error: e,
                  onRetry: () =>
                      ref.invalidate(tenantMessagesProvider(tenantId)),
                ),
              ],
              data: (items) => items.isEmpty
                  ? [
                      Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: EmptyView(
                          message: l10n.noMessages,
                          icon: Icons.sms_outlined,
                        ),
                      ),
                    ]
                  : [for (final m in items) _MessageTile(message: m)],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageTile extends ConsumerWidget {
  const _MessageTile({required this.message});

  final TenantMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dates = ref.watch(appDatesProvider);
    final scheme = Theme.of(context).colorScheme;
    final m = message;
    final (status, color) = switch (m.status) {
      'sent' => (l10n.messageSent, Colors.green),
      'failed' => (l10n.messageFailed, scheme.error),
      _ => (
        m.sendAfter != null
            ? l10n.messageScheduled(
                TimeOfDay.fromDateTime(m.sendAfter!).format(context),
              )
            : l10n.messageQueued,
        scheme.outline,
      ),
    };
    final time = TimeOfDay.fromDateTime(m.createdAt).format(context);

    return ListTile(
      leading: Icon(m.isTelegram ? Icons.telegram : Icons.sms_outlined),
      title: Text(m.body, maxLines: 3, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          '${dates.date(m.createdAt)} $time',
          if (m.error != null) m.error!,
        ].join(' · '),
      ),
      trailing: Text(status, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}
