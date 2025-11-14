import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Type-safe route paths and names.
class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String categories = '/categories';
  static const String calendar = '/calendar';
  static const String settings = '/setting';

  static const String reminderNew = '/reminder/new';
  static const String categoryDetail = '/categories/:id';

  static void goHome(BuildContext context) => context.go(home);
  static void goCategories(BuildContext context) => context.go(categories);
  static void goCalender(BuildContext context) => context.go(calendar);
  static void goSettings(BuildContext context) => context.go(settings);

  static void pushReminderNew(BuildContext context) => context.pushNamed(RouteNames.reminderNew);
  static void pushCategoryDetail(BuildContext context, int id) => context.push('/categories/$id');
}

/// Route names for named navigation.
class RouteNames {
  RouteNames._();

  static const String home = 'home';
  static const String categories = 'categories';
  static const String calendar = 'calendar';
  static const String settings = 'setting';
  static const String reminderNew = 'reminderNew';
  static const String categoryShow = 'categoryShow';
}
