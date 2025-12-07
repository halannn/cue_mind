import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Handles route parameter validation errors.
class RouteErrorHandler {
  RouteErrorHandler._();

  /// Displays error page for invalid route parameters.
  static Widget handleInvalidParameter({
    required String? rawValue,
    required String paramName,
  }) {
    debugPrint('❌ Invalid $paramName: "$rawValue"');

    return Scaffold(
      appBar: AppBar(title: const Text('Invalid Parameter'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
              const SizedBox(height: 24),

              Text(
                'Invalid $paramName',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              if (rawValue != null) ...[
                Text(
                  'Received: "$rawValue"',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
              ],

              Text(
                'The $paramName you\'re looking for doesn\'t exist or is invalid.',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Navigation button
              Builder(
                builder: (context) => FilledButton.icon(
                  onPressed: () {
                    // Try to pop first, if can't pop then go home
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      context.go('/');
                    }
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Return to Home'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static int? parseId(GoRouterState state, String paramName) {
    final rawValue = state.pathParameters[paramName];
    if (rawValue == null) return null;

    return int.tryParse(rawValue);
  }
}
