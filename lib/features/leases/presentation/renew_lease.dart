import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/locale_controller.dart';
import '../../../core/utils/app_dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/form_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../tenants/presentation/payment_record_badge.dart';
import '../data/leases_repository.dart';
import '../domain/lease.dart';
import '../domain/renewal.dart';
import '../domain/rent_rules.dart';

/// Shown on an active lease in its last 180 days: renew it to a new end date.
class RenewLeaseCard extends ConsumerWidget {
  const RenewLeaseCard({
    super.key,
    required this.lease,
    required this.onRenewed,
  });

  final Lease lease;
  final VoidCallback onRenewed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final days = lease.daysUntilEnd ?? 0;
    return Card(
      key: const Key('renewLeaseCard'),
      color: days <= 60
          ? Theme.of(context).colorScheme.tertiaryContainer
          : null,
      child: ListTile(
        leading: const Icon(Icons.autorenew),
        title: Text(l10n.renewLease),
        subtitle: Text(l10n.renewLeaseHelp(days < 0 ? 0 : days)),
        trailing: FilledButton(
          key: const Key('renewLeaseButton'),
          onPressed: () => renewLease(context, ref, lease, onRenewed),
          child: Text(l10n.renew),
        ),
      ),
    );
  }
}

Future<void> renewLease(
  BuildContext context,
  WidgetRef ref,
  Lease lease,
  VoidCallback onRenewed,
) async {
  final l10n = AppLocalizations.of(context);
  final repo = ref.read(leasesRepositoryProvider);
  final RenewalCheck check;
  try {
    check = await repo.renewalCheck(lease.id);
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyError(context, e))));
    }
    return;
  }
  if (!context.mounted) return;

  final locale = ref.read(localeControllerProvider).languageCode;
  final dates = ref.read(appDatesProvider);
  final rent = TextEditingController(text: santimToInput(check.currentRent));
  var newEnd = check.suggestedEndDate;
  var notify = true;
  LeaseRenewal? renewal;

  final saved = await showFormSheet(
    context,
    FormSheet(
      title: l10n.renewLease,
      saveLabel: l10n.renew,
      onSave: () async {
        renewal = await repo.renew(
          lease.id,
          newEndDate: newEnd,
          newRent: parseBirr(rent.text)!,
          notifyTenant: notify,
        );
      },
      fieldsBuilder: (context, errors) => [
        if (check.tenantRecord != null) ...[
          PaymentRecordBadge(
            key: const Key('renewalRecord'),
            record: check.tenantRecord!,
          ),
          fieldGap,
        ],
        Text(l10n.currentEnd(dates.date(check.currentEndDate))),
        fieldGap,
        StatefulBuilder(
          builder: (context, setState) => InkWell(
            key: const Key('renewEndDate'),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: newEnd,
                firstDate: check.rentFrom,
                lastDate: DateTime(
                  check.currentEndDate.year + 5,
                  check.currentEndDate.month,
                  check.currentEndDate.day,
                ),
              );
              if (picked != null) setState(() => newEnd = picked);
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.newEndDate,
                errorText: errors['new_end_date'],
                suffixIcon: const Icon(Icons.calendar_today_outlined),
              ),
              child: Text(dates.date(newEnd)),
            ),
          ),
        ),
        fieldGap,
        StatefulBuilder(
          builder: (context, setState) {
            final value = parseBirr(rent.text) ?? 0;
            final over =
                value > check.currentRent &&
                RentRules(
                  capPercent: check.capPercent,
                  minLeaseYears: 2,
                ).exceedsCap(check.currentRent, value);
            return TextFormField(
              key: const Key('renewRentField'),
              controller: rent,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l10n.rentFrom(dates.date(check.rentFrom)),
                helperText: l10n.maxRentHint(
                  formatBirr(check.maxRent, locale: locale),
                  check.capPercent.toString().replaceAll(RegExp(r'\.0$'), ''),
                ),
                errorText:
                    errors['new_rent'] ?? (over ? l10n.aboveYearlyLimit : null),
              ),
              validator: (v) {
                final n = parseBirr(v ?? '') ?? 0;
                if (n < 100) return l10n.amountInvalid;
                if (n > check.maxRent) return l10n.aboveYearlyLimit;
                return null;
              },
            );
          },
        ),
        StatefulBuilder(
          builder: (context, setState) => SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.notifyTenantSms),
            value: notify,
            onChanged: (v) => setState(() => notify = v),
          ),
        ),
      ],
    ),
  );

  if (!saved || renewal == null || !context.mounted) return;
  onRenewed();
  final r = renewal!;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.leaseRenewed),
      content: Text(
        l10n.leaseRenewedBody(
          dates.date(r.newEndDate),
          formatBirr(r.newRent, locale: locale),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.close),
        ),
        FilledButton.icon(
          key: const Key('shareAddendum'),
          onPressed: () async {
            Navigator.pop(dialogContext);
            try {
              final path = await repo.downloadAddendum(r.id);
              await SharePlus.instance.share(
                ShareParams(
                  files: [XFile(path, mimeType: 'application/pdf')],
                  text: l10n.renewalAddendum,
                ),
              );
            } on ApiException catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(friendlyError(context, e))),
                );
              }
            }
          },
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: Text(l10n.renewalAddendum),
        ),
      ],
    ),
  );
}
