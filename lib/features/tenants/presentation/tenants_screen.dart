import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/api/api_exception.dart';

import '../../../core/utils/phone_number.dart';
import '../../../core/widgets/async_views.dart';
import '../../../l10n/app_localizations.dart';
import '../data/tenants_repository.dart';
import '../domain/tenant.dart';

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
                  trailing: PopupMenuButton<String>(
                    key: Key('tenantMenu-${t.id}'),
                    onSelected: (action) => action == 'export'
                        ? _export(context, ref, t)
                        : _anonymize(context, ref, t),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'export',
                        child: Text(l10n.tenantExport),
                      ),
                      PopupMenuItem(
                        value: 'anonymize',
                        child: Text(l10n.tenantAnonymize),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref, Tenant t) async {
    try {
      final json = await ref.read(tenantsRepositoryProvider).export(t.id);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/tenant-${t.id}-data.json');
      await file.writeAsString(json, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          text: t.fullName,
        ),
      );
    } on ApiException catch (e) {
      if (context.mounted) _snack(context, friendlyError(context, e));
    }
  }

  Future<void> _anonymize(BuildContext context, WidgetRef ref, Tenant t) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.tenantAnonymize),
        content: Text(l10n.tenantAnonymizeConfirm(t.fullName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.tenantAnonymize),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(tenantsRepositoryProvider).anonymize(t.id);
      ref.invalidate(tenantsProvider);
      if (context.mounted) _snack(context, l10n.tenantAnonymized);
    } on ApiException catch (e) {
      if (context.mounted) _snack(context, friendlyError(context, e));
    }
  }

  void _snack(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
}
