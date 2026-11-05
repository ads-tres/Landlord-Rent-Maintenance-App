import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_dates.dart';
import '../../../core/widgets/async_views.dart';
import '../../../l10n/app_localizations.dart';
import '../data/repairs_repository.dart';
import 'repair_widgets.dart';

class RepairsScreen extends ConsumerWidget {
  const RepairsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dates = ref.watch(appDatesProvider);
    final filter = ref.watch(repairFilterProvider);
    final repairs = ref.watch(repairsProvider);

    final filters = {
      'active': l10n.repairActive,
      'open': l10n.repairOpen,
      'in_progress': l10n.repairInProgress,
      'done': l10n.repairDone,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navRepairs)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await context.push<Object?>('/repairs/new');
          if (created != null) ref.invalidate(repairsProvider);
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.addRepair),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                for (final e in filters.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(e.value),
                      selected: filter == e.key,
                      onSelected: (_) =>
                          ref.read(repairFilterProvider.notifier).set(e.key),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: repairs.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(
                error: e,
                onRetry: () => ref.invalidate(repairsProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return EmptyView(
                    message: l10n.repairsEmpty,
                    icon: Icons.handyman_outlined,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(repairsProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final r = items[i];
                      return ListTile(
                        leading: CircleAvatar(child: Icon(r.category.icon)),
                        title: Text(r.title),
                        subtitle: Text(
                          [
                            [
                              r.unitLabel,
                              r.propertyName,
                            ].whereType<String>().join(' · '),
                            [
                              l10n.repairOpenedOn(dates.date(r.openedAt)),
                              if (r.fromTenant) l10n.repairFromTenant,
                              if (r.photosCount > 0) '📷 ${r.photosCount}',
                            ].join(' · '),
                          ].join('\n'),
                        ),
                        isThreeLine: true,
                        trailing: RepairStatusChip(status: r.status),
                        onTap: () async {
                          await context.push('/repairs/${r.id}');
                          ref.invalidate(repairsProvider);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
