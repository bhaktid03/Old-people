/// Conversation model matching the API schema
class Conversation {
  const Conversation({
    required this.id,
    required this.type,
    required this.memberIds,
    this.adminIds = const [],
    this.name,
    this.avatarUrl,
    this.lastMessageId,
    this.lastMessageAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final ConversationType type;
  final List<String> memberIds;
  final List<String> adminIds;
  final String? name;
  final String? avatarUrl;
  final String? lastMessageId;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['_id']?.toString() ?? json['id'].toString(),
      type: ConversationType.values.firstWhere(
        (e) => e.name == (json['type'] as String? ?? 'solo'),
        orElse: () => ConversationType.solo,
      ),
      memberIds: (json['memberIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      adminIds: (json['adminIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      name: json['name'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      lastMessageId: json['lastMessageId'] as String?,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'].toString())
          : null,
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
        'type': type.name,
        'memberIds': memberIds,
        'adminIds': adminIds,
        if (name != null) 'name': name,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (lastMessageId != null) 'lastMessageId': lastMessageId,
        if (lastMessageAt != null)
          'lastMessageAt': lastMessageAt!.toIso8601String(),
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };
}

enum ConversationType {
  solo,
  group,
}

