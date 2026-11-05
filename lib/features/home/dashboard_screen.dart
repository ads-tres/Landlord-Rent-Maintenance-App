import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../auth/application/auth_controller.dart';
import '../properties/data/properties_repository.dart';

/// Placeholder home screen. Rent and repair totals arrive with the payments block
/// (`GET /dashboard`); for now it shows property and unit counts.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider).value;
    final properties = ref.watch(propertiesProvider).value ?? const [];
    final units = properties.fold<int>(0, (sum, p) => sum + p.unitsCount);
    final vacant = properties.fold<int>(
      0,
      (sum, p) => sum + p.vacantUnitsCount,
    );
    final name = user?.name;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appName)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(propertiesProvider.future),
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
            Row(
              children: [
                _Stat(
                  label: l10n.dashboardProperties,
                  value: properties.length,
                ),
                _Stat(label: l10n.dashboardUnits, value: units),
                _Stat(label: l10n.dashboardVacant, value: vacant),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.dashboardComingSoon),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Text('$value', style: Theme.of(context).textTheme.headlineMedium),
              Text(label, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
