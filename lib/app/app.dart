import 'package:flutter/material.dart';
import 'theme/colors.dart';
import 'theme/typography.dart';
import 'router.dart';
import '../core/accessibility/accessibility_manager.dart';

// Export AppThemeMode for use in other files
export '../core/accessibility/accessibility_manager.dart' show AppThemeMode;

class ChaupalApp extends StatefulWidget {
  const ChaupalApp({super.key});

  @override
  State<ChaupalApp> createState() => _ChaupalAppState();
}

class _ChaupalAppState extends State<ChaupalApp> {
  final AccessibilityManager _accessibilityManager = AccessibilityManager();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _accessibilityManager.init();
      _accessibilityManager.addListener(_onAccessibilityChanged);
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      // If initialization fails, clear corrupted data and retry
      print('Error initializing accessibility manager: $e');
      await _accessibilityManager.clearThemeMode();
      await _accessibilityManager.init();
      _accessibilityManager.addListener(_onAccessibilityChanged);
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    }
  }

  void _onAccessibilityChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _accessibilityManager.removeListener(_onAccessibilityChanged);
    super.dispose();
  }

  ThemeData _buildLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: Brightness.light,
      background: AppColors.background,
    );

    final baseTextTheme = AppTypography.textTheme;
    final scaledTextTheme = baseTextTheme.apply(
      fontSizeFactor: _accessibilityManager.fontScale,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: scaledTextTheme,
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
    );
  }

  ThemeData _buildWarmTheme() {
    // Warm/sepia colors like Kindle - beige, cream, warm browns
    final warmBackground = const Color(0xFFF5E6D3); // Warm beige/cream
    final warmSurface = const Color(0xFFF9F0E6); // Lighter warm cream
    final warmText = const Color(0xFF4A3A2A); // Warm dark brown
    final warmTextSecondary = const Color(0xFF6B5A4A); // Medium warm brown
    final warmOutline = const Color(0xFFD4C4B0); // Warm beige border

    final baseTextTheme = AppTypography.textTheme.copyWith(
      displaySmall: AppTypography.textTheme.displaySmall?.copyWith(
        color: warmText,
      ),
      headlineSmall: AppTypography.textTheme.headlineSmall?.copyWith(
        color: warmText,
      ),
      titleMedium: AppTypography.textTheme.titleMedium?.copyWith(
        color: warmText,
      ),
      bodyLarge: AppTypography.textTheme.bodyLarge?.copyWith(
        color: warmTextSecondary,
      ),
      bodyMedium: AppTypography.textTheme.bodyMedium?.copyWith(
        color: warmTextSecondary,
      ),
    );

    final scaledTextTheme = baseTextTheme.apply(
      fontSizeFactor: _accessibilityManager.fontScale,
    );

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8B6F47), // Warm brown
        brightness: Brightness.light,
        background: warmBackground,
      ),
      scaffoldBackgroundColor: warmBackground,
      textTheme: scaledTextTheme,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: warmSurface,
        foregroundColor: warmText,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: warmSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.08),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: warmOutline, width: 1),
        ),
      ),
      dividerColor: warmOutline,
    );
  }

  ThemeData _buildDarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: Brightness.dark,
      background: const Color(0xFF121212),
    );

    final baseTextTheme = AppTypography.textTheme.copyWith(
      displaySmall: AppTypography.textTheme.displaySmall?.copyWith(
        color: Colors.white,
      ),
      headlineSmall: AppTypography.textTheme.headlineSmall?.copyWith(
        color: Colors.white,
      ),
      titleMedium: AppTypography.textTheme.titleMedium?.copyWith(
        color: Colors.white,
      ),
      bodyLarge: AppTypography.textTheme.bodyLarge?.copyWith(
        color: Colors.white.withOpacity(0.9),
      ),
      bodyMedium: AppTypography.textTheme.bodyMedium?.copyWith(
        color: Colors.white.withOpacity(0.8),
      ),
    );

    final scaledTextTheme = baseTextTheme.apply(
      fontSizeFactor: _accessibilityManager.fontScale,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF121212),
      textTheme: scaledTextTheme,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: const Color(0xFF1E1E1E),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.3),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      dividerColor: Colors.white.withOpacity(0.2),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Build theme based on current mode
    ThemeData currentTheme;
    switch (_accessibilityManager.themeMode) {
      case AppThemeMode.light:
        currentTheme = _buildLightTheme();
        break;
      case AppThemeMode.warm:
        currentTheme = _buildWarmTheme();
        break;
      case AppThemeMode.dark:
        currentTheme = _buildDarkTheme();
        break;
    }

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Chaupal Voice',
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: _accessibilityManager.flutterThemeMode,
      // Override with custom theme if warm mode
      builder: (context, child) {
        if (_accessibilityManager.themeMode == AppThemeMode.warm) {
          return Theme(
            data: _buildWarmTheme(),
            child: child!,
          );
        }
        return child!;
      },
      routerConfig: appRouter,
    );
  }
}


