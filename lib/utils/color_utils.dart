import 'package:flutter/material.dart';

Color? parseColor(String? colorString) {
  if (colorString == null) return null;
  try {
    String hex = colorString.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  } catch (e) {
    print('Error parsing color: $e');
    return null;
  }
}
