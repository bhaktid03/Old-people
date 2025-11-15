class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.messageType = MessageType.text,
    this.mediaUrl,
    this.mediaMimeType,
    this.voiceDurationMs,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final MessageType messageType;
  final String? mediaUrl;
  final String? mediaMimeType;
  final int? voiceDurationMs;

  bool get isSent => senderId != receiverId; // In real app, compare with current user

  /// Parse voiceDurationMs which can be int, string, or null
  static int? _parseVoiceDurationMs(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      if (value.isEmpty) return null;
      return int.tryParse(value);
    }
    return null;
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id']?.toString() ?? json['id'].toString(),
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      content: json['content'] as String,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
      messageType: MessageType.values.firstWhere(
        (e) => e.name == (json['messageType'] as String? ?? 'text'),
        orElse: () => MessageType.text,
      ),
      mediaUrl: json['mediaUrl'] as String?,
      mediaMimeType: json['mediaMimeType'] as String?,
      voiceDurationMs: _parseVoiceDurationMs(json['voiceDurationMs']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'receiverId': receiverId,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
        'messageType': messageType.name,
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
        if (mediaMimeType != null) 'mediaMimeType': mediaMimeType,
        if (voiceDurationMs != null) 'voiceDurationMs': voiceDurationMs,
      };
}

enum MessageType {
  text,
  audio,
  image,
}

