import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyUserId = 'userId';
  static const String _keyDisplayName = 'displayName';

  final ValueNotifier<String?> userIdNotifier = ValueNotifier<String?>(null);
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    userIdNotifier.value = _prefs!.getString(_keyUserId);
  }

  String? get userId => userIdNotifier.value;

  Future<void> saveUser({required String userId, String? displayName}) async {
    final SharedPreferences prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
    if (displayName != null) {
      await prefs.setString(_keyDisplayName, displayName);
    }
    userIdNotifier.value = userId;
  }

  Future<void> clear() async {
    final SharedPreferences prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyDisplayName);
    userIdNotifier.value = null;
  }
}


