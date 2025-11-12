import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Handles route parameter validation errors gracefully.
class RouteErrorHandler {
  RouteErrorHandler._();

  static Widget handleInvalidParamter({
    required String? rawValue,
    required String paramName,
    required VoidCallback onReturnHome,
  }) {
    debugPrint('❌ Invalid $paramName : "$rawValue"');

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
              ),
              const SizedBox(height: 24),

              if (rawValue != null) ...[
                Text(
                  'Received : "$rawValue"',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
              ],

              Text(
                'The $paramName you\'re looking for doesn\'t exist or is invalid.',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: onReturnHome,
                label: const Text('Return to home'),
                icon: const Icon(Icons.home),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Parses an integer ID from route parameters with validation.
  static int? parseId(GoRouterState state, String paramName) {
    final rawValue = state.pathParameters[paramName];
    if (rawValue == null) return null;

    return int.tryParse(rawValue);
  }
}
