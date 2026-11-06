import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/arrears/presentation/arrears_detail_screen.dart';
import '../features/arrears/presentation/arrears_screen.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/code_screen.dart';
import '../features/auth/presentation/phone_screen.dart';
import '../features/compound/presentation/announce_screen.dart';
import '../features/compound/presentation/assets_screen.dart';
import '../features/compound/presentation/meter_detail_screen.dart';
import '../features/compound/presentation/meters_screen.dart';
import '../features/expenses/presentation/add_expense_screen.dart';
import '../features/expenses/presentation/expenses_screen.dart';
import '../features/home/dashboard_screen.dart';
import '../features/move_out/presentation/move_out_screen.dart';
import '../features/listings/presentation/listings_screens.dart';
import '../features/online_rent/presentation/online_rent_screen.dart';
import '../features/home/home_shell.dart';
import '../features/home/settings_screen.dart';
import '../features/leases/presentation/add_lease_screen.dart';
import '../features/leases/presentation/lease_detail_screen.dart';
import '../features/leases/presentation/leases_ending_screen.dart';
import '../features/leases/presentation/statement_screen.dart';
import '../features/payments/domain/payment_sms.dart';
import '../features/payments/presentation/log_payment_screen.dart';
import '../features/properties/presentation/properties_screen.dart';
import '../features/reports/presentation/quarterly_report_screen.dart';
import '../features/repairs/presentation/add_repair_screen.dart';
import '../features/repairs/presentation/repair_detail_screen.dart';
import '../features/repairs/presentation/repairs_screen.dart';
import '../features/properties/presentation/property_detail_screen.dart';
import '../features/rent/presentation/rent_screen.dart';
import '../features/tenants/presentation/add_tenant_screen.dart';
import '../features/team/presentation/team_screen.dart';
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
        path: '/leases/ending',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const LeasesEndingScreen(),
      ),
      GoRoute(
        path: '/leases/unregistered',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const LeasesEndingScreen(unregistered: true),
      ),
      GoRoute(
        path: '/leases/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            LeaseDetailScreen(leaseId: int.parse(state.pathParameters['id']!)),
        routes: [
          GoRoute(
            path: 'statement',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, state) => StatementScreen(
              leaseId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/payments/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => LogPaymentScreen(
          leaseId: int.parse(state.uri.queryParameters['leaseId']!),
          prefill: state.extra is PaymentSms
              ? state.extra! as PaymentSms
              : null,
        ),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'online-rent',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, _) => const OnlineRentScreen(),
          ),
          GoRoute(
            path: 'team',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, _) => const TeamScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/repairs/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => AddRepairScreen(
          unitId: int.tryParse(state.uri.queryParameters['unitId'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/repairs/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => RepairDetailScreen(
          repairId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/reports/quarterly',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const QuarterlyReportScreen(),
      ),
      GoRoute(
        path: '/move-outs/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            MoveOutScreen(moveOutId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/arrears',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const ArrearsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, state) => ArrearsDetailScreen(
              leaseId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/expenses',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const ExpensesScreen(),
        routes: [
          GoRoute(
            path: 'new',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, state) => AddExpenseScreen(
              propertyId: int.tryParse(
                state.uri.queryParameters['propertyId'] ?? '',
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/properties/:id/expenses',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            ExpensesScreen(propertyId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/properties/:id/meters',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            MetersScreen(propertyId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/meters/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            MeterDetailScreen(meterId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/properties/:id/equipment',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            AssetsScreen(propertyId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/equipment/due',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const AssetsScreen(),
      ),
      GoRoute(
        path: '/properties/:id/announce',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            AnnounceScreen(propertyId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/listings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const ListingsScreen(),
        routes: [
          GoRoute(
            path: 'new',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, state) => CreateListingScreen(
              unitId: int.parse(state.uri.queryParameters['unitId']!),
              unitLabel: state.uri.queryParameters['unitLabel'] ?? '',
            ),
          ),
          GoRoute(
            path: ':id',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, state) => ListingDetailScreen(
              listingId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ],
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
                path: '/repairs',
                builder: (_, _) => const RepairsScreen(),
              ),
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
