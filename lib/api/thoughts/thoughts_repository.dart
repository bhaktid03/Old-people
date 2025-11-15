import 'dart:io';
import 'thoughts_api.dart';
import '../../features/headlines/data/viewer_thought_model.dart';

class ThoughtsRepository {
  ThoughtsRepository({ThoughtsApi? thoughtsApi})
      : _thoughtsApi = thoughtsApi ?? ThoughtsApi();

  final ThoughtsApi _thoughtsApi;

  /// Create a text thought
  Future<ViewerThought> createTextThought({
    required String newsUrl,
    required String userId,
    required String text,
  }) async {
    try {
      final response = await _thoughtsApi.createThought(
        newsUrl: newsUrl,
        userId: userId,
        contentType: 'text',
        text: text,
      );

      // Extract data from nested response structure
      final data = response['data'] as Map<String, dynamic>? ?? response;
      
      // Parse response and create ViewerThought
      return ViewerThought(
        id: data['id']?.toString() ?? data['_id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userName: data['userName'] as String? ?? 'You',
        type: ThoughtType.text,
        text: text,
        createdAt: data['createdAt'] != null
            ? DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        status: ThoughtStatus.pending,
      );
    } catch (e) {
      print('Error creating text thought: $e');
      rethrow;
    }
  }

  /// Create an audio thought and upload the audio file
  Future<ViewerThought> createAudioThought({
    required String newsUrl,
    required String userId,
    required File audioFile,
  }) async {
    try {
      // First create the thought
      final thoughtResponse = await _thoughtsApi.createThought(
        newsUrl: newsUrl,
        userId: userId,
        contentType: 'audio',
      );

      // Extract data from nested response structure
      final data = thoughtResponse['data'] as Map<String, dynamic>? ?? thoughtResponse;
      final thoughtId = data['id']?.toString() ?? 
                       data['_id']?.toString() ?? 
                       DateTime.now().millisecondsSinceEpoch.toString();

      // Then upload the audio file
      final uploadResponse = await _thoughtsApi.uploadAudio(
        audioFile: audioFile,
        thoughtId: thoughtId,
      );

      // Extract data from nested upload response structure
      final uploadData = uploadResponse['data'] as Map<String, dynamic>? ?? uploadResponse;

      // Get the media stream URL
      final mediaUrl = _thoughtsApi.getMediaStreamUrl(thoughtId);

      return ViewerThought(
        id: thoughtId,
        userName: data['userName'] as String? ?? 'You',
        type: ThoughtType.audio,
        remoteFileId: uploadData['fileId'] as String?,
        mediaUrl: mediaUrl,
        createdAt: data['createdAt'] != null
            ? DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        status: ThoughtStatus.uploaded,
        localFilePath: audioFile.path,
      );
    } catch (e) {
      print('Error creating audio thought: $e');
      rethrow;
    }
  }

  /// Create a video thought and upload the video file
  Future<ViewerThought> createVideoThought({
    required String newsUrl,
    required String userId,
    required File videoFile,
  }) async {
    try {
      // First create the thought
      final thoughtResponse = await _thoughtsApi.createThought(
        newsUrl: newsUrl,
        userId: userId,
        contentType: 'video',
      );

      // Extract data from nested response structure
      final data = thoughtResponse['data'] as Map<String, dynamic>? ?? thoughtResponse;
      final thoughtId = data['id']?.toString() ?? 
                       data['_id']?.toString() ?? 
                       DateTime.now().millisecondsSinceEpoch.toString();

      // Then upload the video file
      final uploadResponse = await _thoughtsApi.uploadVideo(
        videoFile: videoFile,
        thoughtId: thoughtId,
      );

      // Extract data from nested upload response structure
      final uploadData = uploadResponse['data'] as Map<String, dynamic>? ?? uploadResponse;

      // Get the media stream URL
      final mediaUrl = _thoughtsApi.getMediaStreamUrl(thoughtId);

      return ViewerThought(
        id: thoughtId,
        userName: data['userName'] as String? ?? 'You',
        type: ThoughtType.video,
        remoteFileId: uploadData['fileId'] as String?,
        mediaUrl: mediaUrl,
        createdAt: data['createdAt'] != null
            ? DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        status: ThoughtStatus.uploaded,
        localFilePath: videoFile.path,
      );
    } catch (e) {
      print('Error creating video thought: $e');
      rethrow;
    }
  }

  /// Get a specific thought by ID
  Future<ViewerThought> getThoughtById(String id) async {
    try {
      final response = await _thoughtsApi.getThought(id);
      
      // Extract data from nested response structure
      final data = response['data'] as Map<String, dynamic>? ?? response;
      
      // Extract content for media URL
      final content = data['content'] as Map<String, dynamic>?;
      final mediaUrl = content?['mediaUrl'] as String?;
      
      // Build full media URL if it's a relative path
      String? fullMediaUrl;
      if (mediaUrl != null) {
        if (mediaUrl.startsWith('http')) {
          fullMediaUrl = mediaUrl;
        } else {
          // If it's a relative path, construct full URL
          fullMediaUrl = _thoughtsApi.getMediaStreamUrl(id);
        }
      }
      
      return ViewerThought(
        id: data['id']?.toString() ?? data['_id']?.toString() ?? id,
        userName: data['userName'] as String? ?? 'Anonymous',
        type: ThoughtType.fromString(data['contentType'] as String? ?? 'text'),
        text: content?['text'] as String?,
        remoteFileId: content?['audioFileId'] as String? ?? content?['videoFileId'] as String?,
        mediaUrl: fullMediaUrl,
        createdAt: data['createdAt'] != null
            ? DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        status: ThoughtStatus.uploaded,
      );
    } catch (e) {
      print('Error fetching thought: $e');
      rethrow;
    }
  }

  /// Get thoughts by news URL
  Future<List<ViewerThought>> getThoughtsByNewsUrl(String newsUrl) async {
    try {
      final response = await _thoughtsApi.getThoughtsByNewsUrl(newsUrl);
      
      // Extract data from nested response structure
      final data = response['data'] as List<dynamic>? ?? [];
      
      return data.map((item) {
        final thoughtData = item as Map<String, dynamic>;
        final content = thoughtData['content'] as Map<String, dynamic>?;
        final mediaUrl = content?['mediaUrl'] as String?;
        
        // Build full media URL if it's a relative path
        String? fullMediaUrl;
        final thoughtId = thoughtData['id']?.toString() ?? thoughtData['_id']?.toString() ?? '';
        
        if (mediaUrl != null && mediaUrl.isNotEmpty) {
          if (mediaUrl.startsWith('http://') || mediaUrl.startsWith('https://')) {
            // Already a full URL
            fullMediaUrl = mediaUrl;
          } else {
            // Relative path, construct full URL
            fullMediaUrl = _thoughtsApi.getMediaStreamUrl(thoughtId);
          }
        } else {
          // If no mediaUrl in content, construct it from thoughtId for audio/video
          if (thoughtData['contentType'] == 'audio' || thoughtData['contentType'] == 'video') {
            fullMediaUrl = _thoughtsApi.getMediaStreamUrl(thoughtId);
          }
        }
        
        print('[ThoughtsRepository] Thought ID: $thoughtId, contentType: ${thoughtData['contentType']}, mediaUrl: $fullMediaUrl');
        
        return ViewerThought(
          id: thoughtData['id']?.toString() ?? thoughtData['_id']?.toString() ?? '',
          userName: thoughtData['userName'] as String? ?? 'Anonymous',
          type: ThoughtType.fromString(thoughtData['contentType'] as String? ?? 'text'),
          text: content?['text'] as String?,
          remoteFileId: content?['audioFileId'] as String? ?? content?['videoFileId'] as String?,
          mediaUrl: fullMediaUrl,
          createdAt: thoughtData['createdAt'] != null
              ? DateTime.tryParse(thoughtData['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now(),
          status: ThoughtStatus.uploaded,
        );
      }).toList();
    } catch (e) {
      print('Error fetching thoughts by news URL: $e');
      rethrow;
    }
  }

  /// Get media stream URL for a thought
  String getMediaStreamUrl(String thoughtId) {
    return _thoughtsApi.getMediaStreamUrl(thoughtId);
  }
}

