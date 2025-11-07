class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.messageType = MessageType.text,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final MessageType messageType;

  bool get isSent => senderId != receiverId; // In real app, compare with current user

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
      };
}

enum MessageType {
  text,
  audio,
  image,
}

