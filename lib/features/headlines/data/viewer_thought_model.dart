/// Model for viewer thoughts/comments on news articles
class ViewerThought {
  const ViewerThought({
    required this.id,
    required this.userName,
    required this.type,
    this.text,
    this.audioUrl,
    this.videoUrl,
    this.localFilePath,
    this.remoteFileId,
    this.mediaUrl,
    this.duration,
    this.status = ThoughtStatus.pending,
    this.llmReply,
    this.headlineId,
    required this.createdAt,
  });

  final String id;
  final String userName;
  final ThoughtType type;
  final String? text;
  final String? audioUrl;
  final String? videoUrl;
  final String? localFilePath; // local device path for playback before upload
  final String? remoteFileId; // backend fileId (GridFS)
  final String? mediaUrl; // URL to stream media from server
  final Duration? duration;
  final ThoughtStatus status; // pending, uploaded, approved, flagged
  final String? llmReply;
  final String? headlineId; // link to parent headline/article (for MongoDB)
  final DateTime createdAt;

  factory ViewerThought.fromJson(Map<String, dynamic> json) {
    // Extract content if it exists (for API responses)
    final content = json['content'] as Map<String, dynamic>?;
    final mediaUrl = content?['mediaUrl'] as String?;
    
    // Determine type from contentType or type field
    final contentType = json['contentType'] as String?;
    final typeStr = contentType ?? json['type'] as String? ?? 'text';
    
    return ViewerThought(
      id: json['_id']?.toString() ?? json['id'].toString(),
      userName: json['userName'] as String? ?? 'Anonymous',
      type: ThoughtType.fromString(typeStr),
      text: json['text'] as String? ?? content?['text'] as String?,
      audioUrl: json['audioUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      localFilePath: json['localFilePath'] as String?,
      remoteFileId: json['remoteFileId'] as String? ?? content?['audioFileId'] as String? ?? content?['videoFileId'] as String?,
      mediaUrl: mediaUrl,
      duration: json['durationMs'] != null
          ? Duration(milliseconds: json['durationMs'] as int)
          : null,
      status: ThoughtStatus.fromString(json['status'] as String? ?? 'pending'),
      llmReply: json['llmReply'] as String?,
      headlineId: json['headlineId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userName': userName,
        'type': type.toString(),
        'text': text,
        'audioUrl': audioUrl,
        'videoUrl': videoUrl,
        'localFilePath': localFilePath,
        'remoteFileId': remoteFileId,
        'mediaUrl': mediaUrl,
        'durationMs': duration?.inMilliseconds,
        'status': status.toString(),
        'llmReply': llmReply,
        'headlineId': headlineId,
        'createdAt': createdAt.toIso8601String(),
      };
}

enum ThoughtType {
  text,
  audio,
  video;

  static ThoughtType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'audio':
        return ThoughtType.audio;
      case 'video':
        return ThoughtType.video;
      default:
        return ThoughtType.text;
    }
  }

  @override
  String toString() {
    switch (this) {
      case ThoughtType.audio:
        return 'audio';
      case ThoughtType.video:
        return 'video';
      case ThoughtType.text:
        return 'text';
    }
  }
}

enum ThoughtStatus {
  pending,
  uploaded,
  approved,
  flagged;

  static ThoughtStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'uploaded':
        return ThoughtStatus.uploaded;
      case 'approved':
        return ThoughtStatus.approved;
      case 'flagged':
        return ThoughtStatus.flagged;
      default:
        return ThoughtStatus.pending;
    }
  }

  @override
  String toString() {
    switch (this) {
      case ThoughtStatus.uploaded:
        return 'uploaded';
      case ThoughtStatus.approved:
        return 'approved';
      case ThoughtStatus.flagged:
        return 'flagged';
      case ThoughtStatus.pending:
        return 'pending';
    }
  }
}

