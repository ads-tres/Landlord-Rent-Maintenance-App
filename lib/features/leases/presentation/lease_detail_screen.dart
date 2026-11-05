import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/locale_controller.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/phone_number.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/form_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../payments/data/payments_repository.dart';
import '../../payments/presentation/payment_labels.dart';
import '../../properties/data/properties_repository.dart';
import '../../rent/presentation/rent_screen.dart';
import '../data/leases_repository.dart';
import '../domain/lease.dart';
import '../domain/rent_rules.dart';
import 'status_chips.dart';

class LeaseDetailScreen extends ConsumerWidget {
  const LeaseDetailScreen({super.key, required this.leaseId});

  final int leaseId;

  void _refreshAll(WidgetRef ref, Lease lease) {
    ref.invalidate(leaseProvider(leaseId));
    ref.invalidate(leaseChargesProvider(leaseId));
    ref.invalidate(leasePaymentsProvider(leaseId));
    ref.invalidate(monthChargesProvider);
    ref.invalidate(dashboardProvider);
    ref.invalidate(propertiesProvider);
    if (lease.propertyId != null) {
      ref.invalidate(propertyProvider(lease.propertyId!));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider).languageCode;
    final lease = ref.watch(leaseProvider(leaseId));

    return Scaffold(
      floatingActionButton: (lease.value?.isActive ?? false)
          ? FloatingActionButton.extended(
              key: const Key('logPaymentFab'),
              onPressed: () => context.push('/payments/new?leaseId=$leaseId'),
              icon: const Icon(Icons.payments_outlined),
              label: Text(l10n.logPayment),
            )
          : null,
      appBar: AppBar(
        title: Text(l10n.leaseTitle),
        actions: [
          if (lease.value?.isActive ?? false)
            PopupMenuButton<String>(
              onSelected: (action) async {
                final l = lease.requireValue;
                final changed = action == 'rent'
                    ? await _changeRent(context, ref, l)
                    : await _endLease(context, ref, l);
                if (changed) _refreshAll(ref, l);
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'rent', child: Text(l10n.changeRent)),
                PopupMenuItem(value: 'end', child: Text(l10n.endLease)),
              ],
            ),
        ],
      ),
      body: lease.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(leaseProvider(leaseId)),
        ),
        data: (l) => RefreshIndicator(
          onRefresh: () async => _refreshAll(ref, l),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Header(lease: l, locale: locale),
              if (l.missingFields.isNotEmpty) ...[
                const SizedBox(height: 12),
                _DirectiveWarning(missing: l.missingFields),
              ],
              if (l.balance != null) ...[
                const SizedBox(height: 12),
                _BalanceRow(balance: l.balance!, locale: locale),
              ],
              if (l.rentChanges.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.rentHistory,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final c in l.rentChanges)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.trending_up),
                    title: Text(
                      l10n.rentChangeLine(
                        formatBirr(c.oldRent, locale: locale),
                        formatBirr(c.newRent, locale: locale),
                        formatDate(c.effectiveDate, locale),
                        RentRules(
                          capPercent: c.capPercent,
                          minLeaseYears: 2,
                        ).capLabel,
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 16),
              Text(
                l10n.charges,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              _LeaseCharges(leaseId: leaseId, locale: locale),
              const SizedBox(height: 16),
              Text(
                l10n.payments,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              _LeasePayments(
                leaseId: leaseId,
                locale: locale,
                onChanged: () => _refreshAll(ref, l),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _changeRent(
    BuildContext context,
    WidgetRef ref,
    Lease lease,
  ) async {
    final rules = await ref.read(rentRulesProvider.future);
    if (!context.mounted) return false;
    return showFormSheet(context, _rentChangeSheet(context, ref, lease, rules));
  }

  FormSheet _rentChangeSheet(
    BuildContext context,
    WidgetRef ref,
    Lease lease,
    RentRules rules,
  ) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.read(localeControllerProvider).languageCode;
    final amount = TextEditingController(
      text: santimToInput(lease.monthlyRent),
    );
    var effective = dateOnly(DateTime.now());
    if (effective.isBefore(lease.startDate)) effective = lease.startDate;

    return FormSheet(
      title: l10n.changeRent,
      onSave: () => ref
          .read(leasesRepositoryProvider)
          .changeRent(
            lease.id,
            newRent: parseBirr(amount.text)!,
            effectiveDate: effective,
          ),
      fieldsBuilder: (context, errors) => [
        Text(l10n.currentRent(formatBirr(lease.monthlyRent, locale: locale))),
        fieldGap,
        StatefulBuilder(
          builder: (context, setState) {
            final newRent = parseBirr(amount.text);
            final over =
                newRent != null && rules.exceedsCap(lease.monthlyRent, newRent);
            final increase = newRent != null && newRent > lease.monthlyRent;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('newRentField'),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: amount,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: l10n.newRent,
                    errorText:
                        errors['new_rent'] ??
                        (over
                            ? l10n.aboveCap(
                                rules.capLabel,
                                formatBirr(
                                  rules.maxAllowedRent(lease.monthlyRent),
                                  locale: locale,
                                ),
                              )
                            : null),
                    helperText: increase && !over
                        ? l10n.withinCap(
                            RentRules.increasePercent(
                              lease.monthlyRent,
                              newRent,
                            ).toString(),
                            rules.capLabel,
                          )
                        : null,
                  ),
                  validator: (v) {
                    final value = parseBirr(v ?? '');
                    if (value == null || value < 100) return l10n.amountInvalid;
                    if (rules.exceedsCap(lease.monthlyRent, value)) {
                      return l10n.aboveCap(
                        rules.capLabel,
                        formatBirr(
                          rules.maxAllowedRent(lease.monthlyRent),
                          locale: locale,
                        ),
                      );
                    }
                    return null;
                  },
                ),
                fieldGap,
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: effective,
                      firstDate: lease.startDate,
                      lastDate: lease.endDate,
                    );
                    if (picked != null) setState(() => effective = picked);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.effectiveDate,
                      errorText: errors['effective_date'],
                      suffixIcon: const Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(formatDate(effective, locale)),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<bool> _endLease(
    BuildContext context,
    WidgetRef ref,
    Lease lease,
  ) async {
    final l10n = AppLocalizations.of(context);
    final locale = ref.read(localeControllerProvider).languageCode;
    final today = dateOnly(DateTime.now());
    final initial = today.isBefore(lease.startDate)
        ? lease.startDate
        : (today.isAfter(lease.endDate) ? lease.endDate : today);

    final endedOn = await showDatePicker(
      context: context,
      helpText: l10n.endedOnLabel,
      initialDate: initial,
      firstDate: lease.startDate,
      lastDate: lease.endDate,
    );
    if (endedOn == null || !context.mounted) return false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.endLease),
        content: Text(l10n.endLeaseConfirm(formatDate(endedOn, locale))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;

    try {
      await ref.read(leasesRepositoryProvider).end(lease.id, endedOn: endedOn);
      return true;
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(context, e))));
      }
      return false;
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.lease, required this.locale});

  final Lease lease;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final statusText = switch (lease.status) {
      LeaseStatus.active =>
        lease.daysUntilEnd != null && lease.daysUntilEnd! <= 60
            ? l10n.endsIn(lease.daysUntilEnd! < 0 ? 0 : lease.daysUntilEnd!)
            : l10n.leaseActive,
      LeaseStatus.ended =>
        lease.terminatedOn != null
            ? l10n.endedOn(formatDate(lease.terminatedOn!, locale))
            : l10n.leaseEnded,
      LeaseStatus.draft => l10n.leaseDraft,
    };

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(color: theme.colorScheme.outline),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lease.tenantName ?? '', style: theme.textTheme.titleLarge),
            if (lease.tenantPhone != null)
              Text(formatEthiopianPhone(lease.tenantPhone!)),
            const SizedBox(height: 4),
            Text(
              [
                lease.unitLabel,
                lease.propertyName,
              ].whereType<String>().join(' · '),
              style: TextStyle(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(statusText),
              visualDensity: VisualDensity.compact,
              side: BorderSide.none,
            ),
            const Divider(),
            row(
              l10n.monthlyRent,
              formatBirr(lease.monthlyRent, locale: locale),
            ),
            row(l10n.deposit, formatBirr(lease.deposit, locale: locale)),
            row(l10n.dueDay, '${lease.dueDay}'),
            row(l10n.startDate, formatDate(lease.startDate, locale)),
            row(l10n.endDate, formatDate(lease.endDate, locale)),
            row(
              l10n.registeredOn,
              lease.registeredAt == null
                  ? l10n.notRegistered
                  : formatDate(lease.registeredAt!, locale),
            ),
            if ((lease.conditionNotes ?? '').isNotEmpty)
              row(l10n.conditionNotes, lease.conditionNotes!),
          ],
        ),
      ),
    );
  }
}

class _DirectiveWarning extends StatelessWidget {
  const _DirectiveWarning({required this.missing});

  final List<String> missing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final labels = missing.map(
      (m) => switch (m) {
        'landlord_name' => l10n.missingLandlordName,
        'tenant_address' => l10n.missingTenantAddress,
        'condition_notes' => l10n.missingConditionNotes,
        _ => m,
      },
    );
    return Card(
      color: scheme.tertiaryContainer,
      child: ListTile(
        leading: Icon(Icons.info_outline, color: scheme.onTertiaryContainer),
        title: Text(
          l10n.missingLeaseFields(labels.join(', ')),
          style: TextStyle(color: scheme.onTertiaryContainer),
        ),
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({required this.balance, required this.locale});

  final LeaseBalance balance;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget tile(String label, int amount, {Color? color}) => Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              FittedBox(
                child: Text(
                  formatBirr(amount, locale: locale),
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: color),
                ),
              ),
              Text(label, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );

    return Row(
      children: [
        tile(l10n.balanceCharged, balance.charged),
        tile(l10n.balancePaid, balance.paid),
        tile(
          l10n.balanceOutstanding,
          balance.outstanding,
          color: balance.outstanding > 0
              ? Theme.of(context).colorScheme.error
              : null,
        ),
      ],
    );
  }
}

class _LeaseCharges extends ConsumerWidget {
  const _LeaseCharges({required this.leaseId, required this.locale});

  final int leaseId;
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final charges = ref.watch(leaseChargesProvider(leaseId));

    return charges.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => ErrorView(
        error: e,
        onRetry: () => ref.invalidate(leaseChargesProvider(leaseId)),
      ),
      data: (items) => Column(
        children: [
          for (final c in items.reversed)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(formatPeriod(c.period, locale)),
              subtitle: Text(l10n.dueOn(formatDate(c.dueDate, locale))),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(formatBirr(c.amountDue, locale: locale)),
                  const SizedBox(width: 8),
                  ChargeStatusChip(status: c.status),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LeasePayments extends ConsumerWidget {
  const _LeasePayments({
    required this.leaseId,
    required this.locale,
    required this.onChanged,
  });

  final int leaseId;
  final String locale;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final payments = ref.watch(leasePaymentsProvider(leaseId));

    return payments.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => ErrorView(
        error: e,
        onRetry: () => ref.invalidate(leasePaymentsProvider(leaseId)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(l10n.paymentsEmpty),
          );
        }
        return Column(
          children: [
            for (final p in items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.receipt_outlined),
                title: Text(formatBirr(p.amount, locale: locale)),
                subtitle: Text(
                  [
                    formatDate(p.paidAt, locale),
                    p.method.label(l10n),
                    if (p.reference != null) p.reference!,
                  ].join(' · '),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (action) async {
                    if (action == 'share' && p.receiptUrl != null) {
                      await SharePlus.instance.share(
                        ShareParams(
                          text:
                              '${l10n.receiptNumber(p.receiptNumber)}: ${p.receiptUrl}',
                        ),
                      );
                    } else if (action == 'remove') {
                      final ok = await _confirmRemove(context, p.amount);
                      if (ok != true) return;
                      try {
                        await ref.read(paymentsRepositoryProvider).remove(p.id);
                        onChanged();
                      } on ApiException catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(friendlyError(context, e))),
                          );
                        }
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    if (p.receiptUrl != null)
                      PopupMenuItem(
                        value: 'share',
                        child: Text(l10n.shareReceipt),
                      ),
                    if (p.isManual)
                      PopupMenuItem(
                        value: 'remove',
                        child: Text(l10n.removePayment),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Future<bool?> _confirmRemove(BuildContext context, int amount) {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removePayment),
        content: Text(
          l10n.removePaymentConfirm(formatBirr(amount, locale: locale)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.removePayment),
          ),
        ],
      ),
    );
  }
}
