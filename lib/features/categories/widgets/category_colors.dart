import 'package:flutter/material.dart';

class CategoryColors {
  CategoryColors._();

  static const List<Color> palette = [
    Color(0xFFEF5350),
    Color(0xFFEC407A),
    Color(0xFFAB47BC),
    Color(0xFF7E57C2),
    Color(0xFF5C6BC0),
    Color(0xFF42A5F5),
    Color(0xFF26C6DA),
    Color(0xFF26A69A),
    Color(0xFF66BB6A),
    Color(0xFFFFA726),
    Color(0xFF8D6E63),
    Color(0xFF78909C),
  ];

  static const Color defaultColor = Color(0xFF8E8E93);

  static String getColorName(Color color) {
    final index = palette.indexOf(color);
    if (index == -1) return 'Unknown';

    const names = [
      'Red',
      'Pink',
      'Purple',
      'Deep Purple',
      'Indigo',
      'Blue',
      'Cyan',
      'Teal',
      'Green',
      'Orange',
      'Brown',
      'Blue Grey',
    ];

    return names[index];
  }
}
