import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/offline/response_cache.dart';
import '../../l10n/app_localizations.dart';
import '../auth/application/auth_controller.dart';
import '../payments/application/pending_payments.dart';

/// Bottom navigation for the signed-in landlord, with offline and unsent-payment banners.
/// Unsent payments are retried on start and whenever the app returns to the foreground.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        _sync();
        // Picks up changes made outside the app, e.g. linking Telegram.
        ref.read(authControllerProvider.notifier).refreshUser();
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _sync() => ref.read(pendingPaymentsProvider.notifier).sync();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shell = widget.shell;
    final offline = ref.watch(offlineStatusProvider);
    final pending = ref.watch(pendingPaymentsProvider).value ?? const [];
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          if (offline)
            Material(
              key: const Key('offlineBanner'),
              color: scheme.surfaceContainerHighest,
              child: SafeArea(
                bottom: false,
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.cloud_off),
                  title: Text(l10n.offlineBanner),
                ),
              ),
            ),
          if (pending.isNotEmpty)
            Material(
              key: const Key('pendingBanner'),
              color: scheme.tertiaryContainer,
              child: SafeArea(
                bottom: false,
                top: !offline,
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.cloud_upload_outlined,
                    color: scheme.onTertiaryContainer,
                  ),
                  title: Text(
                    l10n.pendingPaymentsBanner(pending.length),
                    style: TextStyle(color: scheme.onTertiaryContainer),
                  ),
                  trailing: TextButton(
                    onPressed: _sync,
                    child: Text(l10n.syncNow),
                  ),
                ),
              ),
            ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: offline || pending.isNotEmpty,
              child: shell,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: l10n.navDashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.home_work_outlined),
            selectedIcon: const Icon(Icons.home_work),
            label: l10n.navProperties,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: l10n.navRent,
          ),
          NavigationDestination(
            icon: const Icon(Icons.handyman_outlined),
            selectedIcon: const Icon(Icons.handyman),
            label: l10n.navRepairs,
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people),
            label: l10n.navTenants,
          ),
        ],
      ),
    );
  }
}
