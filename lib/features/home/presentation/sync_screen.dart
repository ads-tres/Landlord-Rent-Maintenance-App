import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/offline/outbox.dart';
import '../../../core/widgets/async_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../payments/application/pending_payments.dart';
import '../../payments/presentation/pending_payment_tile.dart';

/// Sends everything saved offline: payments first, then expenses and repairs.
/// Returns how many records reached the server.
Future<int> syncAll(WidgetRef ref) async =>
    await ref.read(pendingPaymentsProvider.notifier).sync() +
    await ref.read(outboxProvider.notifier).sync();

/// Payments, expenses and repairs saved on the phone that have not been sent.
int pendingCount(WidgetRef ref) =>
    (ref.watch(pendingPaymentsProvider).value?.length ?? 0) +
    (ref.watch(outboxProvider).value?.length ?? 0);

Future<void> showSavedOfflineDialog(BuildContext context, String message) {
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.cloud_off),
      title: Text(l10n.savedOffline),
      content: Text(message),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.done),
        ),
      ],
    ),
  );
}

/// Everything saved offline, so the landlord can see it is safe, send it now,
/// or fix what the server refused.
class SyncScreen extends ConsumerStatefulWidget {
  const SyncScreen({super.key});

  @override
  ConsumerState<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends ConsumerState<SyncScreen> {
  bool _syncing = false;

  Future<void> _sync() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _syncing = true);
    try {
      final sent = await syncAll(ref);
      if (!mounted) return;
      final left = pendingCount(ref);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            left == 0 ? l10n.allSynced : l10n.syncedSome(sent, left),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final payments = ref.watch(pendingPaymentsProvider).value ?? const [];
    final items = ref.watch(outboxProvider).value ?? const [];
    final expenses = items.where((i) => i.kind == OutboxKind.expense).toList();
    final repairs = items.where((i) => i.kind == OutboxKind.repair).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.waitingToSync)),
      floatingActionButton: payments.isEmpty && items.isEmpty
          ? null
          : FloatingActionButton.extended(
              key: const Key('syncAll'),
              onPressed: _syncing ? null : _sync,
              icon: _syncing
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(l10n.syncNow),
            ),
      body: payments.isEmpty && items.isEmpty
          ? EmptyView(message: l10n.allSynced, icon: Icons.cloud_done_outlined)
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l10n.waitingToSyncHelp),
                ),
                if (payments.isNotEmpty) ...[
                  _Header(l10n.syncPayments),
                  for (final p in payments) PendingPaymentTile(payment: p),
                ],
                if (expenses.isNotEmpty) ...[
                  _Header(l10n.syncExpenses),
                  for (final i in expenses) OutboxTile(item: i),
                ],
                if (repairs.isNotEmpty) ...[
                  _Header(l10n.syncRepairs),
                  for (final i in repairs) OutboxTile(item: i),
                ],
              ],
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}

/// Unsent entries of one kind, shown above the Repairs or Expenses list
/// (which can't load them from the server yet).
class QueuedEntries extends ConsumerWidget {
  const QueuedEntries({super.key, required this.kind});

  final OutboxKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = (ref.watch(outboxProvider).value ?? const [])
        .where((i) => i.kind == kind)
        .toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Material(
      color: Theme.of(context).colorScheme.tertiaryContainer.withAlpha(90),
      child: Column(
        children: [
          for (final i in items) OutboxTile(item: i),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

/// An expense or repair saved on the phone that has not reached the server yet.
class OutboxTile extends ConsumerWidget {
  const OutboxTile({super.key, required this.item});

  final OutboxItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final failed = item.lastError != null;

    return ListTile(
      key: Key('outbox-${item.clientRef}'),
      leading: Icon(
        failed ? Icons.error_outline : Icons.cloud_upload_outlined,
        color: failed ? scheme.error : scheme.tertiary,
      ),
      title: Text(item.title),
      subtitle: Text(
        [
          ?item.subtitle,
          if (item.photos.isNotEmpty) l10n.photosCount(item.photos.length),
          failed ? l10n.syncFailed(item.lastError!) : l10n.notSynced,
        ].join('\n'),
      ),
      isThreeLine: item.subtitle != null || item.photos.isNotEmpty,
      trailing: IconButton(
        tooltip: l10n.discardPending,
        icon: const Icon(Icons.delete_outline),
        onPressed: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              content: Text(l10n.discardItemConfirm),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.discardPending),
                ),
              ],
            ),
          );
          if (ok == true) {
            await ref.read(outboxProvider.notifier).discard(item.clientRef);
          }
        },
      ),
    );
  }
}
