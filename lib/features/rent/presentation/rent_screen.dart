import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/locale_controller.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../leases/data/leases_repository.dart';
import '../../leases/domain/charge.dart';
import '../../leases/presentation/status_chips.dart';

/// Which month the rent list shows (first day of the month).
class RentMonth extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void previous() => state = DateTime(state.year, state.month - 1);
  void next() => state = DateTime(state.year, state.month + 1);
}

final rentMonthProvider = NotifierProvider<RentMonth, DateTime>(RentMonth.new);

/// null = all; otherwise one of unpaid, late, partial, paid.
class RentFilter extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) => state = value;
}

final rentFilterProvider = NotifierProvider<RentFilter, String?>(
  RentFilter.new,
);

/// All charges for the selected month; filtering happens on the device so totals stay complete.
final monthChargesProvider = FutureProvider.autoDispose<List<Charge>>((ref) {
  final month = ref.watch(rentMonthProvider);
  return ref.watch(leasesRepositoryProvider).charges(period: periodOf(month));
});

bool matchesFilter(Charge c, String? filter) => switch (filter) {
  null => true,
  'unpaid' => c.status != ChargeStatus.paid,
  _ => c.status.name == filter,
};

class RentScreen extends ConsumerWidget {
  const RentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider).languageCode;
    final month = ref.watch(rentMonthProvider);
    final filter = ref.watch(rentFilterProvider);
    final charges = ref.watch(monthChargesProvider);

    final filters = <String?, String>{
      null: l10n.filterAll,
      'unpaid': l10n.filterUnpaid,
      'late': l10n.statusLate,
      'partial': l10n.statusPartial,
      'paid': l10n.statusPaid,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navRent),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                key: const Key('previousMonth'),
                onPressed: ref.read(rentMonthProvider.notifier).previous,
                icon: const Icon(Icons.chevron_left),
              ),
              SizedBox(
                width: 180,
                child: Text(
                  formatPeriod(periodOf(month), locale),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                key: const Key('nextMonth'),
                onPressed: ref.read(rentMonthProvider.notifier).next,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ),
      body: charges.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(monthChargesProvider),
        ),
        data: (items) {
          final due = items.fold<int>(0, (s, c) => s + c.amountDue);
          final paid = items.fold<int>(0, (s, c) => s + c.amountPaid);
          final shown = items.where((c) => matchesFilter(c, filter)).toList();

          return RefreshIndicator(
            onRefresh: () => ref.refresh(monthChargesProvider.future),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Row(
                    children: [
                      _Total(
                        label: l10n.monthTotalDue,
                        amount: due,
                        locale: locale,
                      ),
                      _Total(
                        label: l10n.monthCollected,
                        amount: paid,
                        locale: locale,
                      ),
                      _Total(
                        label: l10n.monthOutstanding,
                        amount: due - paid,
                        locale: locale,
                        highlight: due - paid > 0,
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      for (final entry in filters.entries)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(entry.value),
                            selected: filter == entry.key,
                            onSelected: (_) => ref
                                .read(rentFilterProvider.notifier)
                                .set(entry.key),
                          ),
                        ),
                    ],
                  ),
                ),
                if (shown.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: EmptyView(
                      message: l10n.chargesEmpty,
                      icon: Icons.receipt_long_outlined,
                    ),
                  )
                else
                  for (final c in shown)
                    ListTile(
                      title: Text(c.tenantName ?? ''),
                      subtitle: Text(
                        [
                          [
                            c.unitLabel,
                            c.propertyName,
                          ].whereType<String>().join(' · '),
                          c.status == ChargeStatus.late
                              ? l10n.daysLate(c.daysLate)
                              : l10n.dueOn(formatDate(c.dueDate, locale)),
                        ].join('\n'),
                      ),
                      isThreeLine: true,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatBirr(
                              c.balance > 0 ? c.balance : c.amountDue,
                              locale: locale,
                            ),
                          ),
                          ChargeStatusChip(status: c.status),
                        ],
                      ),
                      onTap: () => context.push(
                        c.status == ChargeStatus.paid
                            ? '/leases/${c.leaseId}'
                            : '/payments/new?leaseId=${c.leaseId}',
                      ),
                      onLongPress: () => context.push('/leases/${c.leaseId}'),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({
    required this.label,
    required this.amount,
    required this.locale,
    this.highlight = false,
  });

  final String label;
  final int amount;
  final String locale;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              FittedBox(
                child: Text(
                  formatBirr(amount, locale: locale),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: highlight
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
                ),
              ),
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
