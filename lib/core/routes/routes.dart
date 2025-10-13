import 'package:go_router/go_router.dart';
import '../navigation/view/main_layout.dart';
import '../../features/home/views/home_view.dart';
import '../../features/categories/views/categories_view.dart';
import '../../features/calender/views/calender_view.dart';
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
        GoRoute(path: '/categories', name: 'categories', builder: (_, __) => const CategoriesView()),
        GoRoute(path: '/calender', name: 'calender', builder: (_, __) => const ArchiveView()),
        GoRoute(path: '/setting', name: 'setting', builder: (_, __) => const SettingView()),
      ],
    ),
  ],
);
