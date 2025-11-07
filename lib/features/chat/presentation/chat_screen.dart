import 'package:flutter/material.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../widgets/mic_dictation_button.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/accessibility/accessibility_manager.dart';
import '../../../api/chats/chats_repository.dart';
import '../../../api/chats/models/conversation.dart';
import '../../../api/chats/models/message.dart' as api_models;
import '../data/conversation_adapter.dart';
import '../data/user_model.dart';
import '../data/chat_message_model.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversation,
    required this.user,
  });

  final Conversation conversation;
  final ChatUser user;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatsRepository _repository = ChatsRepository();
  final SessionManager _session = SessionManager();
  final AccessibilityManager _accessibilityManager = AccessibilityManager();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
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
    _messageController.dispose();
    _scrollController.dispose();
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

  Color _getOutlineColor() {
    if (_accessibilityManager.isDarkMode) {
      return Colors.white.withOpacity(0.1);
    } else if (_accessibilityManager.isWarmMode) {
      return const Color(0xFFD4C4B0); // Warm beige border
    }
    return AppColors.outline;
  }

  Future<void> _initialize() async {
    await _session.init();
    _currentUserId = _session.userId;
    if (_currentUserId != null) {
      await _loadMessages();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to view messages'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }


  Future<void> _loadMessages() async {
    if (_currentUserId == null) return;

    try {
      final apiMessages = await _repository.listMessages(
        conversationId: widget.conversation.id,
        limit: 50,
      );

      // Convert API messages to UI messages
      final messages = apiMessages.map((apiMsg) {
        return ConversationAdapter.apiMessageToUiMessage(
          apiMsg,
          _currentUserId!,
          widget.user.id,
        );
      }).toList();

      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load messages: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_currentUserId == null) return;
    
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();

    // Optimistically add message with temp ID
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = ChatMessage(
      id: tempId,
      senderId: _currentUserId!,
      receiverId: widget.user.id,
      content: content,
      timestamp: DateTime.now(),
      isRead: false,
    );

    setState(() {
      _messages.add(optimisticMessage);
    });
    _scrollToBottom();

    try {
      // Send to API
      final apiMessage = await _repository.sendMessage(
        conversationId: widget.conversation.id,
        senderId: _currentUserId!,
        type: api_models.MessageType.text,
        text: content,
      );

      // Convert API message to UI message
      final uiMessage = ConversationAdapter.apiMessageToUiMessage(
        apiMessage,
        _currentUserId!,
        widget.user.id,
      );

      // Replace optimistic message with real one from server
      setState(() {
        _messages.removeWhere((m) => m.id == tempId);
        _messages.add(uiMessage);
      });
      _scrollToBottom();
    } catch (e) {
      // Remove optimistic message on error
      setState(() {
        _messages.removeWhere((m) => m.id == tempId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  bool _shouldShowTimeSeparator(int index) {
    if (index == 0) return true;
    final current = _messages[index];
    final previous = _messages[index - 1];
    final difference = current.timestamp.difference(previous.timestamp);
    return difference.inMinutes > 5;
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
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.brand.withOpacity(0.1),
                  child: Text(
                    widget.user.name.isNotEmpty
                        ? widget.user.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brand,
                    ),
                  ),
                ),
                if (widget.user.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _getSurfaceColor(),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _getTextPrimary(),
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.user.isOnline)
                    Text(
                      'Online',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.success,
                            fontSize: 12,
                          ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: isDark ? Colors.white70 : AppColors.brand,
                    ),
                  )
                : _messages.isEmpty
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
                              'No messages yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: _getTextMuted(),
                                  ),
                            ),
                            const SizedBox(height: Spacing.xs),
                            Text(
                              'Start the conversation!',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: _getTextMuted(),
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.md,
                          vertical: Spacing.sm,
                        ),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isSent = message.senderId == _currentUserId;
                          final showTime = _shouldShowTimeSeparator(index);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (showTime)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: Spacing.sm,
                                  ),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: Spacing.sm,
                                        vertical: Spacing.xs / 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getOutlineColor().withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _formatTime(message.timestamp),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: _getTextMuted(),
                                              fontSize: 11,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              _MessageBubble(
                                message: message,
                                isSent: isSent,
                                isDark: isDark,
                                isWarm: isWarm,
                                getTextPrimary: _getTextPrimary,
                                getTextMuted: _getTextMuted,
                                getSurfaceColor: _getSurfaceColor,
                              ),
                            ],
                          );
                        },
                      ),
          ),
          _MessageInput(
            controller: _messageController,
            isDark: isDark,
            isWarm: isWarm,
            getTextPrimary: _getTextPrimary,
            getTextSecondary: _getTextSecondary,
            getTextMuted: _getTextMuted,
            getBackgroundColor: _getBackgroundColor,
            getSurfaceColor: _getSurfaceColor,
            getOutlineColor: _getOutlineColor,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isSent,
    required this.isDark,
    required this.isWarm,
    required this.getTextPrimary,
    required this.getTextMuted,
    required this.getSurfaceColor,
  });

  final ChatMessage message;
  final bool isSent;
  final bool isDark;
  final bool isWarm;
  final Color Function() getTextPrimary;
  final Color Function() getTextMuted;
  final Color Function() getSurfaceColor;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: Spacing.xs,
          left: isSent ? Spacing.xl * 2 : 0,
          right: isSent ? 0 : Spacing.xl * 2,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSent ? AppColors.brand : getSurfaceColor(),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isSent ? 16 : 4),
            bottomRight: Radius.circular(isSent ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark 
                  ? Colors.black.withOpacity(0.3)
                  : (isWarm 
                      ? Colors.black.withOpacity(0.1)
                      : AppColors.shadow)),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSent ? Colors.white : getTextPrimary(),
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: Spacing.xs / 2),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isSent
                    ? Colors.white.withOpacity(0.8)
                    : getTextMuted(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}

class _MessageInput extends StatefulWidget {
  const _MessageInput({
    super.key,
    required this.controller,
    required this.isDark,
    required this.isWarm,
    required this.getTextPrimary,
    required this.getTextSecondary,
    required this.getTextMuted,
    required this.getBackgroundColor,
    required this.getSurfaceColor,
    required this.getOutlineColor,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isDark;
  final bool isWarm;
  final Color Function() getTextPrimary;
  final Color Function() getTextSecondary;
  final Color Function() getTextMuted;
  final Color Function() getBackgroundColor;
  final Color Function() getSurfaceColor;
  final Color Function() getOutlineColor;
  final VoidCallback onSend;

  @override
  State<_MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<_MessageInput> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: widget.getSurfaceColor(),
        boxShadow: [
          BoxShadow(
            color: (widget.isDark 
                ? Colors.black.withOpacity(0.3)
                : (widget.isWarm 
                    ? Colors.black.withOpacity(0.1)
                    : AppColors.shadow)),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                style: TextStyle(color: widget.getTextPrimary()),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: widget.getTextMuted()),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: widget.getOutlineColor()),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: widget.getOutlineColor()),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: AppColors.brand, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.sm,
                  ),
                  filled: true,
                  fillColor: widget.getBackgroundColor(),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) {
                  if (_hasText) widget.onSend();
                },
              ),
            ),
            const SizedBox(width: Spacing.sm),
                MicDictationButton(
                  controller: widget.controller,
                  size: 48,
                ),
                const SizedBox(width: Spacing.sm),
            Container(
              decoration: BoxDecoration(
                color: _hasText ? AppColors.brand : widget.getOutlineColor().withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.send_rounded,
                  color: _hasText ? Colors.white : widget.getTextMuted(),
                ),
                onPressed: _hasText ? widget.onSend : null,
                tooltip: 'Send',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

