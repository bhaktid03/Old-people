import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../core/localization/l10n.dart';

/// Service for text-to-speech functionality with multilingual support.
/// Handles English and Hindi content with automatic language detection.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false;
  bool _isPaused = false;
  String? _currentText;
  String? _currentHeadlineLanguage;
  double _speechRate;
  
  // Callbacks
  VoidCallback? onComplete;
  VoidCallback? onStart;
  VoidCallback? onStop;
  Function(String word, int startOffset, int endOffset)? onWordUpdate;

  TtsService() : _speechRate = 0.75 {
    _initialize();
  }

  Future<void> _initialize() async {
    // Set default parameters with speech rate of 0.75 (slower, more comfortable pace)
    await _tts.setSpeechRate(_speechRate);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    // Set up completion handler
    _tts.setCompletionHandler(() {
      _isPlaying = false;
      _isPaused = false;
      onComplete?.call();
    });

    // Set up start handler
    _tts.setStartHandler(() {
      _isPlaying = true;
      _isPaused = false;
      onStart?.call();
    });

    // Set up progress handler for word-level updates (word highlighting)
    _tts.setProgressHandler((String text, int startOffset, int endOffset, String word) {
      if (onWordUpdate != null) {
        onWordUpdate!(word, startOffset, endOffset);
      }
    });

    // Set up error handler
    _tts.setErrorHandler((msg) {
      _isPlaying = false;
      _isPaused = false;
      print('TTS Error: $msg');
    });
  }

  /// Detects if text contains Hindi characters (Devanagari script)
  bool _containsHindi(String text) {
    // Hindi uses Devanagari script: Unicode range U+0900 to U+097F
    final hindiRegex = RegExp(r'[\u0900-\u097F]');
    return hindiRegex.hasMatch(text);
  }

  /// Detects the primary language of the text
  /// Returns 'hi' if Hindi characters are present (even in mixed content), 'en' otherwise
  /// For mixed content, prioritizes Hindi since Hindi TTS can handle English words better than English TTS handles Hindi
  String _detectLanguage(String text) {
    if (text.isEmpty) return 'en';
    
    // Count Hindi characters
    final hindiRegex = RegExp(r'[\u0900-\u097F]');
    final hindiMatches = hindiRegex.allMatches(text);
    final hindiCharCount = hindiMatches.length;
    
    // If any Hindi characters are present, use Hindi TTS
    // This is a simple heuristic - Hindi TTS engines typically handle English words better
    // than English TTS engines handle Hindi, so we prefer Hindi for mixed content
    if (hindiCharCount > 0) {
      return 'hi';
    }
    
    return 'en';
  }

  /// Maps language code to TTS language code
  /// 'en' -> 'en-US' (or 'en-IN' if available), 'hi' -> 'hi-IN'
  String _getTtsLanguageCode(String langCode) {
    switch (langCode) {
      case 'hi':
        return 'hi-IN';
      case 'en':
      default:
        // Try en-IN first (Indian English), fallback to en-US
        return 'en-IN';
    }
  }

  /// Gets the language to use for TTS
  /// Priority: 1) Detected from text, 2) Headline language, 3) App locale
  String _getLanguageForText(String text, String? headlineLanguage) {
    // First try to detect from text content
    final detectedLang = _detectLanguage(text);
    
    // If headline has explicit language, prefer it if it matches detection
    if (headlineLanguage != null && 
        (headlineLanguage == 'hi' || headlineLanguage == 'en')) {
      // If headline language matches detected, use it
      // Otherwise, if text clearly contains Hindi, use Hindi
      if (detectedLang == 'hi' || headlineLanguage == 'hi') {
        return 'hi';
      }
    }
    
    // Fallback to app locale if detection is ambiguous
    if (detectedLang == 'en' && headlineLanguage == null) {
      return L10n.locale.value;
    }
    
    return detectedLang;
  }

  /// Speaks the given text with automatic language detection
  /// [text] - The text to speak
  /// [headlineLanguage] - Optional language from headline (e.g., 'en', 'hi')
  /// [rate] - Speech rate (defaults to 0.75 for comfortable listening pace)
  Future<void> speak(
    String text, {
    String? headlineLanguage,
    double? rate,
  }) async {
    if (text.isEmpty) return;

    _currentText = text;
    _currentHeadlineLanguage = headlineLanguage;

    // Determine language
    final langCode = _getLanguageForText(text, headlineLanguage);
    final ttsLangCode = _getTtsLanguageCode(langCode);

    try {
      // Set language
      final result = await _tts.setLanguage(ttsLangCode);
      if (result != 1) {
        // Language not available, try fallback
        print('Language $ttsLangCode not available, trying fallback');
        if (langCode == 'hi') {
          await _tts.setLanguage('en-IN'); // Fallback to English
        } else {
          await _tts.setLanguage('en-US'); // Fallback to US English
        }
      }

      // Set speech rate (use provided rate or default to 0.75)
      if (rate != null) {
        _speechRate = rate;
      }
      await _tts.setSpeechRate(_speechRate);

      // Speak
      await _tts.speak(text);
    } catch (e) {
      print('Error in TTS speak: $e');
      _isPlaying = false;
      _isPaused = false;
    }
  }

  /// Pauses the current speech
  /// Note: Pause may not be supported on all platforms. If it fails, we stop instead.
  Future<void> pause() async {
    if (_isPlaying && !_isPaused) {
      try {
        await _tts.pause();
        _isPaused = true;
      } catch (e) {
        // Pause not supported, stop instead
        print('Pause not supported, stopping: $e');
        await stop();
      }
    }
  }

  /// Resumes paused speech
  /// Note: TTS doesn't support true resume from pause position,
  /// so this restarts from the beginning
  Future<void> resume() async {
    if (_isPaused && _currentText != null) {
      // Restart from beginning since TTS doesn't support position tracking
      _isPaused = false;
      await speak(
        _currentText!,
        headlineLanguage: _currentHeadlineLanguage,
        rate: _speechRate,
      );
    }
  }

  /// Stops the current speech
  Future<void> stop() async {
    await _tts.stop();
    _isPlaying = false;
    _isPaused = false;
    _currentText = null;
    _currentHeadlineLanguage = null;
    onStop?.call();
  }

  /// Toggles play/pause
  Future<void> toggle() async {
    if (_isPlaying) {
      if (_isPaused) {
        await resume();
      } else {
        await pause();
      }
    } else if (_currentText != null) {
      // Resume from beginning if we have text but not playing
      await speak(_currentText!);
    }
  }

  /// Checks if TTS is currently playing
  bool get isPlaying => _isPlaying && !_isPaused;

  /// Checks if TTS is currently paused
  bool get isPaused => _isPaused;

  /// Checks if TTS is active (playing or paused)
  bool get isActive => _isPlaying;

  /// Gets the current speech rate
  double getSpeechRate() {
    return _speechRate;
  }

  /// Sets the speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 1.0);
    await _tts.setSpeechRate(_speechRate);
  }

  /// Gets available languages
  Future<List<dynamic>> getLanguages() async {
    return await _tts.getLanguages;
  }

  /// Gets available voices
  Future<List<dynamic>> getVoices() async {
    return await _tts.getVoices;
  }
}