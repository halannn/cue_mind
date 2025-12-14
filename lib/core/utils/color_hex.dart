import 'package:flutter/material.dart';

extension HexColorParsing on String {
  Color toColor({Color fallback = const Color(0xFF8E8E93)}) {
    var s = replaceAll('#', '');
    if (s.length == 6) s = 'FF$s';
    if (s.length != 8) return fallback;
    final v = int.tryParse(s, radix: 16);
    if (v == null) return fallback;
    return Color(v);
  }
}

extension ColorHexString on Color {
  String toHex({bool leadingHashSign = true, bool includeAlpha = false}) {
    final a = includeAlpha
        ? ((this.a * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0')
        : '';
    final r = ((this.r * 255.0).round() & 0xff)
        .toRadixString(16)
        .padLeft(2, '0');
    final g = ((this.g * 255.0).round() & 0xff)
        .toRadixString(16)
        .padLeft(2, '0');
    final b = ((this.b * 255.0).round() & 0xff)
        .toRadixString(16)
        .padLeft(2, '0');
    final hex = '${includeAlpha ? a : ''}$r$g$b'.toUpperCase();
    return leadingHashSign ? '#$hex' : hex;
  }
}
