import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routes/routes.dart';
import 'core/services/providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class NoGlowScrollBehavior extends ScrollBehavior {
  const NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lightTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      useMaterial3: true,
    );
    final darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );

    final bootstrapState = ref.watch(appBootstrapProvider);

    return bootstrapState.when(
      data: (_) => MaterialApp.router(
        title: 'Cue Mind',
        debugShowCheckedModeBanner: false,
        restorationScopeId: 'app',
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        scrollBehavior: const NoGlowScrollBehavior(),
        routerConfig: router,
      ),
      loading: () => MaterialApp(
        title: 'Cue Mind',
        debugShowCheckedModeBanner: false,
        restorationScopeId: 'app',
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        scrollBehavior: const NoGlowScrollBehavior(),
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (e, st) {
        return MaterialApp(
          title: 'Cue Mind',
          debugShowCheckedModeBanner: false,
          restorationScopeId: 'app',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.system,
          scrollBehavior: const NoGlowScrollBehavior(),
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Init error: $e'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(appBootstrapProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
