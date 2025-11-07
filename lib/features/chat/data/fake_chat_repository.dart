import 'chat_message_model.dart';
import 'user_model.dart';

/// Fake repository for MVP - replace with real API later
class FakeChatRepository {
  static final List<ChatUser> _users = [
    const ChatUser(
      id: '1',
      name: 'Rajesh Kumar',
      isOnline: true,
    ),
    const ChatUser(
      id: '2',
      name: 'Priya Sharma',
      isOnline: false,
      lastSeen: null,
    ),
    const ChatUser(
      id: '3',
      name: 'Amit Patel',
      isOnline: true,
    ),
    const ChatUser(
      id: '4',
      name: 'Sunita Devi',
      isOnline: false,
    ),
    const ChatUser(
      id: '5',
      name: 'Vikram Singh',
      isOnline: true,
    ),
    const ChatUser(
      id: '6',
      name: 'Anita Joshi',
      isOnline: false,
    ),
  ];

  // Mock conversations - key is userId, value is list of messages
  static final Map<String, List<ChatMessage>> _conversations = {
    '1': [
      ChatMessage(
        id: 'm1',
        senderId: '1',
        receiverId: 'current',
        content: 'Hello! How are you doing?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      ChatMessage(
        id: 'm2',
        senderId: 'current',
        receiverId: '1',
        content: 'I am doing great, thank you!',
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
        isRead: true,
      ),
      ChatMessage(
        id: 'm3',
        senderId: '1',
        receiverId: 'current',
        content: 'That\'s wonderful to hear!',
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
    ],
    '2': [
      ChatMessage(
        id: 'm4',
        senderId: '2',
        receiverId: 'current',
        content: 'Good morning!',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: true,
      ),
    ],
    '3': [
      ChatMessage(
        id: 'm5',
        senderId: 'current',
        receiverId: '3',
        content: 'Hi there!',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
      ),
    ],
  };

  Future<List<ChatUser>> getChatUsers() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return _users;
  }

  Future<List<ChatMessage>> getMessages(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _conversations[userId] ?? [];
  }

  Future<void> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final message = ChatMessage(
      id: 'm${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'current',
      receiverId: receiverId,
      content: content,
      timestamp: DateTime.now(),
      isRead: false,
    );
    _conversations[receiverId] ??= [];
    _conversations[receiverId]!.add(message);
  }

  ChatMessage? getLastMessage(String userId) {
    final messages = _conversations[userId];
    if (messages == null || messages.isEmpty) return null;
    return messages.last;
  }

  int getUnreadCount(String userId) {
    final messages = _conversations[userId] ?? [];
    return messages.where((m) => m.senderId != 'current' && !m.isRead).length;
  }
}

