import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/utils/app_dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/phone_number.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/form_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../payments/data/payments_repository.dart';
import '../../expenses/data/expenses_repository.dart';
import '../data/repairs_repository.dart';
import '../domain/repair.dart';
import 'repair_widgets.dart';

class RepairDetailScreen extends ConsumerWidget {
  const RepairDetailScreen({super.key, required this.repairId});

  final int repairId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dates = ref.watch(appDatesProvider);
    final repair = ref.watch(repairProvider(repairId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navRepairs)),
      body: repair.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(repairProvider(repairId)),
        ),
        data: (r) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                CircleAvatar(child: Icon(r.category.icon)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    r.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                RepairStatusChip(status: r.status),
              ],
            ),
            const SizedBox(height: 8),
            Text([r.unitLabel, r.propertyName].whereType<String>().join(' · ')),
            if (r.tenantName != null)
              Text(
                [
                  r.tenantName!,
                  if (r.tenantPhone != null)
                    formatEthiopianPhone(r.tenantPhone!),
                ].join(' · '),
              ),
            Text(
              [
                l10n.repairOpenedOn(dates.date(r.openedAt)),
                if (r.fromTenant) l10n.repairFromTenant,
                if (r.closedAt != null)
                  l10n.repairClosedOn(dates.date(r.closedAt!)),
              ].join(' · '),
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
            if ((r.description ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(r.description!),
            ],
            if (r.cost != null && r.cost! > 0)
              Card(
                child: ListTile(
                  key: const Key('repairCost'),
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text(
                    formatBirr(
                      r.cost!,
                      locale: Localizations.localeOf(context).languageCode,
                    ),
                  ),
                  subtitle: Text(l10n.repairCostRecorded),
                ),
              ),
            if (r.handledByName != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.handledBy(r.handledByName!),
                  key: const Key('handledBy'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            if ((r.resolutionNote ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.notes),
                  title: Text(r.resolutionNote!),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.photos,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addPhoto(context, ref, r),
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(l10n.addPhoto),
                ),
              ],
            ),
            if (r.photos.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: r.photos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (_) => Dialog(
                        child: InteractiveViewer(
                          child: AuthImage(
                            url: r.photos[i].url,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 120,
                        child: AuthImage(url: r.photos[i].url),
                      ),
                    ),
                  ),
                ),
              ),
            if (r.voiceNotes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l10n.voiceNotes,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final (i, v) in r.voiceNotes.indexed)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.play_circle_outline),
                  title: Text(l10n.voiceNote(i + 1)),
                  // Signed link valid for 30 minutes; opens in the phone's audio player.
                  onTap: () => launchUrl(
                    Uri.parse(v.url),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
            ],
            const SizedBox(height: 24),
            ..._actions(context, ref, r),
          ],
        ),
      ),
    );
  }

  List<Widget> _actions(BuildContext context, WidgetRef ref, Repair r) {
    final l10n = AppLocalizations.of(context);
    return switch (r.status) {
      RepairStatus.open => [
        FilledButton.icon(
          key: const Key('startRepair'),
          onPressed: () =>
              _changeStatus(context, ref, r, RepairStatus.inProgress),
          icon: const Icon(Icons.construction),
          label: Text(l10n.startRepair),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => _changeStatus(context, ref, r, RepairStatus.done),
          child: Text(l10n.finishRepair),
        ),
      ],
      RepairStatus.inProgress => [
        FilledButton.icon(
          key: const Key('finishRepair'),
          onPressed: () => _changeStatus(context, ref, r, RepairStatus.done),
          icon: const Icon(Icons.check),
          label: Text(l10n.finishRepair),
        ),
      ],
      RepairStatus.done => [
        OutlinedButton(
          onPressed: () =>
              _changeStatus(context, ref, r, RepairStatus.open, askNote: false),
          child: Text(l10n.reopenRepair),
        ),
      ],
    };
  }

  Future<void> _changeStatus(
    BuildContext context,
    WidgetRef ref,
    Repair r,
    RepairStatus status, {
    bool askNote = true,
  }) async {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(repairsRepositoryProvider);
    final note = TextEditingController();
    final cost = TextEditingController(
      text: r.cost == null ? '' : santimToInput(r.cost!),
    );
    final done = status == RepairStatus.done;
    var notify = r.tenantName != null;

    final saved = !askNote
        ? await repo
              .updateStatus(r.id, status, notifyTenant: false)
              .then((_) => true, onError: (_) => false)
        : await showFormSheet(
            context,
            FormSheet(
              title: status == RepairStatus.done
                  ? l10n.finishRepair
                  : l10n.startRepair,
              onSave: () => repo.updateStatus(
                r.id,
                status,
                note: note.text.trim(),
                notifyTenant: notify,
                cost: done ? parseBirr(cost.text) : null,
              ),
              fieldsBuilder: (context, errors) => [
                TextFormField(
                  key: const Key('repairNoteField'),
                  controller: note,
                  decoration: InputDecoration(
                    labelText: l10n.repairNote,
                    hintText: l10n.repairNoteHint,
                    errorText: errors['note'],
                  ),
                ),
                if (done) ...[
                  fieldGap,
                  TextFormField(
                    key: const Key('repairCostField'),
                    controller: cost,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.repairCost,
                      helperText: l10n.repairCostHelp,
                      errorText: errors['cost'],
                    ),
                  ),
                ],
                if (r.tenantName != null)
                  StatefulBuilder(
                    builder: (context, setState) => SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.notifyTenantSms),
                      value: notify,
                      onChanged: (v) => setState(() => notify = v),
                    ),
                  ),
              ],
            ),
          );

    if (saved) {
      ref.invalidate(repairProvider(repairId));
      ref.invalidate(repairsProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(expensesProvider);
    }
  }

  Future<void> _addPhoto(BuildContext context, WidgetRef ref, Repair r) async {
    final path = await pickRepairPhoto(context);
    if (path == null) return;
    try {
      await ref.read(repairsRepositoryProvider).addPhoto(r.id, path);
      ref.invalidate(repairProvider(repairId));
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(context, e))));
      }
    }
  }
}
