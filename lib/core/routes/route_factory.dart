import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Factory for creating GoRouter routes
class RoutesFactory {
  RoutesFactory._();

  /// Creates a bottom navigation route
  static GoRoute createBottomNavRoute({
    required String path,
    required String name,
    required Widget child,
    required GlobalKey<NavigatorState> navigatorKey,
  }) {
    return GoRoute(
      path: path,
      name: name,
      parentNavigatorKey: navigatorKey,
      pageBuilder: (_, _) => NoTransitionPage(child: child),
    );
  }

  /// Creates a full-screen dialog route.
  static GoRoute createDialogRoute({
    required String path,
    required String name,
    required Widget child,
    required GlobalKey<NavigatorState> navigatorKey,
  }) {
    return GoRoute(
      path: path,
      name: name,
      parentNavigatorKey: navigatorKey,
      pageBuilder: (_, _) => MaterialPage(fullscreenDialog: true, child: child),
    );
  }

  /// Creates a standard push route with custom page builder.
  static GoRoute createPushRoute({
    required String path,
    required String name,
    required GlobalKey<NavigatorState> navigatorKey,
    required Widget Function(GoRouterState) builder,
  }) {
    return GoRoute(
      path: path,
      name: name,
      parentNavigatorKey: navigatorKey,
      pageBuilder: (_, state) => MaterialPage(child: builder(state)),
    );
  }
}
