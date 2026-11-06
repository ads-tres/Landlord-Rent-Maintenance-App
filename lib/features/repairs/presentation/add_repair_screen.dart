import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/offline/outbox.dart';
import '../../home/presentation/sync_screen.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/form_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../payments/data/payments_repository.dart';
import '../data/repairs_repository.dart';
import '../domain/repair.dart';
import 'repair_widgets.dart';

/// The landlord records a repair (for example one the tenant reported by phone).
class AddRepairScreen extends ConsumerStatefulWidget {
  const AddRepairScreen({super.key, this.unitId});

  final int? unitId;

  @override
  ConsumerState<AddRepairScreen> createState() => _AddRepairScreenState();
}

class _AddRepairScreenState extends ConsumerState<AddRepairScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  late int? _unitId = widget.unitId;
  RepairCategory _category = RepairCategory.other;
  final List<String> _photos = [];
  final String _clientRef = newClientRef();
  bool _saving = false;
  Map<String, String> _errors = const {};
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
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
      final repair = await ref
          .read(repairsRepositoryProvider)
          .create(
            unitId: _unitId!,
            title: _title.text.trim(),
            category: _category,
            description: _description.text.trim(),
            photoPaths: _photos,
            clientRef: _clientRef,
          );
      ref.invalidate(dashboardProvider);
      if (mounted) Navigator.of(context).pop(repair);
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

  /// No connection: keep the repair on the phone and send it later.
  Future<void> _saveOffline() async {
    final l10n = AppLocalizations.of(context);
    final unit = ref
        .read(unitOptionsProvider)
        .value
        ?.where((u) => u.id == _unitId)
        .firstOrNull;
    final title = _title.text.trim();
    final description = _description.text.trim();
    await ref
        .read(outboxProvider.notifier)
        .add(
          OutboxItem(
            kind: OutboxKind.repair,
            clientRef: _clientRef,
            createdAt: DateTime.now(),
            title: title,
            subtitle: unit == null
                ? null
                : [unit.label, unit.propertyName].join(' · '),
            fields: {
              'unit_id': _unitId,
              'title': title,
              'category': _category.apiValue,
              if (description.isNotEmpty) 'description': description,
            },
            photos: [..._photos],
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
    final units = ref.watch(unitOptionsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addRepair)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              units.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => ErrorView(
                  error: e,
                  onRetry: () => ref.invalidate(unitOptionsProvider),
                ),
                data: (items) => DropdownButtonFormField<int>(
                  key: const Key('unitDropdown'),
                  initialValue: items.any((u) => u.id == _unitId)
                      ? _unitId
                      : null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.repairUnit,
                    errorText: _errors['unit_id'],
                  ),
                  items: [
                    for (final u in items)
                      DropdownMenuItem(
                        value: u.id,
                        child: Text(
                          [
                            u.label,
                            u.propertyName,
                            if (u.tenantName != null) u.tenantName!,
                          ].join(' · '),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _unitId = v),
                  validator: (v) => v == null ? l10n.required : null,
                ),
              ),
              fieldGap,
              DropdownButtonFormField<RepairCategory>(
                initialValue: _category,
                decoration: InputDecoration(labelText: l10n.repairCategory),
                items: [
                  for (final c in RepairCategory.values)
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
                onChanged: (v) => setState(() {
                  _category = v ?? _category;
                  if (_title.text.isEmpty) _title.text = _category.label(l10n);
                }),
              ),
              fieldGap,
              TextFormField(
                key: const Key('repairTitleField'),
                controller: _title,
                decoration: InputDecoration(
                  labelText: l10n.repairTitle,
                  errorText: _errors['title'],
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.required : null,
              ),
              fieldGap,
              TextFormField(
                controller: _description,
                minLines: 2,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: l10n.repairDescription,
                  errorText: _errors['description'],
                ),
              ),
              fieldGap,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in _photos)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(p),
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton.filledTonal(
                            iconSize: 16,
                            visualDensity: VisualDensity.compact,
                            onPressed: () => setState(() => _photos.remove(p)),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                      ],
                    ),
                  if (_photos.length < 4)
                    OutlinedButton.icon(
                      onPressed: () async {
                        final path = await pickRepairPhoto(context);
                        if (path != null) setState(() => _photos.add(path));
                      },
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: Text(l10n.addPhoto),
                    ),
                ],
              ),
              if (_errors.keys.any((k) => k.startsWith('photos')))
                Text(
                  _errors.entries
                      .firstWhere((e) => e.key.startsWith('photos'))
                      .value,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('saveRepairButton'),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(),
                      )
                    : Text(l10n.addRepair),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
