import 'package:flutter/material.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/accessibility/accessibility_manager.dart';
import '../../../api/chats/chats_repository.dart';
import '../../../api/chats/models/conversation.dart';
import '../../../api/profiles/profiles_repository.dart';
import '../../../api/profiles/models/profile.dart';
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
  final ProfilesRepository _profilesRepository = ProfilesRepository();
  final SessionManager _session = SessionManager();
  final AccessibilityManager _accessibilityManager = AccessibilityManager();
  List<Conversation> _conversations = [];
  Map<String, ChatUser> _conversationUsers = {}; // Map conversationId -> ChatUser
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _accessibilityManager.addListener(_onThemeChanged);
    _initialize();
  }

  @override
  void dispose() {
    _accessibilityManager.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // Helper methods to get colors based on theme
  Color _getTextPrimary() {
    if (_accessibilityManager.isDarkMode) {
      return Colors.white;
    } else if (_accessibilityManager.isWarmMode) {
      return const Color(0xFF4A3A2A); // Warm dark brown
    }
    return AppColors.textPrimary;
  }

  Color _getTextSecondary() {
    if (_accessibilityManager.isDarkMode) {
      return Colors.white.withOpacity(0.7);
    } else if (_accessibilityManager.isWarmMode) {
      return const Color(0xFF6B5A4A); // Medium warm brown
    }
    return AppColors.textSecondary;
  }

  Color _getTextMuted() {
    if (_accessibilityManager.isDarkMode) {
      return Colors.white.withOpacity(0.5);
    } else if (_accessibilityManager.isWarmMode) {
      return const Color(0xFF6B5A4A).withOpacity(0.7);
    }
    return AppColors.textMuted;
  }

  Color _getBackgroundColor() {
    if (_accessibilityManager.isDarkMode) {
      return const Color(0xFF121212);
    } else if (_accessibilityManager.isWarmMode) {
      return const Color(0xFFF5E6D3); // Warm beige
    }
    return AppColors.background;
  }

  Color _getSurfaceColor() {
    if (_accessibilityManager.isDarkMode) {
      return const Color(0xFF1E1E1E);
    } else if (_accessibilityManager.isWarmMode) {
      return const Color(0xFFF9F0E6); // Warm cream
    }
    return AppColors.surface;
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
      // Fetch actual user profiles to get correct names
      final conversationUsers = <String, ChatUser>{};
      for (final conversation in conversations) {
        if (conversation.type == ConversationType.solo) {
          final otherMemberId = conversation.memberIds
              .firstWhere((id) => id != _currentUserId, orElse: () => '');
          
          if (otherMemberId.isNotEmpty) {
            try {
              // Fetch the actual profile to get the correct display name
              final profile = await _profilesRepository.getProfile(otherMemberId);
              conversationUsers[conversation.id] = ChatUser(
                id: otherMemberId,
                name: profile.displayName.isNotEmpty ? profile.displayName : otherMemberId,
                avatarUrl: profile.photoUrl,
                isOnline: false, // TODO: Get from presence service
              );
            } catch (e) {
              // If profile fetch fails, use the member ID as name
              conversationUsers[conversation.id] = ChatUser(
                id: otherMemberId,
                name: otherMemberId,
                avatarUrl: null,
                isOnline: false,
              );
            }
          }
        } else {
          // Group conversation
          final chatUser = ConversationAdapter.conversationToChatUser(
            conversation,
            _currentUserId!,
          );
          if (chatUser != null) {
            conversationUsers[conversation.id] = chatUser;
          }
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
    final isDark = _accessibilityManager.isDarkMode;
    final isWarm = _accessibilityManager.isWarmMode;
    
    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      appBar: AppBar(
        backgroundColor: _getSurfaceColor(),
        foregroundColor: _getTextPrimary(),
        title: Text(
          L10n.chats,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getTextPrimary(),
              ),
        ),
        leading: const SizedBox(),
        actions: [
          IconButton(
            icon: Icon(
              Icons.search_rounded, 
              size: 28,
              color: _getTextPrimary(),
            ),
            onPressed: () {
              // TODO: Implement search
            },
            tooltip: 'Search',
          ),
          const SizedBox(width: Spacing.xs),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: isDark ? Colors.white70 : AppColors.brand,
              ),
            )
          : _conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 64,
                        color: _getTextMuted(),
                      ),
                      const SizedBox(height: Spacing.md),
                      Text(
                        'No chats yet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: _getTextMuted(),
                            ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  color: AppColors.brand,
                  child: _conversations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 64,
                                color: _getTextMuted(),
                              ),
                              const SizedBox(height: Spacing.md),
                              Text(
                                'No chats yet',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: _getTextMuted(),
                                    ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: _conversations.length,
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
                              isDark: isDark,
                              isWarm: isWarm,
                              getTextPrimary: _getTextPrimary,
                              getTextSecondary: _getTextSecondary,
                              getTextMuted: _getTextMuted,
                              getSurfaceColor: _getSurfaceColor,
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
        child: const Icon(Icons.add, color: Colors.white, size: 28),
        tooltip: 'New chat',
      ),
    );
  }

  Future<void> _showNewChatDialog() async {
    final searchController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSearching = false;
    Profile? foundProfile;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = _accessibilityManager.isDarkMode;
          final isWarm = _accessibilityManager.isWarmMode;
          
          Color dialogBg = isDark 
              ? const Color(0xFF1E1E1E) 
              : (isWarm ? const Color(0xFFF9F0E6) : Colors.white);
          Color textColor = isDark 
              ? Colors.white 
              : (isWarm ? const Color(0xFF4A3A2A) : AppColors.textPrimary);
          Color hintColor = isDark 
              ? Colors.white.withOpacity(0.5) 
              : (isWarm ? const Color(0xFF6B5A4A) : AppColors.textMuted);

          Future<void> searchUser() async {
            final query = searchController.text.trim();
            if (query.isEmpty) {
              setDialogState(() {
                foundProfile = null;
              });
              return;
            }

            setDialogState(() {
              isSearching = true;
              foundProfile = null;
            });

            try {
              // Normalize phone number
              String normalizedId = query.replaceAll(RegExp(r'\s+'), '');
              if (!normalizedId.startsWith('+') && !normalizedId.startsWith('91')) {
                if (normalizedId.length == 10) {
                  normalizedId = '+91$normalizedId';
                } else if (!normalizedId.startsWith('+')) {
                  normalizedId = '+$normalizedId';
                }
              }

              // Try to fetch profile by userId (phone number)
              final profile = await _profilesRepository.getProfile(normalizedId);
              setDialogState(() {
                foundProfile = profile;
                isSearching = false;
              });
            } catch (e) {
              setDialogState(() {
                foundProfile = null;
                isSearching = false;
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('User not found. Please check the phone number or username.'),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            }
          }

          return AlertDialog(
            backgroundColor: dialogBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'New Chat',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter phone number or user ID',
                      style: TextStyle(
                        color: hintColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: searchController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'e.g., +919876543210',
                        hintStyle: TextStyle(color: hintColor),
                        prefixIcon: Icon(Icons.search, color: hintColor),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: hintColor),
                                onPressed: () {
                                  searchController.clear();
                                  setDialogState(() {
                                    foundProfile = null;
                                  });
                                },
                              )
                            : const SizedBox.shrink(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark 
                                ? Colors.white.withOpacity(0.2)
                                : (isWarm ? const Color(0xFFD4C4B0) : AppColors.outline),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark 
                                ? Colors.white.withOpacity(0.2)
                                : (isWarm ? const Color(0xFFD4C4B0) : AppColors.outline),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.brand,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: isDark 
                            ? Colors.white.withOpacity(0.05)
                            : (isWarm ? const Color(0xFFF5E6D3) : AppColors.background),
                      ),
                      keyboardType: TextInputType.phone,
                      textCapitalization: TextCapitalization.none,
                      onChanged: (_) => setDialogState(() {}),
                      onFieldSubmitted: (_) => searchUser(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a phone number or user ID';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    if (isSearching)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.brand,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Searching...',
                              style: TextStyle(color: hintColor, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    if (foundProfile != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.brand.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.brand.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.brand.withOpacity(0.2),
                              backgroundImage: foundProfile!.photoUrl != null
                                  ? NetworkImage(foundProfile!.photoUrl!)
                                  : null,
                              child: foundProfile!.photoUrl == null
                                  ? Text(
                                      foundProfile!.displayName.isNotEmpty
                                          ? foundProfile!.displayName[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: AppColors.brand,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    foundProfile!.displayName.isNotEmpty
                                        ? foundProfile!.displayName
                                        : foundProfile!.userId,
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    foundProfile!.userId,
                                    style: TextStyle(
                                      color: hintColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: hintColor),
                ),
              ),
              ElevatedButton(
                onPressed: foundProfile != null
                    ? () async {
                        Navigator.of(dialogContext).pop();
                        await _createNewConversation(foundProfile!.userId);
                      }
                    : searchController.text.trim().isNotEmpty
                        ? searchUser
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(foundProfile != null ? 'Start Chat' : 'Search'),
              ),
            ],
          );
        },
      ),
    );
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

      // Fetch the actual profile to get the correct display name
      Profile? profile;
      try {
        profile = await _profilesRepository.getProfile(normalizedId);
      } catch (e) {
        // Profile might not exist, continue with normalizedId as name
      }

      // Create ChatUser with correct name
      final chatUser = ChatUser(
        id: normalizedId,
        name: profile?.displayName.isNotEmpty == true 
            ? profile!.displayName 
            : normalizedId,
        avatarUrl: profile?.photoUrl,
        isOnline: false,
      );

      if (mounted) {
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
    required this.isDark,
    required this.isWarm,
    required this.getTextPrimary,
    required this.getTextSecondary,
    required this.getTextMuted,
    required this.getSurfaceColor,
    required this.onTap,
  });

  final ChatUser user;
  final String lastMessage;
  final String lastTime;
  final int unreadCount;
  final bool isDark;
  final bool isWarm;
  final Color Function() getTextPrimary;
  final Color Function() getTextSecondary;
  final Color Function() getTextMuted;
  final Color Function() getSurfaceColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: getSurfaceColor(),
            border: Border(
              bottom: BorderSide(
                color: (isDark 
                    ? Colors.white.withOpacity(0.05)
                    : (isWarm 
                        ? const Color(0xFFD4C4B0).withOpacity(0.2)
                        : AppColors.outline.withOpacity(0.1))),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // Avatar with online indicator
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.brand.withOpacity(0.1),
                    ),
                    child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              user.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    user.name.isNotEmpty 
                                        ? user.name[0].toUpperCase() 
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.brand,
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Text(
                              user.name.isNotEmpty 
                                  ? user.name[0].toUpperCase() 
                                  : '?',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.brand,
                              ),
                            ),
                          ),
                  ),
                  if (user.isOnline)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: getSurfaceColor(),
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Name, message, and time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: getTextPrimary(),
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (lastTime.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            lastTime,
                            style: TextStyle(
                              color: getTextMuted(),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage,
                            style: TextStyle(
                              fontSize: 15,
                              color: unreadCount > 0
                                  ? getTextPrimary()
                                  : getTextMuted(),
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.brand,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 22,
                              minHeight: 22,
                            ),
                            child: Center(
                              child: Text(
                                unreadCount > 99 ? '99+' : unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

