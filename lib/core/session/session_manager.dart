import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyUserId = 'userId';
  static const String _keyDisplayName = 'displayName';
  static const String _keyPhotoUrl = 'photoUrl';

  final ValueNotifier<String?> userIdNotifier = ValueNotifier<String?>(null);
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    userIdNotifier.value = _prefs!.getString(_keyUserId);
  }

  String? get userId => userIdNotifier.value;
  
  String? get displayName {
    return _prefs?.getString(_keyDisplayName);
  }
  
  String? get photoUrl {
    return _prefs?.getString(_keyPhotoUrl);
  }

  Future<void> saveUser({
    required String userId, 
    String? displayName,
    String? photoUrl,
  }) async {
    final SharedPreferences prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
    if (displayName != null) {
      await prefs.setString(_keyDisplayName, displayName);
    }
    if (photoUrl != null) {
      await prefs.setString(_keyPhotoUrl, photoUrl);
    }
    userIdNotifier.value = userId;
  }

  Future<void> clear() async {
    final SharedPreferences prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyDisplayName);
    await prefs.remove(_keyPhotoUrl);
    userIdNotifier.value = null;
  }
}


