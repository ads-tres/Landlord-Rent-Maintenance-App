import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/locale_controller.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/form_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_controller.dart';
import '../data/online_rent_repository.dart';

/// Online rent setup: the bank account Chapa pays out to, and the on/off switch.
class OnlineRentScreen extends ConsumerStatefulWidget {
  const OnlineRentScreen({super.key});

  @override
  ConsumerState<OnlineRentScreen> createState() => _OnlineRentScreenState();
}

class _OnlineRentScreenState extends ConsumerState<OnlineRentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _number = TextEditingController();
  Bank? _bank;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(onlineRentRepositoryProvider)
          .savePayoutAccount(
            bankCode: _bank!.id,
            bankName: _bank!.name,
            accountName: _name.text.trim(),
            accountNumber: _number.text.trim(),
          );
      _number.clear();
      ref.invalidate(payoutAccountProvider);
      await ref.read(authControllerProvider.notifier).refreshUser();
    } on ApiException catch (e) {
      ref.invalidate(payoutAccountProvider);
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

  Future<void> _toggle(bool on) async {
    setState(() => _busy = true);
    try {
      await ref.read(onlineRentRepositoryProvider).setEnabled(on);
      await ref.read(authControllerProvider.notifier).refreshUser();
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
    final user = ref.watch(authControllerProvider).value;
    final account = ref.watch(payoutAccountProvider);
    final banks = ref.watch(banksProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.onlineRent)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.onlineRentHelp),
          const SizedBox(height: 8),
          Text(
            l10n.onlineRentFee(formatBirr(2500, locale: locale)),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          account.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => ErrorView(
              error: e,
              onRetry: () => ref.invalidate(payoutAccountProvider),
            ),
            data: (a) => a == null
                ? const SizedBox.shrink()
                : Card(
                    child: ListTile(
                      leading: Icon(
                        a.isActive
                            ? Icons.account_balance
                            : Icons.error_outline,
                        color: a.isActive ? scheme.primary : scheme.error,
                      ),
                      title: Text(
                        '${a.bankName ?? a.bankCode} · ${a.accountNumber}',
                      ),
                      subtitle: Text(
                        [
                          a.accountName,
                          switch (a.status) {
                            'active' => l10n.accountActive,
                            'failed' => l10n.accountFailed,
                            _ => l10n.accountPending,
                          },
                        ].join(' · '),
                      ),
                    ),
                  ),
          ),
          SwitchListTile(
            key: const Key('onlineRentSwitch'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.acceptOnlineRent),
            subtitle: Text(
              (user?.onlineRentEnabled ?? false)
                  ? l10n.onlineRentOn
                  : l10n.onlineRentOff,
            ),
            value: user?.onlineRentEnabled ?? false,
            onChanged: _busy || !(account.value?.isActive ?? false)
                ? null
                : _toggle,
          ),
          const Divider(height: 32),
          Text(
            l10n.payoutAccount,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Form(
            key: _formKey,
            child: Column(
              children: [
                fieldGap,
                banks.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => ErrorView(
                    error: e,
                    onRetry: () => ref.invalidate(banksProvider),
                  ),
                  data: (items) => DropdownButtonFormField<Bank>(
                    key: const Key('bankDropdown'),
                    initialValue: _bank,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l10n.bank),
                    items: [
                      for (final b in items)
                        DropdownMenuItem(
                          value: b,
                          child: Text(b.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (b) => setState(() => _bank = b),
                    validator: (v) => v == null ? l10n.required : null,
                  ),
                ),
                fieldGap,
                TextFormField(
                  key: const Key('accountNameField'),
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: l10n.accountName),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l10n.required : null,
                ),
                fieldGap,
                TextFormField(
                  key: const Key('accountNumberField'),
                  controller: _number,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(labelText: l10n.accountNumber),
                  validator: (v) =>
                      (v == null || v.length < 6) ? l10n.required : null,
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_error!, style: TextStyle(color: scheme.error)),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('saveAccountButton'),
                    onPressed: _busy ? null : _save,
                    child: Text(l10n.saveAccount),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
