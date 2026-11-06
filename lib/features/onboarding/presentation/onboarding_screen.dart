import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/form_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_controller.dart';
import '../data/onboarding_repository.dart';

/// Home card: how far the landlord is with setting up, until it's done or hidden.
class OnboardingCard extends ConsumerWidget {
  const OnboardingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final onboarding = ref.watch(onboardingProvider).value;
    if (onboarding == null || !onboarding.showOnHome) {
      return const SizedBox.shrink();
    }
    return Card(
      key: const Key('onboardingCard'),
      color: Theme.of(context).colorScheme.primaryContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await context.push('/setup');
          ref.invalidate(onboardingProvider);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.rocket_launch_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.getStarted,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(l10n.stepsDone(onboarding.doneCount, onboarding.total)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: onboarding.total == 0
                    ? 0
                    : onboarding.doneCount / onboarding.total,
              ),
              const SizedBox(height: 8),
              Text(l10n.getStartedHelp),
            ],
          ),
        ),
      ),
    );
  }
}

/// The setup checklist: each step says what to do and opens the right screen.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final onboarding = ref.watch(onboardingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.getStarted),
        actions: [
          TextButton(
            key: const Key('hideSetup'),
            onPressed: () async {
              await ref.read(onboardingRepositoryProvider).dismiss();
              ref.invalidate(onboardingProvider);
              if (context.mounted) context.pop();
            },
            child: Text(l10n.hide),
          ),
        ],
      ),
      body: onboarding.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(onboardingProvider),
        ),
        data: (o) => RefreshIndicator(
          onRefresh: () => ref.refresh(onboardingProvider.future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                o.completed
                    ? l10n.setupComplete
                    : l10n.stepsDone(o.doneCount, o.total),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: o.total == 0 ? 0 : o.doneCount / o.total,
              ),
              const SizedBox(height: 8),
              for (final (i, step) in o.steps.indexed)
                _StepTile(
                  number: i + 1,
                  stepKey: step.key,
                  done: step.done,
                  optional: step.optional,
                  onTap: () => _open(context, ref, step.key, o),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    String key,
    Onboarding o,
  ) async {
    switch (key) {
      case 'profile':
        await _editName(context, ref);
      case 'property' || 'units' || 'lease':
        context.go('/properties');
      case 'tenant':
        context.go('/tenants');
      case 'payment':
        context.go('/rent');
      case 'tenant_page':
        if (o.firstLeaseId != null) {
          await context.push('/leases/${o.firstLeaseId}');
        }
      case 'telegram':
        await context.push('/settings');
      case 'caretaker':
        await context.push('/settings/team');
    }
    ref.invalidate(onboardingProvider);
  }

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final name = TextEditingController(
      text: ref.read(authControllerProvider).value?.name,
    );
    await showFormSheet(
      context,
      FormSheet(
        title: l10n.setupProfileTitle,
        onSave: () => ref
            .read(authControllerProvider.notifier)
            .updateProfile(name: name.text.trim()),
        fieldsBuilder: (context, errors) => [
          TextFormField(
            key: const Key('setupNameField'),
            controller: name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.yourFullName,
              helperText: l10n.yourFullNameHelp,
              errorText: errors['name'],
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.required : null,
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.number,
    required this.stepKey,
    required this.done,
    required this.optional,
    required this.onTap,
  });

  final int number;
  final String stepKey;
  final bool done;
  final bool optional;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (title, help) = switch (stepKey) {
      'profile' => (l10n.setupProfileTitle, l10n.setupProfileHelp),
      'property' => (l10n.setupPropertyTitle, l10n.setupPropertyHelp),
      'units' => (l10n.setupUnitsTitle, l10n.setupUnitsHelp),
      'tenant' => (l10n.setupTenantTitle, l10n.setupTenantHelp),
      'lease' => (l10n.setupLeaseTitle, l10n.setupLeaseHelp),
      'payment' => (l10n.setupPaymentTitle, l10n.setupPaymentHelp),
      'tenant_page' => (l10n.setupTenantPageTitle, l10n.setupTenantPageHelp),
      'telegram' => (l10n.setupTelegramTitle, l10n.setupTelegramHelp),
      'caretaker' => (l10n.setupCaretakerTitle, l10n.setupCaretakerHelp),
      _ => (stepKey, ''),
    };
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      key: Key('setupStep-$stepKey'),
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: done ? Colors.green : scheme.surfaceContainerHighest,
        foregroundColor: done ? Colors.white : scheme.onSurface,
        child: done ? const Icon(Icons.check) : Text('$number'),
      ),
      title: Text(
        optional ? '$title (${l10n.optional})' : title,
        style: done
            ? TextStyle(
                color: scheme.outline,
                decoration: TextDecoration.lineThrough,
              )
            : null,
      ),
      subtitle: Text(help),
      trailing: done ? null : const Icon(Icons.chevron_right),
      onTap: done ? null : onTap,
    );
  }
}
