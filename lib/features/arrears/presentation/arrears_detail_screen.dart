import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/locale_controller.dart';
import '../../../core/utils/app_dates.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/form_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_controller.dart';
import '../data/arrears_repository.dart';
import '../domain/arrears.dart';

/// One late lease: what is owed, the next polite step, a payment plan, and the history.
class ArrearsDetailScreen extends ConsumerWidget {
  const ArrearsDetailScreen({super.key, required this.leaseId});

  final int leaseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider).languageCode;
    final dates = ref.watch(appDatesProvider);
    final caretaker = ref.watch(isCaretakerProvider);
    final arrears = ref.watch(arrearsProvider(leaseId));
    String birr(int s) => formatBirr(s, locale: locale);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.arrears),
        actions: [
          IconButton(
            tooltip: l10n.leaseTitle,
            icon: const Icon(Icons.description_outlined),
            onPressed: () => context.push('/leases/$leaseId'),
          ),
        ],
      ),
      body: arrears.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(arrearsProvider(leaseId)),
        ),
        data: (a) => RefreshIndicator(
          onRefresh: () => ref.refresh(arrearsProvider(leaseId).future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                [?a.tenantName, ?a.unitLabel].join(' · '),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        birr(a.owed),
                        key: const Key('arrearsOwed'),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        a.owed == 0
                            ? l10n.arrearsCleared
                            : [
                                l10n.daysOverdue(a.daysOverdue),
                                l10n.monthsBehind(a.monthsBehind),
                              ].join(' · '),
                      ),
                    ],
                  ),
                ),
              ),
              if (a.owed > 0 && a.plan == null) ...[
                const SizedBox(height: 8),
                if (a.suggested != null)
                  Card(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    child: ListTile(
                      key: const Key('suggestedStep'),
                      leading: const Icon(Icons.tips_and_updates_outlined),
                      title: Text(l10n.nextStep(a.suggested!.label(l10n))),
                      subtitle: Text(_stepHelp(l10n, a.suggested!)),
                    ),
                  ),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    FilledButton.tonalIcon(
                      key: const Key('sendReminder'),
                      onPressed: () =>
                          _send(context, ref, ArrearsStep.reminder),
                      icon: const Icon(Icons.sms_outlined),
                      label: Text(l10n.arrearsReminder),
                    ),
                    FilledButton.tonalIcon(
                      key: const Key('sendNotice'),
                      onPressed: () => _send(context, ref, ArrearsStep.notice),
                      icon: const Icon(Icons.report_outlined),
                      label: Text(l10n.arrearsNotice),
                    ),
                    if (!caretaker) ...[
                      OutlinedButton.icon(
                        key: const Key('demandLetter'),
                        onPressed: () => _demandLetter(context, ref),
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: Text(l10n.arrearsDemandLetter),
                      ),
                      OutlinedButton.icon(
                        key: const Key('createPlan'),
                        onPressed: () => _createPlan(context, ref, a),
                        icon: const Icon(Icons.event_repeat),
                        label: Text(l10n.arrearsPlan),
                      ),
                    ],
                  ],
                ),
              ],
              if (a.plan != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.planProgress(
                          birr(a.plan!.paid),
                          birr(a.plan!.total),
                        ),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (!caretaker)
                      TextButton(
                        key: const Key('cancelPlan'),
                        onPressed: () => _cancelPlan(context, ref, a.plan!),
                        child: Text(l10n.cancel),
                      ),
                  ],
                ),
                LinearProgressIndicator(
                  value: a.plan!.total == 0 ? 0 : a.plan!.paid / a.plan!.total,
                ),
                for (final i in a.plan!.instalments)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      i.covered
                          ? Icons.check_circle
                          : (i.overdue ? Icons.error_outline : Icons.schedule),
                      color: i.covered
                          ? Colors.green
                          : (i.overdue
                                ? Theme.of(context).colorScheme.error
                                : null),
                    ),
                    title: Text(dates.date(i.dueDate)),
                    trailing: Text(birr(i.amount)),
                  ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.arrearsHistory,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton.icon(
                    key: const Key('addNote'),
                    onPressed: () => _addNote(context, ref),
                    icon: const Icon(Icons.note_add_outlined),
                    label: Text(l10n.arrearsNote),
                  ),
                ],
              ),
              if (a.actions.isEmpty) Text(l10n.arrearsNoHistory),
              for (final e in a.actions)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(e.kind.label(l10n)),
                  subtitle: Text(
                    [
                      dates.date(e.createdAt),
                      birr(e.amountOwed),
                      if (e.by != null) e.by!,
                      if ((e.note ?? '').isNotEmpty) e.note!,
                    ].join(' · '),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _stepHelp(AppLocalizations l10n, ArrearsStep step) => switch (step) {
    ArrearsStep.reminder => l10n.arrearsReminderHelp,
    ArrearsStep.notice => l10n.arrearsNoticeHelp,
    ArrearsStep.demandLetter => l10n.arrearsDemandLetterHelp,
    _ => '',
  };

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action, {
    String? done,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      ref.invalidate(arrearsProvider(leaseId));
      ref.invalidate(arrearsListProvider);
      if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
    } on ApiException catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(friendlyError(context, e))),
        );
      }
    }
  }

  Future<void> _send(
    BuildContext context,
    WidgetRef ref,
    ArrearsStep kind,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(kind.label(l10n)),
        content: Text(
          kind == ArrearsStep.reminder
              ? l10n.arrearsReminderHelp
              : l10n.arrearsNoticeHelp,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('confirmSend'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.send),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await _run(
      context,
      ref,
      () => ref.read(arrearsRepositoryProvider).act(leaseId, kind),
      done: l10n.arrearsSent,
    );
  }

  Future<void> _demandLetter(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    await _run(context, ref, () async {
      final path = await ref
          .read(arrearsRepositoryProvider)
          .downloadDemandLetter(leaseId);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: 'application/pdf')],
          text: l10n.arrearsDemandLetter,
        ),
      );
    });
  }

  Future<void> _addNote(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final note = TextEditingController();
    final saved = await showFormSheet(
      context,
      FormSheet(
        title: l10n.arrearsNote,
        onSave: () => ref
            .read(arrearsRepositoryProvider)
            .act(leaseId, ArrearsStep.note, note: note.text.trim()),
        fieldsBuilder: (context, errors) => [
          TextFormField(
            key: const Key('arrearsNoteField'),
            controller: note,
            autofocus: true,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: l10n.arrearsNoteHint,
              errorText: errors['note'],
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.required : null,
          ),
        ],
      ),
    );
    if (saved) {
      ref.invalidate(arrearsProvider(leaseId));
    }
  }

  Future<void> _createPlan(
    BuildContext context,
    WidgetRef ref,
    Arrears a,
  ) async {
    final l10n = AppLocalizations.of(context);
    final locale = ref.read(localeControllerProvider).languageCode;
    final dates = ref.read(appDatesProvider);
    var count = 3;
    var first = dateOnly(DateTime.now()).add(const Duration(days: 7));
    var notify = true;

    final saved = await showFormSheet(
      context,
      FormSheet(
        title: l10n.arrearsPlan,
        saveLabel: l10n.agreePlan,
        onSave: () => ref
            .read(arrearsRepositoryProvider)
            .createPlan(
              leaseId,
              splitPlan(a.owed, count, first),
              notifyTenant: notify,
            ),
        fieldsBuilder: (context, errors) => [
          StatefulBuilder(
            builder: (context, setState) {
              final parts = splitPlan(a.owed, count, first);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.planIntro(formatBirr(a.owed, locale: locale))),
                  fieldGap,
                  DropdownButtonFormField<int>(
                    key: const Key('planCount'),
                    initialValue: count,
                    decoration: InputDecoration(labelText: l10n.instalments),
                    items: [
                      for (var n = 1; n <= 6; n++)
                        DropdownMenuItem(value: n, child: Text('$n')),
                    ],
                    onChanged: (v) => setState(() => count = v ?? count),
                  ),
                  fieldGap,
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: first,
                        firstDate: dateOnly(DateTime.now()),
                        lastDate: DateTime.now().add(const Duration(days: 120)),
                      );
                      if (picked != null) setState(() => first = picked);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: l10n.firstInstalment,
                        errorText: errors['instalments'],
                        suffixIcon: const Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(dates.date(first)),
                    ),
                  ),
                  fieldGap,
                  for (final p in parts)
                    Row(
                      children: [
                        Expanded(child: Text(dates.date(p.dueDate))),
                        Text(formatBirr(p.amount, locale: locale)),
                      ],
                    ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.notifyTenantSms),
                    value: notify,
                    onChanged: (v) => setState(() => notify = v),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
    if (saved) {
      ref.invalidate(arrearsProvider(leaseId));
      ref.invalidate(arrearsListProvider);
    }
  }

  Future<void> _cancelPlan(
    BuildContext context,
    WidgetRef ref,
    PaymentPlanSummary plan,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.cancelPlanConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.no),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.cancelPlan),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await _run(
      context,
      ref,
      () => ref.read(arrearsRepositoryProvider).cancelPlan(plan.id),
    );
  }
}

/// Splits [total] into [count] monthly instalments from [first]; the last takes the remainder.
List<({DateTime dueDate, int amount})> splitPlan(
  int total,
  int count,
  DateTime first,
) {
  final each = total ~/ count;
  return [
    for (var i = 0; i < count; i++)
      (
        dueDate: DateTime(first.year, first.month + i, first.day),
        amount: i == count - 1 ? total - each * (count - 1) : each,
      ),
  ];
}
