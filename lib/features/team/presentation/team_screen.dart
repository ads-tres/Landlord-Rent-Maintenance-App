import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/utils/phone_number.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/form_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../data/team_repository.dart';

/// The landlord's caretakers: they log payments and handle repairs, but can't
/// see reports or change money settings.
class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final team = ref.watch(teamProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.team)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('inviteCaretaker'),
        onPressed: () => _invite(context, ref),
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(l10n.addCaretaker),
      ),
      body: team.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            ErrorView(error: e, onRetry: () => ref.invalidate(teamProvider)),
        data: (members) => ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.caretakerCan),
            ),
            if (members.isEmpty)
              EmptyView(message: l10n.teamEmpty, icon: Icons.group_outlined),
            for (final m in members)
              ListTile(
                key: Key('member-${m.id}'),
                leading: const Icon(Icons.badge_outlined),
                title: Text(m.name ?? formatEthiopianPhone(m.phone)),
                subtitle: Text(
                  [
                    formatEthiopianPhone(m.phone),
                    m.joined ? l10n.caretakerJoined : l10n.caretakerInvited,
                  ].join(' · '),
                ),
                trailing: IconButton(
                  key: Key('removeMember-${m.id}'),
                  tooltip: l10n.removeCaretaker,
                  icon: const Icon(Icons.person_remove_outlined),
                  onPressed: () => _remove(context, ref, m),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _invite(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final name = TextEditingController();
    final phone = TextEditingController();

    final saved = await showFormSheet(
      context,
      FormSheet(
        title: l10n.addCaretaker,
        saveLabel: l10n.sendInvite,
        onSave: () => ref
            .read(teamRepositoryProvider)
            .invite(name: name.text.trim(), phone: phone.text.trim()),
        fieldsBuilder: (context, errors) => [
          TextFormField(
            key: const Key('caretakerNameField'),
            controller: name,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.caretakerName,
              errorText: errors['name'],
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.required : null,
          ),
          fieldGap,
          TextFormField(
            key: const Key('caretakerPhoneField'),
            controller: phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
            ],
            decoration: InputDecoration(
              labelText: l10n.phoneLabel,
              hintText: '09XX XXX XXX',
              errorText: errors['phone'],
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.required : null,
          ),
          fieldGap,
          Text(
            l10n.inviteHelp,
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
    );
    if (saved) ref.invalidate(teamProvider);
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    TeamMember member,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.removeCaretakerConfirm(member.name ?? member.phone)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('confirmRemoveMember'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.removeCaretaker),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(teamRepositoryProvider).remove(member.id);
      ref.invalidate(teamProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(friendlyError(context, e))),
        );
      }
    }
  }
}
