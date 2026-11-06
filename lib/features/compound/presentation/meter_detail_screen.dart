import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/locale_controller.dart';
import '../../../core/utils/app_dates.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/form_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../payments/data/payments_repository.dart';
import '../../rent/presentation/rent_screen.dart';
import '../../repairs/presentation/repair_widgets.dart' show pickRepairPhoto;
import '../data/compound_repository.dart';
import '../domain/compound.dart';
import 'labels.dart';

/// A shared meter with its bills; enter a new bill and see how it splits.
class MeterDetailScreen extends ConsumerWidget {
  const MeterDetailScreen({super.key, required this.meterId});

  final int meterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider).languageCode;
    final dates = ref.watch(appDatesProvider);
    final meter = ref.watch(meterProvider(meterId));
    final bills = ref.watch(billsProvider(meterId));

    return Scaffold(
      appBar: AppBar(title: Text(meter.value?.name ?? l10n.sharedMeters)),
      floatingActionButton: meter.hasValue
          ? FloatingActionButton.extended(
              key: const Key('enterBillFab'),
              onPressed: () async {
                final saved = await Navigator.of(context).push<UtilityBill>(
                  MaterialPageRoute(
                    builder: (_) => EnterBillScreen(meter: meter.requireValue),
                  ),
                );
                if (saved != null) {
                  ref.invalidate(billsProvider(meterId));
                  ref.invalidate(meterProvider(meterId));
                }
              },
              icon: const Icon(Icons.receipt_long),
              label: Text(l10n.enterBill),
            )
          : null,
      body: meter.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(meterProvider(meterId)),
        ),
        data: (m) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Icon(m.kind.icon)),
              title: Text(
                '${m.kind.label(l10n)} · ${m.splitMethod.label(l10n)}',
              ),
              subtitle: Text(
                m.units
                    .map(
                      (u) => u.sharePercent != null
                          ? '${u.label} ${u.sharePercent!.toStringAsFixed(0)}%'
                          : u.label,
                    )
                    .join(', '),
              ),
            ),
            const SizedBox(height: 8),
            Text(l10n.bills, style: Theme.of(context).textTheme.titleMedium),
            bills.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => ErrorView(
                error: e,
                onRetry: () => ref.invalidate(billsProvider(meterId)),
              ),
              data: (items) => items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(l10n.billsEmpty),
                    )
                  : Column(
                      children: [
                        for (final b in items)
                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: Text(
                              '${dates.period(b.period)} · ${formatBirr(b.amount, locale: locale)}',
                            ),
                            subtitle: Text(l10n.dueOn(dates.date(b.dueDate))),
                            children: [
                              for (final line in b.lines)
                                ListTile(
                                  dense: true,
                                  title: Text(line.unitLabel),
                                  subtitle: line.tenantName != null
                                      ? Text(line.tenantName!)
                                      : null,
                                  trailing: Text(
                                    formatBirr(line.amount, locale: locale),
                                  ),
                                ),
                              if (b.landlordShare > 0)
                                ListTile(
                                  dense: true,
                                  title: Text(
                                    l10n.landlordShare(
                                      formatBirr(
                                        b.landlordShare,
                                        locale: locale,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class EnterBillScreen extends ConsumerStatefulWidget {
  const EnterBillScreen({super.key, required this.meter});

  final Meter meter;

  @override
  ConsumerState<EnterBillScreen> createState() => _EnterBillScreenState();
}

class _EnterBillScreenState extends ConsumerState<EnterBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime _due = dateOnly(DateTime.now()).add(const Duration(days: 7));
  final Map<int, (TextEditingController, TextEditingController)> _readings = {};
  String? _photo;
  bool _notify = true;
  bool _busy = false;
  SplitPreview? _preview;
  String? _error;

  bool get _submeter => widget.meter.splitMethod == SplitMethod.submeter;

  @override
  void dispose() {
    _amount.dispose();
    for (final (a, b) in _readings.values) {
      a.dispose();
      b.dispose();
    }
    super.dispose();
  }

  Map<int, (double, double)> _readingValues() => {
    for (final e in _readings.entries)
      e.key: (
        double.tryParse(e.value.$1.text) ?? 0,
        double.tryParse(e.value.$2.text) ?? 0,
      ),
  };

  Future<void> _run(bool save) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final repo = ref.read(compoundRepositoryProvider);
    try {
      if (save) {
        final bill = await repo.createBill(
          widget.meter.id,
          period: periodOf(_month),
          amount: parseBirr(_amount.text)!,
          dueDate: _due,
          readings: _submeter ? _readingValues() : const {},
          photoPath: _photo,
          notifyTenants: _notify,
        );
        ref.invalidate(monthChargesProvider);
        ref.invalidate(dashboardProvider);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).billSaved)),
        );
        Navigator.of(context).pop(bill);
      } else {
        final preview = await repo.previewBill(
          widget.meter.id,
          period: periodOf(_month),
          amount: parseBirr(_amount.text)!,
          dueDate: _due,
          readings: _submeter ? _readingValues() : const {},
        );
        if (mounted) setState(() => _preview = preview);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(
          () => _error =
              e.fieldErrors.values.firstOrNull ?? friendlyError(context, e),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider).languageCode;
    final dates = ref.watch(appDatesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.enterBill)),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() => _preview = null),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              widget.meter.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            fieldGap,
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(
                    () => _month = DateTime(_month.year, _month.month - 1),
                  ),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: InputDecorator(
                    decoration: InputDecoration(labelText: l10n.billMonth),
                    child: Text(dates.month(_month)),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(
                    () => _month = DateTime(_month.year, _month.month + 1),
                  ),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            fieldGap,
            TextFormField(
              key: const Key('billAmountField'),
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(labelText: l10n.billAmount),
              validator: (v) =>
                  (parseBirr(v ?? '') ?? 0) < 100 ? l10n.amountInvalid : null,
            ),
            fieldGap,
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _due,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _due = picked);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.billDueDate,
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                child: Text(dates.date(_due)),
              ),
            ),
            if (_submeter) ...[
              const SizedBox(height: 16),
              Text(
                l10n.readings,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final u in widget.meter.units)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      SizedBox(width: 90, child: Text(u.label)),
                      for (final (i, label) in [
                        l10n.previousReading,
                        l10n.currentReading,
                      ].indexed) ...[
                        Expanded(
                          child: TextFormField(
                            key: Key('reading-${u.unitId}-$i'),
                            controller: i == 0
                                ? _readings
                                      .putIfAbsent(
                                        u.unitId,
                                        () => (
                                          TextEditingController(),
                                          TextEditingController(),
                                        ),
                                      )
                                      .$1
                                : _readings
                                      .putIfAbsent(
                                        u.unitId,
                                        () => (
                                          TextEditingController(),
                                          TextEditingController(),
                                        ),
                                      )
                                      .$2,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'),
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText: label,
                              isDense: true,
                            ),
                            validator: (v) => double.tryParse(v ?? '') == null
                                ? l10n.required
                                : null,
                          ),
                        ),
                        if (i == 0) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
            ],
            fieldGap,
            Row(
              children: [
                if (_photo != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_photo!),
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                TextButton.icon(
                  onPressed: () async {
                    final path = await pickRepairPhoto(context);
                    if (path != null) setState(() => _photo = path);
                  },
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(l10n.billPhoto),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _notify,
              onChanged: (v) => setState(() => _notify = v),
              title: Text(l10n.notifyTenants),
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (_preview != null) ...[
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.splitResult,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      for (final line in _preview!.lines)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  [
                                    line.unitLabel,
                                    line.vacant
                                        ? l10n.vacant
                                        : (line.tenantName ?? ''),
                                  ].where((s) => s.isNotEmpty).join(' · '),
                                ),
                              ),
                              Text(formatBirr(line.amount, locale: locale)),
                            ],
                          ),
                        ),
                      if (_preview!.landlordShare > 0)
                        Text(
                          l10n.landlordShare(
                            formatBirr(_preview!.landlordShare, locale: locale),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('previewSplitButton'),
                    onPressed: _busy ? null : () => _run(false),
                    child: Text(l10n.previewSplit),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const Key('saveBillButton'),
                    onPressed: _busy ? null : () => _run(true),
                    child: Text(l10n.saveBill),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
