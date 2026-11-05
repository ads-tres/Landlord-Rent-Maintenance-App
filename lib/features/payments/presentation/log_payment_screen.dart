import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/locale_controller.dart';
import '../../../core/utils/app_dates.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/form_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../leases/data/leases_repository.dart';
import '../../leases/domain/lease.dart';
import '../../rent/presentation/rent_screen.dart';
import '../application/pending_payments.dart';
import '../data/payments_repository.dart';
import '../domain/payment.dart';
import 'payment_labels.dart';

/// Records money a tenant paid (cash, Telebirr or bank) against a lease.
class LogPaymentScreen extends ConsumerWidget {
  const LogPaymentScreen({super.key, required this.leaseId});

  final int leaseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final lease = ref.watch(leaseProvider(leaseId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.logPayment)),
      body: lease.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(leaseProvider(leaseId)),
        ),
        data: (l) => _PaymentForm(lease: l),
      ),
    );
  }
}

class _PaymentForm extends ConsumerStatefulWidget {
  const _PaymentForm({required this.lease});

  final Lease lease;

  @override
  ConsumerState<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends ConsumerState<_PaymentForm> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: santimToInput(
      _outstanding > 0 ? _outstanding : widget.lease.monthlyRent,
    ),
  );
  final _reference = TextEditingController();
  final _notes = TextEditingController();
  DateTime _paidAt = dateOnly(DateTime.now());
  PaymentMethod _method = PaymentMethod.telebirr;
  bool _sendSms = true;

  /// Same id for every attempt from this form, so a retry never duplicates the payment.
  final String _clientRef = newClientRef();
  bool _saving = false;
  Map<String, String> _errors = const {};
  String? _error;

  int get _outstanding => widget.lease.balance?.outstanding ?? 0;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _setAmount(int santim) =>
      setState(() => _amount.text = santimToInput(santim));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _errors = const {};
      _error = null;
    });
    try {
      final payment = await ref
          .read(paymentsRepositoryProvider)
          .create(
            leaseId: widget.lease.id,
            amount: parseBirr(_amount.text)!,
            paidAt: _paidAt,
            method: _method,
            reference: _method.needsReference ? _reference.text.trim() : null,
            notes: _notes.text.trim(),
            sendSms: _sendSms,
            clientRef: _clientRef,
          );
      final leaseId = widget.lease.id;
      ref.invalidate(leaseProvider(leaseId));
      ref.invalidate(leaseChargesProvider(leaseId));
      ref.invalidate(leasePaymentsProvider(leaseId));
      ref.invalidate(monthChargesProvider);
      ref.invalidate(dashboardProvider);
      if (!mounted) return;
      setState(() => _saving = false);
      await showModalBottomSheet<void>(
        context: context,
        isDismissible: false,
        showDragHandle: true,
        builder: (_) => PaymentSavedSheet(payment: payment),
      );
      if (mounted) Navigator.of(context).pop(payment);
    } on ApiException catch (e) {
      if (e.isNetworkError) {
        await _saveOffline();
        return;
      }
      if (!mounted) return;
      setState(() {
        _errors = e.fieldErrors;
        _error = e.fieldErrors.isEmpty ? friendlyError(context, e) : null;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// No connection: keep the payment on the phone and send it later.
  Future<void> _saveOffline() async {
    await ref
        .read(pendingPaymentsProvider.notifier)
        .add(
          PendingPayment(
            clientRef: _clientRef,
            leaseId: widget.lease.id,
            amount: parseBirr(_amount.text)!,
            paidAt: _paidAt,
            method: _method,
            reference: _method.needsReference ? _reference.text.trim() : null,
            notes: _notes.text.trim(),
            sendSms: _sendSms,
            tenantName: widget.lease.tenantName,
            unitLabel: widget.lease.unitLabel,
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.cloud_off),
        title: Text(l10n.savedOffline),
        content: Text(l10n.savedOfflineHelp),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.done),
          ),
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider).languageCode;
    final dates = ref.watch(appDatesProvider);
    final lease = widget.lease;
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(lease.tenantName ?? ''),
              subtitle: Text(
                [
                  lease.unitLabel,
                  lease.propertyName,
                ].whereType<String>().join(' · '),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('amountField'),
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              style: Theme.of(context).textTheme.headlineSmall,
              decoration: InputDecoration(
                labelText: l10n.amountPaid,
                errorText: _errors['amount'],
              ),
              validator: (v) =>
                  (parseBirr(v ?? '') ?? 0) < 100 ? l10n.amountInvalid : null,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (_outstanding > 0)
                  ActionChip(
                    label: Text(
                      l10n.quickBalance(
                        formatBirr(_outstanding, locale: locale),
                      ),
                    ),
                    onPressed: () => _setAmount(_outstanding),
                  ),
                for (final n in [1, 2, 3, 6])
                  ActionChip(
                    label: Text(l10n.quickMonths(n)),
                    onPressed: () => _setAmount(lease.monthlyRent * n),
                  ),
              ],
            ),
            fieldGap,
            Text(
              l10n.paymentMethod,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            SegmentedButton<PaymentMethod>(
              segments: [
                for (final m in PaymentMethod.manual)
                  ButtonSegment(value: m, label: Text(m.label(l10n))),
              ],
              selected: {_method},
              onSelectionChanged: (s) => setState(() => _method = s.first),
            ),
            if (_method.needsReference) ...[
              fieldGap,
              TextFormField(
                key: const Key('referenceField'),
                controller: _reference,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: l10n.reference,
                  helperText: l10n.referenceHelp,
                  errorText: _errors['reference'],
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.required : null,
              ),
            ],
            fieldGap,
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _paidAt,
                  firstDate: lease.startDate.subtract(const Duration(days: 60)),
                  lastDate: dateOnly(DateTime.now()),
                );
                if (picked != null) setState(() => _paidAt = picked);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.paidOn,
                  errorText: _errors['paid_at'],
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                child: Text(dates.date(_paidAt)),
              ),
            ),
            fieldGap,
            TextFormField(
              controller: _notes,
              decoration: InputDecoration(
                labelText: l10n.notes,
                errorText: _errors['notes'],
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _sendSms,
              onChanged: (v) => setState(() => _sendSms = v),
              title: Text(l10n.sendReceipt),
              subtitle: Text(l10n.sendReceiptHelp),
            ),
            if (_error != null)
              Text(_error!, style: TextStyle(color: scheme.error)),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('savePaymentButton'),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(),
                    )
                  : Text(l10n.logPayment),
            ),
          ],
        ),
      ),
    );
  }
}

/// Confirmation after logging a payment, with the receipt link to share.
class PaymentSavedSheet extends ConsumerWidget {
  const PaymentSavedSheet({super.key, required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider).languageCode;
    final dates = ref.watch(appDatesProvider);
    final periods = payment.allocations
        .map((a) => dates.period(a.period))
        .toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.check_circle,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.paymentSaved,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              formatBirr(payment.amount, locale: locale),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              l10n.receiptNumber(payment.receiptNumber),
              textAlign: TextAlign.center,
            ),
            if (periods.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.paymentCovers(periods.join(', ')),
                  textAlign: TextAlign.center,
                ),
              ),
            if (payment.smsStatus != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(l10n.smsQueued, textAlign: TextAlign.center),
              ),
            const SizedBox(height: 16),
            if (payment.receiptUrl != null)
              OutlinedButton.icon(
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    text:
                        '${l10n.receiptNumber(payment.receiptNumber)}: ${payment.receiptUrl}',
                  ),
                ),
                icon: const Icon(Icons.share),
                label: Text(l10n.shareReceipt),
              ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.done),
            ),
          ],
        ),
      ),
    );
  }
}
