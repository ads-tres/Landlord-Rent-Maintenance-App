import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/phone_number.dart';
import '../../../core/widgets/async_views.dart';
import '../../../l10n/app_localizations.dart';
import '../data/tenants_repository.dart';

class TenantsScreen extends ConsumerWidget {
  const TenantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tenants = ref.watch(tenantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navTenants),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SearchBar(
              hintText: l10n.searchTenants,
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              onSubmitted: ref.read(tenantSearchProvider.notifier).set,
              onChanged: (v) {
                if (v.isEmpty) ref.read(tenantSearchProvider.notifier).set('');
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await context.push<Object?>('/tenants/new');
          if (added != null) ref.invalidate(tenantsProvider);
        },
        icon: const Icon(Icons.person_add_alt),
        label: Text(l10n.addTenant),
      ),
      body: tenants.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            ErrorView(error: e, onRetry: () => ref.invalidate(tenantsProvider)),
        data: (items) {
          if (items.isEmpty) {
            return EmptyView(
              message: l10n.tenantsEmpty,
              icon: Icons.people_outline,
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(tenantsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final t = items[i];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(t.fullName.characters.first),
                  ),
                  title: Text(t.fullName),
                  subtitle: Text(formatEthiopianPhone(t.phone)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
