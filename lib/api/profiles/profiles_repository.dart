import 'dart:io';

import 'models/profile.dart';
import 'profiles_api.dart';

class ProfilesRepository {
  ProfilesRepository({ProfilesApi? api}) : _api = api ?? ProfilesApi();

  final ProfilesApi _api;

  /// Get user profile
  Future<Profile> getProfile(String userId) => _api.getProfile(userId);

  /// Get user's posts
  Future<List<Map<String, dynamic>>> getUserPosts({
    required String userId,
    int? limit,
  }) =>
      _api.getUserPosts(userId: userId, limit: limit);

  /// Update user profile
  Future<Profile> updateProfile({
    required String userId,
    String? displayName,
    File? photoFile,
  }) =>
      _api.updateProfile(
        userId: userId,
        displayName: displayName,
        photoFile: photoFile,
      );

  /// Delete user account
  Future<void> deleteAccount(String userId) => _api.deleteAccount(userId);
}

