import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/locale_controller.dart';
import '../../../core/utils/app_dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/phone_number.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/form_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_controller.dart';
import '../data/tenants_repository.dart';
import '../domain/tenant_record.dart';
import 'payment_record_badge.dart';

/// How a tenant has paid, month by month, with the landlord's private notes.
class TenantRecordScreen extends ConsumerWidget {
  const TenantRecordScreen({super.key, required this.tenantId});

  final int tenantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider).languageCode;
    final dates = ref.watch(appDatesProvider);
    final caretaker = ref.watch(isCaretakerProvider);
    final tenant = ref.watch(tenantProvider(tenantId));
    final record = ref.watch(tenantRecordProvider(tenantId));
    final scheme = Theme.of(context).colorScheme;

    Widget stat(String label, String value, {Key? key, Color? color}) =>
        Expanded(
          child: Column(
            children: [
              Text(
                value,
                key: key,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(color: color),
              ),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(tenant.value?.fullName ?? l10n.paymentRecord),
        actions: [
          IconButton(
            key: const Key('tenantMessages'),
            tooltip: l10n.messages,
            icon: const Icon(Icons.sms_outlined),
            onPressed: () => context.push('/tenants/$tenantId/messages'),
          ),
        ],
      ),
      body: record.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(tenantRecordProvider(tenantId)),
        ),
        data: (r) => RefreshIndicator(
          onRefresh: () => ref.refresh(tenantRecordProvider(tenantId).future),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (tenant.value != null)
                Text(formatEthiopianPhone(tenant.value!.phone)),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PaymentRecordBadge(record: r),
                      if (r.rating == PaymentRating.newTenant)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(l10n.ratingNewHelp),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          stat(
                            l10n.paidOnTime,
                            '${r.onTime}',
                            key: const Key('onTimeCount'),
                          ),
                          stat(l10n.paidLate, '${r.late}'),
                          stat(
                            l10n.notPaid,
                            '${r.unpaid}',
                            color: r.unpaid > 0 ? scheme.error : null,
                          ),
                        ],
                      ),
                      if (r.recent.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          l10n.lastMonths(r.recent.length),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final m in r.recent)
                              Tooltip(
                                message: [
                                  dates.period(m.period),
                                  switch (m.status) {
                                    'on_time' => l10n.paidOnTime,
                                    'late' => l10n.daysLateCount(
                                      m.daysLate ?? 0,
                                    ),
                                    _ => l10n.notPaid,
                                  },
                                ].join(' · '),
                                child: CircleAvatar(
                                  key: Key('month-${m.period}'),
                                  radius: 9,
                                  backgroundColor: switch (m.status) {
                                    'on_time' => Colors.green.shade600,
                                    'late' => Colors.orange.shade700,
                                    _ => scheme.error,
                                  },
                                ),
                              ),
                          ],
                        ),
                      ],
                      const Divider(height: 28),
                      if (r.outstanding > 0)
                        Text(
                          l10n.owesNow(
                            formatBirr(r.outstanding, locale: locale),
                          ),
                          style: TextStyle(color: scheme.error),
                        ),
                      if (r.tenantSince != null)
                        Text(l10n.tenantSince(dates.date(r.tenantSince!))),
                      Text(l10n.leasesCount(r.leases)),
                      const SizedBox(height: 8),
                      Text(
                        l10n.paymentRecordHowCounted,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              if (!caretaker) ...[
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    key: const Key('tenantNotes'),
                    leading: const Icon(Icons.sticky_note_2_outlined),
                    title: Text(l10n.privateNotes),
                    subtitle: Text(
                      (r.notes ?? '').isEmpty
                          ? l10n.privateNotesHelp
                          : r.notes!,
                    ),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => _editNotes(context, ref, r.notes),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editNotes(
    BuildContext context,
    WidgetRef ref,
    String? current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final notes = TextEditingController(text: current);
    final saved = await showFormSheet(
      context,
      FormSheet(
        title: l10n.privateNotes,
        onSave: () =>
            ref.read(tenantsRepositoryProvider).saveNotes(tenantId, notes.text),
        fieldsBuilder: (context, errors) => [
          TextFormField(
            key: const Key('notesField'),
            controller: notes,
            autofocus: true,
            minLines: 3,
            maxLines: 8,
            maxLength: 2000,
            decoration: InputDecoration(
              labelText: l10n.privateNotes,
              helperText: l10n.privateNotesShared,
              helperMaxLines: 3,
              errorText: errors['notes'],
            ),
          ),
        ],
      ),
    );
    if (saved) ref.invalidate(tenantRecordProvider(tenantId));
  }
}
