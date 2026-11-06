import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/locale_controller.dart';
import '../../../core/utils/app_dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/language_picker.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_controller.dart';
import '../data/leases_repository.dart';
import '../domain/lease.dart';
import '../domain/rent_rules.dart';

/// One line of a lease's rent history. A landlord can print the notice letter,
/// or cancel a change that hasn't started yet.
class RentChangeTile extends ConsumerWidget {
  const RentChangeTile({
    super.key,
    required this.lease,
    required this.change,
    required this.onChanged,
  });

  final Lease lease;
  final RentChange change;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider).languageCode;
    final dates = ref.watch(appDatesProvider);
    final caretaker = ref.watch(isCaretakerProvider);
    final c = change;

    final status = [
      if (c.upcoming) l10n.rentChangeUpcoming,
      if (c.tenantAgreed)
        l10n.tenantAgreedInWriting
      else if (c.isIncrease && c.noticeDays != null)
        l10n.rentNoticeGiven(c.noticeDays!),
      if (c.upcoming && c.tenantNotified) l10n.tenantTexted,
    ];

    return ListTile(
      key: Key('rentChange-${c.id}'),
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        c.isIncrease ? Icons.trending_up : Icons.trending_down,
        color: c.upcoming ? Theme.of(context).colorScheme.tertiary : null,
      ),
      title: Text(
        l10n.rentChangeLine(
          formatBirr(c.oldRent, locale: locale),
          formatBirr(c.newRent, locale: locale),
          dates.date(c.effectiveDate),
          RentRules(capPercent: c.capPercent, minLeaseYears: 2).capLabel,
        ),
      ),
      subtitle: status.isEmpty ? null : Text(status.join(' · ')),
      trailing: caretaker || c.id == 0
          ? null
          : PopupMenuButton<String>(
              key: Key('rentChangeMenu-${c.id}'),
              onSelected: (action) => action == 'notice'
                  ? _shareNotice(context, ref)
                  : _cancel(context, ref),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'notice',
                  child: Text(l10n.rentNoticeLetter),
                ),
                if (c.upcoming)
                  PopupMenuItem(
                    value: 'cancel',
                    child: Text(l10n.cancelRentChange),
                  ),
              ],
            ),
    );
  }

  Future<void> _shareNotice(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final language = await pickDocumentLanguage(
      context,
      title: l10n.rentNoticeLetter,
      help: l10n.rentNoticeLetterHelp,
    );
    if (language == null || !context.mounted) return;
    try {
      final path = await ref
          .read(leasesRepositoryProvider)
          .downloadRentNotice(lease.id, change.id, language);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: 'application/pdf')],
          text: l10n.rentNoticeLetter,
        ),
      );
    } on ApiException catch (e) {
      if (context.mounted) _snack(context, friendlyError(context, e));
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cancelRentChange),
        content: Text(
          change.tenantNotified
              ? l10n.cancelRentChangeNotified
              : l10n.cancelRentChangeConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.keepIt),
          ),
          FilledButton(
            key: const Key('confirmCancelRentChange'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.cancelRentChange),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(leasesRepositoryProvider)
          .cancelRentChange(lease.id, change.id);
      onChanged();
      if (context.mounted) _snack(context, l10n.rentChangeCancelled);
    } on ApiException catch (e) {
      if (context.mounted) _snack(context, friendlyError(context, e));
    }
  }

  void _snack(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
}
