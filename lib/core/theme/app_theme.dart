import 'package:flutter/material.dart';

/// Centralized theme configuration for the application.
class AppTheme {
  AppTheme._();

  static const Color _seedColor = Colors.indigo;

  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
    useMaterial3: true,
  );

  static ThemeData get dark => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  );
}
