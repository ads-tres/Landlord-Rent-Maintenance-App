import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/utils/phone_number.dart';
import '../../../core/widgets/async_views.dart';
import '../../../l10n/app_localizations.dart';
import '../application/auth_controller.dart';

class CodeScreen extends ConsumerStatefulWidget {
  const CodeScreen({super.key, required this.phone});

  final String phone;

  @override
  ConsumerState<CodeScreen> createState() => _CodeScreenState();
}

class _CodeScreenState extends ConsumerState<CodeScreen> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final l10n = AppLocalizations.of(context);
    if (_code.text.length != 6) {
      setState(() => _error = l10n.codeInvalid);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // On success the router redirects to the home screen.
      await ref
          .read(authControllerProvider.notifier)
          .verify(widget.phone, _code.text);
    } on ApiException catch (e) {
      if (mounted) {
        setState(
          () => _error = e.fieldErrors['code'] ?? friendlyError(context, e),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    try {
      await ref.read(authControllerProvider.notifier).requestCode(widget.phone);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = friendlyError(context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              l10n.codeTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(l10n.codeSentTo(formatEthiopianPhone(widget.phone))),
            const SizedBox(height: 24),
            TextField(
              key: const Key('codeField'),
              controller: _code,
              autofocus: true,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(letterSpacing: 8),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: l10n.codeLabel,
                errorText: _error,
              ),
              onChanged: (v) {
                if (v.length == 6 && !_busy) _verify();
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _verify,
              child: _busy
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(),
                    )
                  : Text(l10n.verify),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.changeNumber),
                ),
                TextButton(
                  onPressed: _busy ? null : _resend,
                  child: Text(l10n.resendCode),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
