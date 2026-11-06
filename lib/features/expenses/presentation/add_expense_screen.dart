import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/locale_controller.dart';
import '../../../core/offline/outbox.dart';
import '../../home/presentation/sync_screen.dart';
import '../../../core/utils/app_dates.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/form_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../properties/data/properties_repository.dart';
import '../../repairs/presentation/repair_widgets.dart';
import '../data/expenses_repository.dart';
import '../domain/expense.dart';

/// Record money spent on a property, with an optional photo of the receipt.
class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key, this.propertyId});

  final int? propertyId;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  final _vendor = TextEditingController();
  late int? _propertyId = widget.propertyId;
  int? _unitId;
  ExpenseCategory _category = ExpenseCategory.repair;
  DateTime _spentOn = dateOnly(DateTime.now());
  String? _photo;
  final String _clientRef = newClientRef();
  bool _saving = false;
  Map<String, String> _errors = const {};
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _vendor.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _errors = const {};
      _error = null;
    });
    try {
      final expense = await ref
          .read(expensesRepositoryProvider)
          .create(
            propertyId: _propertyId!,
            unitId: _unitId,
            category: _category,
            amount: parseBirr(_amount.text)!,
            spentOn: _spentOn,
            description: _description.text.trim(),
            vendor: _vendor.text.trim(),
            photoPath: _photo,
            clientRef: _clientRef,
          );
      if (mounted) Navigator.of(context).pop(expense);
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

  /// No connection: keep the expense on the phone and send it later.
  Future<void> _saveOffline() async {
    final l10n = AppLocalizations.of(context);
    final locale = ref.read(localeControllerProvider).languageCode;
    final amount = parseBirr(_amount.text)!;
    final property = ref
        .read(propertiesProvider)
        .value
        ?.where((p) => p.id == _propertyId)
        .firstOrNull;
    final description = _description.text.trim();
    final vendor = _vendor.text.trim();
    await ref
        .read(outboxProvider.notifier)
        .add(
          OutboxItem(
            kind: OutboxKind.expense,
            clientRef: _clientRef,
            createdAt: DateTime.now(),
            title: [
              _category.label(l10n),
              formatBirr(amount, locale: locale),
            ].join(' · '),
            subtitle: [
              ?property?.name,
              ref.read(appDatesProvider).date(_spentOn),
            ].join(' · '),
            fields: {
              'property_id': _propertyId,
              'unit_id': ?_unitId,
              'category': _category.apiValue,
              'amount': amount,
              'spent_on': ymd(_spentOn),
              if (description.isNotEmpty) 'description': description,
              if (vendor.isNotEmpty) 'vendor': vendor,
            },
            photos: [?_photo],
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    await showSavedOfflineDialog(context, l10n.savedOfflineItemHelp);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final properties = ref.watch(propertiesProvider);
    final units = _propertyId == null
        ? const []
        : ref.watch(propertyProvider(_propertyId!)).value?.units ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addExpense)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              properties.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => ErrorView(
                  error: e,
                  onRetry: () => ref.invalidate(propertiesProvider),
                ),
                data: (items) => DropdownButtonFormField<int>(
                  key: const Key('expensePropertyDropdown'),
                  initialValue: items.any((p) => p.id == _propertyId)
                      ? _propertyId
                      : null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.expenseProperty,
                    errorText: _errors['property_id'],
                  ),
                  items: [
                    for (final p in items)
                      DropdownMenuItem(value: p.id, child: Text(p.name)),
                  ],
                  onChanged: (v) => setState(() {
                    _propertyId = v;
                    _unitId = null;
                  }),
                  validator: (v) => v == null ? l10n.required : null,
                ),
              ),
              if (units.isNotEmpty) ...[
                fieldGap,
                DropdownButtonFormField<int?>(
                  key: ValueKey('unit-$_propertyId'),
                  initialValue: _unitId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.expenseUnit,
                    errorText: _errors['unit_id'],
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.expenseWholeProperty),
                    ),
                    for (final u in units)
                      DropdownMenuItem(value: u.id, child: Text(u.label)),
                  ],
                  onChanged: (v) => setState(() => _unitId = v),
                ),
              ],
              fieldGap,
              DropdownButtonFormField<ExpenseCategory>(
                key: const Key('expenseCategoryDropdown'),
                initialValue: _category,
                decoration: InputDecoration(
                  labelText: l10n.expenseCategory,
                  errorText: _errors['category'],
                ),
                items: [
                  for (final c in ExpenseCategory.values)
                    DropdownMenuItem(
                      value: c,
                      child: Row(
                        children: [
                          Icon(c.icon, size: 20),
                          const SizedBox(width: 8),
                          Text(c.label(l10n)),
                        ],
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              fieldGap,
              TextFormField(
                key: const Key('expenseAmountField'),
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  labelText: l10n.expenseAmount,
                  errorText: _errors['amount'],
                ),
                validator: (v) =>
                    (parseBirr(v ?? '') ?? 0) < 1 ? l10n.amountInvalid : null,
              ),
              fieldGap,
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _spentOn,
                    firstDate: DateTime(2015),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _spentOn = picked);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.expenseDate,
                    errorText: _errors['spent_on'],
                    suffixIcon: const Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(ref.watch(appDatesProvider).date(_spentOn)),
                ),
              ),
              fieldGap,
              TextFormField(
                key: const Key('expenseDescriptionField'),
                controller: _description,
                decoration: InputDecoration(
                  labelText: l10n.expenseDescription,
                  hintText: l10n.expenseDescriptionHint,
                  errorText: _errors['description'],
                ),
              ),
              fieldGap,
              TextFormField(
                controller: _vendor,
                decoration: InputDecoration(
                  labelText: l10n.expenseVendorOptional,
                  errorText: _errors['vendor'],
                ),
              ),
              fieldGap,
              if (_photo != null)
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_photo!),
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _photo = null),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                )
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final path = await pickRepairPhoto(context);
                      if (path != null) setState(() => _photo = path);
                    },
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(l10n.addReceiptPhoto),
                  ),
                ),
              if (_error != null) ...[
                fieldGap,
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('saveExpense'),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
