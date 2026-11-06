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
class LeasesEndingScreen extends ConsumerWidget {
  const LeasesEndingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dates = ref.watch(appDatesProvider);
    final locale = ref.watch(localeControllerProvider).languageCode;
    final leases = ref.watch(endingLeasesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.leasesEnding)),
      body: leases.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(endingLeasesProvider),
        ),
        data: (items) => items.isEmpty
            ? EmptyView(
                message: l10n.leasesEndingEmpty,
                icon: Icons.event_available,
              )
            : RefreshIndicator(
                onRefresh: () => ref.refresh(endingLeasesProvider.future),
                child: ListView(
                  children: [
                    for (final l in items)
                      ListTile(
                        key: Key('endingLease-${l.id}'),
                        leading: const Icon(Icons.event_outlined),
                        title: Text([?l.tenantName, ?l.unitLabel].join(' · ')),
                        subtitle: Text(
                          [
                            dates.date(l.endDate),
                            formatBirr(l.monthlyRent, locale: locale),
                          ].join(' · '),
                        ),
                        trailing: Chip(
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
                          ref.invalidate(endingLeasesProvider);
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
