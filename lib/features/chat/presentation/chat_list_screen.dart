import 'package:flutter/material.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../core/localization/l10n.dart';
import '../data/fake_chat_repository.dart';
import '../data/user_model.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FakeChatRepository _repository = FakeChatRepository();
  List<ChatUser> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await _repository.getChatUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  String _getLastMessagePreview(String userId) {
    final lastMessage = _repository.getLastMessage(userId);
    if (lastMessage == null) return 'No messages yet';
    return lastMessage.content;
  }

  String _getLastMessageTime(String userId) {
    final lastMessage = _repository.getLastMessage(userId);
    if (lastMessage == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(lastMessage.timestamp);

    if (difference.inDays > 7) {
      return '${lastMessage.timestamp.day}/${lastMessage.timestamp.month}';
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
          : _users.isEmpty
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
                  onRefresh: _loadUsers,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                    itemCount: _users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: Spacing.xs),
                    itemBuilder: (context, index) {
                    final user = _users[index];
                    final unreadCount = _repository.getUnreadCount(user.id);
                    final lastMessage = _getLastMessagePreview(user.id);
                    final lastTime = _getLastMessageTime(user.id);

                    return _ChatListItem(
                      user: user,
                      lastMessage: lastMessage,
                      lastTime: lastTime,
                      unreadCount: unreadCount,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(user: user),
                          ),
                        );
                        },
                      );
                    },
                  ),
                ),
    );
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

