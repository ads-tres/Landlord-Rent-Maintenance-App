import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/locale_controller.dart';
import '../../../core/utils/app_dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_views.dart';
import '../../../l10n/app_localizations.dart';
import '../data/unit_history_repository.dart';

/// Rent lost to empty units in a year, worst unit first.
class VacancyScreen extends ConsumerStatefulWidget {
  const VacancyScreen({super.key});

  @override
  ConsumerState<VacancyScreen> createState() => _VacancyScreenState();
}

class _VacancyScreenState extends ConsumerState<VacancyScreen> {
  int? _year;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider).languageCode;
    final dates = ref.watch(appDatesProvider);
    final report = ref.watch(vacancyReportProvider(_year));
    String birr(int v) => formatBirr(v, locale: locale);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.vacancyTitle)),
      body: report.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(vacancyReportProvider(_year)),
        ),
        data: (r) => ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Row(
              children: [
                IconButton(
                  key: const Key('previousYear'),
                  onPressed: () => setState(() => _year = r.year - 1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${r.year}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text('${dates.date(r.from)} – ${dates.date(r.to)}'),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('nextYear'),
                  onPressed: () => setState(() => _year = r.year + 1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(l10n.rentLostToVacancy),
                subtitle: Text(
                  [
                    l10n.daysEmptyCount(r.vacantDays),
                    if (r.occupancyPercent != null)
                      l10n.occupancyValue('${r.occupancyPercent}'),
                  ].join(' · '),
                ),
                trailing: Text(
                  birr(r.lost),
                  key: const Key('vacancyTotal'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: r.lost > 0
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                l10n.vacancyHowCounted,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (r.unpricedUnits > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  l10n.vacancyUnpricedUnits(r.unpricedUnits),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (r.units.isEmpty)
              EmptyView(
                message: l10n.unitsEmpty,
                icon: Icons.meeting_room_outlined,
              ),
            for (final u in r.units)
              ListTile(
                key: Key('vacancyUnit-${u.id}'),
                leading: Icon(
                  u.vacant
                      ? Icons.meeting_room_outlined
                      : Icons.check_circle_outline,
                  color: u.vacant ? Theme.of(context).colorScheme.error : null,
                ),
                title: Text('${u.label} · ${u.propertyName}'),
                subtitle: Text(
                  [
                    l10n.daysEmptyCount(u.figures.vacantDays),
                    if (u.vacantSince != null)
                      l10n.emptySinceDate(dates.date(u.vacantSince!)),
                  ].join(' · '),
                ),
                trailing: Text(
                  u.figures.priced || u.figures.lost > 0
                      ? birr(u.figures.lost)
                      : '—',
                ),
                onTap: () => context.push('/units/${u.id}/history'),
              ),
          ],
        ),
      ),
    );
  }
}
