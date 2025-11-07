import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Custom theme modes for the app
enum AppThemeMode {
  light,
  warm,  // Sepia/warm tone like Kindle
  dark,
}

/// Manages accessibility settings: font size scaling and theme mode
class AccessibilityManager extends ChangeNotifier {
  static const String _keyFontScale = 'fontScale';
  static const String _keyThemeMode = 'themeMode';

  static final AccessibilityManager _instance = AccessibilityManager._internal();
  factory AccessibilityManager() => _instance;
  AccessibilityManager._internal();

  SharedPreferences? _prefs;
  
  // Font scale multipliers (1.0 = normal, 1.15 = 15% larger, etc.)
  // Reduced max to prevent overlay errors
  static const List<double> _fontScales = [1.0, 1.15, 1.3, 1.45, 1.6];
  static const List<String> _fontScaleLabels = ['Normal', 'Large', 'Larger', 'Largest', 'Extra Large'];
  
  int _currentFontScaleIndex = 0;
  AppThemeMode _themeMode = AppThemeMode.light;

  double get fontScale => _fontScales[_currentFontScaleIndex];
  String get fontScaleLabel => _fontScaleLabels[_currentFontScaleIndex];
  AppThemeMode get themeMode {
    // Safety check: ensure we always return a valid AppThemeMode
    if (_themeMode is! AppThemeMode) {
      _themeMode = AppThemeMode.light;
    }
    return _themeMode;
  }
  bool get isDarkMode => _themeMode == AppThemeMode.dark;
  bool get isWarmMode => _themeMode == AppThemeMode.warm;
  bool get isLightMode => _themeMode == AppThemeMode.light;
  int get currentFontScaleIndex => _currentFontScaleIndex;
  int get maxFontScaleIndex => _fontScales.length - 1;
  
  // Convert to Flutter's ThemeMode for compatibility
  ThemeMode get flutterThemeMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.warm:
        return ThemeMode.light; // Use light as base, we'll override with warm theme
    }
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Force reset to ensure type safety - clear any corrupted state
    _themeMode = AppThemeMode.light;
    
    // Load font scale
    final savedFontScaleIndex = _prefs?.getInt(_keyFontScale) ?? 0;
    if (savedFontScaleIndex >= 0 && savedFontScaleIndex < _fontScales.length) {
      _currentFontScaleIndex = savedFontScaleIndex;
    }
    
    // Load theme mode - clear old data if it exists and migrate
    final savedThemeMode = _prefs?.getString(_keyThemeMode);
    if (savedThemeMode != null && savedThemeMode.isNotEmpty) {
      // Handle migration from old ThemeMode to new AppThemeMode
      AppThemeMode parsedMode = AppThemeMode.light; // Default
      
      // Try to parse as AppThemeMode first
      try {
        // Check if it's in the format "AppThemeMode.light", "AppThemeMode.warm", etc.
        String modeString = savedThemeMode;
        if (modeString.contains('AppThemeMode.')) {
          modeString = modeString.replaceAll('AppThemeMode.', '');
        }
        
        // Try to match by name (handle both "light" and "AppThemeMode.light" formats)
        parsedMode = AppThemeMode.values.firstWhere(
          (mode) => mode.name == modeString || 
                    mode.name == savedThemeMode ||
                    mode.toString() == savedThemeMode ||
                    savedThemeMode.contains(mode.name),
          orElse: () => AppThemeMode.light,
        );
      } catch (e) {
        // If not found, try to migrate from old ThemeMode values
        final lowerMode = savedThemeMode.toLowerCase();
        if (lowerMode.contains('light')) {
          parsedMode = AppThemeMode.light;
        } else if (lowerMode.contains('dark')) {
          parsedMode = AppThemeMode.dark;
        } else if (lowerMode.contains('warm')) {
          parsedMode = AppThemeMode.warm;
        } else {
          parsedMode = AppThemeMode.light; // Default
        }
      }
      
      _themeMode = parsedMode;
      // Save the new format to migrate
      await _saveThemeMode();
    } else {
      // No saved value, use default
      _themeMode = AppThemeMode.light;
      await _saveThemeMode(); // Save default to clear any old format
    }
    
    notifyListeners();
  }

  void increaseFontSize() {
    if (_currentFontScaleIndex < _fontScales.length - 1) {
      _currentFontScaleIndex++;
      _saveFontScale();
      notifyListeners();
    }
  }

  void decreaseFontSize() {
    if (_currentFontScaleIndex > 0) {
      _currentFontScaleIndex--;
      _saveFontScale();
      notifyListeners();
    }
  }

  void setFontScale(int index) {
    if (index >= 0 && index < _fontScales.length) {
      _currentFontScaleIndex = index;
      _saveFontScale();
      notifyListeners();
    }
  }

  void toggleThemeMode() {
    // Cycle through: light -> warm -> dark -> light
    switch (_themeMode) {
      case AppThemeMode.light:
        _themeMode = AppThemeMode.warm;
        break;
      case AppThemeMode.warm:
        _themeMode = AppThemeMode.dark;
        break;
      case AppThemeMode.dark:
        _themeMode = AppThemeMode.light;
        break;
    }
    _saveThemeMode();
    notifyListeners();
  }

  void setThemeMode(AppThemeMode mode) {
    _themeMode = mode;
    _saveThemeMode();
    notifyListeners();
  }
  
  String get themeModeLabel {
    switch (_themeMode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.warm:
        return 'Warm';
      case AppThemeMode.dark:
        return 'Dark';
    }
  }
  
  IconData get themeModeIcon {
    switch (_themeMode) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.warm:
        return Icons.wb_twilight;
      case AppThemeMode.dark:
        return Icons.dark_mode;
    }
  }

  Future<void> _saveFontScale() async {
    await _prefs?.setInt(_keyFontScale, _currentFontScaleIndex);
  }

  Future<void> _saveThemeMode() async {
    // Ensure we're saving a valid AppThemeMode
    if (_themeMode is! AppThemeMode) {
      _themeMode = AppThemeMode.light;
    }
    // Save as just the enum name (e.g., "light", "warm", "dark") for easier parsing
    await _prefs?.setString(_keyThemeMode, _themeMode.name);
  }
  
  /// Clear any corrupted theme mode data (for debugging/migration)
  Future<void> clearThemeMode() async {
    await _prefs?.remove(_keyThemeMode);
    _themeMode = AppThemeMode.light;
    notifyListeners();
  }

  // Get text style with scaled font size
  TextStyle? scaleTextStyle(TextStyle? baseStyle) {
    if (baseStyle == null) return null;
    return baseStyle.copyWith(fontSize: (baseStyle.fontSize ?? 16) * fontScale);
  }
}

