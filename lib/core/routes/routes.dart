import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'route_config.dart';
import 'route_factory.dart';
import 'route_error_handler.dart';

import '../navigation/view/main_layout.dart';
import '../../features/home/views/home_view.dart';
import '../../features/home/views/new_reminder_view.dart';
import '../../features/categories/views/categories_view.dart';
import '../../features/categories/views/category_view.dart';
import '../../features/calendar/views/calender_view.dart';
import '../../features/setting/views/setting_view.dart';

// =============================================================================
// NAVIGATOR KEYS
// =============================================================================
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

// =============================================================================
// ROUTER CONFIGURATION
// =============================================================================
final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.home,

  // Error handling for unknown routes
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Page Not Found')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.orange),
          const SizedBox(height: 16),
          const Text('404- Page Not Found', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 16),
          Text('Path: ${state.uri.path}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.home),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  ),

  routes: [
    // =========================================================================
    // SHELL ROUTE - Bottom Navigation Container
    // =========================================================================
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        // Bottom navigation routes
        RoutesFactory.createBottomNavRoute(
          path: AppRoutes.home,
          name: RouteNames.home,
          child: const HomeView(),
          navigatorKey: shellNavigatorKey,
        ),
        RoutesFactory.createBottomNavRoute(
          path: AppRoutes.categories,
          name: RouteNames.categories,
          child: const CategoriesView(),
          navigatorKey: shellNavigatorKey,
        ),
        RoutesFactory.createBottomNavRoute(
          path: AppRoutes.calendar,
          name: RouteNames.calendar,
          child: const CalendarView(),
          navigatorKey: shellNavigatorKey,
        ),
        RoutesFactory.createBottomNavRoute(
          path: AppRoutes.settings,
          name: RouteNames.settings,
          child: const SettingView(),
          navigatorKey: shellNavigatorKey,
        ),
      ],
    ),

    // =========================================================================
    // ROOT ROUTES - Full Screen
    // =========================================================================
    RoutesFactory.createDialogRoute(
      path: AppRoutes.reminderNew,
      name: RouteNames.reminderNew,
      child: const NewReminderView(),
      navigatorKey: rootNavigatorKey,
    ),

    RoutesFactory.createPushRoute(
      path: AppRoutes.categoryDetail,
      name: RouteNames.categoryShow,
      navigatorKey: rootNavigatorKey,
      builder: (state) => _buildCategoryDetailPage(state),
    ),
  ],
);

// =============================================================================
// ROUTE BUILDERS - Complex Routes with Validation
// =============================================================================
Widget _buildCategoryDetailPage(GoRouterState state) {
  final id = RouteErrorHandler.parseId(state, 'id');

  if (id == null) {
    return RouteErrorHandler.handleInvalidParamter(
      rawValue: state.pathParameters['id'],
      paramName: 'Category ID',
      onReturnHome: () {
        state.namedLocation(RouteNames.categories);
      },
    );
  }
  return CategoryView(id: id);
}
