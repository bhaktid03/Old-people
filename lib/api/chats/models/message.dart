/// Message model matching the API schema
class ChatApiMessage {
  const ChatApiMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.type,
    this.text,
    this.mediaUrl,
    this.mediaMimeType,
    this.voiceDurationMs,
    this.receipts = const [],
    this.editedAt,
    this.deletedAt,
    this.deletedForUserIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final MessageType type;
  final String? text;
  final String? mediaUrl;
  final String? mediaMimeType;
  final int? voiceDurationMs;
  final List<MessageReceipt> receipts;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final List<String> deletedForUserIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Get the message content to display
  String get content => text ?? mediaUrl ?? '';

  /// Check if message is deleted for a specific user
  bool isDeletedForUser(String userId) {
    return deletedAt != null || deletedForUserIds.contains(userId);
  }

  /// Get receipt for a specific user
  MessageReceipt? getReceiptForUser(String userId) {
    try {
      return receipts.firstWhere((r) => r.userId == userId);
    } catch (_) {
      return null;
    }
  }

  factory ChatApiMessage.fromJson(Map<String, dynamic> json) {
    return ChatApiMessage(
      id: json['_id']?.toString() ?? json['id'].toString(),
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == (json['type'] as String? ?? 'text'),
        orElse: () => MessageType.text,
      ),
      text: json['text'] as String?,
      mediaUrl: json['mediaUrl'] as String?,
      mediaMimeType: json['mediaMimeType'] as String?,
      voiceDurationMs: json['voiceDurationMs'] as int?,
      receipts: (json['receipts'] as List<dynamic>?)
              ?.map((e) => MessageReceipt.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      editedAt: json['editedAt'] != null
          ? DateTime.tryParse(json['editedAt'].toString())
          : null,
      deletedAt: json['deletedAt'] != null
          ? DateTime.tryParse(json['deletedAt'].toString())
          : null,
      deletedForUserIds: (json['deletedForUserIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'type': type.name,
        if (text != null) 'text': text,
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
        if (mediaMimeType != null) 'mediaMimeType': mediaMimeType,
        if (voiceDurationMs != null) 'voiceDurationMs': voiceDurationMs,
        'receipts': receipts.map((r) => r.toJson()).toList(),
        if (editedAt != null) 'editedAt': editedAt!.toIso8601String(),
        if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
        'deletedForUserIds': deletedForUserIds,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };
}

enum MessageType {
  text,
  media,
  voice,
}

/// Message receipt model
class MessageReceipt {
  const MessageReceipt({
    required this.userId,
    this.deliveredAt,
    this.seenAt,
  });

  final String userId;
  final DateTime? deliveredAt;
  final DateTime? seenAt;

  bool get isDelivered => deliveredAt != null;
  bool get isSeen => seenAt != null;

  factory MessageReceipt.fromJson(Map<String, dynamic> json) {
    return MessageReceipt(
      userId: json['userId'] as String,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'].toString())
          : null,
      seenAt: json['seenAt'] != null
          ? DateTime.tryParse(json['seenAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        if (deliveredAt != null)
          'deliveredAt': deliveredAt!.toIso8601String(),
        if (seenAt != null) 'seenAt': seenAt!.toIso8601String(),
      };
}

