import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/locale_controller.dart';
import '../../../core/utils/app_dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_views.dart';
import '../../../l10n/app_localizations.dart';
import '../data/reminders_repository.dart';
import '../domain/bulk_reminder.dart';

/// Opens the "remind everyone who owes" sheet for [month].
Future<void> showBulkReminderSheet(BuildContext context, DateTime month) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BulkReminderSheet(month: month),
    );

/// Preview of who will be texted for a month, with a sample message; untick to leave someone out.
class BulkReminderSheet extends ConsumerStatefulWidget {
  const BulkReminderSheet({super.key, required this.month});

  final DateTime month;

  @override
  ConsumerState<BulkReminderSheet> createState() => _BulkReminderSheetState();
}

class _BulkReminderSheetState extends ConsumerState<BulkReminderSheet> {
  late final String _period =
      '${widget.month.year}-${widget.month.month.toString().padLeft(2, '0')}';
  late Future<ReminderPreview> _preview = _load();
  Set<int>? _selected;
  bool _sending = false;

  Future<ReminderPreview> _load() async {
    final p = await ref.read(remindersRepositoryProvider).preview(_period);
    _selected = {
      for (final i in p.items)
        if (i.skip == null) i.leaseId,
    };
    return p;
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final ids = _selected!.toList();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.sendRemindersConfirm(ids.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('confirmSendReminders'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.send),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final sent = await ref
          .read(remindersRepositoryProvider)
          .send(_period, ids);
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.remindersSent(sent))));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      messenger.showSnackBar(
        SnackBar(content: Text(friendlyError(context, e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider).languageCode;
    final dates = ref.watch(appDatesProvider);
    String birr(int v) => formatBirr(v, locale: locale);

    String skipLabel(String skip) => switch (skip) {
      'opted_out' => l10n.skipOptedOut,
      'reminded_today' => l10n.skipRemindedToday,
      _ => l10n.skipNoTenant,
    };

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, scroll) => FutureBuilder<ReminderPreview>(
        future: _preview,
        builder: (context, snap) {
          if (snap.hasError) {
            return ErrorView(
              error: snap.error!,
              onRetry: () => setState(() => _preview = _load()),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final p = snap.data!;
          final selected = _selected!;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  controller: scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Text(
                      l10n.remindWhoOwes(dates.period(p.period)),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.items.isEmpty
                          ? l10n.nobodyOwes
                          : l10n.owedByCount(birr(p.totalOwed), p.items.length),
                    ),
                    if (p.sample != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        l10n.sampleMessage,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(p.sample!, key: const Key('sampleSms')),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    for (final i in p.items)
                      CheckboxListTile(
                        key: Key('remind-${i.leaseId}'),
                        contentPadding: EdgeInsets.zero,
                        value: i.skip == null && selected.contains(i.leaseId),
                        onChanged: i.skip != null
                            ? null
                            : (v) => setState(
                                () => v == true
                                    ? selected.add(i.leaseId)
                                    : selected.remove(i.leaseId),
                              ),
                        title: Text([?i.tenant, i.unit].join(' · ')),
                        subtitle: Text(
                          [
                            birr(i.owed),
                            if (i.skip != null) skipLabel(i.skip!),
                          ].join(' · '),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.remindersQuietHours,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('sendReminders'),
                      onPressed: selected.isEmpty || _sending ? null : _send,
                      icon: const Icon(Icons.send),
                      label: Text(l10n.sendRemindersCount(selected.length)),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
