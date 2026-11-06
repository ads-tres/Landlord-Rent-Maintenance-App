import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/locale_controller.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_views.dart';
import '../../../l10n/app_localizations.dart';
import '../data/arrears_repository.dart';

/// Tenants behind on rent, most overdue first, with the suggested next step.
class ArrearsScreen extends ConsumerWidget {
  const ArrearsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider).languageCode;
    final list = ref.watch(arrearsListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.arrears)),
      body: list.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(arrearsListProvider),
        ),
        data: (items) => items.isEmpty
            ? EmptyView(
                message: l10n.arrearsEmpty,
                icon: Icons.verified_outlined,
              )
            : RefreshIndicator(
                onRefresh: () => ref.refresh(arrearsListProvider.future),
                child: ListView(
                  children: [
                    for (final a in items)
                      ListTile(
                        key: Key('arrears-${a.leaseId}'),
                        leading: CircleAvatar(
                          backgroundColor: a.daysOverdue >= 30
                              ? Theme.of(context).colorScheme.errorContainer
                              : Theme.of(context).colorScheme.tertiaryContainer,
                          child: Text('${a.daysOverdue}'),
                        ),
                        title: Text([?a.tenantName, ?a.unitLabel].join(' · ')),
                        subtitle: Text(
                          [
                            l10n.daysOverdue(a.daysOverdue),
                            if (a.plan != null)
                              l10n.onPaymentPlan
                            else if (a.suggested != null)
                              l10n.nextStep(a.suggested!.label(l10n)),
                          ].join(' · '),
                        ),
                        trailing: Text(
                          formatBirr(a.owed, locale: locale),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        onTap: () async {
                          await context.push('/arrears/${a.leaseId}');
                          ref.invalidate(arrearsListProvider);
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
