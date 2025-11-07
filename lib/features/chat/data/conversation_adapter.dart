import '../../../api/chats/models/conversation.dart';
import '../../../api/chats/models/message.dart' as api_models;
import 'chat_message_model.dart';
import 'user_model.dart';

/// Adapter to convert between API models and UI models
class ConversationAdapter {
  /// Convert Conversation to ChatUser for display in list
  /// This extracts the other member from a solo conversation
  static ChatUser? conversationToChatUser(
    Conversation conversation,
    String currentUserId,
  ) {
    // For solo conversations, get the other member
    if (conversation.type == ConversationType.solo) {
      final otherMemberId = conversation.memberIds
          .firstWhere((id) => id != currentUserId, orElse: () => '');
      
      if (otherMemberId.isEmpty) return null;

      return ChatUser(
        id: otherMemberId,
        name: conversation.name ?? 'User',
        avatarUrl: conversation.avatarUrl,
        isOnline: false, // TODO: Get from presence service
      );
    }

    // For group conversations, return group info
    return ChatUser(
      id: conversation.id,
      name: conversation.name ?? 'Group Chat',
      avatarUrl: conversation.avatarUrl,
      isOnline: false,
    );
  }

  /// Convert ChatApiMessage to ChatMessage for UI
  static ChatMessage apiMessageToUiMessage(
    api_models.ChatApiMessage apiMessage,
    String currentUserId,
    String otherUserId,
  ) {
    return ChatMessage(
      id: apiMessage.id,
      senderId: apiMessage.senderId,
      receiverId: apiMessage.senderId == currentUserId
          ? otherUserId
          : currentUserId,
      content: apiMessage.content,
      timestamp: apiMessage.createdAt ?? DateTime.now(),
      isRead: apiMessage.getReceiptForUser(currentUserId)?.isSeen ?? false,
      messageType: _mapMessageType(apiMessage.type),
    );
  }

  static MessageType _mapMessageType(api_models.MessageType apiType) {
    switch (apiType) {
      case api_models.MessageType.text:
        return MessageType.text;
      case api_models.MessageType.media:
        return MessageType.image;
      case api_models.MessageType.voice:
        return MessageType.audio;
    }
  }
}

