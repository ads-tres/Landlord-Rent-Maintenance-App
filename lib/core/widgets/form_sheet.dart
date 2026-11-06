import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../api/api_exception.dart';
import 'async_views.dart';

/// Bottom sheet with a form and a save button that shows server validation errors.
class FormSheet extends StatefulWidget {
  const FormSheet({
    super.key,
    required this.title,
    required this.fieldsBuilder,
    required this.onSave,
    this.saveLabel,
  });

  final String title;

  /// Text on the save button; "Save" when null.
  final String? saveLabel;

  /// Builds the form fields. `errors` holds server validation messages by field name.
  final List<Widget> Function(BuildContext context, Map<String, String> errors)
  fieldsBuilder;

  final Future<void> Function() onSave;

  @override
  State<FormSheet> createState() => _FormSheetState();
}

class _FormSheetState extends State<FormSheet> {
  final _formKey = GlobalKey<FormState>();
  Map<String, String> _errors = const {};
  String? _error;
  bool _saving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _errors = const {};
      _error = null;
    });
    try {
      await widget.onSave();
      if (mounted) Navigator.of(context).pop(true);
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              ...widget.fieldsBuilder(context, _errors),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(),
                      )
                    : Text(widget.saveLabel ?? l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> showFormSheet(BuildContext context, FormSheet sheet) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => sheet,
  );
  return saved ?? false;
}

const fieldGap = SizedBox(height: 12);
