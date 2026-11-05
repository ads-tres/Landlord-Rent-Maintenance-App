import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/locale_controller.dart';
import '../../../core/utils/phone_number.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/form_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../data/tenants_repository.dart';

/// Adds a tenant. The lease part of the guided form arrives with the leases block.
class AddTenantScreen extends ConsumerStatefulWidget {
  const AddTenantScreen({super.key});

  @override
  ConsumerState<AddTenantScreen> createState() => _AddTenantScreenState();
}

class _AddTenantScreenState extends ConsumerState<AddTenantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _idNumber = TextEditingController();
  final _address = TextEditingController();
  bool _noticeShown = false;
  bool _noticeMissing = false;
  bool _saving = false;
  Map<String, String> _errors = const {};
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _phone, _idNumber, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    setState(() => _noticeMissing = !_noticeShown);
    if (!valid || !_noticeShown) return;

    setState(() {
      _saving = true;
      _errors = const {};
      _error = null;
    });
    try {
      final tenant = await ref
          .read(tenantsRepositoryProvider)
          .create(
            fullName: _name.text.trim(),
            phone: normalizeEthiopianPhone(_phone.text)!,
            idNumber: _idNumber.text.trim(),
            address: _address.text.trim(),
            privacyNoticeShown: _noticeShown,
            noticeLocale: ref.read(localeControllerProvider).languageCode,
          );
      if (mounted) Navigator.of(context).pop(tenant);
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addTenant)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.fullName,
                  errorText: _errors['full_name'],
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.required : null,
              ),
              fieldGap,
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+ \-]')),
                ],
                decoration: InputDecoration(
                  labelText: l10n.phoneLabel,
                  hintText: l10n.phoneHint,
                  errorText: _errors['phone'],
                ),
                validator: (v) => normalizeEthiopianPhone(v ?? '') == null
                    ? l10n.phoneInvalid
                    : null,
              ),
              fieldGap,
              TextFormField(
                controller: _idNumber,
                decoration: InputDecoration(
                  labelText: l10n.idNumber,
                  helperText: l10n.idNumberHelp,
                  errorText: _errors['id_number'],
                ),
              ),
              fieldGap,
              TextFormField(
                controller: _address,
                decoration: InputDecoration(
                  labelText: l10n.address,
                  errorText: _errors['address'],
                ),
              ),
              const SizedBox(height: 20),
              Card(
                color: scheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.privacyNoticeTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.privacyNoticeBody),
                      CheckboxListTile(
                        key: const Key('privacyNoticeCheckbox'),
                        contentPadding: EdgeInsets.zero,
                        value: _noticeShown,
                        onChanged: (v) => setState(() {
                          _noticeShown = v ?? false;
                          if (_noticeShown) _noticeMissing = false;
                        }),
                        title: Text(l10n.privacyNoticeConfirm),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      if (_noticeMissing ||
                          _errors['privacy_notice_shown'] != null)
                        Text(
                          _errors['privacy_notice_shown'] ??
                              l10n.privacyNoticeRequired,
                          style: TextStyle(color: scheme.error),
                        ),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: scheme.error)),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(),
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
