import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/locale_controller.dart';
import '../../../core/utils/phone_number.dart';
import '../../../core/widgets/async_views.dart';
import '../../../l10n/app_localizations.dart';
import '../application/auth_controller.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  bool _sending = false;
  String? _serverError;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _serverError = null);
    if (!_formKey.currentState!.validate()) return;

    final phone = normalizeEthiopianPhone(_phone.text)!;
    setState(() => _sending = true);
    try {
      await ref.read(authControllerProvider.notifier).requestCode(phone);
      if (mounted) context.push('/login/code', extra: phone);
    } on ApiException catch (e) {
      setState(
        () =>
            _serverError = e.fieldErrors['phone'] ?? friendlyError(context, e),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () => ref
                .read(localeControllerProvider.notifier)
                .set(Locale(locale.languageCode == 'am' ? 'en' : 'am')),
            child: Text(locale.languageCode == 'am' ? 'English' : 'አማርኛ'),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                l10n.appName,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.loginTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(l10n.loginSubtitle),
              const SizedBox(height: 24),
              TextFormField(
                key: const Key('phoneField'),
                controller: _phone,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+ \-]')),
                ],
                decoration: InputDecoration(
                  labelText: l10n.phoneLabel,
                  hintText: l10n.phoneHint,
                  prefixIcon: const Icon(Icons.phone),
                  errorText: _serverError,
                ),
                validator: (v) => normalizeEthiopianPhone(v ?? '') == null
                    ? l10n.phoneInvalid
                    : null,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('sendCodeButton'),
                onPressed: _sending ? null : _submit,
                child: _sending
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(),
                      )
                    : Text(l10n.sendCode),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
