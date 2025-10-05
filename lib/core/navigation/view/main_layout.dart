import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/navigation_viewmodel.dart';

class MainLayout extends StatelessWidget {
  final List<Widget> pages;
  const MainLayout({super.key, required this.pages});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NavigationViewModel(),
      child: Consumer<NavigationViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            body: pages[viewModel.currentIndex],
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: viewModel.currentIndex,
              onTap: (index) {
                viewModel.updateIndex(index);
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              selectedItemColor: Theme.of(
                context,
              ).colorScheme.onPrimaryContainer,
              unselectedItemColor: Theme.of(
                context,
              ).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
              selectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.category),
                  label: 'Categories',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.browse_gallery),
                  label: 'Archive',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
