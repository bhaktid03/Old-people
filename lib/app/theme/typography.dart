import 'package:flutter/material.dart';
import 'colors.dart';

/// Large, readable type scale tailored for older adults
class AppTypography {
  AppTypography._();

  static TextTheme textTheme = const TextTheme(
    displaySmall: TextStyle(
      fontSize: 28,
      height: 1.3,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    headlineSmall: TextStyle(
      fontSize: 22,
      height: 1.35,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    titleMedium: TextStyle(
      fontSize: 20,
      height: 1.4,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    bodyLarge: TextStyle(
      fontSize: 18,
      height: 1.5,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
    ),
    bodyMedium: TextStyle(
      fontSize: 16,
      height: 1.5,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
    ),
    labelLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
  );
}


