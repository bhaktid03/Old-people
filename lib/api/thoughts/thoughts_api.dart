import 'dart:io';
import '../client/api_client.dart';
import '../common/endpoints.dart';

class ThoughtsApi {
  ThoughtsApi({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(enableLogging: true);

  final ApiClient _apiClient;

  /// Create a new thought/comment on a news article
  /// 
  /// Parameters:
  /// - newsUrl: URL of the news article
  /// - userId: User ID
  /// - contentType: Type of content (text, audio, or video)
  /// - text: Text content (required for text type)
  Future<Map<String, dynamic>> createThought({
    required String newsUrl,
    required String userId,
    required String contentType, // 'text', 'audio', or 'video'
    String? text,
  }) async {
    final Map<String, dynamic> body = {
      'newsUrl': newsUrl,
      'userId': userId,
      'contentType': contentType,
      'content': {
        'type': contentType,
        if (text != null && text.isNotEmpty) 'text': text,
      },
    };

    return await _apiClient.postJson(
      url: Endpoints.createThought(),
      body: body,
    );
  }

  /// Upload an audio file
  /// 
  /// Parameters:
  /// - audioFile: The audio file to upload
  /// - thoughtId: Optional thought ID to attach this audio to
  Future<Map<String, dynamic>> uploadAudio({
    required File audioFile,
    String? thoughtId,
  }) async {
    final Map<String, String> fields = {};
    if (thoughtId != null && thoughtId.isNotEmpty) {
      fields['thoughtId'] = thoughtId;
    }

    return await _apiClient.postMultipart(
      url: Endpoints.uploadAudio(),
      fields: fields,
      file: audioFile,
      fileFieldName: 'file',
    );
  }

  /// Upload a video file
  /// 
  /// Parameters:
  /// - videoFile: The video file to upload
  /// - thoughtId: Optional thought ID to attach this video to
  Future<Map<String, dynamic>> uploadVideo({
    required File videoFile,
    String? thoughtId,
  }) async {
    final Map<String, String> fields = {};
    if (thoughtId != null && thoughtId.isNotEmpty) {
      fields['thoughtId'] = thoughtId;
    }

    return await _apiClient.postMultipart(
      url: Endpoints.uploadVideo(),
      fields: fields,
      file: videoFile,
      fileFieldName: 'file',
    );
  }

  /// Get thoughts by news URL
  /// 
  /// Parameters:
  /// - newsUrl: The news article URL
  Future<Map<String, dynamic>> getThoughtsByNewsUrl(String newsUrl) async {
    return await _apiClient.getJson(
      url: Endpoints.getThoughts(),
      queryParameters: {'newsUrl': newsUrl},
    );
  }

  /// Get a specific thought by ID
  /// 
  /// Parameters:
  /// - id: The thought ID
  Future<Map<String, dynamic>> getThought(String id) async {
    return await _apiClient.getJson(
      url: Endpoints.getThought(id),
    );
  }

  /// Get media stream URL for a thought
  /// Returns the full URL to stream the media attached to a thought
  String getMediaStreamUrl(String thoughtId) {
    return Endpoints.getMediaStreamByThought(thoughtId);
  }
}

