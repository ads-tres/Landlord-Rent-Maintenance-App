import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/locale_controller.dart';
import '../../../core/utils/app_dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../leases/data/leases_repository.dart';
import '../../leases/domain/lease.dart';
import '../domain/payment_sms.dart';
import 'payment_labels.dart';

/// Lets the landlord paste a Telebirr or bank confirmation SMS and shows what was read.
/// Returns the parsed message, or null if cancelled.
Future<PaymentSms?> showPasteSmsSheet(BuildContext context) =>
    showModalBottomSheet<PaymentSms>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _PasteSmsSheet(),
    );

class _PasteSmsSheet extends ConsumerStatefulWidget {
  const _PasteSmsSheet();

  @override
  ConsumerState<_PasteSmsSheet> createState() => _PasteSmsSheetState();
}

class _PasteSmsSheetState extends ConsumerState<_PasteSmsSheet> {
  final _text = TextEditingController();
  PaymentSms? _sms;

  @override
  void initState() {
    super.initState();
    // Most landlords copy the SMS first: start with whatever is on the clipboard.
    _clipboard().then((text) {
      if (mounted && text.isNotEmpty && _text.text.isEmpty) {
        _text.text = text;
        _read();
      }
    });
  }

  Future<String> _clipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      return data?.text?.trim() ?? '';
    } catch (_) {
      return ''; // No clipboard access: the landlord can still paste by hand.
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _read() => setState(
    () => _sms = _text.text.trim().isEmpty ? null : parsePaymentSms(_text.text),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider).languageCode;
    final dates = ref.watch(appDatesProvider);
    final sms = _sms;

    Widget row(String label, String? value) => value == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 110, child: Text(label)),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.pasteSms, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(l10n.pasteSmsHelp),
            const SizedBox(height: 12),
            TextField(
              key: const Key('smsField'),
              controller: _text,
              minLines: 4,
              maxLines: 8,
              onChanged: (_) => _read(),
              decoration: InputDecoration(
                hintText: l10n.pasteSmsHint,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: l10n.pasteFromClipboard,
                  icon: const Icon(Icons.content_paste),
                  onPressed: () async {
                    _text.text = await _clipboard();
                    _read();
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (sms != null && !sms.hasAmount)
              Text(
                l10n.smsNoAmount,
                key: const Key('smsNoAmount'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (sms != null && sms.hasAmount)
              Card(
                key: const Key('smsPreview'),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      row(
                        l10n.amountPaid,
                        formatBirr(sms.amount!, locale: locale),
                      ),
                      row(l10n.paymentMethod, sms.method?.label(l10n)),
                      row(l10n.reference, sms.reference),
                      row(
                        l10n.paidOn,
                        sms.paidAt == null ? null : dates.date(sms.paidAt!),
                      ),
                      row(
                        l10n.smsFrom,
                        [?sms.payerName, ?sms.payerPhone].join(' · ').ifEmpty(),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('useSms'),
              onPressed: sms != null && sms.hasAmount
                  ? () => Navigator.pop(context, sms)
                  : null,
              child: Text(l10n.useSms),
            ),
          ],
        ),
      ),
    );
  }
}

extension on String {
  String? ifEmpty() => isEmpty ? null : this;
}

/// From the Rent tab: paste an SMS, find the lease it is for, and open Log payment filled in.
Future<void> logPaymentFromSms(BuildContext context, WidgetRef ref) async {
  final sms = await showPasteSmsSheet(context);
  if (sms == null || !context.mounted) return;

  final List<Lease> leases;
  try {
    leases = await ref.read(leasesRepositoryProvider).active();
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyError(context, e))));
    }
    return;
  }
  if (!context.mounted) return;

  final matches = matchLeasesToSms(sms, leases);
  final lease = isConfidentMatch(matches)
      ? matches.first.lease
      : await _pickLease(context, leases, matches);
  if (lease == null || !context.mounted) return;
  await context.push('/payments/new?leaseId=${lease.id}', extra: sms);
}

Future<Lease?> _pickLease(
  BuildContext context,
  List<Lease> leases,
  List<LeaseMatch> matches,
) {
  final l10n = AppLocalizations.of(context);
  final likely = {for (final m in matches) m.lease.id};
  final ordered = [
    for (final m in matches) m.lease,
    ...leases.where((l) => !likely.contains(l.id)),
  ];
  return showModalBottomSheet<Lease>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(title: Text(l10n.smsPickLease)),
            if (ordered.isEmpty) ListTile(title: Text(l10n.smsNoLeases)),
            for (final l in ordered)
              ListTile(
                key: Key('smsLease-${l.id}'),
                leading: const Icon(Icons.person_outline),
                title: Text([?l.tenantName, ?l.unitLabel].join(' · ')),
                subtitle: l.propertyName == null ? null : Text(l.propertyName!),
                trailing: likely.contains(l.id)
                    ? Chip(
                        label: Text(l10n.smsLikely),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide.none,
                      )
                    : null,
                onTap: () => Navigator.pop(context, l),
              ),
          ],
        ),
      ),
    ),
  );
}
