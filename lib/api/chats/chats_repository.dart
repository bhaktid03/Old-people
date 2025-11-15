import 'dart:io';
import 'chats_api.dart';
import 'models/conversation.dart';
import 'models/message.dart';

class ChatsRepository {
  ChatsRepository({ChatsApi? api}) : _api = api ?? ChatsApi();

  final ChatsApi _api;

  /// Create a conversation (solo or group)
  Future<Conversation> createConversation({
    required ConversationType type,
    required List<String> memberIds,
    List<String>? adminIds,
    String? name,
    String? avatarUrl,
  }) =>
      _api.createConversation(
        type: type,
        memberIds: memberIds,
        adminIds: adminIds,
        name: name,
        avatarUrl: avatarUrl,
      );

  /// List conversations for a user
  Future<List<Conversation>> listConversations({
    required String userId,
    int? limit,
  }) =>
      _api.listConversations(
        userId: userId,
        limit: limit,
      );

  /// Get conversation by ID
  Future<Conversation> getConversation(String id) =>
      _api.getConversation(id);

  /// List messages in a conversation
  Future<List<ChatApiMessage>> listMessages({
    required String conversationId,
    int? limit,
    String? before,
  }) =>
      _api.listMessages(
        conversationId: conversationId,
        limit: limit,
        before: before,
      );

  /// Send a message
  Future<ChatApiMessage> sendMessage({
    required String conversationId,
    required String senderId,
    required MessageType type,
    String? text,
    String? mediaUrl,
    String? mediaMimeType,
    int? voiceDurationMs,
    File? mediaFile,
  }) =>
      _api.sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        type: type,
        text: text,
        mediaUrl: mediaUrl,
        mediaMimeType: mediaMimeType,
        voiceDurationMs: voiceDurationMs,
        mediaFile: mediaFile,
      );

  /// Update delivery/read receipts
  Future<void> updateReceipt({
    required String messageId,
    required String userId,
    bool? delivered,
    bool? seen,
  }) =>
      _api.updateReceipt(
        messageId: messageId,
        userId: userId,
        delivered: delivered,
        seen: seen,
      );
}

