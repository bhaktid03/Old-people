import 'package:flutter/material.dart';
import 'theme/colors.dart';
import 'theme/typography.dart';
import 'router.dart';

class ChaupalApp extends StatelessWidget {
  const ChaupalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: Brightness.light,
      background: AppColors.background,
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Chaupal Voice',
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: AppTypography.textTheme,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          color: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shadowColor: AppColors.shadow,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.outline, width: 1),
          ),
        ),
        dividerColor: AppColors.outline,
      ),
      routerConfig: appRouter,
    );
  }
}


