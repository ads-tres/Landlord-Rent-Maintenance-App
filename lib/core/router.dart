import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/code_screen.dart';
import '../features/auth/presentation/phone_screen.dart';
import '../features/home/dashboard_screen.dart';
import '../features/home/home_shell.dart';
import '../features/home/settings_screen.dart';
import '../features/leases/presentation/add_lease_screen.dart';
import '../features/leases/presentation/lease_detail_screen.dart';
import '../features/payments/presentation/log_payment_screen.dart';
import '../features/properties/presentation/properties_screen.dart';
import '../features/properties/presentation/property_detail_screen.dart';
import '../features/rent/presentation/rent_screen.dart';
import '../features/tenants/presentation/add_tenant_screen.dart';
import '../features/tenants/presentation/tenants_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // Re-run redirects whenever the auth state changes.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final atSplash = state.matchedLocation == '/splash';
      final atLogin = state.matchedLocation.startsWith('/login');

      if (auth.isLoading && !auth.hasValue) return atSplash ? null : '/splash';

      final loggedIn = auth.value != null;
      if (!loggedIn) return atLogin ? null : '/login';
      if (atLogin || atSplash) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const _Splash()),
      GoRoute(
        path: '/login',
        builder: (_, _) => const PhoneScreen(),
        routes: [
          GoRoute(
            path: 'code',
            builder: (_, state) =>
                CodeScreen(phone: state.extra as String? ?? ''),
          ),
        ],
      ),
      // Full-screen lease pages, reachable from any tab.
      GoRoute(
        path: '/leases/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) {
          final q = state.uri.queryParameters;
          return AddLeaseScreen(
            unitId: int.parse(q['unitId']!),
            unitLabel: q['unitLabel'] ?? '',
            propertyId: int.tryParse(q['propertyId'] ?? ''),
          );
        },
      ),
      GoRoute(
        path: '/leases/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            LeaseDetailScreen(leaseId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/payments/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => LogPaymentScreen(
          leaseId: int.parse(state.uri.queryParameters['leaseId']!),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/properties',
                builder: (_, _) => const PropertiesScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => PropertyDetailScreen(
                      propertyId: int.parse(state.pathParameters['id']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/rent', builder: (_, _) => const RentScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tenants',
                builder: (_, _) => const TenantsScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (_, _) => const AddTenantScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, _) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
