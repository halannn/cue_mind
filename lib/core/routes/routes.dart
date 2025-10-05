import 'package:go_router/go_router.dart';
import '../navigation/view/main_layout.dart';
import '../../features/home/views/home_view.dart';
import '../../features/categories/views/categories_view.dart';
import '../../features/archive/views/archive_view.dart';
import '../../features/setting/views/setting_view.dart';

final router = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return MainLayout(
          pages: const [
            HomeView(),
            CategoriesView(),
            ArchiveView(),
            SettingView()
          ],
        );
      },
      routes: [
        GoRoute(path: '/', name: 'home', builder: (_, __) => const HomeView()),
        GoRoute(path: '/explore', name: 'explore', builder: (_, __) => const CategoriesView()),
        GoRoute(path: '/archive', name: 'archive', builder: (_, __) => const ArchiveView()),
        GoRoute(path: '/profile', name: 'profile', builder: (_, __) => const SettingView()),
      ],
    ),
  ],
);
