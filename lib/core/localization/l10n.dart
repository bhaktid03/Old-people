import 'package:flutter/foundation.dart';

/// Lightweight localization without intl for MVP.
/// Later you can swap to `intl` + ARB without changing call sites.
class L10n {
  static const List<String> supportedLocales = ['en', 'hi'];

  // Current language code; update this to trigger UI rebuilds where listened.
  static final ValueNotifier<String> locale = ValueNotifier<String>('en');

  // Convenience to read a string by key for current locale
  static String _s(String key) {
    final lang = locale.value;
    final table = _strings[lang] ?? _strings['en']!;
    return table[key] ?? _strings['en']![key] ?? key;
  }

  // Exposed getters used across app
  static String get goodMorning => _s('goodMorning');
  static String get home => _s('home');
  static String get community => _s('community');
  static String get chats => _s('chats');
  static String get profile => _s('profile');
  static String get listen => _s('listen');
  static String get openArticle => _s('openArticle');
  static String get shareYourThoughts => _s('shareYourThoughts');
  static String get chooseNewspaper => _s('chooseNewspaper');
  static String get failedToLoad => _s('failedToLoad');
  static String get noHeadlines => _s('noHeadlines');
  // Community
  static String get communityWall => _s('communityWall');
  static String get trending => _s('trending');
  static String get recent => _s('recent');
  static String get showRespect => _s('showRespect');
  static String get thoughtsQ => _s('thoughtsQ');
  static String get play => _s('play');
  static String get pause => _s('pause');
  // Share thoughts modal
  static String get whatsOnYourMind => _s('whatsOnYourMind');
  static String get tellUsPlaceholder => _s('tellUsPlaceholder');
  static String get record => _s('record');
  static String get post => _s('post');
  static String get cancel => _s('cancel');
  static String get shareYourVichaar => _s('shareYourVichaar');
  static String get recordAudio => _s('recordAudio');
  static String get typeText => _s('typeText');
  static String get recordVideo => _s('recordVideo');
  static String get thoughtsByViewers => _s('thoughtsByViewers');
  static String get enterYourThought => _s('enterYourThought');
  static String get submit => _s('submit');
  static String get recording => _s('recording');
  static String get stopRecording => _s('stopRecording');
  static String get noThoughtsYet => _s('noThoughtsYet');

  // String tables (en, hi)
  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'goodMorning': 'Good Morning!',
      'home': 'Home',
      'community': 'Community',
      'chats': 'Chats',
      'profile': 'Profile',
      'listen': 'Listen',
      'openArticle': 'Open Article',
      'shareYourThoughts': 'Share Your Thoughts',
      'chooseNewspaper': 'Choose newspaper',
      'failedToLoad': 'Failed to load headlines',
      'noHeadlines': 'No headlines available for this newspaper.',
      'communityWall': 'Community Wall',
      'trending': 'Trending',
      'recent': 'Recent',
      'showRespect': 'Show Respect',
      'thoughtsQ': 'Thoughts?',
      'play': 'Play',
      'pause': 'Pause',
      'whatsOnYourMind': "What's on your mind?",
      'tellUsPlaceholder': "Tell us what's on your mind...",
      'record': 'Record',
      'post': 'Post',
      'cancel': 'Cancel',
      'shareYourVichaar': 'Share Your Vichaar (Thought)',
      'recordAudio': 'Record Audio',
      'typeText': 'Type Text',
      'recordVideo': 'Record Video',
      'thoughtsByViewers': 'Thoughts By Viewers',
      'enterYourThought': 'Enter your thought...',
      'submit': 'Submit',
      'recording': 'Recording...',
      'stopRecording': 'Stop Recording',
      'noThoughtsYet': 'No thoughts yet. Be the first to share!',
    },
    'hi': {
      'goodMorning': 'सुप्रभात!',
      'home': 'होम',
      'community': 'समुदाय',
      'chats': 'चैट्स',
      'profile': 'प्रोफ़ाइल',
      'listen': 'सुनें',
      'openArticle': 'लेख खोलें',
      'shareYourThoughts': 'अपने विचार साझा करें',
      'chooseNewspaper': 'अख़बार चुनें',
      'failedToLoad': 'समाचार लोड करने में समस्या',
      'noHeadlines': 'इस अख़बार के लिए कोई शीर्षक उपलब्ध नहीं है।',
      'communityWall': 'कम्युनिटी वॉल',
      'trending': 'ट्रेंडिंग',
      'recent': 'हालिया',
      'showRespect': 'सम्मान दिखाएं',
      'thoughtsQ': 'विचार?',
      'play': 'चलाएँ',
      'pause': 'रोकें',
      'whatsOnYourMind': 'आपके मन में क्या है?',
      'tellUsPlaceholder': 'हमें बताएं कि आपके मन में क्या है...',
      'record': 'रिकॉर्ड करें',
      'post': 'पोस्ट करें',
      'cancel': 'रद्द करें',
      'shareYourVichaar': 'अपना विचार साझा करें',
      'recordAudio': 'ऑडियो रिकॉर्ड करें',
      'typeText': 'टेक्स्ट टाइप करें',
      'recordVideo': 'वीडियो रिकॉर्ड करें',
      'thoughtsByViewers': 'दर्शकों के विचार',
      'enterYourThought': 'अपना विचार दर्ज करें...',
      'submit': 'सबमिट करें',
      'recording': 'रिकॉर्डिंग...',
      'stopRecording': 'रिकॉर्डिंग रोकें',
      'noThoughtsYet': 'अभी तक कोई विचार नहीं। पहले साझा करने वाले बनें!',
    },
  };
}


