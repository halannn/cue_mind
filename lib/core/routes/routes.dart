import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../navigation/view/main_layout.dart';
import '../../features/home/views/home_view.dart';
import '../../features/home/views/new_reminder_view.dart';
import '../../features/categories/views/categories_view.dart';
import '../../features/calender/views/calender_view.dart';
import '../../features/setting/views/setting_view.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (context, state, child) {
        return MainLayout(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          parentNavigatorKey: shellNavigatorKey,
          pageBuilder: (_, _) => const NoTransitionPage(child: HomeView()),
        ),
        GoRoute(
          path: '/categories',
          name: 'categories',
          parentNavigatorKey: shellNavigatorKey,
          pageBuilder: (_, _) => const NoTransitionPage(child: CategoriesView()),
        ),
        GoRoute(
          path: '/calendar',
          name: 'calendar',
          parentNavigatorKey: shellNavigatorKey,
          pageBuilder: (_, _) => const NoTransitionPage(child: CalendarView()),
        ),
        GoRoute(
          path: '/setting',
          name: 'setting',
          parentNavigatorKey: shellNavigatorKey,
          pageBuilder: (_, _) => const NoTransitionPage(child: SettingView()),
        ),
      ],
    ),

    GoRoute(
      path: '/reminder/new',
      name: 'reminderNew',
      parentNavigatorKey: rootNavigatorKey,
     pageBuilder: (_, _) => const MaterialPage(
        fullscreenDialog: true,
        child: NewReminderView(),
      ),
    ),
  ],
);
