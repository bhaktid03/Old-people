import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'dart:async';
import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../widgets/mic_dictation_button.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/accessibility/accessibility_manager.dart';
import '../../../api/chats/chats_repository.dart';
import '../../../api/chats/models/conversation.dart';
import '../../../api/chats/models/message.dart' as api_models;
import '../../../api/common/endpoints.dart';
import '../../../services/audio_recorder.dart';
import '../../../services/audio_player_service.dart';
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
  
  // Voice recording state
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  final AudioRecorderService _audioRecorder = AudioRecorderService();
  String? _recordingPath;
  
  // Image picker
  final ImagePicker _imagePicker = ImagePicker();

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
    _recordingTimer?.cancel();
    if (_isRecording) {
      _audioRecorder.stop();
    }
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

      // Sort messages by timestamp (oldest first, newest last)
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

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

  Future<void> _sendMessage({String? audioPath, File? imageFile, File? videoFile}) async {
    if (_currentUserId == null) return;
    
    final content = _messageController.text.trim();
    
    // Determine message type and prepare file
    api_models.MessageType messageType;
    String? text;
    String? mediaMimeType;
    int? voiceDurationMs;
    File? mediaFile;
    
    if (audioPath != null) {
      messageType = api_models.MessageType.voice;
      mediaFile = File(audioPath);
      mediaMimeType = 'audio/m4a';
      voiceDurationMs = _recordingDuration.inMilliseconds;
    } else if (imageFile != null) {
      messageType = api_models.MessageType.media;
      mediaFile = imageFile;
      mediaMimeType = 'image/jpeg';
      text = content.isNotEmpty ? content : null;
    } else if (videoFile != null) {
      messageType = api_models.MessageType.media;
      mediaFile = videoFile;
      mediaMimeType = 'video/mp4';
      text = content.isNotEmpty ? content : null;
    } else {
      if (content.isEmpty) return;
      messageType = api_models.MessageType.text;
      text = content;
    }

    _messageController.clear();

    // Optimistically add message with temp ID
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = ChatMessage(
      id: tempId,
      senderId: _currentUserId!,
      receiverId: widget.user.id,
      content: text ?? (audioPath != null ? '🎤 Voice message' : '📷 Media'),
      timestamp: DateTime.now(),
      isRead: false,
      messageType: messageType == api_models.MessageType.voice 
          ? MessageType.audio 
          : (messageType == api_models.MessageType.media ? MessageType.image : MessageType.text),
      mediaUrl: mediaFile?.path, // Temporary local path for optimistic UI
      mediaMimeType: mediaMimeType,
      voiceDurationMs: voiceDurationMs,
    );

    setState(() {
      _messages.add(optimisticMessage);
    });
    _scrollToBottom();

    try {
      // Send to API - pass mediaFile for multipart upload
      final apiMessage = await _repository.sendMessage(
        conversationId: widget.conversation.id,
        senderId: _currentUserId!,
        type: messageType,
        text: text,
        mediaMimeType: mediaMimeType,
        voiceDurationMs: voiceDurationMs,
        mediaFile: mediaFile, // This will trigger multipart upload
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
  
  // Voice recording methods
  Future<void> _startRecording() async {
    try {
      await _audioRecorder.start();
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
        _recordingPath = null;
      });
      
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordingDuration = Duration(seconds: _recordingDuration.inSeconds + 1);
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _stopRecording({bool send = true}) async {
    _recordingTimer?.cancel();
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordingPath = path;
      });
      
      if (send && path != null && _recordingDuration.inSeconds > 0) {
        await _sendMessage(audioPath: path);
      }
      
      setState(() {
        _recordingDuration = Duration.zero;
        _recordingPath = null;
      });
    } catch (e) {
      setState(() {
        _isRecording = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to stop recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Photo/Video picker methods
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      
      if (pickedFile != null && mounted) {
        await _sendMessage(imageFile: File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _pickVideo() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      
      if (pickedFile != null && mounted) {
        await _sendMessage(videoFile: File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Video'),
              onTap: () {
                Navigator.pop(context);
                _pickVideo();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
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
      body: Stack(
        children: [
          Column(
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
                onSend: () => _sendMessage(),
                onAttach: _showMediaPicker,
                isRecording: _isRecording,
                recordingDuration: _recordingDuration,
                onStartRecording: _startRecording,
                onStopRecording: _stopRecording,
                formatDuration: _formatDuration,
              ),
            ],
          ),
          // Recording overlay
          if (_isRecording)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        _formatDuration(_recordingDuration),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        'Recording...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatefulWidget {
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
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  final AudioPlayerService _audioPlayer = AudioPlayerService();
  bool _isPlaying = false;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  Duration? _duration;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.message.messageType == MessageType.audio) {
      _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
        if (!mounted) return;
        final isCurrentlyPlaying = _audioPlayer.currentId == widget.message.id && 
                                   _audioPlayer.isPlaying;
        if (isCurrentlyPlaying != _isPlaying) {
          setState(() {
            _isPlaying = isCurrentlyPlaying;
          });
        }
      });
      
      _positionSubscription = _audioPlayer.positionStream.listen((position) {
        if (!mounted) return;
        if (_audioPlayer.currentId == widget.message.id) {
          setState(() {
            _position = position;
            _duration = _audioPlayer.duration;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _toggleAudioPlayback() async {
    if (widget.message.mediaUrl == null) return;
    
    try {
      final mediaUrl = Endpoints.getMediaStream(widget.message.mediaUrl!);
      await _audioPlayer.togglePlay(
        id: widget.message.id,
        sourcePath: mediaUrl,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: Spacing.xs,
          left: widget.isSent ? Spacing.xl * 2 : 0,
          right: widget.isSent ? 0 : Spacing.xl * 2,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        decoration: BoxDecoration(
          color: widget.isSent ? AppColors.brand : widget.getSurfaceColor(),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(widget.isSent ? 16 : 4),
            bottomRight: Radius.circular(widget.isSent ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: (widget.isDark 
                  ? Colors.black.withOpacity(0.3)
                  : (widget.isWarm 
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
            // Voice message
            if (widget.message.messageType == MessageType.audio)
              _buildVoiceMessage()
            // Image message
            else if (widget.message.messageType == MessageType.image && 
                     widget.message.mediaUrl != null)
              _buildImageMessage()
            // Video message
            else if (widget.message.messageType == MessageType.image && 
                     widget.message.mediaMimeType?.startsWith('video/') == true &&
                     widget.message.mediaUrl != null)
              _buildVideoMessage()
            // Text message
            else
              _buildTextMessage(),
            const SizedBox(height: Spacing.xs / 2),
            Text(
              _formatTime(widget.message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: widget.isSent
                    ? Colors.white.withOpacity(0.8)
                    : widget.getTextMuted(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceMessage() {
    final duration = widget.message.voiceDurationMs != null
        ? Duration(milliseconds: widget.message.voiceDurationMs!)
        : _duration ?? Duration.zero;
    final displayDuration = _isPlaying ? _position : duration;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            _isPlaying ? Icons.pause : Icons.play_arrow,
            color: widget.isSent ? Colors.white : AppColors.brand,
            size: 28,
          ),
          onPressed: _toggleAudioPlayback,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: Spacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isPlaying && _duration != null)
                LinearProgressIndicator(
                  value: _duration!.inMilliseconds > 0
                      ? _position.inMilliseconds / _duration!.inMilliseconds
                      : 0,
                  backgroundColor: widget.isSent
                      ? Colors.white.withOpacity(0.3)
                      : AppColors.brand.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.isSent ? Colors.white : AppColors.brand,
                  ),
                )
              else
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: widget.isSent
                        ? Colors.white.withOpacity(0.3)
                        : AppColors.brand.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              const SizedBox(height: Spacing.xs / 2),
              Text(
                _formatDuration(displayDuration),
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isSent
                      ? Colors.white.withOpacity(0.9)
                      : widget.getTextPrimary(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageMessage() {
    final mediaUrl = Endpoints.getMediaStream(widget.message.mediaUrl!);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            mediaUrl,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 200,
                color: widget.getSurfaceColor(),
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: widget.isSent ? Colors.white : AppColors.brand,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                color: widget.getSurfaceColor(),
                child: Icon(
                  Icons.broken_image,
                  color: widget.getTextMuted(),
                  size: 48,
                ),
              );
            },
          ),
        ),
        if (widget.message.content.isNotEmpty) ...[
          const SizedBox(height: Spacing.sm),
          Text(
            widget.message.content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: widget.isSent ? Colors.white : widget.getTextPrimary(),
                  height: 1.4,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildVideoMessage() {
    return _VideoPlayerWidget(
      mediaUrl: Endpoints.getMediaStream(widget.message.mediaUrl!),
      isSent: widget.isSent,
      getSurfaceColor: widget.getSurfaceColor,
      getTextMuted: widget.getTextMuted,
    );
  }

  Widget _buildTextMessage() {
    return Text(
      widget.message.content,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: widget.isSent ? Colors.white : widget.getTextPrimary(),
            height: 1.4,
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

class _VideoPlayerWidget extends StatefulWidget {
  const _VideoPlayerWidget({
    required this.mediaUrl,
    required this.isSent,
    required this.getSurfaceColor,
    required this.getTextMuted,
  });

  final String mediaUrl;
  final bool isSent;
  final Color Function() getSurfaceColor;
  final Color Function() getTextMuted;

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.mediaUrl));
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return Container(
        height: 200,
        color: widget.getSurfaceColor(),
        child: Center(
          child: CircularProgressIndicator(
            color: widget.isSent ? Colors.white : AppColors.brand,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),
          if (!_isPlaying)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(Spacing.md),
              child: Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 48,
              ),
            ),
        ],
      ),
    );
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
    required this.onAttach,
    required this.isRecording,
    required this.recordingDuration,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.formatDuration,
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
  final VoidCallback onAttach;
  final bool isRecording;
  final Duration recordingDuration;
  final VoidCallback onStartRecording;
  final void Function({bool send}) onStopRecording;
  final String Function(Duration) formatDuration;

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
            // Attach button
            IconButton(
              icon: Icon(
                Icons.attach_file_rounded,
                color: widget.getTextPrimary(),
              ),
              onPressed: widget.onAttach,
              tooltip: 'Attach',
            ),
            const SizedBox(width: Spacing.xs),
            Expanded(
              child: TextField(
                controller: widget.controller,
                enabled: !widget.isRecording,
                style: TextStyle(color: widget.getTextPrimary()),
                decoration: InputDecoration(
                  hintText: widget.isRecording 
                      ? 'Recording... ${widget.formatDuration(widget.recordingDuration)}'
                      : 'Type a message...',
                  hintStyle: TextStyle(color: widget.getTextMuted()),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: widget.isRecording 
                          ? AppColors.error 
                          : widget.getOutlineColor(),
                      width: widget.isRecording ? 2 : 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: widget.isRecording 
                          ? AppColors.error 
                          : widget.getOutlineColor(),
                      width: widget.isRecording ? 2 : 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: widget.isRecording 
                          ? AppColors.error 
                          : AppColors.brand, 
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.sm,
                  ),
                  filled: true,
                  fillColor: widget.isRecording 
                      ? AppColors.error.withOpacity(0.1)
                      : widget.getBackgroundColor(),
                  suffixIcon: widget.isRecording
                      ? Padding(
                          padding: const EdgeInsets.all(Spacing.sm),
                          child: Icon(
                            Icons.mic,
                            color: AppColors.error,
                            size: 20,
                          ),
                        )
                      : null,
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) {
                  if (_hasText && !widget.isRecording) {
                    widget.onSend();
                  }
                },
              ),
            ),
            const SizedBox(width: Spacing.sm),
            // Voice recording button (WhatsApp style) or send button
            _VoiceRecordButton(
              isRecording: widget.isRecording,
              hasText: _hasText,
              onStartRecording: widget.onStartRecording,
              onStopRecording: widget.onStopRecording,
              onSend: widget.onSend,
              getTextPrimary: widget.getTextPrimary,
              getOutlineColor: widget.getOutlineColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceRecordButton extends StatefulWidget {
  const _VoiceRecordButton({
    required this.isRecording,
    required this.hasText,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onSend,
    required this.getTextPrimary,
    required this.getOutlineColor,
  });

  final bool isRecording;
  final bool hasText;
  final VoidCallback onStartRecording;
  final void Function({bool send}) onStopRecording;
  final VoidCallback onSend;
  final Color Function() getTextPrimary;
  final Color Function() getOutlineColor;

  @override
  State<_VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends State<_VoiceRecordButton> {
  bool _isPointerDown = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isRecording) {
      return Listener(
        onPointerDown: (_) => _isPointerDown = true,
        onPointerUp: (_) {
          if (_isPointerDown && widget.isRecording) {
            widget.onStopRecording(send: true);
          }
          _isPointerDown = false;
        },
        onPointerCancel: (_) => _isPointerDown = false,
        child: GestureDetector(
          onTap: () => widget.onStopRecording(send: false),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      );
    } else if (widget.hasText) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.brand,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(
            Icons.send_rounded,
            color: Colors.white,
          ),
          onPressed: widget.onSend,
          tooltip: 'Send',
        ),
      );
    } else {
      return Listener(
        onPointerDown: (_) {
          _isPointerDown = true;
          widget.onStartRecording();
        },
        onPointerUp: (_) {
          if (_isPointerDown && widget.isRecording) {
            widget.onStopRecording(send: true);
          }
          _isPointerDown = false;
        },
        onPointerCancel: (_) {
          if (_isPointerDown && widget.isRecording) {
            widget.onStopRecording(send: false);
          }
          _isPointerDown = false;
        },
        child: GestureDetector(
          onLongPress: widget.onStartRecording,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: widget.getOutlineColor().withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mic_rounded,
              color: widget.getTextPrimary(),
              size: 24,
            ),
          ),
        ),
      );
    }
  }
}

