import 'package:flutter/material.dart';

class CategoryColors {
  CategoryColors._();

  static const List<Color> palette = [
    Color(0xFFF44336),
    Color(0xFF9C27B0),
    Color(0xFF673AB7),
    Color(0xFF2196F3),
    Color(0xFF00BCD4),
    Color(0xFF009688),
    Color(0xFF4CAF50),
    Color(0xFFFFEB3B),
    Color(0xFFFF9800),
    Color(0xFF795548),
    Color(0xFF607D8B),
  ];

  static const Color defaultColor = Color(0xFF8E8E93);

  static String getColorName(Color color) {
    final index = palette.indexOf(color);
    if (index == -1) return 'Custom';

    const names = [
      'Red',
      'Purple',
      'Deep Purple',
      'Blue',
      'Cyan',
      'Teal',
      'Green',
      'Yellow',
      'Orange',
      'Brown',
      'Blue Grey',
    ];

    return names[index];
  }

  static bool isPresetColor(Color color) {
    return palette.contains(color);
  }
}
