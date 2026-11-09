import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/locale_controller.dart';
import '../../../core/utils/app_dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_views.dart';
import '../../../l10n/app_localizations.dart';
import '../data/unit_history_repository.dart';
import '../domain/unit_history.dart';

/// Everything that happened to one unit: tenants, rent, repairs and empty spells.
class UnitHistoryScreen extends ConsumerWidget {
  const UnitHistoryScreen({super.key, required this.unitId});

  final int unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final history = ref.watch(unitHistoryProvider(unitId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          history.value == null
              ? l10n.unitHistory
              : '${history.value!.label} · ${history.value!.propertyName}',
        ),
      ),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(unitHistoryProvider(unitId)),
        ),
        data: (h) => RefreshIndicator(
          onRefresh: () => ref.refresh(unitHistoryProvider(unitId).future),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _Summary(history: h),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  l10n.unitTimeline,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final e in h.events) _EventTile(event: e),
            ],
          ),
        ),
      ),
    );
  }
}

class _Summary extends ConsumerWidget {
  const _Summary({required this.history});

  final UnitHistory history;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider).languageCode;
    final dates = ref.watch(appDatesProvider);
    final h = history;
    String birr(int v) => formatBirr(v, locale: locale);

    Widget line(String label, String value, {Key? key, bool alert = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(child: Text(label)),
              Text(
                value,
                key: key,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: alert ? Theme.of(context).colorScheme.error : null,
                ),
              ),
            ],
          ),
        );

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.unitThisYear(h.yearLabel),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            if (h.year.occupancyPercent != null)
              line(l10n.occupancy, '${h.year.occupancyPercent}%'),
            line(l10n.daysEmpty, '${h.year.vacantDays}'),
            line(
              l10n.rentLostToVacancy,
              h.year.priced || h.year.lost > 0 ? birr(h.year.lost) : '—',
              key: const Key('unitLost'),
              alert: h.year.lost > 0,
            ),
            if (h.repairCostThisYear > 0)
              line(l10n.repairCosts, birr(h.repairCostThisYear)),
            const Divider(height: 20),
            if (h.currentRent != null)
              line(l10n.currentRentLabel, birr(h.currentRent!)),
            line(l10n.tenantsSoFar, '${h.tenants}'),
            if (h.averageStayMonths != null)
              line(
                l10n.averageStay,
                l10n.monthsCount(h.averageStayMonths!.round()),
              ),
            if (h.repairCost > 0)
              line(l10n.repairCostsAllTime, birr(h.repairCost)),
            const SizedBox(height: 6),
            Text(
              l10n.trackedSince(dates.date(h.trackedSince)),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (!h.year.priced)
              Text(
                l10n.vacancyUnpricedHelp,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

class _EventTile extends ConsumerWidget {
  const _EventTile({required this.event});

  final UnitEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider).languageCode;
    final dates = ref.watch(appDatesProvider);
    final scheme = Theme.of(context).colorScheme;
    final e = event;
    String birr(int v) => formatBirr(v, locale: locale);

    final (
      IconData icon,
      Color? color,
      String title,
      String? subtitle,
    ) = switch (e.type) {
      UnitEventType.leaseStarted => (
        Icons.login,
        scheme.primary,
        l10n.eventLeaseStarted(e.tenant ?? ''),
        e.rent == null ? null : l10n.eventRent(birr(e.rent!)),
      ),
      UnitEventType.leaseEnded => (
        Icons.logout,
        null,
        l10n.eventLeaseEnded(e.tenant ?? ''),
        e.early ? l10n.eventEndedEarly : null,
      ),
      UnitEventType.rentChanged => (
        (e.newRent ?? 0) > (e.oldRent ?? 0)
            ? Icons.trending_up
            : Icons.trending_down,
        null,
        l10n.eventRentChanged(birr(e.oldRent ?? 0), birr(e.newRent ?? 0)),
        e.upcoming ? l10n.rentChangeUpcoming : null,
      ),
      UnitEventType.repair => (
        Icons.handyman_outlined,
        null,
        e.title ?? l10n.navRepairs,
        e.cost != null && e.cost! > 0 ? birr(e.cost!) : null,
      ),
      UnitEventType.vacant => (
        Icons.meeting_room_outlined,
        scheme.error,
        e.until == null
            ? l10n.eventEmptySince(e.days ?? 0)
            : l10n.eventEmptyFor(e.days ?? 0),
        [
          if (e.until != null) l10n.eventUntil(dates.date(e.until!)),
          e.lost == null ? l10n.vacancyUnpriced : l10n.eventLost(birr(e.lost!)),
        ].join(' · '),
      ),
    };

    final route = switch (e.type) {
      UnitEventType.repair when e.repairId != null => '/repairs/${e.repairId}',
      UnitEventType.leaseStarted ||
      UnitEventType.leaseEnded ||
      UnitEventType.rentChanged when e.leaseId != null =>
        '/leases/${e.leaseId}',
      _ => null,
    };

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text([dates.date(e.date), ?subtitle].join(' · ')),
      onTap: route == null ? null : () => context.push(route),
    );
  }
}
