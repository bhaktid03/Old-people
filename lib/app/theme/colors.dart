import 'package:flutter/material.dart';

/// App color tokens designed for high contrast and readability.
class AppColors {
  AppColors._();

  // Light theme neutrals
  static const Color background = Color(0xFFF9FAFB); // very light gray
  static const Color surface = Color(0xFFFFFFFF);
  static const Color outline = Color(0xFFB6B6B6);
  static const Color shadow = Color(0x1A000000);

  // Brand
  static const Color brand = Color(0xFF146C94); // deep, accessible blue
  static const Color brandDark = Color(0xFF0E4C68);

  // Text colors with strong contrast
  static const Color textPrimary = Color(0xFF111827); // near black
  static const Color textSecondary = Color(0xFF374151);
  static const Color textMuted = Color(0xFF6B7280);

  // Semantic
  static const Color success = Color(0xFF166534);
  static const Color warning = Color(0xFF92400E);
  static const Color error = Color(0xFF7F1D1D);
}


