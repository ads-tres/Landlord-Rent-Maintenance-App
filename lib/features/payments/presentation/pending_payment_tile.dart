import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/locale_controller.dart';
import '../../../core/utils/app_dates.dart';
import '../../../core/utils/money.dart';
import '../../../l10n/app_localizations.dart';
import '../application/pending_payments.dart';
import 'payment_labels.dart';

/// A payment saved on the phone that has not reached the server yet.
class PendingPaymentTile extends ConsumerWidget {
  const PendingPaymentTile({
    super.key,
    required this.payment,
    this.showTenant = true,
  });

  final PendingPayment payment;
  final bool showTenant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider).languageCode;
    final dates = ref.watch(appDatesProvider);
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(
        payment.lastError == null
            ? Icons.cloud_upload_outlined
            : Icons.error_outline,
        color: payment.lastError == null ? scheme.tertiary : scheme.error,
      ),
      title: Text(
        [
          if (showTenant && payment.tenantName != null) payment.tenantName!,
          formatBirr(payment.amount, locale: locale),
        ].join(' · '),
      ),
      subtitle: Text(
        [
          [
            dates.date(payment.paidAt),
            payment.method.label(l10n),
            if (showTenant && payment.unitLabel != null) payment.unitLabel!,
          ].join(' · '),
          payment.lastError == null
              ? l10n.notSynced
              : l10n.syncFailed(payment.lastError!),
        ].join('\n'),
      ),
      isThreeLine: true,
      trailing: IconButton(
        tooltip: l10n.discardPending,
        icon: const Icon(Icons.delete_outline),
        onPressed: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              content: Text(l10n.discardPendingConfirm),
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
            await ref
                .read(pendingPaymentsProvider.notifier)
                .discard(payment.clientRef);
          }
        },
      ),
    );
  }
}
