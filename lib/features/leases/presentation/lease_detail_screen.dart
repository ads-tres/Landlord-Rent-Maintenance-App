import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/locale_controller.dart';
import '../../../core/utils/app_dates.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/phone_number.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/form_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../listings/data/listings_repository.dart';
import '../../move_out/data/move_out_repository.dart';
import '../../online_rent/data/online_rent_repository.dart';
import '../../payments/application/pending_payments.dart';
import '../../payments/data/payments_repository.dart';
import '../../payments/presentation/pending_payment_tile.dart';
import '../../payments/presentation/payment_labels.dart';
import '../../properties/data/properties_repository.dart';
import '../../repairs/data/repairs_repository.dart';
import '../../rent/presentation/rent_screen.dart';
import '../data/leases_repository.dart';
import '../domain/lease.dart';
import '../domain/rent_rules.dart';
import 'charge_labels.dart';
import 'status_chips.dart';
import '../../auth/application/auth_controller.dart';

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
    final caretaker = ref.watch(isCaretakerProvider);
    final dates = ref.watch(appDatesProvider);
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
                if (action == 'moveout') {
                  await _startMoveOut(context, ref, l);
                  return;
                }
                final changed = action == 'rent'
                    ? await _changeRent(context, ref, l)
                    : await _endLease(context, ref, l);
                if (changed) _refreshAll(ref, l);
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  key: const Key('moveOutMenuItem'),
                  value: 'moveout',
                  child: Text(l10n.moveOut),
                ),
                if (!caretaker) ...[
                  PopupMenuItem(value: 'rent', child: Text(l10n.changeRent)),
                  PopupMenuItem(value: 'end', child: Text(l10n.endLease)),
                ],
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
              if (l.status == LeaseStatus.draft) ...[
                Card(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l10n.leaseDraftBanner),
                        const SizedBox(height: 8),
                        if (!caretaker)
                          FilledButton(
                            key: const Key('activateLeaseButton'),
                            onPressed: () async {
                              if (await _activate(context, ref, l)) {
                                _refreshAll(ref, l);
                              }
                            },
                            child: Text(l10n.activateLease),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (l.moveOutId != null) ...[
                Card(
                  color: l.moveOutSettled
                      ? null
                      : Theme.of(context).colorScheme.tertiaryContainer,
                  child: ListTile(
                    key: const Key('moveOutCard'),
                    leading: Icon(
                      l.moveOutSettled
                          ? Icons.receipt_long_outlined
                          : Icons.moving_outlined,
                    ),
                    title: Text(
                      l.moveOutSettled
                          ? l10n.depositStatement
                          : l10n.moveOutInProgress,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await context.push('/move-outs/${l.moveOutId}');
                      _refreshAll(ref, l);
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _Header(lease: l, locale: locale),
              if (l.missingFields.isNotEmpty) ...[
                const SizedBox(height: 12),
                _DirectiveWarning(missing: l.missingFields),
              ],
              if (l.portalUrl != null) ...[
                const SizedBox(height: 12),
                _PortalLinkCard(lease: l, onReset: () => _refreshAll(ref, l)),
              ],
              if (l.payUrl != null) ...[
                const SizedBox(height: 12),
                _PayLinkCard(lease: l),
              ],
              if (l.repairUrl != null) ...[
                const SizedBox(height: 12),
                _RepairLinkCard(lease: l, onReset: () => _refreshAll(ref, l)),
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
                        dates.date(c.effectiveDate),
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

  Future<bool> _activate(BuildContext context, WidgetRef ref, Lease lease) {
    final l10n = AppLocalizations.of(context);
    final notes = TextEditingController();
    final deposit = TextEditingController();
    var start = lease.startDate;
    var end = lease.endDate;

    return showFormSheet(
      context,
      FormSheet(
        title: l10n.activateLease,
        onSave: () => ref
            .read(listingsRepositoryProvider)
            .activateLease(
              lease.id,
              conditionNotes: notes.text.trim(),
              startDate: start,
              endDate: end,
              deposit: parseBirr(deposit.text),
            ),
        fieldsBuilder: (context, errors) => [
          TextFormField(
            key: const Key('activateConditionField'),
            controller: notes,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: l10n.conditionNotes,
              hintText: l10n.conditionNotesHint,
              errorText: errors['condition_notes'],
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.required : null,
          ),
          fieldGap,
          StatefulBuilder(
            builder: (context, setState) {
              final dates = ref.read(appDatesProvider);
              return Column(
                children: [
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: start,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          start = picked;
                          end = minimumLeaseEnd(picked, 2);
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(labelText: l10n.startDate),
                      child: Text(dates.date(start)),
                    ),
                  ),
                  fieldGap,
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.endDate,
                      errorText: errors['end_date'],
                    ),
                    child: Text(dates.date(end)),
                  ),
                ],
              );
            },
          ),
          fieldGap,
          TextFormField(
            controller: deposit,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.deposit,
              errorText: errors['deposit'],
            ),
          ),
        ],
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
    final dates = ref.read(appDatesProvider);
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
                    child: Text(dates.date(effective)),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _startMoveOut(
    BuildContext context,
    WidgetRef ref,
    Lease lease,
  ) async {
    final l10n = AppLocalizations.of(context);
    if (lease.moveOutId != null) {
      await context.push('/move-outs/${lease.moveOutId}');
      _refreshAll(ref, lease);
      return;
    }
    final today = dateOnly(DateTime.now());
    final initial = today.isBefore(lease.startDate)
        ? lease.startDate
        : (today.isAfter(lease.endDate) ? lease.endDate : today);
    final movedOutOn = await showDatePicker(
      context: context,
      helpText: l10n.movedOutOn,
      initialDate: initial,
      firstDate: lease.startDate,
      lastDate: lease.endDate,
    );
    if (movedOutOn == null || !context.mounted) return;

    try {
      final m = await ref
          .read(moveOutRepositoryProvider)
          .start(lease.id, movedOutOn: movedOutOn);
      if (!context.mounted) return;
      await context.push('/move-outs/${m.id}');
      _refreshAll(ref, lease);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(context, e))));
      }
    }
  }

  Future<bool> _endLease(
    BuildContext context,
    WidgetRef ref,
    Lease lease,
  ) async {
    final l10n = AppLocalizations.of(context);
    final dates = ref.read(appDatesProvider);
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
        content: Text(l10n.endLeaseConfirm(dates.date(endedOn))),
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

class _Header extends ConsumerWidget {
  const _Header({required this.lease, required this.locale});

  final Lease lease;
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dates = ref.watch(appDatesProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final statusText = switch (lease.status) {
      LeaseStatus.active =>
        lease.daysUntilEnd != null && lease.daysUntilEnd! <= 60
            ? l10n.endsIn(lease.daysUntilEnd! < 0 ? 0 : lease.daysUntilEnd!)
            : l10n.leaseActive,
      LeaseStatus.ended =>
        lease.terminatedOn != null
            ? l10n.endedOn(dates.date(lease.terminatedOn!))
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
            row(l10n.startDate, dates.date(lease.startDate)),
            row(l10n.endDate, dates.date(lease.endDate)),
            row(
              l10n.registeredOn,
              lease.registeredAt == null
                  ? l10n.notRegistered
                  : dates.date(lease.registeredAt!),
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
    final dates = ref.watch(appDatesProvider);
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
              title: Text(
                c.isUtility
                    ? '${utilityLabel(l10n, c.utilityKind)} · ${dates.period(c.period)}'
                    : dates.period(c.period),
              ),
              subtitle: Text(l10n.dueOn(dates.date(c.dueDate))),
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
    final dates = ref.watch(appDatesProvider);
    final l10n = AppLocalizations.of(context);
    final pending = (ref.watch(pendingPaymentsProvider).value ?? const [])
        .where((p) => p.leaseId == leaseId)
        .toList();
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
        if (items.isEmpty && pending.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(l10n.paymentsEmpty),
          );
        }
        return Column(
          children: [
            for (final p in pending)
              PendingPaymentTile(payment: p, showTenant: false),
            for (final p in items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(p.isManual ? Icons.receipt_outlined : Icons.bolt),
                title: Row(
                  children: [
                    Text(formatBirr(p.amount, locale: locale)),
                    if (!p.isManual) ...[
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(
                          p.source == 'deposit'
                              ? l10n.methodDeposit
                              : l10n.paidOnline,
                        ),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide.none,
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  [
                    dates.date(p.paidAt),
                    p.method.label(l10n),
                    if (p.reference != null) p.reference!,
                    if (p.recordedByName != null)
                      l10n.loggedBy(p.recordedByName!),
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
                    if (p.isManual && !ref.watch(isCaretakerProvider))
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

/// The tenant's own page: send, share, copy or replace the link.
class _PortalLinkCard extends ConsumerWidget {
  const _PortalLinkCard({required this.lease, required this.onReset});

  final Lease lease;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(leasesRepositoryProvider);
    final url = lease.portalUrl!;

    Future<void> run(Future<void> Function() action, {String? done}) async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await action();
        if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
      } on ApiException catch (e) {
        if (context.mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text(friendlyError(context, e))),
          );
        }
      }
    }

    return Card(
      key: const Key('portalLinkCard'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tenantPage,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(l10n.tenantPageHelp),
            const SizedBox(height: 4),
            SelectableText(
              url,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            Wrap(
              spacing: 4,
              children: [
                if (lease.isActive)
                  TextButton.icon(
                    key: const Key('sendPortalLink'),
                    onPressed: () => run(
                      () => repo.sendPortalLink(lease.id),
                      done: l10n.tenantPageSent,
                    ),
                    icon: const Icon(Icons.sms_outlined),
                    label: Text(l10n.sendToTenant),
                  ),
                TextButton.icon(
                  onPressed: () =>
                      SharePlus.instance.share(ShareParams(text: url)),
                  icon: const Icon(Icons.share),
                  label: Text(l10n.share),
                ),
                TextButton.icon(
                  key: const Key('copyPortalLink'),
                  onPressed: () => run(
                    () => Clipboard.setData(ClipboardData(text: url)),
                    done: l10n.linkCopied,
                  ),
                  icon: const Icon(Icons.copy),
                  label: Text(l10n.copy),
                ),
                TextButton.icon(
                  key: const Key('resetPortalLink'),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        content: Text(l10n.resetTenantPageConfirm),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(l10n.cancel),
                          ),
                          FilledButton(
                            key: const Key('confirmResetPortalLink'),
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(l10n.resetLink),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await run(() => repo.resetPortalLink(lease.id));
                      onReset();
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.resetLink),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RepairLinkCard extends ConsumerWidget {
  const _RepairLinkCard({required this.lease, required this.onReset});

  final Lease lease;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(repairsRepositoryProvider);

    Future<void> run(Future<void> Function() action, {String? done}) async {
      try {
        await action();
        if (done != null && context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(done)));
        }
      } on ApiException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(friendlyError(context, e))));
        }
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.repairLink,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(l10n.repairLinkHelp),
            const SizedBox(height: 4),
            SelectableText(
              lease.repairUrl!,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            Wrap(
              spacing: 4,
              children: [
                TextButton.icon(
                  key: const Key('sendRepairLink'),
                  onPressed: () => run(
                    () => repo.sendRepairLink(lease.id),
                    done: l10n.repairLinkSent,
                  ),
                  icon: const Icon(Icons.sms_outlined),
                  label: Text(l10n.sendRepairLink),
                ),
                TextButton.icon(
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(text: lease.repairUrl!),
                  ),
                  icon: const Icon(Icons.share),
                  label: Text(l10n.shareRepairLink),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        content: Text(l10n.resetRepairLinkConfirm),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(l10n.cancel),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(l10n.resetRepairLink),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await run(() => repo.resetRepairLink(lease.id));
                      onReset();
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.resetRepairLink),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PayLinkCard extends ConsumerWidget {
  const _PayLinkCard({required this.lease});

  final Lease lease;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Card(
      key: const Key('payLinkCard'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.payLink, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(l10n.payLinkHelp),
            SelectableText(
              lease.payUrl!,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            Wrap(
              spacing: 4,
              children: [
                TextButton.icon(
                  key: const Key('sendPayLink'),
                  onPressed: () async {
                    try {
                      await ref
                          .read(onlineRentRepositoryProvider)
                          .sendPayLink(lease.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.payLinkSent)),
                        );
                      }
                    } on ApiException catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(friendlyError(context, e))),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.sms_outlined),
                  label: Text(l10n.sendPayLink),
                ),
                TextButton.icon(
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(text: lease.payUrl!),
                  ),
                  icon: const Icon(Icons.share),
                  label: Text(l10n.shareRepairLink),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
