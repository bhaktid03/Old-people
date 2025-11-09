import 'dart:io';
import '../client/api_client.dart';
import '../common/endpoints.dart';
import 'models/conversation.dart';
import 'models/message.dart';

class ChatsApi {
  ChatsApi({ApiClient? client})
      : _client = client ?? ApiClient(enableLogging: true);

  final ApiClient _client;

  /// Create a conversation (solo or group)
  /// POST /api/v1/chats/conversations
  Future<Conversation> createConversation({
    required ConversationType type,
    required List<String> memberIds,
    List<String>? adminIds,
    String? name,
    String? avatarUrl,
    String? id,
  }) async {
    // Validate memberIds
    if (memberIds.length < 2) {
      throw Exception('At least 2 memberIds are required');
    }

    // Generate a temporary ID if not provided
    // The server will use this or generate its own
    final conversationId = id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';

    final body = <String, dynamic>{
      '_id': conversationId,
      'type': type.name,
      'memberIds': memberIds,
      if (adminIds != null && adminIds.isNotEmpty) 'adminIds': adminIds,
      if (name != null && name.isNotEmpty) 'name': name,
      if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatarUrl': avatarUrl,
    };

    final response = await _client.postJson(
      url: Endpoints.createConversation(),
      body: body,
    );

    return Conversation.fromJson(response);
  }

  /// List conversations for a user
  /// GET /api/v1/chats/conversations?userId={userId}&limit={limit}
  Future<List<Conversation>> listConversations({
    required String userId,
    int? limit,
  }) async {
    final url = Endpoints.listConversations(
      userId: userId,
      limit: limit,
    );

    final response = await _client.getJson(url: url);

    // Handle empty response
    if (response.isEmpty) {
      return [];
    }

    // Handle response with 'data' property containing a list
    if (response.containsKey('data')) {
      final data = response['data'];
      if (data is List) {
        if (data.isEmpty) return [];
        return data
            .map((json) {
              try {
                return Conversation.fromJson(json as Map<String, dynamic>);
              } catch (e) {
                // Skip invalid entries
                return null;
              }
            })
            .whereType<Conversation>()
            .toList();
      } else if (data is Map<String, dynamic>) {
        // Single object in data property
        try {
          return [Conversation.fromJson(data)];
        } catch (e) {
          return [];
        }
      }
    }

    // Handle response as a single conversation object
    try {
      return [Conversation.fromJson(response)];
    } catch (e) {
      // If parsing fails, return empty list instead of crashing
      return [];
    }
  }

  /// Get conversation by ID
  /// GET /api/v1/chats/conversations/{id}
  Future<Conversation> getConversation(String id) async {
    final response = await _client.getJson(
      url: Endpoints.getConversation(id),
    );

    return Conversation.fromJson(response);
  }

  /// List messages in a conversation
  /// GET /api/v1/chats/conversations/{id}/messages?limit={limit}&before={before}
  Future<List<ChatApiMessage>> listMessages({
    required String conversationId,
    int? limit,
    String? before,
  }) async {
    final url = Endpoints.listMessages(
      conversationId,
      limit: limit,
      before: before,
    );

    final response = await _client.getJson(url: url);

    // Handle both array and object with data property
    if (response.containsKey('data') && response['data'] is List) {
      final data = response['data'] as List<dynamic>;
      return data
          .map((json) => ChatApiMessage.fromJson(json as Map<String, dynamic>))
          .toList();
    } else if (response.containsKey('data')) {
      // Single object in data property
      return [ChatApiMessage.fromJson(response['data'] as Map<String, dynamic>)];
    } else {
      // If response is a single object, wrap it in a list
      return [ChatApiMessage.fromJson(response)];
    }
  }

  /// Send a message
  /// POST /api/v1/chats/conversations/{id}/messages
  /// Supports both JSON (text-only) and multipart/form-data (with media)
  Future<ChatApiMessage> sendMessage({
    required String conversationId,
    required String senderId,
    required MessageType type,
    String? text,
    String? mediaUrl,
    String? mediaMimeType,
    int? voiceDurationMs,
    String? messageId,
    File? mediaFile,
  }) async {
    // If mediaFile is provided, use multipart/form-data
    if (mediaFile != null) {
      final fields = <String, String>{
        'senderId': senderId,
        'type': type.name,
        if (text != null && text.isNotEmpty) 'text': text,
        if (mediaMimeType != null && mediaMimeType.isNotEmpty)
          'mediaMimeType': mediaMimeType,
        if (voiceDurationMs != null) 'voiceDurationMs': voiceDurationMs.toString(),
        // Send empty _id to let server auto-generate
        '_id': '',
      };

      final response = await _client.postMultipart(
        url: Endpoints.sendMessage(conversationId),
        fields: fields,
        file: mediaFile,
        fileFieldName: 'media',
        timeout: const Duration(seconds: 90), // Longer timeout for media uploads
      );

      return ChatApiMessage.fromJson(response);
    }

    // Otherwise, use JSON (text-only or when mediaUrl is already provided)
    final body = <String, dynamic>{
      'senderId': senderId,
      'type': type.name,
      if (text != null && text.isNotEmpty) 'text': text,
      if (mediaUrl != null && mediaUrl.isNotEmpty) 'mediaUrl': mediaUrl,
      if (mediaMimeType != null && mediaMimeType.isNotEmpty)
        'mediaMimeType': mediaMimeType,
      if (voiceDurationMs != null) 'voiceDurationMs': voiceDurationMs,
      // Send empty _id to let server auto-generate
      '_id': '',
    };

    final response = await _client.postJson(
      url: Endpoints.sendMessage(conversationId),
      body: body,
    );

    return ChatApiMessage.fromJson(response);
  }

  /// Update delivery/read receipts
  /// POST /api/v1/chats/messages/{messageId}/receipt
  Future<void> updateReceipt({
    required String messageId,
    required String userId,
    bool? delivered,
    bool? seen,
  }) async {
    final body = <String, dynamic>{
      'userId': userId,
      'delivered': delivered ?? false,
      'seen': seen ?? false,
    };

    await _client.postJson(
      url: Endpoints.updateReceipt(messageId),
      body: body,
    );
  }
}

