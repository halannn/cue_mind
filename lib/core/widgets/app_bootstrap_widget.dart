import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/providers.dart';
import 'bootstrap_error_screen.dart';
import 'bootstrap_loading_screen.dart';

/// Handles app bootstrap state and displays appropriate screens.
class AppBootstrapWidget extends ConsumerWidget {
  final Widget child;

  const AppBootstrapWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrapState = ref.watch(appBootstrapProvider);

    return bootstrapState.when(
      data: (_) => child,

      loading: () => const BootstrapLoadingScreen(),

      error: (error, stackTrace) => BootstrapErrorScreen(
        error: error,
        stackTrace: stackTrace,
        onRetry: () {
          ref.invalidate(appBootstrapProvider);
        },
      ),
    );
  }
}
