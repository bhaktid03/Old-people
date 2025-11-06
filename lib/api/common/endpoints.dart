// Centralized API endpoints and base URL configuration
// Update `apiBaseUrl` to point to your backend.

/// Base URL for the API. Keep this as a single source of truth.
/// Example: https://api.example.com
String apiBaseUrl = 'http://10.21.8.236:4000';

/// Helpers for building endpoint URLs from the base.
class Endpoints {
  static String sendOtp() => '$apiBaseUrl/auth/otp/send';
  static String verifyOtp() => '$apiBaseUrl/auth/otp/verify';
  static String updateProfile(String userId) => '$apiBaseUrl/api/v1/profiles/$userId';
  static String getNews() => '$apiBaseUrl/api/v1/news';
  static String createThought() => '$apiBaseUrl/api/v1/thoughts';
  static String getThoughts() => '$apiBaseUrl/api/v1/thoughts';
  static String getThought(String id) => '$apiBaseUrl/api/v1/thoughts/$id';
  static String uploadAudio() => '$apiBaseUrl/api/v1/media/audio';
  static String uploadVideo() => '$apiBaseUrl/api/v1/media/video';
  static String getMediaStreamByThought(String thoughtId) => '$apiBaseUrl/api/v1/media/by-thought/$thoughtId/stream';
  static String createCommunityPostV2() => '$apiBaseUrl/api/v1/community-v2/posts';
  static String getCommunityPostsV2() => '$apiBaseUrl/api/v1/community-v2/posts';
  static String mediaV2Stream({required String type, required String fileId}) => '$apiBaseUrl/api/v1/media-v2/$type/$fileId/stream';
}
