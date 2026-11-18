import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tims/app/routes/route_paths.dart';
import 'package:tims/app/services/providers.dart';
import 'package:tims/features/authentication/pages/login_page.dart';
import 'package:tims/features/authentication/pages/register_page.dart';
import 'package:tims/features/authentication/pages/forgot_password_page.dart';
import 'package:tims/features/authentication/pages/splash_page.dart';
import 'package:tims/features/dashboard/pages/dashboard_page.dart';
import 'package:tims/features/inventory/pages/inventory_page.dart';
import 'package:tims/features/categories/pages/categories_page.dart';
import 'package:tims/features/items/pages/items_page.dart';
import 'package:tims/features/qualifications/pages/qualifications_page.dart';
import 'package:tims/features/procurement/pages/purchase_requests_page.dart';
import 'package:tims/features/procurement/pages/purchase_orders_page.dart';
import 'package:tims/features/receiving/pages/receiving_page.dart';
import 'package:tims/features/issuance/pages/issuance_page.dart';
import 'package:tims/features/borrowing/pages/borrowing_page.dart';
import 'package:tims/features/returns/pages/returns_page.dart';
import 'package:tims/features/maintenance/pages/maintenance_page.dart';
import 'package:tims/features/reports/pages/reports_page.dart';
import 'package:tims/features/notifications/pages/notifications_page.dart';
import 'package:tims/features/settings/pages/settings_page.dart';
import 'package:tims/features/profile/pages/profile_page.dart';
import 'package:tims/features/shared/pages/main_shell.dart';

/// Root navigator, shared so app-wide dialogs can appear over any screen.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Router configuration provider.
final routerProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    redirect: (context, state) {
      final isLoggedIn = authService.isAuthenticated;
      final isAuthRoute = state.matchedLocation == RoutePaths.login ||
          state.matchedLocation == RoutePaths.register ||
          state.matchedLocation == RoutePaths.forgotPassword ||
          state.matchedLocation == RoutePaths.splash;

      if (isAuthRoute && isLoggedIn) {
        return RoutePaths.dashboard;
      }
      if (!isAuthRoute && !isLoggedIn) {
        return RoutePaths.login;
      }
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RoutePaths.register,
        name: RouteNames.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      // Main shell route
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.dashboard,
            name: RouteNames.dashboard,
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: RoutePaths.inventory,
            name: RouteNames.inventory,
            builder: (context, state) => const InventoryPage(),
          ),
          GoRoute(
            path: RoutePaths.categories,
            name: RouteNames.categories,
            builder: (context, state) => const CategoriesPage(),
          ),
          GoRoute(
            path: RoutePaths.items,
            name: RouteNames.items,
            builder: (context, state) => const ItemsPage(),
          ),
          GoRoute(
            path: RoutePaths.qualifications,
            name: RouteNames.qualifications,
            builder: (context, state) => const QualificationsPage(),
          ),
          GoRoute(
            path: RoutePaths.purchaseRequests,
            name: RouteNames.purchaseRequests,
            builder: (context, state) => const PurchaseRequestsPage(),
          ),
          GoRoute(
            path: RoutePaths.purchaseOrders,
            name: RouteNames.purchaseOrders,
            builder: (context, state) => const PurchaseOrdersPage(),
          ),
          GoRoute(
            path: RoutePaths.receiving,
            name: RouteNames.receiving,
            builder: (context, state) => const ReceivingPage(),
          ),
          GoRoute(
            path: RoutePaths.issuance,
            name: RouteNames.issuance,
            builder: (context, state) => const IssuancePage(),
          ),
          GoRoute(
            path: RoutePaths.borrowing,
            name: RouteNames.borrowing,
            builder: (context, state) => const BorrowingPage(),
          ),
          GoRoute(
            path: RoutePaths.returns,
            name: RouteNames.returns,
            builder: (context, state) => const ReturnsPage(),
          ),
          GoRoute(
            path: RoutePaths.maintenance,
            name: RouteNames.maintenance,
            builder: (context, state) => const MaintenancePage(),
          ),
          GoRoute(
            path: RoutePaths.reports,
            name: RouteNames.reports,
            builder: (context, state) => const ReportsPage(),
          ),
          GoRoute(
            path: RoutePaths.notifications,
            name: RouteNames.notifications,
            builder: (context, state) => const NotificationsPage(),
          ),
          GoRoute(
            path: RoutePaths.settings,
            name: RouteNames.settings,
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: RoutePaths.profile,
            name: RouteNames.profile,
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );
});
