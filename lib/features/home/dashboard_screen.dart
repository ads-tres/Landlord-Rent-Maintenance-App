import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/locale_controller.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/async_views.dart';
import '../../l10n/app_localizations.dart';
import '../auth/application/auth_controller.dart';
import '../payments/data/payments_repository.dart';
import '../rent/presentation/rent_screen.dart';

/// Home screen: this month's money, late tenants, repairs and leases ending soon.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider).languageCode;
    final caretaker = ref.watch(isCaretakerProvider);
    final user = ref.watch(authControllerProvider).value;
    final summary = ref.watch(dashboardProvider);
    final name = user?.name;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          IconButton(
            key: const Key('settingsButton'),
            tooltip: l10n.navSettings,
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              name == null || name.isEmpty
                  ? l10n.dashboardWelcomeNoName
                  : l10n.dashboardWelcome(name),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            summary.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => ErrorView(
                error: e,
                onRetry: () => ref.invalidate(dashboardProvider),
              ),
              data: (s) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.dashboardCollected),
                          Text(
                            formatBirr(s.collectedThisMonth, locale: locale),
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          Text(
                            l10n.dashboardDueThisMonth(
                              formatBirr(s.dueThisMonth, locale: locale),
                            ),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!caretaker)
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        key: const Key('openReport'),
                        leading: const Icon(Icons.assessment_outlined),
                        title: Text(l10n.reportOpen),
                        subtitle: Text(l10n.reportOpenHelp),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/reports/quarterly'),
                      ),
                    ),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.7,
                    children: [
                      _Tile(
                        label: l10n.dashboardOutstanding,
                        value: formatBirr(s.outstanding, locale: locale),
                        alert: s.outstanding > 0,
                        onTap: () => _openRent(context, ref, 'unpaid'),
                      ),
                      _Tile(
                        label: l10n.dashboardLateTenants,
                        value: '${s.lateTenants}',
                        alert: s.lateTenants > 0,
                        onTap: () => _openRent(context, ref, 'late'),
                      ),
                      _Tile(
                        label: l10n.dashboardOpenRepairs,
                        value: '${s.openRepairs}',
                      ),
                      _Tile(
                        key: const Key('leasesEndingTile'),
                        label: l10n.dashboardLeasesEnding,
                        value: '${s.leasesEndingSoon}',
                        alert: s.leasesEndingSoon > 0,
                        onTap: () => context.push('/leases/ending'),
                      ),
                      _Tile(
                        key: const Key('servicesDueTile'),
                        label: l10n.dashboardServicesDue,
                        value: '${s.servicesDue}',
                        alert: s.servicesDue > 0,
                        onTap: () => context.push('/equipment/due'),
                      ),
                      if (!caretaker)
                        _Tile(
                          key: const Key('expensesTile'),
                          label: l10n.dashboardExpenses,
                          value: formatBirr(
                            s.expensesThisMonth,
                            locale: locale,
                          ),
                          onTap: () => context.push('/expenses'),
                        ),
                      _Tile(
                        label: l10n.dashboardUnits,
                        value: '${s.units}',
                        onTap: () => context.go('/properties'),
                      ),
                      _Tile(
                        label: l10n.dashboardVacant,
                        value: '${s.vacantUnits}',
                        onTap: () => context.go('/properties'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openRent(BuildContext context, WidgetRef ref, String filter) {
    ref.read(rentFilterProvider.notifier).set(filter);
    context.go('/rent');
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    super.key,
    required this.label,
    required this.value,
    this.alert = false,
    this.onTap,
  });

  final String label;
  final String value;
  final bool alert;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(color: alert ? scheme.error : null),
                ),
              ),
              Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
