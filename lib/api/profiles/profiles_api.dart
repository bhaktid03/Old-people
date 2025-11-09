import 'dart:io';

import '../client/api_client.dart';
import '../common/endpoints.dart';
import 'models/profile.dart';

class ProfilesApi {
  ProfilesApi({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(enableLogging: true);

  final ApiClient _apiClient;

  /// Get user profile by userId
  /// GET /api/v1/profiles/{userId}
  Future<Profile> getProfile(String userId) async {
    final response = await _apiClient.getJson(
      url: Endpoints.getProfile(userId),
    );

    // Handle response format: { ok: true, profile: {...} }
    final profileData = response['profile'] ?? response['data'] ?? response;
    return Profile.fromJson(profileData as Map<String, dynamic>);
  }

  /// Get user's posts
  /// GET /api/v1/profiles/{userId}/posts?limit={limit}
  Future<List<Map<String, dynamic>>> getUserPosts({
    required String userId,
    int? limit,
  }) async {
    final response = await _apiClient.getJson(
      url: Endpoints.getUserPosts(userId, limit: limit),
    );

    final dynamic data = response['data'] ?? response['results'] ?? response['items'] ?? response;
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return <Map<String, dynamic>>[];
  }

  /// Update user profile
  /// PUT /api/v1/profiles/{userId}
  Future<Profile> updateProfile({
    required String userId,
    String? displayName,
    File? photoFile,
  }) async {
    // If photo is provided, use multipart upload
    if (photoFile != null) {
      final fields = <String, String>{
        if (displayName != null && displayName.isNotEmpty) 'displayName': displayName,
      };

      final response = await _apiClient.putMultipart(
        url: Endpoints.updateProfile(userId),
        fields: fields,
        imageFile: photoFile,
        fileFieldName: 'image', // Backend expects 'image' field name
      );

      // Handle response format: { ok: true, profile: {...} }
      final profileData = response['profile'] ?? response['data'] ?? response;
      return Profile.fromJson(profileData as Map<String, dynamic>);
    } else {
      // No photo, use JSON update
      final body = <String, dynamic>{
        if (displayName != null && displayName.isNotEmpty) 'displayName': displayName,
      };

      final response = await _apiClient.putJson(
        url: Endpoints.updateProfile(userId),
        body: body,
      );

      // Handle response format: { ok: true, profile: {...} }
      final profileData = response['profile'] ?? response['data'] ?? response;
      return Profile.fromJson(profileData as Map<String, dynamic>);
    }
  }
}

