import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/locale_controller.dart';
import '../../../core/utils/app_dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_views.dart';
import '../../../l10n/app_localizations.dart';
import '../data/leases_repository.dart';

/// Leases ending in the next 60 days, soonest first: renew or plan the move-out.
/// With [unregistered], active leases not yet registered with the woreda office.
class LeasesEndingScreen extends ConsumerWidget {
  const LeasesEndingScreen({super.key, this.unregistered = false});

  final bool unregistered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dates = ref.watch(appDatesProvider);
    final locale = ref.watch(localeControllerProvider).languageCode;
    final provider = unregistered
        ? unregisteredLeasesProvider
        : endingLeasesProvider;
    final leases = ref.watch(provider);

    return Scaffold(
      appBar: AppBar(
        title: Text(unregistered ? l10n.leasesToRegister : l10n.leasesEnding),
      ),
      body: leases.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            ErrorView(error: e, onRetry: () => ref.invalidate(provider)),
        data: (items) => items.isEmpty
            ? EmptyView(
                message: unregistered
                    ? l10n.leasesToRegisterEmpty
                    : l10n.leasesEndingEmpty,
                icon: Icons.event_available,
              )
            : RefreshIndicator(
                onRefresh: () => ref.refresh(provider.future),
                child: ListView(
                  children: [
                    for (final l in items)
                      ListTile(
                        key: Key('endingLease-${l.id}'),
                        leading: const Icon(Icons.event_outlined),
                        title: Text([?l.tenantName, ?l.unitLabel].join(' · ')),
                        subtitle: Text(
                          [
                            unregistered
                                ? l10n.startedOn(dates.date(l.startDate))
                                : dates.date(l.endDate),
                            formatBirr(l.monthlyRent, locale: locale),
                          ].join(' · '),
                        ),
                        trailing: unregistered
                            ? const Icon(Icons.chevron_right)
                            : Chip(
                                label: Text(
                                  l10n.endsIn(
                                    (l.daysUntilEnd ?? 0) < 0
                                        ? 0
                                        : l.daysUntilEnd ?? 0,
                                  ),
                                ),
                                visualDensity: VisualDensity.compact,
                                side: BorderSide.none,
                              ),
                        onTap: () async {
                          await context.push('/leases/${l.id}');
                          ref.invalidate(provider);
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
