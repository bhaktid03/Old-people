/// Model for viewer thoughts/comments on news articles
class ViewerThought {
  const ViewerThought({
    required this.id,
    required this.userName,
    required this.type,
    this.text,
    this.audioUrl,
    this.videoUrl,
    required this.createdAt,
  });

  final String id;
  final String userName;
  final ThoughtType type;
  final String? text;
  final String? audioUrl;
  final String? videoUrl;
  final DateTime createdAt;

  factory ViewerThought.fromJson(Map<String, dynamic> json) {
    return ViewerThought(
      id: json['_id']?.toString() ?? json['id'].toString(),
      userName: json['userName'] as String? ?? 'Anonymous',
      type: ThoughtType.fromString(json['type'] as String? ?? 'text'),
      text: json['text'] as String?,
      audioUrl: json['audioUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
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

