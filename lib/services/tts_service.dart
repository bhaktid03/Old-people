import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();

  Future<void> speak(String text, {String language = 'en-US', double rate = 0.85}) async {
    await _tts.setLanguage(language);
    await _tts.setSpeechRate(rate);
    await _tts.speak(text);
  }
}


