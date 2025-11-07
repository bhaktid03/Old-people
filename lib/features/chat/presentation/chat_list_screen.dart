import 'package:flutter/material.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/session/session_manager.dart';
import '../../../api/chats/chats_repository.dart';
import '../../../api/chats/models/conversation.dart';
import '../data/conversation_adapter.dart';
import '../data/user_model.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatsRepository _repository = ChatsRepository();
  final SessionManager _session = SessionManager();
  List<Conversation> _conversations = [];
  Map<String, ChatUser> _conversationUsers = {}; // Map conversationId -> ChatUser
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _session.init();
    _currentUserId = _session.userId;
    if (_currentUserId != null) {
      await _loadConversations();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadConversations() async {
    if (_currentUserId == null) return;

    try {
      final conversations = await _repository.listConversations(
        userId: _currentUserId!,
        limit: 50,
      );

      // Convert conversations to ChatUsers for display
      final conversationUsers = <String, ChatUser>{};
      for (final conversation in conversations) {
        final chatUser = ConversationAdapter.conversationToChatUser(
          conversation,
          _currentUserId!,
        );
        if (chatUser != null) {
          conversationUsers[conversation.id] = chatUser;
        }
      }

      setState(() {
        _conversations = conversations;
        _conversationUsers = conversationUsers;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load conversations: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getLastMessagePreview(Conversation conversation) {
    if (conversation.lastMessageId == null) return 'No messages yet';
    // TODO: Could fetch last message text if needed
    return 'Tap to view messages';
  }

  String _getLastMessageTime(Conversation conversation) {
    if (conversation.lastMessageAt == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(conversation.lastMessageAt!);

    if (difference.inDays > 7) {
      return '${conversation.lastMessageAt!.day}/${conversation.lastMessageAt!.month}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          L10n.chats,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        leading: const SizedBox(),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, size: 28),
            onPressed: () {
              // TODO: Implement search
            },
            tooltip: 'Search',
          ),
          const SizedBox(width: Spacing.xs),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 64,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: Spacing.md),
                      Text(
                        'No chats yet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: _conversations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 64,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(height: Spacing.md),
                              Text(
                                'No chats yet',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                          itemCount: _conversations.length,
                          separatorBuilder: (_, __) => const SizedBox(height: Spacing.xs),
                          itemBuilder: (context, index) {
                            final conversation = _conversations[index];
                            final user = _conversationUsers[conversation.id];
                            if (user == null) return const SizedBox.shrink();

                            final lastMessage = _getLastMessagePreview(conversation);
                            final lastTime = _getLastMessageTime(conversation);
                            // TODO: Calculate unread count from receipts
                            final unreadCount = 0;

                            return _ChatListItem(
                              user: user,
                              lastMessage: lastMessage,
                              lastTime: lastTime,
                              unreadCount: unreadCount,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      conversation: conversation,
                                      user: user,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatDialog,
        backgroundColor: AppColors.brand,
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        tooltip: 'New chat',
      ),
    );
  }

  Future<void> _showNewChatDialog() async {
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Chat'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: phoneController,
            decoration: InputDecoration(
              labelText: 'Phone Number or User ID',
              hintText: 'Enter phone number (e.g., +919876543210)',
              prefixIcon: const Icon(Icons.person_add),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.phone,
            textCapitalization: TextCapitalization.none,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a phone number or user ID';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Start Chat'),
          ),
        ],
      ),
    );

    if (result == true && phoneController.text.trim().isNotEmpty) {
      await _createNewConversation(phoneController.text.trim());
    }
  }

  Future<void> _createNewConversation(String otherUserId) async {
    if (_currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to start a chat'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Normalize phone number (remove spaces, ensure it starts with +)
    String normalizedId = otherUserId.replaceAll(RegExp(r'\s+'), '');
    if (!normalizedId.startsWith('+') && !normalizedId.startsWith('91')) {
      // If it doesn't start with + or 91, assume it's a phone number and add +
      if (normalizedId.length == 10) {
        normalizedId = '+91$normalizedId';
      } else if (!normalizedId.startsWith('+')) {
        normalizedId = '+$normalizedId';
      }
    }

    // Check if conversation already exists
    Conversation? existingConversation;
    try {
      existingConversation = _conversations.firstWhere(
        (conv) {
          if (conv.type == ConversationType.solo) {
            return conv.memberIds.contains(normalizedId) &&
                conv.memberIds.contains(_currentUserId!);
          }
          return false;
        },
      );
    } catch (_) {
      // No existing conversation found
      existingConversation = null;
    }

    try {
      Conversation conversation;

      if (existingConversation != null && existingConversation.id.isNotEmpty) {
        // Conversation already exists, use it
        conversation = existingConversation;
      } else {
        // Create new conversation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Creating conversation...'),
              duration: Duration(seconds: 1),
            ),
          );
        }

        conversation = await _repository.createConversation(
          type: ConversationType.solo,
          memberIds: [_currentUserId!, normalizedId],
        );
      }

      // Convert to ChatUser for navigation
      final chatUser = ConversationAdapter.conversationToChatUser(
        conversation,
        _currentUserId!,
      );

      if (chatUser != null && mounted) {
        // Navigate to chat screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversation: conversation,
              user: chatUser,
            ),
          ),
        );

        // Refresh the list to include the new conversation
        await _loadConversations();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create conversation'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create conversation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _ChatListItem extends StatelessWidget {
  const _ChatListItem({
    required this.user,
    required this.lastMessage,
    required this.lastTime,
    required this.unreadCount,
    required this.onTap,
  });

  final ChatUser user;
  final String lastMessage;
  final String lastTime;
  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        color: AppColors.surface,
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.brand.withOpacity(0.1),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brand,
                    ),
                  ),
                ),
                if (user.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (lastTime.isNotEmpty)
                        Text(
                          lastTime,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Spacing.xs / 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: unreadCount > 0
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                                fontWeight: unreadCount > 0
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brand,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Center(
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

