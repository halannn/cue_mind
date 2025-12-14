import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoutesFactory {
  RoutesFactory._();

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

  static GoRoute createDialogRouteWithBuilder({
    required String path,
    required String name,
    required GlobalKey<NavigatorState> navigatorKey,
    required Widget Function(GoRouterState state) builder,
  }) {
    return GoRoute(
      path: path,
      name: name,
      parentNavigatorKey: navigatorKey,
      pageBuilder: (_, state) =>
          MaterialPage(fullscreenDialog: true, child: builder(state)),
    );
  }

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
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: builder(state),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                ),
            child: child,
          );
        },
      ),
    );
  }
}
