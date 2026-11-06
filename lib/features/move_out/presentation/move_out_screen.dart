import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/locale_controller.dart';
import '../../../core/utils/app_dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/form_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../leases/data/leases_repository.dart';
import '../../payments/data/payments_repository.dart';
import '../../payments/domain/payment.dart';
import '../../payments/presentation/payment_labels.dart';
import '../../properties/data/properties_repository.dart';
import '../../repairs/presentation/repair_widgets.dart';
import '../data/move_out_repository.dart';
import '../domain/move_out.dart';

/// Move-out: condition check with photos, deposit deductions, settlement and
/// the statement for the tenant.
class MoveOutScreen extends ConsumerWidget {
  const MoveOutScreen({super.key, required this.moveOutId});

  final int moveOutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final moveOut = ref.watch(moveOutProvider(moveOutId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.moveOut)),
      body: moveOut.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(moveOutProvider(moveOutId)),
        ),
        data: (m) => RefreshIndicator(
          onRefresh: () => ref.refresh(moveOutProvider(moveOutId).future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              if (m.tenantName != null || m.unitLabel != null)
                Text(
                  [?m.tenantName, ?m.unitLabel].join(' · '),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              if (m.settled) ...[
                const SizedBox(height: 8),
                _SettledBanner(moveOut: m),
              ],
              _ConditionSection(moveOut: m),
              _DeductionsSection(moveOut: m),
              _Summary(moveOut: m),
              const SizedBox(height: 16),
              if (!m.settled)
                FilledButton.icon(
                  key: const Key('settleMoveOut'),
                  onPressed: () => _settle(context, ref, m),
                  icon: const Icon(Icons.task_alt),
                  label: Text(l10n.settleMoveOut),
                )
              else
                _SettledActions(moveOut: m),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _settle(BuildContext context, WidgetRef ref, MoveOut m) async {
    final l10n = AppLocalizations.of(context);
    final locale = ref.read(localeControllerProvider).languageCode;
    final reference = TextEditingController();
    var method = PaymentMethod.cash;
    var notify = true;

    final saved = await showFormSheet(
      context,
      FormSheet(
        title: l10n.settleMoveOut,
        saveLabel: l10n.settleMoveOutConfirm,
        onSave: () => ref
            .read(moveOutRepositoryProvider)
            .settle(
              m.id,
              refundMethod: m.refundAmount > 0 ? method.name : null,
              refundReference: reference.text.trim(),
              notifyTenant: notify,
            ),
        fieldsBuilder: (context, errors) => [
          Text(
            m.refundAmount > 0
                ? l10n.settleRefundLine(
                    formatBirr(m.refundAmount, locale: locale),
                  )
                : l10n.settleNoRefund,
          ),
          if (m.balanceOwed > 0) ...[
            const SizedBox(height: 4),
            Text(
              l10n.moveOutBalanceOwed(
                formatBirr(m.balanceOwed, locale: locale),
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            l10n.settleEndsLease,
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
          if (m.refundAmount > 0) ...[
            fieldGap,
            StatefulBuilder(
              builder: (context, setState) => SegmentedButton<PaymentMethod>(
                segments: [
                  for (final pm in PaymentMethod.manual)
                    ButtonSegment(value: pm, label: Text(pm.label(l10n))),
                ],
                selected: {method},
                onSelectionChanged: (s) => setState(() => method = s.first),
              ),
            ),
            fieldGap,
            TextFormField(
              controller: reference,
              decoration: InputDecoration(
                labelText: l10n.refundReference,
                errorText:
                    errors['refund_reference'] ?? errors['refund_method'],
              ),
            ),
          ],
          StatefulBuilder(
            builder: (context, setState) => SwitchListTile(
              key: const Key('notifyTenantSwitch'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.sendStatementToTenant),
              value: notify,
              onChanged: (v) => setState(() => notify = v),
            ),
          ),
        ],
      ),
    );

    if (saved) {
      ref.invalidate(moveOutProvider(m.id));
      ref.invalidate(leaseProvider(m.leaseId));
      ref.invalidate(leaseChargesProvider(m.leaseId));
      ref.invalidate(leasePaymentsProvider(m.leaseId));
      ref.invalidate(dashboardProvider);
      ref.invalidate(propertiesProvider);
    }
  }
}

/// Runs a change and refreshes the move-out, or shows the error.
Future<void> _change(
  BuildContext context,
  WidgetRef ref,
  int id,
  Future<Object?> Function() action,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final errorText = friendlyError;
  try {
    await action();
    ref.invalidate(moveOutProvider(id));
  } on ApiException catch (e) {
    if (context.mounted) {
      messenger.showSnackBar(SnackBar(content: Text(errorText(context, e))));
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.titleMedium),
        ),
        ?trailing,
      ],
    ),
  );
}

class _ConditionSection extends ConsumerWidget {
  const _ConditionSection({required this.moveOut});

  final MoveOut moveOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dates = ref.watch(appDatesProvider);
    final m = moveOut;
    final repo = ref.read(moveOutRepositoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(l10n.moveOutCondition),
        ListTile(
          key: const Key('moveOutDate'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.event_outlined),
          title: Text(l10n.movedOutOn),
          subtitle: Text(dates.date(m.movedOutOn)),
          trailing: m.settled ? null : const Icon(Icons.edit_outlined),
          onTap: m.settled
              ? null
              : () async {
                  final lease = await ref.read(leaseProvider(m.leaseId).future);
                  if (!context.mounted) return;
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: m.movedOutOn,
                    firstDate: lease.startDate,
                    lastDate: lease.endDate,
                  );
                  if (picked == null || !context.mounted) return;
                  await _change(
                    context,
                    ref,
                    m.id,
                    () => repo.update(m.id, movedOutOn: picked),
                  );
                },
        ),
        SwitchListTile(
          key: const Key('keysReturned'),
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.key_outlined),
          title: Text(l10n.keysReturned),
          value: m.keysReturned,
          onChanged: m.settled
              ? null
              : (v) => _change(
                  context,
                  ref,
                  m.id,
                  () => repo.update(m.id, keysReturned: v),
                ),
        ),
        ListTile(
          key: const Key('conditionNotes'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.notes),
          title: Text(
            (m.conditionNotes ?? '').isEmpty
                ? l10n.conditionNotesEmpty
                : m.conditionNotes!,
          ),
          trailing: m.settled ? null : const Icon(Icons.edit_outlined),
          onTap: m.settled ? null : () => _editNotes(context, ref),
        ),
        if (m.photoUrls.isNotEmpty || !m.settled)
          SizedBox(
            height: 96,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final url in m.photoUrls)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(width: 96, child: AuthImage(url: url)),
                    ),
                  ),
                if (!m.settled && m.photoUrls.length < 12)
                  SizedBox(
                    width: 96,
                    child: OutlinedButton(
                      key: const Key('addMoveOutPhoto'),
                      onPressed: () async {
                        final path = await pickRepairPhoto(context);
                        if (path == null || !context.mounted) return;
                        await _change(
                          context,
                          ref,
                          m.id,
                          () => repo.addPhoto(m.id, path),
                        );
                      },
                      child: const Icon(Icons.add_a_photo_outlined),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _editNotes(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final notes = TextEditingController(text: moveOut.conditionNotes);
    final saved = await showFormSheet(
      context,
      FormSheet(
        title: l10n.moveOutCondition,
        onSave: () => ref
            .read(moveOutRepositoryProvider)
            .update(moveOut.id, conditionNotes: notes.text.trim()),
        fieldsBuilder: (context, errors) => [
          TextFormField(
            key: const Key('conditionNotesField'),
            controller: notes,
            autofocus: true,
            minLines: 3,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: l10n.conditionNotes,
              hintText: l10n.conditionNotesHint,
              errorText: errors['condition_notes'],
            ),
          ),
        ],
      ),
    );
    if (saved) ref.invalidate(moveOutProvider(moveOut.id));
  }
}

class _DeductionsSection extends ConsumerWidget {
  const _DeductionsSection({required this.moveOut});

  final MoveOut moveOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider).languageCode;
    final m = moveOut;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          l10n.deductions,
          trailing: m.settled
              ? null
              : TextButton.icon(
                  key: const Key('addDeduction'),
                  onPressed: () => _add(context, ref),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addDeduction),
                ),
        ),
        if (m.deductions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(l10n.noDeductions),
          ),
        for (final d in m.deductions)
          ListTile(
            key: Key('deduction-${d.id}'),
            contentPadding: EdgeInsets.zero,
            title: Text(d.kind.label(l10n)),
            subtitle: (d.description ?? '').isEmpty
                ? null
                : Text(d.description!),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(formatBirr(d.amount, locale: locale)),
                if (!m.settled && !d.fromCharge)
                  IconButton(
                    tooltip: l10n.delete,
                    icon: const Icon(Icons.close),
                    onPressed: () => _change(
                      context,
                      ref,
                      m.id,
                      () => ref
                          .read(moveOutRepositoryProvider)
                          .removeDeduction(d.id),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final description = TextEditingController();
    final amount = TextEditingController();
    var kind = DeductionKind.damage;

    final saved = await showFormSheet(
      context,
      FormSheet(
        title: l10n.addDeduction,
        onSave: () => ref
            .read(moveOutRepositoryProvider)
            .addDeduction(
              moveOut.id,
              kind: kind,
              description: description.text.trim(),
              amount: parseBirr(amount.text)!,
            ),
        fieldsBuilder: (context, errors) => [
          StatefulBuilder(
            builder: (context, setState) =>
                DropdownButtonFormField<DeductionKind>(
                  initialValue: kind,
                  decoration: InputDecoration(labelText: l10n.deductionKind),
                  items: [
                    for (final k in DeductionKind.manual)
                      DropdownMenuItem(value: k, child: Text(k.label(l10n))),
                  ],
                  onChanged: (v) => setState(() => kind = v ?? kind),
                ),
          ),
          fieldGap,
          TextFormField(
            key: const Key('deductionDescriptionField'),
            controller: description,
            decoration: InputDecoration(
              labelText: l10n.deductionDescription,
              hintText: l10n.deductionDescriptionHint,
              errorText: errors['description'],
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.required : null,
          ),
          fieldGap,
          TextFormField(
            key: const Key('deductionAmountField'),
            controller: amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              labelText: l10n.expenseAmount,
              errorText: errors['amount'],
            ),
            validator: (v) =>
                (parseBirr(v ?? '') ?? 0) < 1 ? l10n.amountInvalid : null,
          ),
        ],
      ),
    );
    if (saved) ref.invalidate(moveOutProvider(moveOut.id));
  }
}

class _Summary extends ConsumerWidget {
  const _Summary({required this.moveOut});

  final MoveOut moveOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider).languageCode;
    String birr(int s) => formatBirr(s, locale: locale);
    final m = moveOut;
    final scheme = Theme.of(context).colorScheme;

    Widget line(String label, String value, {Key? key, TextStyle? style}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(child: Text(label, style: style)),
              Text(value, key: key, style: style),
            ],
          ),
        );

    final strong = Theme.of(context).textTheme.titleMedium;
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            line(l10n.depositHeld, birr(m.deposit)),
            line(l10n.deductions, '− ${birr(m.deductionsTotal)}'),
            const Divider(),
            line(
              l10n.refund,
              birr(m.refundAmount),
              key: const Key('refundAmount'),
              style: strong,
            ),
            if (m.balanceOwed > 0)
              line(
                l10n.stillOwed,
                birr(m.balanceOwed),
                key: const Key('balanceOwed'),
                style: strong?.copyWith(color: scheme.error),
              ),
          ],
        ),
      ),
    );
  }
}

class _SettledBanner extends ConsumerWidget {
  const _SettledBanner({required this.moveOut});

  final MoveOut moveOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final method = moveOut.refundMethod == null
        ? null
        : PaymentMethod.parse(moveOut.refundMethod).label(l10n);
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: ListTile(
        leading: const Icon(Icons.task_alt),
        title: Text(l10n.moveOutSettled),
        subtitle: method == null
            ? null
            : Text(
                [
                  l10n.refundedBy(method),
                  if ((moveOut.refundReference ?? '').isNotEmpty)
                    moveOut.refundReference!,
                ].join(' · '),
              ),
      ),
    );
  }
}

class _SettledActions extends ConsumerStatefulWidget {
  const _SettledActions({required this.moveOut});

  final MoveOut moveOut;

  @override
  ConsumerState<_SettledActions> createState() => _SettledActionsState();
}

class _SettledActionsState extends ConsumerState<_SettledActions> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, {String? done}) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
      if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
    } on ApiException catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(friendlyError(context, e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final m = widget.moveOut;
    final repo = ref.read(moveOutRepositoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          key: const Key('shareStatement'),
          onPressed: _busy
              ? null
              : () => _run(() async {
                  final path = await repo.downloadStatement(m.id);
                  await SharePlus.instance.share(
                    ShareParams(
                      files: [XFile(path, mimeType: 'application/pdf')],
                      text: l10n.depositStatement,
                    ),
                  );
                }),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: Text(l10n.shareStatement),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('sendStatement'),
          onPressed: _busy
              ? null
              : () => _run(
                  () => repo.sendStatement(m.id),
                  done: l10n.statementSent,
                ),
          icon: const Icon(Icons.sms_outlined),
          label: Text(l10n.sendStatementToTenant),
        ),
        if (m.unitId != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('listUnitAfterMoveOut'),
            onPressed: () => context.push(
              '/listings/new?unitId=${m.unitId}&unitLabel=${Uri.encodeQueryComponent(m.unitLabel ?? '')}',
            ),
            icon: const Icon(Icons.campaign_outlined),
            label: Text(l10n.listUnit),
          ),
        ],
      ],
    );
  }
}
