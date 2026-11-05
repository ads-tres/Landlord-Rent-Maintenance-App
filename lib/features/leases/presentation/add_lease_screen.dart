import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/utils/app_dates.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/form_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../properties/data/properties_repository.dart';
import '../../tenants/data/tenants_repository.dart';
import '../../tenants/domain/tenant.dart';
import '../../tenants/presentation/add_tenant_screen.dart';
import '../data/leases_repository.dart';

/// Guided lease form with the fields Addis directive 7/2024 asks for.
class AddLeaseScreen extends ConsumerStatefulWidget {
  const AddLeaseScreen({
    super.key,
    required this.unitId,
    required this.unitLabel,
    this.propertyId,
  });

  final int unitId;
  final String unitLabel;
  final int? propertyId;

  @override
  ConsumerState<AddLeaseScreen> createState() => _AddLeaseScreenState();
}

class _AddLeaseScreenState extends ConsumerState<AddLeaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rent = TextEditingController();
  final _deposit = TextEditingController();
  final _condition = TextEditingController();

  int? _tenantId;
  late DateTime _start = dateOnly(DateTime.now());
  DateTime? _end;
  late int _dueDay = _start.day > 30 ? 30 : _start.day;
  bool _dueDayEdited = false;
  DateTime? _registeredAt;

  bool _saving = false;
  Map<String, String> _errors = const {};
  String? _error;

  @override
  void dispose() {
    _rent.dispose();
    _deposit.dispose();
    _condition.dispose();
    super.dispose();
  }

  DateTime _minEnd(int years) => minimumLeaseEnd(_start, years);

  Future<DateTime?> _pickDate(
    DateTime initial, {
    DateTime? first,
    DateTime? last,
  }) {
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first ?? DateTime(2015),
      lastDate: last ?? DateTime(2100),
    );
  }

  Future<void> _addTenant() async {
    final tenant = await Navigator.of(
      context,
    ).push<Tenant>(MaterialPageRoute(builder: (_) => const AddTenantScreen()));
    if (tenant != null) {
      ref.invalidate(tenantsProvider);
      setState(() => _tenantId = tenant.id);
    }
  }

  Future<void> _save(int minYears) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _errors = const {};
      _error = null;
    });
    try {
      final lease = await ref
          .read(leasesRepositoryProvider)
          .create(
            unitId: widget.unitId,
            tenantId: _tenantId!,
            startDate: _start,
            endDate: _end ?? _minEnd(minYears),
            monthlyRent: parseBirr(_rent.text)!,
            deposit: parseBirr(_deposit.text) ?? 0,
            dueDay: _dueDay,
            conditionNotes: _condition.text.trim(),
            registeredAt: _registeredAt,
          );
      ref.invalidate(propertiesProvider);
      if (widget.propertyId != null) {
        ref.invalidate(propertyProvider(widget.propertyId!));
      }
      if (mounted) Navigator.of(context).pop(lease);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errors = e.fieldErrors;
        _error = e.fieldErrors.isEmpty ? friendlyError(context, e) : null;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dates = ref.watch(appDatesProvider);
    final rules = ref.watch(rentRulesProvider).value;
    final minYears = rules?.minLeaseYears ?? 2;
    final minEnd = _minEnd(minYears);
    final end = _end ?? minEnd;
    final tenants = ref.watch(tenantsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.leaseFor(widget.unitLabel))),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              tenants.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => ErrorView(
                  error: e,
                  onRetry: () => ref.invalidate(tenantsProvider),
                ),
                data: (items) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        key: const Key('tenantDropdown'),
                        initialValue: items.any((t) => t.id == _tenantId)
                            ? _tenantId
                            : null,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: l10n.tenant,
                          hintText: items.isEmpty
                              ? l10n.noTenantsYet
                              : l10n.selectTenant,
                          errorText: _errors['tenant_id'],
                        ),
                        items: [
                          for (final t in items)
                            DropdownMenuItem(
                              value: t.id,
                              child: Text(
                                t.fullName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (v) => setState(() => _tenantId = v),
                        validator: (v) => v == null ? l10n.required : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: IconButton.filledTonal(
                        tooltip: l10n.newTenant,
                        onPressed: _addTenant,
                        icon: const Icon(Icons.person_add_alt),
                      ),
                    ),
                  ],
                ),
              ),
              fieldGap,
              _DateField(
                label: l10n.startDate,
                value: dates.date(_start),
                error: _errors['start_date'],
                onTap: () async {
                  final picked = await _pickDate(_start);
                  if (picked == null) return;
                  setState(() {
                    _start = picked;
                    if (_end != null && _end!.isBefore(_minEnd(minYears))) {
                      _end = null;
                    }
                    if (!_dueDayEdited) {
                      _dueDay = picked.day > 30 ? 30 : picked.day;
                    }
                  });
                },
              ),
              fieldGap,
              _DateField(
                label: l10n.endDate,
                value: dates.date(end),
                helper: l10n.endDateHelp(minYears),
                error:
                    _errors['end_date'] ??
                    (end.isBefore(minEnd)
                        ? l10n.endDateTooEarly(dates.date(minEnd))
                        : null),
                onTap: () async {
                  final picked = await _pickDate(end, first: minEnd);
                  if (picked != null) setState(() => _end = picked);
                },
              ),
              fieldGap,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('rentField'),
                      controller: _rent,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      decoration: InputDecoration(
                        labelText: l10n.monthlyRent,
                        errorText: _errors['monthly_rent'],
                      ),
                      validator: (v) => (parseBirr(v ?? '') ?? 0) < 100
                          ? l10n.amountInvalid
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _deposit,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      decoration: InputDecoration(
                        labelText: l10n.deposit,
                        errorText: _errors['deposit'],
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty || parseBirr(v) != null)
                          ? null
                          : l10n.amountInvalid,
                    ),
                  ),
                ],
              ),
              fieldGap,
              DropdownButtonFormField<int>(
                initialValue: _dueDay,
                decoration: InputDecoration(
                  labelText: l10n.dueDay,
                  helperText: l10n.dueDayHelp,
                  errorText: _errors['due_day'],
                ),
                items: [
                  for (var d = 1; d <= 30; d++)
                    DropdownMenuItem(value: d, child: Text('$d')),
                ],
                onChanged: (v) => setState(() {
                  _dueDay = v ?? _dueDay;
                  _dueDayEdited = true;
                }),
              ),
              fieldGap,
              TextFormField(
                key: const Key('conditionField'),
                controller: _condition,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: l10n.conditionNotes,
                  hintText: l10n.conditionNotesHint,
                  alignLabelWithHint: true,
                  errorText: _errors['condition_notes'],
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.required : null,
              ),
              fieldGap,
              _DateField(
                label: l10n.registeredOn,
                value: _registeredAt == null
                    ? l10n.notRegistered
                    : dates.date(_registeredAt!),
                error: _errors['registered_at'],
                trailing: _registeredAt == null
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _registeredAt = null),
                      ),
                onTap: () async {
                  final picked = await _pickDate(
                    _registeredAt ?? DateTime.now(),
                    last: DateTime.now(),
                  );
                  if (picked != null) setState(() => _registeredAt = picked);
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: scheme.error)),
              ],
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('saveLeaseButton'),
                onPressed: _saving || end.isBefore(minEnd)
                    ? null
                    : () => _save(minYears),
                child: _saving
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(),
                      )
                    : Text(l10n.addLease),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.disclaimer,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.helper,
    this.error,
    this.trailing,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final String? helper;
  final String? error;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          errorText: error,
          suffixIcon: trailing ?? const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(value),
      ),
    );
  }
}
