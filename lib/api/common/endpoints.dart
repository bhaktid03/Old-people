// Centralized API endpoints and base URL configuration
// Update apiBaseUrl to point to your backend.

/// Base URL for the API. Keep this as a single source of truth.
/// Example: https://api.example.com
String apiBaseUrl = 'http://10.132.145.86:4000';

/// Helpers for building endpoint URLs from the base.
class Endpoints {
  static String sendOtp() => '$apiBaseUrl/auth/otp/send';
  static String verifyOtp() => '$apiBaseUrl/auth/otp/verify';
  static String getProfile(String userId) => '$apiBaseUrl/api/v1/profiles/$userId';
  static String updateProfile(String userId) => '$apiBaseUrl/api/v1/profiles/$userId';
  static String deleteAccount(String userId) => '$apiBaseUrl/api/v1/profiles/$userId';
  static String getUserPosts(String userId, {int? limit}) {
    final params = <String>[];
    if (limit != null) params.add('limit=$limit');
    final query = params.isEmpty ? '' : '?${params.join('&')}';
    return '$apiBaseUrl/api/v1/profiles/$userId/posts$query';
  }
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

  // Chat endpoints
  static String createConversation() => '$apiBaseUrl/api/v1/chats/conversations';
  static String listConversations({String? userId, int? limit}) {
    final params = <String>[];
    if (userId != null) {
      params.add('userId=${Uri.encodeComponent(userId)}');
    }
    if (limit != null) {
      params.add('limit=$limit');
    }
    final query = params.isEmpty ? '' : '?${params.join('&')}';
    return '$apiBaseUrl/api/v1/chats/conversations$query';
  }

  static String getConversation(String id) =>
      '$apiBaseUrl/api/v1/chats/conversations/$id';

  static String listMessages(String conversationId, {int? limit, String? before}) {
    final params = <String>[];
    if (limit != null) params.add('limit=$limit');
    if (before != null) params.add('before=$before');
    final query = params.isEmpty ? '' : '?${params.join('&')}';
    return '$apiBaseUrl/api/v1/chats/conversations/$conversationId/messages$query';
  }

  static String sendMessage(String conversationId) =>
      '$apiBaseUrl/api/v1/chats/conversations/$conversationId/messages';

  static String updateReceipt(String messageId) =>
      '$apiBaseUrl/api/v1/chats/messages/${Uri.encodeComponent(messageId)}/receipt';

  // Media streaming endpoint
  static String getMediaStream(String mediaUrl) {
    // If mediaUrl is already a full URL, return it
    if (mediaUrl.startsWith('http://') || mediaUrl.startsWith('https://')) {
      return mediaUrl;
    }
    // If mediaUrl is a path like /api/v1/media/{id}/stream, prepend base URL
    if (mediaUrl.startsWith('/')) {
      return '$apiBaseUrl$mediaUrl';
    }
    // Otherwise, use the media stream endpoint with query parameter
    return '$apiBaseUrl/api/v1/chats/media/stream?mediaUrl=${Uri.encodeComponent(mediaUrl)}';
  }

}